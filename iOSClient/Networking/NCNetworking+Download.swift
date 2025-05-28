//
//  NCNetworking+Download.swift
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
import RealmSwift

extension NCNetworking {
    func download(metadata: tableMetadata,
                  withNotificationProgressTask: Bool,
                  start: @escaping () -> Void = { },
                  requestHandler: @escaping (_ request: DownloadRequest) -> Void = { _ in },
                  progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                  completion: @escaping (_ afError: AFError?, _ error: NKError) -> Void = { _, _ in }) {
        if metadata.session == sessionDownload {
            downloadFile(metadata: metadata, withNotificationProgressTask: withNotificationProgressTask) {
                start()
            } requestHandler: { request in
                requestHandler(request)
            } progressHandler: { progress in
                progressHandler(progress)
            } completion: { afError, error in
                completion(afError, error)
            }
        } else {
            downloadFileInBackground(metadata: metadata, start: start, completion: { error in
                completion(nil, error)
            })
        }
    }

    private func downloadFile(metadata: tableMetadata,
                              withNotificationProgressTask: Bool,
                              start: @escaping () -> Void = { },
                              requestHandler: @escaping (_ request: DownloadRequest) -> Void = { _ in },
                              progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                              completion: @escaping (_ afError: AFError?, _ error: NKError) -> Void = { _, _ in }) {
        var metadata = metadata
        var downloadTask: URLSessionTask?
        let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
        let fileNameLocalPath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileName)
        let options = NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        if let metadataExists = database.getMetadataFromOcId(metadata.ocId) {
            metadata = metadataExists
        } else {
            metadata = database.addMetadataAndReturn(metadata)
        }

        if metadata.status == global.metadataStatusDownloading || metadata.status == global.metadataStatusUploading {
            return completion(nil, NKError())
        }

        NextcloudKit.shared.download(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, account: metadata.account, options: options, requestHandler: { request in
            self.database.setMetadataSession(ocId: metadata.ocId,
                                             status: self.global.metadataStatusDownloading)
            requestHandler(request)
        }, taskHandler: { task in
            downloadTask = task
            self.database.setMetadataSession(ocId: metadata.ocId,
                                             sessionTaskIdentifier: task.taskIdentifier,
                                             status: self.global.metadataStatusDownloading)
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterDownloadStartFile,
                                                        object: nil,
                                                        userInfo: ["ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "account": metadata.account])
            self.transferDelegate?.tranferChange(status: self.global.notificationCenterDownloadStartFile,
                                                 metadata: tableMetadata(value: metadata),
                                                 error: .success)
            start()
        }, progressHandler: { progress in
            self.transferDelegate?.transferProgressDidUpdate(progress: Float(progress.fractionCompleted),
                                                             totalBytes: progress.totalUnitCount,
                                                             totalBytesExpected: progress.completedUnitCount,
                                                             fileName: metadata.fileName,
                                                             serverUrl: metadata.serverUrl)
            progressHandler(progress)
        }) { _, etag, date, length, responseData, afError, error in
            var error = error
            var dateLastModified: Date?

            // this delay was added because for small file the "taskHandler: { task" is not called, so this part of code is not executed
            NextcloudKit.shared.nkCommonInstance.backgroundQueue.asyncAfter(deadline: .now() + 0.5) {
                if let downloadTask = downloadTask {
                    if let header = responseData?.response?.allHeaderFields,
                       let dateString = header["Last-Modified"] as? String {
                        dateLastModified = NextcloudKit.shared.nkCommonInstance.convertDate(dateString, format: "EEE, dd MMM y HH:mm:ss zzz")
                    }
                    if afError?.isExplicitlyCancelledError ?? false {
                        error = NKError(errorCode: self.global.errorRequestExplicityCancelled, errorDescription: "error request explicity cancelled")
                    }
                    self.downloadComplete(fileName: metadata.fileName, serverUrl: metadata.serverUrl, etag: etag, date: date, dateLastModified: dateLastModified, length: length, task: downloadTask, error: error)
                }
                completion(afError, error)
            }
        }
    }

    private func downloadFileInBackground(metadata: tableMetadata,
                                          start: @escaping () -> Void = { },
                                          requestHandler: @escaping (_ request: DownloadRequest) -> Void = { _ in },
                                          progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                                          completion: @escaping (_ error: NKError) -> Void) {
        let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
        let fileNameLocalPath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)

        start()

        let (task, error) = NKBackground(nkCommonInstance: NextcloudKit.shared.nkCommonInstance).download(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, account: metadata.account)

        if let task, error == .success {
            database.setMetadataSession(ocId: metadata.ocId,
                                        sessionTaskIdentifier: task.taskIdentifier,
                                        status: self.global.metadataStatusDownloading)
            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadStartFile,
                                                        object: nil,
                                                        userInfo: ["ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "account": metadata.account])
            self.transferDelegate?.tranferChange(status: self.global.notificationCenterDownloadStartFile,
                                                 metadata: tableMetadata(value: metadata),
                                                 error: .success)
        } else {
            database.setMetadataSession(ocId: metadata.ocId,
                                        session: "",
                                        sessionTaskIdentifier: 0,
                                        sessionError: "",
                                        selector: "",
                                        status: self.global.metadataStatusNormal)
        }

        completion(error)
    }

    func downloadingFinish(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let httpResponse = (downloadTask.response as? HTTPURLResponse) {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
               let url = downloadTask.currentRequest?.url,
               var serverUrl = url.deletingLastPathComponent().absoluteString.removingPercentEncoding {
                let fileName = url.lastPathComponent
                if serverUrl.hasSuffix("/") { serverUrl = String(serverUrl.dropLast()) }
                if let metadata = database.getResultMetadata(predicate: NSPredicate(format: "serverUrl == %@ AND fileName == %@", serverUrl, fileName)) {
                    let destinationFilePath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileName)
                    utilityFileSystem.copyFile(at: location, to: NSURL.fileURL(withPath: destinationFilePath))
                }
            }
        }
    }

    func downloadComplete(fileName: String,
                          serverUrl: String,
                          etag: String?,
                          date: Date?,
                          dateLastModified: Date?,
                          length: Int64,
                          task: URLSessionTask,
                          error: NKError) {
        isAppSuspending = false

        DispatchQueue.global().async {
            guard let url = task.currentRequest?.url,
                  let metadata = self.database.getMetadata(from: url, sessionTaskIdentifier: task.taskIdentifier) else { return }

            NextcloudKit.shared.nkCommonInstance.appendServerErrorAccount(metadata.account, errorCode: error.errorCode)

            if error == .success {
                NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)
#if !EXTENSION
                if let result = self.database.getE2eEncryption(predicate: NSPredicate(format: "fileNameIdentifier == %@ AND serverUrl == %@", metadata.fileName, metadata.serverUrl)) {
                    NCEndToEndEncryption.shared().decryptFile(metadata.fileName, fileNameView: metadata.fileNameView, ocId: metadata.ocId, key: result.key, initializationVector: result.initializationVector, authenticationTag: result.authenticationTag)
                }
#endif
                self.database.addLocalFile(metadata: metadata)
                self.database.setMetadataSession(ocId: metadata.ocId,
                                                 session: "",
                                                 sessionTaskIdentifier: 0,
                                                 sessionError: "",
                                                 status: self.global.metadataStatusNormal,
                                                 etag: etag)
                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterDownloadedFile,
                                                            object: nil,
                                                            userInfo: ["ocId": metadata.ocId,
                                                                       "ocIdTransfer": metadata.ocIdTransfer,
                                                                       "session": metadata.session,
                                                                       "serverUrl": metadata.serverUrl,
                                                                       "account": metadata.account,
                                                                       "selector": metadata.sessionSelector,
                                                                       "error": error],
                                                            second: 0.5)
                self.transferDelegate?.tranferChange(status: self.global.notificationCenterDownloadedFile,
                                                     metadata: tableMetadata(value: metadata),
                                                     error: error)
            } else if error.errorCode == NSURLErrorCancelled || error.errorCode == self.global.errorRequestExplicityCancelled {
                NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)
                self.database.setMetadataSession(ocId: metadata.ocId,
                                                 session: "",
                                                 sessionTaskIdentifier: 0,
                                                 sessionError: "",
                                                 selector: "",
                                                 status: self.global.metadataStatusNormal)
                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterDownloadCancelFile,
                                                            object: nil,
                                                            userInfo: ["ocId": metadata.ocId,
                                                                       "ocIdTransfer": metadata.ocIdTransfer,
                                                                       "session": metadata.session,
                                                                       "serverUrl": metadata.serverUrl,
                                                                       "account": metadata.account],
                                                            second: 0.5)
                self.transferDelegate?.tranferChange(status: self.global.notificationCenterDownloadCancelFile,
                                                     metadata: tableMetadata(value: metadata),
                                                     error: .success)
            } else {
                NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)

                self.database.setMetadataSession(ocId: metadata.ocId,
                                                 session: "",
                                                 sessionTaskIdentifier: 0,
                                                 sessionError: "",
                                                 selector: "",
                                                 status: self.global.metadataStatusNormal)
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile,
                                                            object: nil,
                                                            userInfo: ["ocId": metadata.ocId,
                                                                       "ocIdTransfer": metadata.ocIdTransfer,
                                                                       "session": metadata.session,
                                                                       "serverUrl": metadata.serverUrl,
                                                                       "account": metadata.account,
                                                                       "selector": metadata.sessionSelector,
                                                                       "error": error],
                                                            second: 0.5)
                self.transferDelegate?.tranferChange(status: NCGlobal.shared.notificationCenterDownloadedFile,
                                                     metadata: tableMetadata(value: metadata),
                                                     error: error)
            }
        }
    }

    func downloadProgress(_ progress: Float,
                          totalBytes: Int64,
                          totalBytesExpected: Int64,
                          fileName: String,
                          serverUrl: String,
                          session: URLSession,
                          task: URLSessionTask) {

        self.transferDelegate?.transferProgressDidUpdate(progress: progress,
                                                         totalBytes: totalBytes,
                                                         totalBytesExpected: totalBytesExpected,
                                                         fileName: fileName,
                                                         serverUrl: serverUrl)
    }
}
