// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import Alamofire
import Queuer

extension NCNetworking {
    func createLivePhoto(metadata: tableMetadata, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        database.realmRefresh()
        guard let metadataLast = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND urlBase == %@ AND path == %@ AND fileNameView == %@",
                                                                             metadata.account,
                                                                             metadata.urlBase,
                                                                             metadata.path,
                                                                             metadata.livePhotoFile)) else {
            metadata.livePhotoFile = ""
            self.database.addMetadata(metadata)
            return NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadedLivePhoto,
                                                               object: nil,
                                                               userInfo: aUserInfo,
                                                               second: 0.5)
        }
        if metadataLast.status != self.global.metadataStatusNormal {
            return NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Upload set LivePhoto for files (NO Status Normal) " + (metadataLast.fileName as NSString).deletingPathExtension)
        }

        Task {
            await setLivePhoto(metadataFirst: metadata, metadataLast: metadataLast, userInfo: aUserInfo)
    func createLivePhoto(metadata: tableMetadata) async {
        let predicate = NSPredicate(format: "account == %@ AND urlBase == %@ AND path == %@ AND fileNameView == %@",
                                    metadata.account,
                                    metadata.urlBase,
                                    metadata.path,
                                    metadata.livePhotoFile)
    @discardableResult
    func setLivePhoto(account: String) async -> Bool {
        var setLivePhoto: Bool = false
        let results = await NCManageDatabase.shared.getLivePhotos(account: account)
        guard let results,
              !results.isEmpty else {
            return setLivePhoto
        }

        for result in results {

            // VIDEO PART
            //
            let resultLivePhotoVideo = await NextcloudKit.shared.setLivephotoAsync(serverUrlfileNamePath: result.serverUrlFileNameVideo, livePhotoFile: result.fileIdImage, account: account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: account,
                                                                                                path: result.serverUrlFileNameVideo,
                                                                                                name: "setLivephoto")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }
            guard resultLivePhotoVideo.error == .success else {
                nkLog(error: "Upload set LivePhoto Video with error \(resultLivePhotoVideo.error.errorCode)")
                await NCManageDatabase.shared.setLivePhotoError(account: account, serverUrlFileNameNoExt: result.serverUrlFileNameNoExt)
                return false
            }

            // IMAGE PART
            //
            let resultLivePhotoImage = await NextcloudKit.shared.setLivephotoAsync(serverUrlfileNamePath: result.serverUrlFileNameImage, livePhotoFile: result.fileIdVideo, account: account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: account,
                                                                                                path: result.serverUrlFileNameImage,
                                                                                                name: "setLivephoto")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }
        }

    }

    func setLivePhoto(metadataFirst: tableMetadata?, metadataLast: tableMetadata?, livePhoto: Bool = true) async {
        guard let metadataFirst, let metadataLast = metadataLast else { return }
        var livePhotoFileId = ""

        /// METADATA FIRST
        let serverUrlfileNamePathFirst = metadataFirst.urlBase + metadataFirst.path + metadataFirst.fileName
        if livePhoto {
            livePhotoFileId = metadataLast.fileId
        }
        let resultsMetadataFirst = await setLivephoto(serverUrlfileNamePath: serverUrlfileNamePathFirst, livePhotoFile: livePhotoFileId, account: metadataFirst.account)
        if resultsMetadataFirst.error == .success {
            database.setMetadataLivePhotoByServer(account: metadataFirst.account, ocId: metadataFirst.ocId, livePhotoFile: livePhotoFileId)
            await database.setMetadataLivePhotoByServerAsync(account: metadataFirst.account, ocId: metadataFirst.ocId, livePhotoFile: livePhotoFileId)
        }

        ///  METADATA LAST
        let serverUrlfileNamePathLast = metadataLast.urlBase + metadataLast.path + metadataLast.fileName
        if livePhoto {
            livePhotoFileId = metadataFirst.fileId
        }
        let resultsMetadataLast = await setLivephoto(serverUrlfileNamePath: serverUrlfileNamePathLast, livePhotoFile: livePhotoFileId, account: metadataLast.account)
        if resultsMetadataLast.error == .success {
            database.setMetadataLivePhotoByServer(account: metadataLast.account, ocId: metadataLast.ocId, livePhotoFile: livePhotoFileId)
        }

        if resultsMetadataFirst.error == .success, resultsMetadataLast.error == .success {
            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Upload set LivePhoto for files " + (metadataFirst.fileName as NSString).deletingPathExtension)
            await database.setMetadataLivePhotoByServerAsync(account: metadataLast.account, ocId: metadataLast.ocId, livePhotoFile: livePhotoFileId)
        }

        if resultsMetadataFirst.error == .success, resultsMetadataLast.error == .success {
            nkLog(debug: "Upload set LivePhoto for files " + (metadataFirst.fileName as NSString).deletingPathExtension)
            notifyAllDelegates { delegate in
               delegate.transferChange(status: self.global.networkingStatusUploadedLivePhoto,
                                       metadata: metadataFirst,
                                       error: .success)
            guard resultLivePhotoImage.error == .success else {
                nkLog(error: "Upload set LivePhoto Image with error \(resultLivePhotoImage.error.errorCode)")
                await NCManageDatabase.shared.setLivePhotoError(account: account, serverUrlFileNameNoExt: result.serverUrlFileNameNoExt)
                return false
            }

            await NCManageDatabase.shared.setLivePhotoFile(fileId: result.fileIdVideo, livePhotoFile: result.fileIdImage)
            await NCManageDatabase.shared.setLivePhotoFile(fileId: result.fileIdImage, livePhotoFile: result.fileIdVideo)

            await NCManageDatabase.shared.deleteLivePhoto(account: account, serverUrlFileNameNoExt: result.serverUrlFileNameNoExt)

            setLivePhoto = true
        }

        if let aUserInfo {
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadedLivePhoto,
                                                        object: nil,
                                                        userInfo: aUserInfo,
                                                        second: 0.5)
        }
        return setLivePhoto
    }
}
