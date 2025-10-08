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
    static let shared = NCAutoUpload()

    private let database = NCManageDatabase.shared
    private let global = NCGlobal.shared
    private let networking = NCNetworking.shared
    private var endForAssetToUpload: Bool = false
    private var applicationState = UIApplication.shared.applicationState
    private let hud = NCHud()

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
        
        guard let account = NCManageDatabase.shared.getActiveAccount(), account.autoUpload else {
            completion(0)
            return
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
    func initAutoUpload(controller: NCMainTabBarController? = nil,
                        tblAccount: tableAccount) async -> Int {
        guard self.networking.isOnline,
              tblAccount.autoUploadStart,
              tblAccount.autoUploadOnlyNew else {
    func initAutoUpload(controller: NCMainTabBarController? = nil) async -> Int {
        guard self.networking.isOnline else {
            return 0
        }
        var counter = 0

        let tblAccounts = await NCManageDatabase.shared.getTableAccountsAsync(predicate: NSPredicate(format: "autoUploadStart == true"))
        for tblAccount in tblAccounts {
            let albumIds = NCPreferences().getAutoUploadAlbumIds(account: tblAccount.account)
            let assetCollections = PHAssetCollection.allAlbums.filter({albumIds.contains($0.localIdentifier)})
            let result = await getCameraRollAssets(controller: nil, assetCollections: assetCollections, tblAccount: tableAccount(value: tblAccount))
            if let assets = result.assets, !assets.isEmpty, let fileNames = result.fileNames {
                let item = await uploadAssets(controller: nil, tblAccount: tblAccount, assets: assets, fileNames: fileNames)
                counter += item
            }
        }

        return counter
    }

    func initAutoUpload(controller: NCMainTabBarController? = nil, account: String) async -> Int {
        await withUnsafeContinuation({ continuation in
            initAutoUpload(controller: controller, account: account) { num in
                continuation.resume(returning: num)
            }
        })
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
    @MainActor
    func startManualAutoUploadForAlbums(controller: NCMainTabBarController?,
                                        model: NCAutoUploadModel,
                                        assetCollections: [PHAssetCollection],
                                        account: String) async {
        defer {
            NCContentPresenter().dismiss(after: 1)
        }

        guard let tblAccount = await self.database.getTableAccountAsync(predicate: NSPredicate(format: "account == %@", account)) else {
            return
        }

        let image = UIImage(systemName: "photo.on.rectangle.angled")?.image(color: .white, size: 20)
        NCContentPresenter().noteTop(text: NSLocalizedString("_creating_db_photo_progress_", comment: ""), image: image, color: .lightGray, delay: .infinity, priority: .max)

        let result = await getCameraRollAssets(controller: controller, assetCollections: assetCollections, tblAccount: tblAccount)

        // IMPORTANT: Always set to autoUploadSinceDate to now
        await self.database.updateAccountPropertyAsync(\.autoUploadSinceDate, value: Date.now, account: tblAccount.account)

        model.onViewAppear()

        guard let assets = result.assets,
              !assets.isEmpty,
              let fileNames = result.fileNames else {
            nkLog(debug: "Automatic upload 0 upload")
            return
        }

        let num = await uploadAssets(controller: controller, tblAccount: tblAccount, assets: assets, fileNames: fileNames)
        nkLog(debug: "Automatic upload \(num) upload")
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
                NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Automatic upload, no new assets found [" + log + "]")
                return completion(0)
    private func uploadAssets(controller: NCMainTabBarController?,
                              tblAccount: tableAccount,
                              assets: [PHAsset],
                              fileNames: [String]) async -> Int {
        let session = NCSession.shared.getSession(account: tblAccount.account)
        let autoUploadServerUrlBase = await self.database.getAccountAutoUploadServerUrlBaseAsync(account: tblAccount.account, urlBase: tblAccount.urlBase, userId: tblAccount.userId)
        var metadatas: [tableMetadata] = []
        let formatCompatibility = NCPreferences().formatCompatibility
        let keychainLivePhoto = NCPreferences().livePhoto
        let fileSystem = NCUtilityFileSystem()
        let skipFileNames = await self.database.fetchSkipFileNamesAsync(account: tblAccount.account,
                                                                        autoUploadServerUrlBase: autoUploadServerUrlBase)

        nkLog(debug: "Automatic upload, new \(assets.count) assets found")

        for (index, asset) in assets.enumerated() {
            let fileName = fileNames[index]

            // Convert HEIC if compatibility mode is on
            let fileNameCompatible = formatCompatibility && (fileName as NSString).pathExtension.lowercased() == "heic" ? (fileName as NSString).deletingPathExtension + ".jpg" : fileName

            if skipFileNames.contains(fileNameCompatible) || skipFileNames.contains(fileName) {
                continue
            }
            var num: Float = 0

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Automatic upload, new \(assets.count) assets found [" + log + "]")

            NCNetworking.shared.createFolder(assets: assets, useSubFolder: tableAccount.autoUploadCreateSubfolder, session: session)
            let mediaType = asset.mediaType
            let isLivePhoto = asset.mediaSubtypes.contains(.photoLive) && keychainLivePhoto
            let serverUrl = tblAccount.autoUploadCreateSubfolder ? fileSystem.createGranularityPath(asset: asset, serverUrlBase: autoUploadServerUrlBase) : autoUploadServerUrlBase
            let onWWAN = (mediaType == .image && tblAccount.autoUploadWWAnPhoto) || (mediaType == .video && tblAccount.autoUploadWWAnVideo)
            let uploadSession = onWWAN ? self.networking.sessionUploadBackgroundWWan : self.networking.sessionUploadBackground

            let metadata = await self.database.createMetadataAsync(fileName: fileName,
                                                                   ocId: UUID().uuidString,
                                                                   serverUrl: serverUrl,
                                                                   session: session,
                                                                   sceneIdentifier: controller?.sceneIdentifier)

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
            metadata.classFile = {
                switch mediaType {
                case .video: return NKTypeClassFile.video.rawValue
                case .image: return NKTypeClassFile.image.rawValue
                default: return ""
                }
            }()

            metadata.iconName = {
                switch mediaType {
                case .video: return NKTypeIconFile.video.rawValue
                case .image: return NKTypeIconFile.image.rawValue
                default: return ""
                }
            }()

            metadata.typeIdentifier = {
                switch mediaType {
                case .video: return "com.apple.quicktime-movie"
                case .image: return "public.image"
                default: return ""
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

            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Start createProcessUploads")
            NCNetworkingProcess.shared.createProcessUploads(metadatas: metadatas, completion: completion)
        // Set last date in autoUploadOnlyNewSinceDate
        if let metadata = metadatas.last {
            let date = metadata.creationDate as Date
            await self.database.updateAccountPropertyAsync(\.autoUploadSinceDate, value: date, account: session.account)
        }

        if !metadatas.isEmpty {
            let metadatasFolder = await self.database.createMetadatasFolderAsync(assets: assets, useSubFolder: tblAccount.autoUploadCreateSubfolder, session: session)
            await self.database.addMetadatasAsync(metadatasFolder + metadatas)
        }

        return metadatas.count
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
    func getCameraRollAssets(controller: NCMainTabBarController?,
                             assetCollections: [PHAssetCollection] = [],
                             tblAccount: tableAccount) async -> (assets: [PHAsset]?, fileNames: [String]?) {
        let hasPermission = await withCheckedContinuation { continuation in
            NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { granted in
                continuation.resume(returning: granted)
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
        guard hasPermission else {
            return (nil, nil)
        }
        let autoUploadServerUrlBase = await self.database.getAccountAutoUploadServerUrlBaseAsync(account: tblAccount.account, urlBase: tblAccount.urlBase, userId: tblAccount.userId)
        var mediaPredicates: [NSPredicate] = []
        var datePredicates: [NSPredicate] = []
        let fetchOptions = PHFetchOptions()

        if tblAccount.autoUploadImage {
            mediaPredicates.append(NSPredicate(format: "mediaType == %i", PHAssetMediaType.image.rawValue))
        }

        if tblAccount.autoUploadVideo {
            mediaPredicates.append(NSPredicate(format: "mediaType == %i", PHAssetMediaType.video.rawValue))
        }

        if let autoUploadSinceDate = tblAccount.autoUploadSinceDate {
            datePredicates.append(NSPredicate(format: "creationDate > %@", autoUploadSinceDate as NSDate))
        } else if let lastDate = await self.database.fetchLastAutoUploadedDateAsync(account: tblAccount.account, autoUploadServerUrlBase: autoUploadServerUrlBase) {
            datePredicates.append(NSPredicate(format: "creationDate > %@", lastDate as NSDate))
        }

        fetchOptions.predicate = {
            switch (mediaPredicates.isEmpty, datePredicates.isEmpty) {
            case (false, false):
                return NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSCompoundPredicate(orPredicateWithSubpredicates: mediaPredicates),
                    NSCompoundPredicate(andPredicateWithSubpredicates: datePredicates)
                ])
            case (false, true):
                return NSCompoundPredicate(orPredicateWithSubpredicates: mediaPredicates)
            case (true, false):
                return NSCompoundPredicate(andPredicateWithSubpredicates: datePredicates)
            default:
                return nil
            }
        }()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let collections: [PHAssetCollection] = {
            if assetCollections.isEmpty {
                let fetched = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
                return fetched.firstObject.map { [$0] } ?? []
            } else {
                return assetCollections
            }
        }()

        guard !collections.isEmpty else {
             return (nil, nil)
        }

        let allAssets = collections.flatMap { collection in
            let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            return result.objects(at: IndexSet(0..<result.count))
        }
        let newAssets = OrderedSet(allAssets)
        let fileNames = newAssets.compactMap { asset -> String? in
            let date = asset.creationDate ?? Date()
            return NCUtilityFileSystem().createFileName(asset.originalFilename, fileDate: date, fileType: asset.mediaType)
        }

        return(Array(newAssets), fileNames)
    }
}
