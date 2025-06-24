//
//  NCNetworking+LivePhoto.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 07/02/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
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
        }
    }

    func setLivePhoto(metadataFirst: tableMetadata?, metadataLast: tableMetadata?, userInfo aUserInfo: [AnyHashable: Any]? = nil, livePhoto: Bool = true) async {
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
            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO]  Upload set LivePhoto for files " + (metadataFirst.fileName as NSString).deletingPathExtension)
        } else {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Upload set LivePhoto with error \(resultsMetadataFirst.error.errorCode) - \(resultsMetadataLast.error.errorCode)")
        }

        if let aUserInfo {
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadedLivePhoto,
                                                        object: nil,
                                                        userInfo: aUserInfo,
                                                        second: 0.5)
        }
    }
    
    func convertLivePhoto(metadata: tableMetadata) {

        guard metadata.status == NCGlobal.shared.metadataStatusNormal else { return }

        let account = metadata.account
        let livePhotoFile = metadata.livePhotoFile
        let serverUrlfileNamePath = metadata.urlBase + metadata.path + metadata.fileName
        let ocId = metadata.ocId

        DispatchQueue.global().async {
            if let result = NCManageDatabase.shared.getResultMetadata(predicate: NSPredicate(format: "account == '\(account)' AND status == \(NCGlobal.shared.metadataStatusNormal) AND (fileName == '\(livePhotoFile)' || fileId == '\(livePhotoFile)')")) {
                if livePhotoFile == result.fileId { return }
                for case let operation as NCOperationConvertLivePhoto in self.convertLivePhotoQueue.operations where operation.serverUrlfileNamePath == serverUrlfileNamePath { continue }
                self.convertLivePhotoQueue.addOperation(NCOperationConvertLivePhoto(serverUrlfileNamePath: serverUrlfileNamePath, livePhotoFile: result.fileId, account: account, ocId: ocId))
            }
        }
    }
}

class NCOperationConvertLivePhoto: ConcurrentOperation, @unchecked Sendable {

    var serverUrlfileNamePath, livePhotoFile, account, ocId: String

    init(serverUrlfileNamePath: String, livePhotoFile: String, account: String, ocId: String) {
        self.serverUrlfileNamePath = serverUrlfileNamePath
        self.livePhotoFile = livePhotoFile
        self.account = account
        self.ocId = ocId
    }

    override func start() {

        guard !isCancelled else { return self.finish() }
        NextcloudKit.shared.setLivephoto(serverUrlfileNamePath: serverUrlfileNamePath, livePhotoFile: livePhotoFile, account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { _, _, error in
            if error == .success {
                NCManageDatabase.shared.setMetadataLivePhotoByServer(account: self.account, ocId: self.ocId, livePhotoFile: self.livePhotoFile)
            } else {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Convert LivePhoto with error \(error.errorCode)")
            }
            self.finish()
            if NCNetworking.shared.convertLivePhotoQueue.operationCount == 0 {
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource, second: 0.1)
            }
        }
    }
}

