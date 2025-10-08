// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import Alamofire

extension NCNetworking {
    func uploadHub(metadata: tableMetadata,
                   uploadE2EEDelegate: uploadE2EEDelegate? = nil,
                   controller: UIViewController? = nil,
                   start: @escaping () -> Void = { },
                   requestHandler: @escaping (_ request: UploadRequest) -> Void = { _ in },
                   progressHandler: @escaping (_ totalBytesExpected: Int64, _ totalBytes: Int64, _ fractionCompleted: Double) -> Void = { _, _, _ in },
                   completion: @escaping (_ error: NKError) -> Void = { _ in }) {
        let metadata = tableMetadata.init(value: metadata)
        var numChunks: Int = 0
        var hud: NCHud?
        NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Upload file \(metadata.fileNameView) with Identifier \(metadata.assetLocalIdentifier) with size \(metadata.size) [CHUNK \(metadata.chunk), E2EE \(metadata.isDirectoryE2EE)]")
        let transfer = NCTransferProgress.Transfer(ocId: metadata.ocId, ocIdTransfer: metadata.ocIdTransfer, session: metadata.session, chunk: metadata.chunk, e2eEncrypted: metadata.e2eEncrypted, progressNumber: 0, totalBytes: 0, totalBytesExpected: 0)
        NCTransferProgress.shared.append(transfer)
        nkLog(debug: " Upload file \(metadata.fileNameView) with Identifier \(metadata.assetLocalIdentifier) with size \(metadata.size) [CHUNK \(metadata.chunk), E2EE \(metadata.isDirectoryE2EE)]")

    // MARK: - Upload file in foreground

        let metadataCreationDate = metadata.creationDate as Date

        // Update last uploaded date for auto uploaded photos
        if database.getTableAccount(account: metadata.account)?.autoUploadLastUploadedDate == nil {
            self.database.updateAccountProperty(\.autoUploadLastUploadedDate, value: metadataCreationDate, account: metadata.account)
        } else if metadata.sessionSelector == NCGlobal.shared.selectorUploadAutoUpload,
           let autoUploadLastUploadedDate = database.getTableAccount(account: metadata.account)?.autoUploadLastUploadedDate {

            if autoUploadLastUploadedDate < metadataCreationDate {
                self.database.updateAccountProperty(\.autoUploadLastUploadedDate, value: metadataCreationDate, account: metadata.account)
            }
        }

        if metadata.isDirectoryE2EE {
            #if !EXTENSION_FILE_PROVIDER_EXTENSION && !EXTENSION_WIDGET
            let detachedMetadata = metadata.detachedCopy()
            Task {
                let error = await NCNetworkingE2EEUpload().upload(metadata: detachedMetadata, uploadE2EEDelegate: uploadE2EEDelegate, controller: controller)
                completion(error)
            }
            #endif
        } else if metadata.chunk > 0 {
            DispatchQueue.main.async {
                hud = NCHud(controller?.view)
                hud?.initHudRing(text: NSLocalizedString("_wait_file_preparation_", comment: ""),
                                 tapToCancelDetailText: true,
                                 tapOperation: tapOperation)
            }
            uploadChunkFile(metadata: metadata) { num in
                numChunks = num
            } counterChunk: { counter in
                hud?.progress(num: Float(counter), total: Float(numChunks))
            } start: {
                hud?.initHudRing(text: NSLocalizedString("_keep_active_for_upload_", comment: ""))
            } progressHandler: { _, _, fractionCompleted in
                hud?.progress(fractionCompleted)
            } completion: { account, _, error in
                hud?.dismiss()
                let directory = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId)

                switch error {
                case .errorChunkNoEnoughMemory, .errorChunkCreateFolder, .errorChunkFilesEmpty, .errorChunkFileNull:
                    self.database.deleteMetadataOcId(metadata.ocId)
                    self.database.deleteChunks(account: account, ocId: metadata.ocId, directory: directory)
                    NCContentPresenter().messageNotification("_error_files_upload_", error: error, delay: self.global.dismissAfterSecond, type: .error, afterDelay: 0.5)
                case .errorChunkFileUpload:
                    break
                    // self.database.deleteChunks(account: account, ocId: metadata.ocId, directory: directory)
                case .errorChunkMoveFile:
                    self.database.deleteChunks(account: account, ocId: metadata.ocId, directory: directory)
                    NCContentPresenter().messageNotification("_chunk_move_", error: error, delay: self.global.dismissAfterSecond, type: .error, afterDelay: 0.5)
                default: break
                }
                completion(error)
            }
        } else if metadata.session == sessionUpload {
            let fileNameLocalPath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)
            uploadFile(metadata: metadata,
                       fileNameLocalPath: fileNameLocalPath,
                       controller: controller,
                       start: start,
                       progressHandler: progressHandler) { _, _, _, _, _, _, error in
                completion(error)
            }
        } else {
            uploadFileInBackground(metadata: metadata, controller: controller, start: start) { error in
                completion(error)
            }
        }
    }

    /*
    func uploadHubStream(metadata: tableMetadata,
                         uploadE2EEDelegate: uploadE2EEDelegate? = nil,
                         controller: UIViewController? = nil) -> AsyncThrowingStream<UploadEvent, Error> {
        return AsyncThrowingStream(bufferingPolicy: .unbounded) { continuation in
            Task {
                continuation.yield(.started)
                continuation.yield(.progress(...))
                continuation.yield(.completed)
                continuation.finish()
            }
        }
    }
    */

    func uploadFile(metadata: tableMetadata,
                    fileNameLocalPath: String,
    @discardableResult
    func uploadFile(fileNameLocalPath: String,
                    serverUrlFileName: String,
                    creationDate: Date,
                    dateModificationFile: Date,
                    account: String,
                    metadata: tableMetadata? = nil,
                    withUploadComplete: Bool = true,
                    customHeaders: [String: String]? = nil,
                    requestHandler: @escaping (_ request: UploadRequest) -> Void = { _ in },
                    taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
                    progressHandler: @escaping (_ totalBytesExpected: Int64, _ totalBytes: Int64, _ fractionCompleted: Double) -> Void = { _, _, _ in })
    async -> (account: String,
              ocId: String?,
              etag: String?,
              date: Date?,
              size: Int64,
              response: AFDataResponse<Data>?,
              error: NKError) {
        let options = NKRequestOptions(customHeader: customHeaders, queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        NextcloudKit.shared.upload(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: metadata.creationDate as Date, dateModificationFile: metadata.date as Date, account: metadata.account, options: options, requestHandler: { request in

            self.database.setMetadataSession(ocId: metadata.ocId,
                                             status: self.global.metadataStatusUploading)
            requestHandler(request)
        }, taskHandler: { task in
            self.database.setMetadataSession(ocId: metadata.ocId,
                                             sessionTaskIdentifier: task.taskIdentifier)

            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadStartFile,
                                                        object: nil,
                                                        userInfo: ["ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "account": metadata.account,
                                                                   "fileName": metadata.fileName,
                                                                   "sessionSelector": metadata.sessionSelector])
            start()
        NextcloudKit.shared.upload(serverUrlFileName: metadata.serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: metadata.creationDate as Date, dateModificationFile: metadata.date as Date, account: metadata.account, options: options, requestHandler: { request in
        let results = await NextcloudKit.shared.uploadAsync(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: creationDate, dateModificationFile: dateModificationFile, account: account, options: options) { request in
            requestHandler(request)
        } taskHandler: { task in
            Task {
                let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: account,
                                                                                            path: serverUrlFileName,
                                                                                            name: "upload")
                await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)

                if let metadata,
                   let metadata = await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                                        sessionTaskIdentifier: task.taskIdentifier,
                                                                                        status: self.global.metadataStatusUploading) {

                    await self.transferDispatcher.notifyAllDelegates { delegate in
                        delegate.transferChange(status: self.global.networkingStatusUploading,
                                                metadata: metadata,
                                                error: .success)
                    }
                }
            }
        }, progressHandler: { progress in
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterProgressTask,
                                                        object: nil,
                                                        userInfo: ["account": metadata.account,
                                                                   "ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "fileName": metadata.fileName,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "status": NSNumber(value: self.global.metadataStatusUploading),
                                                                   "progress": NSNumber(value: progress.fractionCompleted),
                                                                   "totalBytes": NSNumber(value: progress.totalUnitCount),
                                                                   "totalBytesExpected": NSNumber(value: progress.completedUnitCount)])
            taskHandler(task)
        } progressHandler: { progress in
            Task {
                guard let metadata,
                    await self.progressQuantizer.shouldEmit(serverUrlFileName: serverUrlFileName, fraction: progress.fractionCompleted) else {
                    return
                }
                await NCManageDatabase.shared.setMetadataProgress(ocId: metadata.ocId, progress: progress.fractionCompleted)
                await self.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferProgressDidUpdate(progress: Float(progress.fractionCompleted),
                                                        totalBytes: progress.totalUnitCount,
                                                        totalBytesExpected: progress.completedUnitCount,
                                                        fileName: metadata.fileName,
                                                        serverUrl: metadata.serverUrl)
                }
            }
            progressHandler(progress.completedUnitCount, progress.totalUnitCount, progress.fractionCompleted)
        }

        Task {
            await progressQuantizer.clear(serverUrlFileName: serverUrlFileName)
        }

        if withUploadComplete, let metadata {
            await self.uploadComplete(withMetadata: metadata, ocId: results.ocId, etag: results.etag, date: results.date, size: results.size, error: results.error)
        }

        return results
    }

    // MARK: - Upload chunk file in foreground

    @discardableResult
    func uploadChunkFile(metadata: tableMetadata,
                         withUploadComplete: Bool = true,
                         customHeaders: [String: String]? = nil,
                         numChunks: @escaping (_ num: Int) -> Void = { _ in },
                         counterChunk: @escaping (_ counter: Int) -> Void = { _ in },
                         startFilesChunk: @escaping (_ filesChunk: [(fileName: String, size: Int64)]) -> Void = { _ in },
                         requestHandler: @escaping (_ request: UploadRequest) -> Void = { _ in },
                         taskHandler: @escaping (_ task: URLSessionTask) -> Void = { _ in },
                         progressHandler: @escaping (_ totalBytesExpected: Int64, _ totalBytes: Int64, _ fractionCompleted: Double) -> Void = { _, _, _ in },
                         assembling: @escaping () -> Void = { })
    async -> (account: String,
              remainingChunks: [(fileName: String, size: Int64)]?,
              file: NKFile?,
              error: NKError) {
        let directory = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase)
        let chunkFolder = NCManageDatabase.shared.getChunkFolder(account: metadata.account, ocId: metadata.ocId)
        let filesChunk = NCManageDatabase.shared.getChunks(account: metadata.account, ocId: metadata.ocId)
        var chunkSize = self.global.chunkSizeMBCellular
        if networkReachability == NKTypeReachability.reachableEthernetOrWiFi {
            chunkSize = self.global.chunkSizeMBEthernetOrWiFi
        }
        let options = NKRequestOptions(customHeader: customHeaders, queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        let results = await NextcloudKit.shared.uploadChunkAsync(directory: directory,
                                                                 fileName: metadata.fileName,
                                                                 date: metadata.date as Date,
                                                                 creationDate: metadata.creationDate as Date,
                                                                 serverUrl: metadata.serverUrl,
                                                                 chunkFolder: chunkFolder,
                                                                 filesChunk: filesChunk,
                                                                 chunkSize: chunkSize,
                                                                 account: metadata.account,
                                                                 options: options) { num in
            numChunks(num)
        } counterChunk: { counter in
            counterChunk(counter)
        } start: { filesChunk in
            start()
            self.database.addChunks(account: metadata.account,
                                    ocId: metadata.ocId,
                                    chunkFolder: chunkFolder,
                                    filesChunk: filesChunk)
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadStartFile,
                                                        object: nil,
                                                        userInfo: ["ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "account": metadata.account,
                                                                   "fileName": metadata.fileName,
                                                                   "sessionSelector": metadata.sessionSelector],
                                                        second: 0.2)
        } requestHandler: { _ in
            self.database.setMetadataSession(ocId: metadata.ocId,
                                             status: self.global.metadataStatusUploading)
        } taskHandler: { task in
            self.database.setMetadataSession(ocId: metadata.ocId,
                                             sessionTaskIdentifier: task.taskIdentifier)
            self.notifyAllDelegates { delegate in
                delegate.transferChange(status: self.global.networkingStatusUploading,
                                        metadata: metadata.detachedCopy(),
                                        error: .success)
            }
        } requestHandler: { _ in
        } taskHandler: { task in
            Task {
                await self.database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                            sessionTaskIdentifier: task.taskIdentifier,
                                                            status: self.global.metadataStatusUploading)
            }
        } progressHandler: { totalBytesExpected, totalBytes, fractionCompleted in
            NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterProgressTask,
                                                        object: nil,
                                                        userInfo: ["account": metadata.account,
                                                                   "ocId": metadata.ocId,
                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                   "session": metadata.session,
                                                                   "fileName": metadata.fileName,
                                                                   "serverUrl": metadata.serverUrl,
                                                                   "status": NSNumber(value: self.global.metadataStatusUploading),
                                                                   "chunk": metadata.chunk,
                                                                   "e2eEncrypted": metadata.e2eEncrypted,
                                                                   "progress": NSNumber(value: fractionCompleted),
                                                                   "totalBytes": NSNumber(value: totalBytes),
                                                                   "totalBytesExpected": NSNumber(value: totalBytesExpected)])

            progressHandler(totalBytesExpected, totalBytes, fractionCompleted)
        } uploaded: { fileChunk in
            self.database.deleteChunk(account: metadata.account,
                                      ocId: metadata.ocId,
                                      fileChunk: fileChunk,
                                      directory: directory)
        } completion: { account, _, file, error in
            if error == .success {
                self.database.deleteChunks(account: account,
                                           ocId: metadata.ocId,
                                           directory: directory)
            }
            if withUploadComplete {
                Task {
                    await self.uploadComplete(withMetadata: metadata, ocId: file?.ocId, etag: file?.etag, date: file?.date, size: file?.size ?? 0, error: error)
            Task {
                await NCManageDatabase.shared.addChunksAsync(account: metadata.account, ocId: metadata.ocId, chunkFolder: chunkFolder, filesChunk: filesChunk)
                await self.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferChange(status: self.global.networkingStatusUploading,
                                            metadata: metadata.detachedCopy(),
                                            error: .success)
                }
            }
            startFilesChunk(filesChunk)
        } requestHandler: { request in
            requestHandler(request)
        } taskHandler: { task in
            Task {
                let url = task.originalRequest?.url?.absoluteString ?? ""
                let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                            path: url,
                                                                                            name: "upload")
                await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)

                let ocId = metadata.ocId
                await NCManageDatabase.shared.setMetadataSessionAsync(ocId: ocId,
                                                                      sessionTaskIdentifier: task.taskIdentifier,
                                                                      status: self.global.metadataStatusUploading)
            }
            taskHandler(task)
        } progressHandler: { totalBytesExpected, totalBytes, fractionCompleted in
            Task {
                guard await self.progressQuantizer.shouldEmit(serverUrlFileName: metadata.serverUrlFileName, fraction: fractionCompleted) else {
                    return
                }
                await NCManageDatabase.shared.setMetadataProgress(ocId: metadata.ocId, progress: fractionCompleted)
                await self.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferProgressDidUpdate(progress: Float(fractionCompleted),
                                                       totalBytes: totalBytes,
                                                       totalBytesExpected: totalBytesExpected,
                                                       fileName: metadata.fileName,
                                                       serverUrl: metadata.serverUrl)
                }
            }
            progressHandler(totalBytesExpected, totalBytes, fractionCompleted)
        } assembling: {
            assembling()
        } uploaded: { fileChunk in
            Task {
                await NCManageDatabase.shared.deleteChunkAsync(account: metadata.account,
                                                               ocId: metadata.ocId,
                                                               fileChunk: fileChunk,
                                                               directory: directory)
            }
        }

        if results.error == .success {
            await NCManageDatabase.shared.deleteChunksAsync(account: metadata.account,
                                                            ocId: metadata.ocId,
                                                            directory: directory)
        } else if results.error.errorCode == -1 ||
                  results.error.errorCode == -2 ||
                  results.error.errorCode == -3 ||
                  results.error.errorCode == -4 ||
                  results.error.errorCode == -5 {
            await NCManageDatabase.shared.deleteChunksAsync(account: metadata.account,
                                                            ocId: metadata.ocId,
                                                            directory: directory)
            await NCManageDatabase.shared.deleteMetadataAsync(id: metadata.ocId)
            utilityFileSystem.removeFile(atPath: utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase))

            NCContentPresenter().showError(error: results.error)
            return results
        }

        if withUploadComplete {
            await self.uploadComplete(withMetadata: metadata, ocId: results.file?.ocId, etag: results.file?.etag, date: results.file?.date, size: results.file?.size ?? 0, error: results.error)
        }

        return results
    }

    // MARK: - Upload file in background

    @discardableResult
    func uploadFileInBackground(metadata: tableMetadata,
                                withFileExistsCheck: Bool = false,
                                taskHandler: @escaping (_ task: URLSessionUploadTask?) -> Void = { _ in },
                                start: @escaping () -> Void = { })
    async -> NKError {
        if withFileExistsCheck || metadata.sessionSelector == global.selectorUploadAutoUpload {
            let error = await self.fileExists(serverUrlFileName: metadata.serverUrlFileName, account: metadata.account)
            if error == .success {
                await uploadCancelFile(metadata: metadata)
                return (.success)
            }
        }

        let fileNameLocalPath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileName: metadata.fileName, userId: metadata.userId, urlBase: metadata.urlBase)

        start()

        // Check file dim > 0
        if utilityFileSystem.getFileSize(filePath: fileNameLocalPath) == 0 && metadata.size != 0 {
            self.database.deleteMetadataOcId(metadata.ocId)
            completion(NKError(errorCode: self.global.errorResourceNotFound, errorDescription: NSLocalizedString("_error_not_found_", value: "The requested resource could not be found", comment: "")))
        } else {
            let (task, error) = NKBackground(nkCommonInstance: NextcloudKit.shared.nkCommonInstance).upload(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: metadata.creationDate as Date, dateModificationFile: metadata.date as Date, account: metadata.account, sessionIdentifier: metadata.session)
            if let task, error == .success {
                NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Upload file \(metadata.fileNameView) with task with taskIdentifier \(task.taskIdentifier)")
                self.database.setMetadataSession(ocId: metadata.ocId,
                                                 sessionTaskIdentifier: task.taskIdentifier,
                                                 status: self.global.metadataStatusUploading)
                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadStartFile,
                                                            object: nil,
                                                            userInfo: ["ocId": metadata.ocId,
                                                                       "ocIdTransfer": metadata.ocIdTransfer,
                                                                       "session": metadata.session,
                                                                       "serverUrl": metadata.serverUrl,
                                                                       "account": metadata.account,
                                                                       "fileName": metadata.fileName,
                                                                       "sessionSelector": metadata.sessionSelector])
            } else {
                self.database.deleteMetadataOcId(metadata.ocId)
            }
            let (task, error) = backgroundSession.upload(serverUrlFileName: metadata.serverUrlFileName,
                                                         fileNameLocalPath: fileNameLocalPath,
                                                         dateCreationFile: metadata.creationDate as Date,
                                                         dateModificationFile: metadata.date as Date,
                                                         account: metadata.account,
                                                         sessionIdentifier: metadata.session)
            await NCManageDatabase.shared.deleteMetadataAsync(id: metadata.ocId)
            return NKError(errorCode: self.global.errorResourceNotFound, errorDescription: NSLocalizedString("_error_not_found_", value: "The requested resource could not be found", comment: ""))
        } else {
            let (task, error) = await backgroundSession.uploadAsync(serverUrlFileName: metadata.serverUrlFileName,
                                                                    fileNameLocalPath: fileNameLocalPath,
                                                                    dateCreationFile: metadata.creationDate as Date,
                                                                    dateModificationFile: metadata.date as Date,
                                                                    account: metadata.account,
                                                                    sessionIdentifier: metadata.session)

            taskHandler(task)

            if let task, error == .success {
                nkLog(debug: "Upload file \(metadata.fileNameView) with taskIdentifier \(task.taskIdentifier)")

                /*
                #if !EXTENSION
                NCTransferStore.shared.addItem(TransferItem(fileName: metadata.fileName,
                                                            ocIdTransfer: metadata.ocIdTransfer,
                                                            progress: 0,
                                                            selector: metadata.sessionSelector,
                                                            serverUrl: metadata.serverUrl,
                                                            session: metadata.session,
                                                            status: metadata.status,
                                                            size: metadata.size,
                                                            taskIdentifier: task.taskIdentifier))
                #endif
                */

                if let metadata = await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                                        sessionTaskIdentifier: task.taskIdentifier,
                                                                                        status: self.global.metadataStatusUploading) {

                    await self.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferChange(status: self.global.networkingStatusUploading,
                                            metadata: metadata,
                                            error: .success)
                    }
                }
            } else {
                await NCManageDatabase.shared.deleteMetadataAsync(id: metadata.ocId)
            }

            return(error)
        }
    }

    // wrapper async
    func uploadFileInBackgroundAsync(metadata: tableMetadata, controller: UIViewController? = nil) async -> NKError {
        await withCheckedContinuation { continuation in
            uploadFileInBackground(metadata: metadata,
                                   controller: controller,
                                   start: { },
                                   completion: { error in
                continuation.resume(returning: error)
            })
        }
    }

    func uploadComplete(fileName: String,
                        serverUrl: String,
                        ocId: String?,
                        etag: String?,
                        date: Date?,
                        size: Int64,
                        task: URLSessionTask,
                        error: NKError) {

#if EXTENSION_FILE_PROVIDER_EXTENSION

        guard let url = task.currentRequest?.url,
              let metadata = NCManageDatabase.shared.getMetadata(from: url, sessionTaskIdentifier: task.taskIdentifier) else { return }

        if let ocId, !metadata.ocIdTransfer.isEmpty {
            let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocIdTransfer)
            let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(ocId)
            self.utilityFileSystem.copyFile(atPath: atPath, toPath: toPath)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if error == .success, let ocId {
                /// SIGNAL
                fileProviderData.shared.signalEnumerator(ocId: metadata.ocIdTransfer, type: .delete)
                if !metadata.ocIdTransfer.isEmpty, ocId != metadata.ocIdTransfer {
                    NCManageDatabase.shared.deleteMetadataOcId(metadata.ocIdTransfer)
                }
                metadata.fileName = fileName
                metadata.serverUrl = serverUrl
                metadata.uploadDate = (date as? NSDate) ?? NSDate()
                metadata.etag = etag ?? ""
                metadata.ocId = ocId
                metadata.size = size
                if let fileId = NCUtility().ocIdToFileId(ocId: ocId) {
                    metadata.fileId = fileId
                }

                metadata.sceneIdentifier = nil
                metadata.session = ""
                metadata.sessionError = ""
                metadata.sessionSelector = ""
                metadata.sessionDate = nil
                metadata.sessionTaskIdentifier = 0
                metadata.status = NCGlobal.shared.metadataStatusNormal

                NCManageDatabase.shared.addMetadata(metadata)
                NCManageDatabase.shared.addLocalFile(metadata: metadata)

                /// SIGNAL
                fileProviderData.shared.signalEnumerator(ocId: metadata.ocId, type: .update)
            } else {
                NCManageDatabase.shared.deleteMetadataOcId(metadata.ocIdTransfer)
                /// SIGNAL
                fileProviderData.shared.signalEnumerator(ocId: metadata.ocIdTransfer, type: .delete)
            }
        }
#else
        DispatchQueue.global().async {
        Task {
            #if EXTENSION_FILE_PROVIDER_EXTENSION
            await fileProviderData.shared.uploadComplete(fileName: fileName,
                                                         serverUrl: serverUrl,
                                                         ocId: ocId,
                                                         etag: etag,
                                                         date: date,
                                                         size: size,
                                                         task: task,
                                                         error: error)
            #else
            if let url = task.currentRequest?.url,
               let metadata = await self.database.getMetadataAsync(from: url, sessionTaskIdentifier: task.taskIdentifier) {
                await uploadComplete(withMetadata: metadata, ocId: ocId, etag: etag, date: date, size: size, error: error)
            }
            #endif
        }
    }
    // MARK: -

    func uploadComplete(withMetadata metadata: tableMetadata,
                        ocId: String?,
                        etag: String?,
                        date: Date?,
                        size: Int64,
                        error: NKError) {
        DispatchQueue.main.async {
            var isApplicationStateActive = false
#if !EXTENSION
            isApplicationStateActive = UIApplication.shared.applicationState == .active
#endif
            DispatchQueue.global().async {
                NextcloudKit.shared.nkCommonInstance.appendServerErrorAccount(metadata.account, errorCode: error.errorCode)

                let selector = metadata.sessionSelector

                if error == .success, let ocId = ocId, size == metadata.size {
                    NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)

                    let metadata = tableMetadata.init(value: metadata)
                    metadata.uploadDate = (date as? NSDate) ?? NSDate()
                    metadata.etag = etag ?? ""
                    metadata.ocId = ocId
                    metadata.chunk = 0

                    if let fileId = self.utility.ocIdToFileId(ocId: ocId) {
                        metadata.fileId = fileId
                    }

                    metadata.session = ""
                    metadata.sessionError = ""
                    metadata.sessionTaskIdentifier = 0
                    metadata.status = self.global.metadataStatusNormal

                    self.database.deleteMetadata(predicate: NSPredicate(format: "ocIdTransfer == %@", metadata.ocIdTransfer))
                    self.database.addMetadata(metadata)

                    if selector == self.global.selectorUploadFileNODelete {
                        self.utilityFileSystem.moveFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocIdTransfer), toPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(ocId))
                        self.database.addLocalFile(metadata: metadata)
                    } else {
                        self.utilityFileSystem.removeFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocIdTransfer))
                    }

                    NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Upload complete " + metadata.serverUrl + "/" + metadata.fileName + ", result: success(\(size) bytes)")

                    let userInfo: [String: Any] = ["ocId": metadata.ocId,
                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                   "session": metadata.session,
                                                   "serverUrl": metadata.serverUrl,
                                                   "account": metadata.account,
                                                   "fileName": metadata.fileName,
                                                   "error": error]
                    if metadata.isLivePhoto,
                       NCCapabilities.shared.getCapabilities(account: metadata.account).isLivePhotoServerAvailable {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                            self.createLivePhoto(metadata: metadata, userInfo: userInfo)
                        }
                    } else {
                        NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadedFile,
                                                                    object: nil,
                                                                    userInfo: userInfo,
                                                                    second: 0.5)
                    }
                } else {
                    if error.errorCode == NSURLErrorCancelled || error.errorCode == self.global.errorRequestExplicityCancelled {
                        NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)
                        self.utilityFileSystem.removeFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
                        self.database.deleteMetadataOcId(metadata.ocId)
                        NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadCancelFile,
                                                                    object: nil,
                                                                    userInfo: ["ocId": metadata.ocId,
                                                                               "ocIdTransfer": metadata.ocIdTransfer,
                                                                               "session": metadata.session,
                                                                               "serverUrl": metadata.serverUrl,
                                                                               "account": metadata.account],
                                                                    second: 0.5)
                    } else if error.errorCode == self.global.errorBadRequest || error.errorCode == self.global.errorUnsupportedMediaType {
                        NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)
                        self.utilityFileSystem.removeFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
                        self.database.deleteMetadataOcId(metadata.ocId)
                        NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadCancelFile,
                                                                    object: nil,
                                                                    userInfo: ["ocId": metadata.ocId,
                                                                               "ocIdTransfer": metadata.ocIdTransfer,
                                                                               "session": metadata.session,
                                                                               "serverUrl": metadata.serverUrl,
                                                                               "account": metadata.account],
                                                                    second: 0.5)
                        if isApplicationStateActive {
                            NCContentPresenter().showError(error: NKError(errorCode: error.errorCode, errorDescription: "_virus_detect_"))
                        }

                        // Client Diagnostic
                        self.database.addDiagnostic(account: metadata.account, issue: self.global.diagnosticIssueVirusDetected)
                    } else if error.errorCode == self.global.errorForbidden && isApplicationStateActive {
                        NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)
#if !EXTENSION
                        NextcloudKit.shared.getTermsOfService(account: metadata.account, options: NKRequestOptions(checkInterceptor: false)) { _, tos, _, error in
                            if error == .success, let tos, !tos.hasUserSigned() {
                                // it's a ToS not signed
                            } else {
                                let newFileName = self.utilityFileSystem.createFileName(metadata.fileName, serverUrl: metadata.serverUrl, account: metadata.account)
                                let alertController = UIAlertController(title: error.errorDescription, message: NSLocalizedString("_change_upload_filename_", comment: ""), preferredStyle: .alert)
                                alertController.addAction(UIAlertAction(title: String(format: NSLocalizedString("_save_file_as_", comment: ""), newFileName), style: .default, handler: { _ in
                                    let atpath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + metadata.fileName
                                    let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + newFileName
                                    self.utilityFileSystem.moveFile(atPath: atpath, toPath: toPath)
                                    self.database.setMetadataSession(ocId: metadata.ocId,
                                                                     newFileName: newFileName,
                                                                     sessionTaskIdentifier: 0,
                                                                     sessionError: "",
                                                                     status: self.global.metadataStatusWaitUpload,
                                                                     errorCode: error.errorCode)
                                }))
                                alertController.addAction(UIAlertAction(title: NSLocalizedString("_discard_changes_", comment: ""), style: .destructive, handler: { _ in
                                    self.utilityFileSystem.removeFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
                                    self.database.deleteMetadataOcId(metadata.ocId)
                                    NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadCancelFile,
                                                                                object: nil,
                                                                                userInfo: ["ocId": metadata.ocId,
                                                                                           "ocIdTransfer": metadata.ocIdTransfer,
                                                                                           "session": metadata.session,
                                                                                           "serverUrl": metadata.serverUrl,
                                                                                           "account": metadata.account],
                                                                                second: 0.5)
                                }))

                                // Select UIWindowScene active in serverUrl
                                var controller = UIApplication.shared.firstWindow?.rootViewController
                                let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                                for windowScene in windowScenes {
                                    if let rootViewController = windowScene.keyWindow?.rootViewController as? NCMainTabBarController,
                                       rootViewController.currentServerUrl() == metadata.serverUrl {
                                        controller = rootViewController
                                        break
                                    }
                                }
                                controller?.present(alertController, animated: true)

                                // Client Diagnostic
                                self.database.addDiagnostic(account: metadata.account,
                                                            issue: self.global.diagnosticIssueProblems,
                                                            error: self.global.diagnosticProblemsForbidden)
                            }
                        }
#endif
                    } else {
                        NCTransferProgress.shared.clearCountError(ocIdTransfer: metadata.ocIdTransfer)

                        self.database.setMetadataSession(ocId: metadata.ocId,
                                                         sessionTaskIdentifier: 0,
                                                         sessionError: error.errorDescription,
                                                         status: self.global.metadataStatusUploadError,
                                                         errorCode: error.errorCode)
                        NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterUploadedFile,
                                                                    object: nil,
                                                                    userInfo: ["ocId": metadata.ocId,
                                                                               "ocIdTransfer": metadata.ocIdTransfer,
                                                                               "session": metadata.session,
                                                                               "serverUrl": metadata.serverUrl,
                                                                               "account": metadata.account,
                                                                               "fileName": metadata.fileName,
                                                                               "error": error],
                                                                    second: 0.5)
                        // Client Diagnostic
                        if error.errorCode == self.global.errorInternalServerError {
                            self.database.addDiagnostic(account: metadata.account,
                                                        issue: self.global.diagnosticIssueProblems,
                                                        error: self.global.diagnosticProblemsBadResponse)
                        } else {
                            self.database.addDiagnostic(account: metadata.account,
                                                        issue: self.global.diagnosticIssueProblems,
                                                        error: self.global.diagnosticProblemsUploadServerError)
                        }
                    }
                        error: NKError) async {
        await NextcloudKit.shared.nkCommonInstance.appendServerErrorAccount(metadata.account, errorCode: error.errorCode)

        let selector = metadata.sessionSelector
        let capabilities = await NKCapabilities.shared.getCapabilities(for: metadata.account)

        if error == .success, let ocId {
            nkLog(success: "Uploaded file: " + metadata.serverUrlFileName + ", (\(size) bytes)")

            metadata.uploadDate = (date as? NSDate) ?? NSDate()
            metadata.etag = etag ?? ""
            metadata.ocId = ocId
            metadata.chunk = 0

            if let fileId = self.utility.ocIdToFileId(ocId: ocId) {
                metadata.fileId = fileId
            }

            metadata.session = ""
            metadata.sessionError = ""
            metadata.sessionTaskIdentifier = 0
            metadata.status = self.global.metadataStatusNormal

            await NCManageDatabase.shared.replaceMetadataAsync(id: metadata.ocIdTransfer, metadata: metadata)

            let fileNamePath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocIdTransfer, userId: metadata.userId, urlBase: metadata.urlBase)

            if selector == self.global.selectorUploadFileNODelete {
                await self.utilityFileSystem.moveFileAsync(atPath: fileNamePath,
                                                           toPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(ocId, userId: metadata.userId, urlBase: metadata.urlBase))
                await NCManageDatabase.shared.addLocalFilesAsync(metadatas: [metadata])
            } else {
                self.utilityFileSystem.removeFile(atPath: fileNamePath)
            }

            // Update the auto upload data
            if selector == self.global.selectorUploadAutoUpload,
               let serverUrlBase = metadata.autoUploadServerUrlBase {
                await NCManageDatabase.shared.addAutoUploadTransferAsync(account: metadata.account,
                                                                         serverUrlBase: serverUrlBase,
                                                                         fileName: metadata.fileNameView,
                                                                         assetLocalIdentifier: metadata.assetLocalIdentifier,
                                                                         date: metadata.creationDate as Date)
            }

            // Live Photo
            if metadata.isLivePhoto,
               capabilities.isLivePhotoServerAvailable {
                if metadata.isVideo {
                    await NCManageDatabase.shared.setLivePhotoVideo(account: metadata.account, serverUrlFileName: metadata.serverUrlFileName, fileId: metadata.fileId)
                } else if metadata.isImage {
                    await NCManageDatabase.shared.setLivePhotoImage(account: metadata.account, serverUrlFileName: metadata.serverUrlFileName, fileId: metadata.fileId)
                }
                await self.setLivePhoto(account: metadata.account)
            }

            await self.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferChange(status: self.global.networkingStatusUploaded,
                                        metadata: metadata.detachedCopy(),
                                        error: error)
            }

        } else {
            nkLog(error: "Upload file: " + metadata.serverUrlFileName + ", result: error \(error.errorCode)")

            if error.errorCode == NSURLErrorCancelled || error.errorCode == self.global.errorRequestExplicityCancelled {
                await uploadCancelFile(metadata: metadata)
            } else if (error.errorCode == self.global.errorBadRequest || error.errorCode == self.global.errorUnsupportedMediaType) && error.errorDescription.localizedCaseInsensitiveContains("virus") {
                await uploadCancelFile(metadata: metadata)
                NCContentPresenter().showError(error: NKError(errorCode: error.errorCode, errorDescription: "_virus_detect_"))
                // Client Diagnostic
                await NCManageDatabase.shared.addDiagnosticAsync(account: metadata.account, issue: self.global.diagnosticIssueVirusDetected)
            } else if error.errorCode == self.global.errorForbidden {
                await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                      sessionTaskIdentifier: 0,
                                                                      sessionError: error.errorDescription,
                                                                      status: self.global.metadataStatusUploadError,
                                                                      errorCode: error.errorCode)
                #if !EXTENSION
                if !isAppInBackground {
                    if capabilities.termsOfService {
                        await termsOfService(metadata: metadata)
                    } else {
                        await uploadForbidden(metadata: metadata, error: error)
                    }
                }
                #endif
            } else {
                if let metadata = await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                                        sessionTaskIdentifier: 0,
                                                                                        sessionError: error.errorDescription,
                                                                                        status: self.global.metadataStatusUploadError,
                                                                                        errorCode: error.errorCode) {

                    await self.transferDispatcher.notifyAllDelegates { delegate in
                        delegate.transferChange(status: self.global.networkingStatusUploaded,
                                                metadata: metadata,
                                                error: error)
                    }
                }

                // Client Diagnostic
                if error.errorCode == self.global.errorInternalServerError {
                    await NCManageDatabase.shared.addDiagnosticAsync(account: metadata.account,
                                                                     issue: self.global.diagnosticIssueProblems,
                                                                     error: self.global.diagnosticProblemsBadResponse)
                } else {
                    await NCManageDatabase.shared.addDiagnosticAsync(account: metadata.account,
                                                                     issue: self.global.diagnosticIssueProblems,
                                                                     error: self.global.diagnosticProblemsUploadServerError)
                }
            }
        }
        await self.database.updateBadge()
    }

    func uploadProgress(_ progress: Float,
                        totalBytes: Int64,
                        totalBytesExpected: Int64,
                        fileName: String,
                        serverUrl: String,
                        session: URLSession,
                        task: URLSessionTask) {
    }

#if EXTENSION_FILE_PROVIDER_EXTENSION
        return
#endif

        DispatchQueue.global().async {
            if let metadata = self.database.getResultMetadataFromFileName(fileName, serverUrl: serverUrl, sessionTaskIdentifier: task.taskIdentifier) {
                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterProgressTask,
                                                            object: nil,
                                                            userInfo: ["account": metadata.account,
                                                                       "ocId": metadata.ocId,
                                                                       "ocIdTransfer": metadata.ocIdTransfer,
                                                                       "session": metadata.session,
                                                                       "fileName": metadata.fileName,
                                                                       "serverUrl": serverUrl,
                                                                       "status": NSNumber(value: self.global.metadataStatusUploading),
                                                                       "chunk": metadata.chunk,
                                                                       "e2eEncrypted": metadata.e2eEncrypted,
                                                                       "progress": NSNumber(value: progress),
                                                                       "totalBytes": NSNumber(value: totalBytes),
                                                                       "totalBytesExpected": NSNumber(value: totalBytesExpected)])
            }
    func uploadCancelFile(metadata: tableMetadata) async {
        /*
        #if !EXTENSION
        NCTransferStore.shared.removeItem(ocIdTransfer: metadata.ocIdTransfer)
        #endif
        */

        self.utilityFileSystem.removeFile(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocIdTransfer, userId: metadata.userId, urlBase: metadata.urlBase))
        await NCManageDatabase.shared.deleteMetadataAsync(id: metadata.ocIdTransfer)
        await self.transferDispatcher.notifyAllDelegates { delegate in
            delegate.transferChange(status: self.global.networkingStatusUploadCancel,
                                    metadata: metadata.detachedCopy(),
                                    error: .success)
        }
    }

#if !EXTENSION
    @MainActor
    func uploadForbidden(metadata: tableMetadata, error: NKError) async {
        let newFileName = self.utilityFileSystem.createFileName(metadata.fileName, serverUrl: metadata.serverUrl, account: metadata.account)
        let alertController = UIAlertController(title: error.errorDescription, message: NSLocalizedString("_change_upload_filename_", comment: ""), preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: String(format: NSLocalizedString("_save_file_as_", comment: ""), newFileName), style: .default, handler: { _ in
            Task {
                let atpath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase) + "/" + metadata.fileName
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase) + "/" + newFileName
                await self.utilityFileSystem.moveFileAsync(atPath: atpath, toPath: toPath)
                await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                      newFileName: newFileName,
                                                                      sessionTaskIdentifier: 0,
                                                                      sessionError: "",
                                                                      status: self.global.metadataStatusWaitUpload,
                                                                      errorCode: error.errorCode)
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("_discard_changes_", comment: ""), style: .destructive, handler: { _ in
            Task {
                await self.uploadCancelFile(metadata: metadata)
            }
        }))

        self.getViewController(metadata: metadata)?.present(alertController, animated: true)

        // Client Diagnostic
        await NCManageDatabase.shared.addDiagnosticAsync(account: metadata.account,
                                                         issue: self.global.diagnosticIssueProblems,
                                                         error: self.global.diagnosticProblemsForbidden)
    }

    @MainActor
    func termsOfService(metadata: tableMetadata) async {
        let options = NKRequestOptions(checkInterceptor: false, queue: .main)
        let results = await NextcloudKit.shared.getTermsOfServiceAsync(account: metadata.account, options: options, taskHandler: { task in
            Task {
                let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                            name: "getTermsOfService")
                await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
            }
        })

        if results.error == .success, let tos = results.tos, !tos.hasUserSigned() {
            await self.uploadCancelFile(metadata: metadata)
            return
        }

        let newFileName = self.utilityFileSystem.createFileName(metadata.fileName, serverUrl: metadata.serverUrl, account: metadata.account)

        let alertController = UIAlertController(title: results.error.errorDescription, message: NSLocalizedString("_change_upload_filename_", comment: ""), preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: String(format: NSLocalizedString("_save_file_as_", comment: ""), newFileName), style: .default, handler: { _ in
            Task {
                let atpath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase) + "/" + metadata.fileName
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase) + "/" + newFileName
                await self.utilityFileSystem.moveFileAsync(atPath: atpath, toPath: toPath)
                await NCManageDatabase.shared.setMetadataSessionAsync(ocId: metadata.ocId,
                                                                      newFileName: newFileName,
                                                                      sessionTaskIdentifier: 0,
                                                                      sessionError: "",
                                                                      status: self.global.metadataStatusWaitUpload,
                                                                      errorCode: results.error.errorCode)
            }
        }))

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_discard_changes_", comment: ""), style: .destructive, handler: { _ in
            Task {
                await self.uploadCancelFile(metadata: metadata)
            }
        }))

        self.getViewController(metadata: metadata)?.present(alertController, animated: true)

        // Client Diagnostic
        await NCManageDatabase.shared.addDiagnosticAsync(account: metadata.account,
                                                         issue: self.global.diagnosticIssueProblems,
                                                         error: self.global.diagnosticProblemsForbidden)
    }

    private func getViewController(metadata: tableMetadata) -> UIViewController? {
        var controller = UIApplication.shared.firstWindow?.rootViewController
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for windowScene in windowScenes {
            if let rootViewController = windowScene.keyWindow?.rootViewController as? NCMainTabBarController,
               rootViewController.currentServerUrl() == metadata.serverUrl {
                controller = rootViewController
                break
            }
        }
        return controller
    }
#endif

    // MARK: - Upload NextcloudKitDelegate

    func uploadComplete(fileName: String,
                        serverUrl: String,
                        ocId: String?,
                        etag: String?,
                        date: Date?,
                        size: Int64,
                        task: URLSessionTask,
                        error: NKError) {
        Task {
            await progressQuantizer.clear(serverUrlFileName: serverUrl + "/" + fileName)

            #if EXTENSION_FILE_PROVIDER_EXTENSION
                await FileProviderData.shared.uploadComplete(fileName: fileName,
                                                             serverUrl: serverUrl,
                                                             ocId: ocId,
                                                             etag: etag,
                                                             date: date,
                                                             size: size,
                                                             task: task,
                                                             error: error)
                return
            #endif

            /*
            #if !EXTENSION
            if error == .success {
                NCTransferStore.shared.addItem(TransferItem(completed: true,
                                                            date: date,
                                                            etag: etag,
                                                            fileName: fileName,
                                                            ocId: ocId,
                                                            serverUrl: serverUrl,
                                                            size: size,
                                                            taskIdentifier: task.taskIdentifier))
                return
            } else {
                NCTransferStore.shared.removeItem(serverUrl: serverUrl,
                                                  fileName: fileName,
                                                  taskIdentifier: task.taskIdentifier)
            }
            #endif
            */

            if let metadata = await NCManageDatabase.shared.getMetadataAsync(predicate: NSPredicate(format: "serverUrl == %@ AND fileName == %@ AND sessionTaskIdentifier == %d", serverUrl, fileName, task.taskIdentifier)) {
                await uploadComplete(withMetadata: metadata, ocId: ocId, etag: etag, date: date, size: size, error: error)
            } else {
                let predicate = NSPredicate(format: "fileName == %@ AND serverUrl == %@", fileName, serverUrl)
                await NCManageDatabase.shared.deleteMetadataAsync(predicate: predicate)
            }
        }
    }

    func uploadProgress(_ progress: Float,
                        totalBytes: Int64,
                        totalBytesExpected: Int64,
                        fileName: String,
                        serverUrl: String,
                        session: URLSession,
                        task: URLSessionTask) {
        Task {
            guard await progressQuantizer.shouldEmit(serverUrlFileName: serverUrl + "/" + fileName, fraction: Double(progress)) else {
                return
            }

            /*
            #if !EXTENSION
            NCTransferStore.shared.transferProgress(serverUrl: serverUrl,
                                                    fileName: fileName,
                                                    taskIdentifier: task.taskIdentifier,
                                                    progress: Double(progress))
            #endif
            */

            await NCManageDatabase.shared.setMetadataProgress(fileName: fileName, serverUrl: serverUrl, taskIdentifier: task.taskIdentifier, progress: Double(progress))

            await self.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferProgressDidUpdate(progress: progress,
                                                   totalBytes: totalBytes,
                                                   totalBytesExpected: totalBytesExpected,
                                                   fileName: fileName,
                                                   serverUrl: serverUrl)
            }
        }
    }
}
