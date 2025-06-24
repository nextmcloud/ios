//
//  NCAutoUpload.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 27/01/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import CoreLocation
import NextcloudKit
import Photos
import OrderedCollections

class NCAutoUpload: NSObject {
    @objc static let shared = NCAutoUpload()

    private let database = NCManageDatabase.shared
    private var endForAssetToUpload: Bool = false
    private var applicationState = UIApplication.shared.applicationState
    private let hud = NCHud()
    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!

    // MARK: -

    @objc func initAutoUpload(viewController: UIViewController?, completion: @escaping (_ items: Int) -> Void) {
        if(NCManageDatabase.shared.getAccountAutoUploadFileName() == "Kamera-Medien" || NCManageDatabase.shared.getAccountAutoUploadFileName() == "Camera-Media"){
            //set autoupload folder as per locale
            if(NCManageDatabase.shared.getAccountAutoUploadFileName() != NCBrandOptions.shared.folderDefaultAutoUpload){
                //set auto upload as per locale
                print("auto upload folder set here....")
                NCManageDatabase.shared.setAccountAutoUploadFileName(NCBrandOptions.shared.folderDefaultAutoUpload)
            }
        }
        
        guard let account = NCManageDatabase.shared.getActiveTableAccount(), account.autoUpload else {
            completion(0)
            return
        }
    }
    
    func initAutoUpload(controller: NCMainTabBarController?, account: String, completion: @escaping (_ num: Int) -> Void) {
        applicationState = UIApplication.shared.applicationState
        DispatchQueue.global().async {
            guard NCNetworking.shared.isOnline,
                  let tableAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", account)),
                  tableAccount.autoUploadStart else {
                return completion(0)
            }

            NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { [self] hasPermission in
                guard hasPermission else {
                    self.database.setAccountAutoUploadProperty("autoUpload", state: false)
                    return completion(0)
                }
                let albumIds = NCKeychain().getAutoUploadAlbumIds(account: account)
                let selectedAlbums = PHAssetCollection.allAlbums.filter({albumIds.contains($0.localIdentifier)})

                self.uploadAssets(controller: controller, assetCollections: selectedAlbums, log: "Init Auto Upload", account: account) { num in
                    completion(num)
                }
            }
        }
    }

    func initAutoUpload(controller: NCMainTabBarController? = nil, account: String) async -> Int {
        await withUnsafeContinuation({ continuation in
            initAutoUpload(controller: controller, account: account) { num in
                continuation.resume(returning: num)
            }
        })
    }
    
    @objc func autoUploadFullPhotos(controller: NCMainTabBarController?, log: String, account: String) {
        applicationState = UIApplication.shared.applicationState
        hud.initHudRing(view: controller?.view, text: nil, detailText: nil, tapToCancelDetailText: false)

        NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
            guard hasPermission else { return }
            DispatchQueue.global().async {
                self.uploadAssetsNewAndFull(controller: controller, selector: NCGlobal.shared.selectorUploadAutoUploadAll, log: log, account: account) { _ in
                    self.hud.dismiss()
                }
            }
        }
    }

    private func uploadAssetsNewAndFull(controller: NCMainTabBarController?, selector: String, log: String, account: String, completion: @escaping (_ num: Int) -> Void) {
        guard let tableAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", account)) else {
            return completion(0)
        }
        let session = NCSession.shared.getSession(account: account)
        let autoUploadPath = self.database.getAccountAutoUploadPath(session: session)
        var metadatas: [tableMetadata] = []

        self.getCameraRollAssets(controller: controller, selector: selector, alignPhotoLibrary: false, account: account) { assets in
            guard let assets, !assets.isEmpty else {
                NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Automatic upload, no new assets found [" + log + "]")
                return completion(0)
            }
            var num: Float = 0

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Automatic upload, new \(assets.count) assets found [" + log + "]")
            // Create the folder for auto upload & if request the subfolders
            self.hud.setText(text: NSLocalizedString("_creating_dir_progress_", comment: ""))
            Task {
                if await !NCNetworking.shared.createFolder(assets: assets, useSubFolder: tableAccount.autoUploadCreateSubfolder, withPush: false, hud: self.hud, session: session) {
                    if selector == NCGlobal.shared.selectorUploadAutoUploadAll {
                        let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_error_createsubfolders_upload_")
                        NCContentPresenter().showError(error: error, priority: .max)
                    }
                    return completion(0)
                }

            }
            
            self.hud.setText(text: NSLocalizedString("_creating_db_photo_progress", comment: ""))
            self.hud.progress(0.0)
            self.endForAssetToUpload = false

            for asset in assets {
                var isLivePhoto = false
                var uploadSession: String = ""
                let assetDate = asset.creationDate ?? Date()
                let assetMediaType = asset.mediaType
                var serverUrl: String = ""
                let fileName = NCUtilityFileSystem().createFileName(asset.originalFilename as String, fileDate: assetDate, fileType: assetMediaType)

                if tableAccount.autoUploadCreateSubfolder {
                    serverUrl = NCUtilityFileSystem().createGranularityPath(asset: asset, serverUrl: autoUploadPath)
                } else {
                    serverUrl = autoUploadPath
                }

                if asset.mediaSubtypes.contains(.photoLive), NCKeychain().livePhoto {
                    isLivePhoto = true
                }

                if selector == NCGlobal.shared.selectorUploadAutoUploadAll {
                    uploadSession = NCNetworking.shared.sessionUpload
                } else {
                    if assetMediaType == PHAssetMediaType.image && tableAccount.autoUploadWWAnPhoto == false {
                        uploadSession = NCNetworking.shared.sessionUploadBackground
                    } else if assetMediaType == PHAssetMediaType.video && tableAccount.autoUploadWWAnVideo == false {
                        uploadSession = NCNetworking.shared.sessionUploadBackground
                    } else if assetMediaType == PHAssetMediaType.image && tableAccount.autoUploadWWAnPhoto {
                        uploadSession = NCNetworking.shared.sessionUploadBackgroundWWan
                    } else if assetMediaType == PHAssetMediaType.video && tableAccount.autoUploadWWAnVideo {
                        uploadSession = NCNetworking.shared.sessionUploadBackgroundWWan
                    } else {
                        uploadSession = NCNetworking.shared.sessionUploadBackground
                    }
                }

                // MOST COMPATIBLE SEARCH --> HEIC --> JPG
                var fileNameSearchMetadata = fileName
                let ext = (fileNameSearchMetadata as NSString).pathExtension.uppercased()

                if ext == "HEIC", NCKeychain().formatCompatibility {
                    fileNameSearchMetadata = (fileNameSearchMetadata as NSString).deletingPathExtension + ".jpg"
                }

                if self.database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@", session.account, serverUrl, fileNameSearchMetadata)) != nil {
                    if selector == NCGlobal.shared.selectorUploadAutoUpload {
                        self.database.addPhotoLibrary([asset], account: session.account)
                    }
                } else {
                    let metadata = self.database.createMetadata(fileName: fileName,
                                                                fileNameView: fileName,
                                                                ocId: NSUUID().uuidString,
                                                                serverUrl: serverUrl,
                                                                url: "",
                                                                contentType: "",
                                                                session: session,
                                                                sceneIdentifier: self.appDelegate.sceneIdentifier)

                    if isLivePhoto {
                        metadata.livePhotoFile = (metadata.fileName as NSString).deletingPathExtension + ".mov"
                    }
                    metadata.assetLocalIdentifier = asset.localIdentifier
                    metadata.session = uploadSession
                    metadata.sessionSelector = selector
                    metadata.status = NCGlobal.shared.metadataStatusWaitUpload
                    metadata.sessionDate = Date()
                    if assetMediaType == PHAssetMediaType.video {
                        metadata.classFile = NKCommon.TypeClassFile.video.rawValue
                    } else if assetMediaType == PHAssetMediaType.image {
                        metadata.classFile = NKCommon.TypeClassFile.image.rawValue
                    }
                    if selector == NCGlobal.shared.selectorUploadAutoUpload {
                        NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Automatic upload added \(metadata.fileNameView) with Identifier \(metadata.assetLocalIdentifier)")
                        self.database.addPhotoLibrary([asset], account: account)
                    }
                    metadatas.append(metadata)
                }

                num += 1
                self.hud.progress(num: num, total: Float(assets.count))
            }

            self.endForAssetToUpload = true

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Start createProcessUploads")
            NCNetworkingProcess.shared.createProcessUploads(metadatas: metadatas, completion: completion)
        }
    }

    func autoUploadSelectedAlbums(controller: NCMainTabBarController?, assetCollections: [PHAssetCollection], log: String, account: String) {
        applicationState = UIApplication.shared.applicationState
        hud.initHudRing(view: controller?.view, text: nil, detailText: nil, tapToCancelDetailText: false)

        NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
            guard hasPermission else { return }
            DispatchQueue.global().async {
                self.uploadAssets(controller: controller, assetCollections: assetCollections, log: log, account: account) { _ in
                    self.hud.dismiss()
                }
            }
        }
    }

    private func uploadAssets(controller: NCMainTabBarController?, assetCollections: [PHAssetCollection] = [], log: String, account: String, completion: @escaping (_ num: Int) -> Void) {
        guard let tableAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", account)) else {
            return completion(0)
        }
        let session = NCSession.shared.getSession(account: account)
        let autoUploadPath = self.database.getAccountAutoUploadPath(session: session)
        var metadatas: [tableMetadata] = []

        self.getCameraRollAssets(controller: controller, assetCollections: assetCollections, account: account) { assets in
            guard let assets, !assets.isEmpty else {
                NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Automatic upload, no new assets found [" + log + "]")
                return completion(0)
            }
            var num: Float = 0

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Automatic upload, new \(assets.count) assets found [" + log + "]")

            NCNetworking.shared.createFolder(assets: assets, useSubFolder: tableAccount.autoUploadCreateSubfolder, session: session)

            self.hud.setText(text: NSLocalizedString("_creating_db_photo_progress", comment: ""))
            self.hud.progress(0.0)
            self.endForAssetToUpload = false

            var lastUploadDate = Date()

            for asset in assets {
                var isLivePhoto = false
                var uploadSession: String = ""
                let assetDate = asset.creationDate ?? Date()
                let assetMediaType = asset.mediaType
                var serverUrl: String = ""
                let fileName = NCUtilityFileSystem().createFileName(asset.originalFilename as String, fileDate: assetDate, fileType: assetMediaType)

                if tableAccount.autoUploadCreateSubfolder {
                    serverUrl = NCUtilityFileSystem().createGranularityPath(asset: asset, serverUrl: autoUploadPath)
                } else {
                    serverUrl = autoUploadPath
                }

                if asset.mediaSubtypes.contains(.photoLive), NCKeychain().livePhoto {
                    isLivePhoto = true
                }

                if assetMediaType == PHAssetMediaType.image && tableAccount.autoUploadWWAnPhoto == false {
                    uploadSession = NCNetworking.shared.sessionUploadBackground
                } else if assetMediaType == PHAssetMediaType.video && tableAccount.autoUploadWWAnVideo == false {
                    uploadSession = NCNetworking.shared.sessionUploadBackground
                } else if assetMediaType == PHAssetMediaType.image && tableAccount.autoUploadWWAnPhoto {
                    uploadSession = NCNetworking.shared.sessionUploadBackgroundWWan
                } else if assetMediaType == PHAssetMediaType.video && tableAccount.autoUploadWWAnVideo {
                    uploadSession = NCNetworking.shared.sessionUploadBackgroundWWan
                } else {
                    uploadSession = NCNetworking.shared.sessionUploadBackground
                }

                // MOST COMPATIBLE SEARCH --> HEIC --> JPG
                var fileNameSearchMetadata = fileName
                let ext = (fileNameSearchMetadata as NSString).pathExtension.lowercased()

                if ext == "heic", NCKeychain().formatCompatibility {
                    fileNameSearchMetadata = (fileNameSearchMetadata as NSString).deletingPathExtension + ".jpg"
                }

                if self.database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@", session.account, serverUrl, fileNameSearchMetadata)) == nil {
                    let metadata = self.database.createMetadata(fileName: fileName,
                                                                fileNameView: fileName,
                                                                ocId: NSUUID().uuidString,
                                                                serverUrl: serverUrl,
                                                                url: "",
                                                                contentType: "",
                                                                session: session,
                                                                sceneIdentifier: controller?.sceneIdentifier)

                    if isLivePhoto {
                        metadata.livePhotoFile = (metadata.fileName as NSString).deletingPathExtension + ".mov"
                    }
                    metadata.assetLocalIdentifier = asset.localIdentifier
                    metadata.session = uploadSession
                    metadata.sessionSelector = NCGlobal.shared.selectorUploadAutoUpload
                    metadata.status = NCGlobal.shared.metadataStatusWaitUpload
                    metadata.sessionDate = Date()
                    if assetMediaType == PHAssetMediaType.video {
                        metadata.classFile = NKCommon.TypeClassFile.video.rawValue
                    } else if assetMediaType == PHAssetMediaType.image {
                        metadata.classFile = NKCommon.TypeClassFile.image.rawValue
                    }

                    let metadataCreationDate = metadata.creationDate as Date

                    if lastUploadDate < metadataCreationDate {
                        lastUploadDate = metadataCreationDate
                    }

                    metadatas.append(metadata)
                }

                num += 1
                self.hud.progress(num: num, total: Float(assets.count))
            }

            self.endForAssetToUpload = true

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Start createProcessUploads")
            NCNetworkingProcess.shared.createProcessUploads(metadatas: metadatas, completion: completion)
        }
    }

    // MARK: -

    func processAssets(_ assetCollection: PHAssetCollection, _ fetchOptions: PHFetchOptions, _ tableAccount: tableAccount, _ account: String) -> [PHAsset] {
        let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        var assetResult: [PHAsset] = []

        assets.enumerateObjects { asset, _, _ in
            assetResult.append(asset)
        }

        return assetResult
    }

    @objc func alignPhotoLibrary(controller: NCMainTabBarController?, account: String) {
        getCameraRollAssets(controller: controller, selector: NCGlobal.shared.selectorUploadAutoUploadAll, alignPhotoLibrary: true, account: account) { assets in
            self.database.clearTable(tablePhotoLibrary.self, account: account)
            guard let assets = assets else { return }

            self.database.addPhotoLibrary(assets, account: account)
            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Align Photo Library \(assets.count)")
        }
    }
  
    private func getCameraRollAssets(controller: NCMainTabBarController?, selector: String, alignPhotoLibrary: Bool, account: String, completion: @escaping (_ assets: [PHAsset]?) -> Void) {
        NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
            guard hasPermission,
                  let tableAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", account)) else {
                return completion(nil)
            }
            let assetCollection = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary, options: nil)
            guard let assetCollection = assetCollection.firstObject else { return completion(nil) }
            let predicateImage = NSPredicate(format: "mediaType == %i", PHAssetMediaType.image.rawValue)
            let predicateVideo = NSPredicate(format: "mediaType == %i", PHAssetMediaType.video.rawValue)
            var predicate: NSPredicate?
            let fetchOptions = PHFetchOptions()
            var newAssets: [PHAsset] = []

            if alignPhotoLibrary || (tableAccount.autoUploadImage && tableAccount.autoUploadVideo) {
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateImage, predicateVideo])
            } else if tableAccount.autoUploadImage {
                predicate = predicateImage
            } else if tableAccount.autoUploadVideo {
                predicate = predicateVideo
            } else {
                return completion(nil)
            }

            fetchOptions.predicate = predicate
            let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)

            if selector == NCGlobal.shared.selectorUploadAutoUpload,
               let idAssets = self.database.getPhotoLibraryIdAsset(image: tableAccount.autoUploadImage, video: tableAccount.autoUploadVideo, account: account) {
                assets.enumerateObjects { asset, _, _ in
                    var creationDateString = ""
                    if let creationDate = asset.creationDate {
                        creationDateString = String(describing: creationDate)
                    }
                    let idAsset = account + asset.localIdentifier + creationDateString
                    if !idAssets.contains(idAsset) {
                        if (asset.isFavorite && tableAccount.autoUploadFavoritesOnly) || !tableAccount.autoUploadFavoritesOnly {
                            newAssets.append(asset)
                        }
                    }
                }
            } else {
                assets.enumerateObjects { asset, _, _ in
                    if (asset.isFavorite && tableAccount.autoUploadFavoritesOnly) || !tableAccount.autoUploadFavoritesOnly {
                        newAssets.append(asset)
                    }
                }
            }
            completion(newAssets)
        }
    }
    
    private func getCameraRollAssets(controller: NCMainTabBarController?, assetCollections: [PHAssetCollection] = [], account: String, completion: @escaping (_ assets: [PHAsset]?) -> Void) {
        NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { [self] hasPermission in
            guard hasPermission,
                  let tableAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", account)) else {
                return completion(nil)
            }
            var newAssets: OrderedSet<PHAsset> = []
            let fetchOptions = PHFetchOptions()
            var mediaPredicates: [NSPredicate] = []

            if tableAccount.autoUploadImage {
                mediaPredicates.append(NSPredicate(format: "mediaType == %i", PHAssetMediaType.image.rawValue))
            }

            if tableAccount.autoUploadVideo {
                mediaPredicates.append(NSPredicate(format: "mediaType == %i", PHAssetMediaType.video.rawValue))
            }

            var datePredicates: [NSPredicate] = []

            if let autoUploadSinceDate = tableAccount.autoUploadSinceDate {
                datePredicates.append(NSPredicate(format: "creationDate > %@", autoUploadSinceDate as NSDate))
            }

            if let autoUploadLastUploadedDate = tableAccount.autoUploadLastUploadedDate {
                datePredicates.append(NSPredicate(format: "creationDate > %@", autoUploadLastUploadedDate as NSDate))
            }

            // Combine media type predicates with OR (if any exist)
            let finalMediaPredicate = mediaPredicates.isEmpty ? nil : NSCompoundPredicate(orPredicateWithSubpredicates: mediaPredicates)
            let finalDatePredicate = datePredicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: datePredicates)

            var finalPredicate: NSPredicate?

            if let finalMediaPredicate, let finalDatePredicate {
                finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [finalMediaPredicate, finalDatePredicate])
            } else if let finalMediaPredicate {
                finalPredicate = finalMediaPredicate
            } else if let finalDatePredicate {
                finalPredicate = finalDatePredicate
            }

            fetchOptions.predicate = finalPredicate

            // Add assets into a set to avoid duplicate photos (same photo in multiple albums)
            if assetCollections.isEmpty {
                let assetCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary, options: nil)
                guard let assetCollection = assetCollection.firstObject else { return completion(nil) }
                let allAssets = processAssets(assetCollection, fetchOptions, tableAccount, account)
                print(allAssets)
                newAssets = OrderedSet(allAssets)
                print(newAssets)
            } else {
                var allAssets: [PHAsset] = []
                for assetCollection in assetCollections {
                    allAssets += processAssets(assetCollection, fetchOptions, tableAccount, account)
                }

                newAssets = OrderedSet(allAssets)
            }

            completion(Array(newAssets))
        }
    }
}
