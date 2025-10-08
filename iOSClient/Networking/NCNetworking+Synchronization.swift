// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import Alamofire

extension NCNetworking {
    func synchronization(account: String,
                         serverUrl: String,
                         add: Bool,
                         completion: @escaping (_ errorCode: Int, _ num: Int) -> Void = { _, _ in }) {
        let startDate = Date()
        let options = NKRequestOptions(timeout: 120, taskDescription: NCGlobal.shared.taskDescriptionSynchronization, queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        NextcloudKit.shared.readFileOrFolder(serverUrlFileName: serverUrl,
                                             depth: "infinity",
                                             showHiddenFiles: NCKeychain().showHiddenFiles,
                                             account: account,
                                             options: options) { resultAccount, files, _, error in
            guard account == resultAccount else { return }
            var metadatasDirectory: [tableMetadata] = []
            var metadatasSynchronizationOffline: [tableMetadata] = []

            if !add {
                if self.database.getResultMetadata(predicate: NSPredicate(format: "account == %@ AND sessionSelector == %@ AND (status == %d OR status == %d)",
                                                                          account,
                                                                          self.global.selectorSynchronizationOffline,
                                                                          self.global.metadataStatusWaitDownload,
                                                                          self.global.metadataStatusDownloading)) != nil { return }
            }

            if error == .success, let files {
                for file in files {
                    if file.directory {
                        metadatasDirectory.append(self.database.convertFileToMetadata(file, isDirectoryE2EE: false))
                    } else if self.isSynchronizable(ocId: file.ocId, fileName: file.fileName, etag: file.etag) {
                        metadatasSynchronizationOffline.append(self.database.convertFileToMetadata(file, isDirectoryE2EE: false))
    internal func synchronization(account: String, serverUrl: String, metadatasInDownload: [tableMetadata]?) async {
        let showHiddenFiles = NCKeychain().getShowHiddenFiles(account: account)
    internal func synchronization(account: String, serverUrl: String, userId: String, urlBase: String, metadatasInDownload: [tableMetadata]?) async {
        let showHiddenFiles = NCPreferences().getShowHiddenFiles(account: account)
        let options = NKRequestOptions(timeout: 300, taskDescription: NCGlobal.shared.taskDescriptionSynchronization, queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        nkLog(tag: self.global.logTagSync, emoji: .start, message: "Start read infinite folder: \(serverUrl)")

        let results = await NextcloudKit.shared.readFileOrFolderAsync(serverUrlFileName: serverUrl, depth: "infinity", showHiddenFiles: showHiddenFiles, account: account, options: options) { task in
            Task {
                let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: account,
                                                                                            path: serverUrl,
                                                                                            name: "readFileOrFolder")
                await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
            }
        }

        if results.error == .success, let files = results.files {
            nkLog(tag: self.global.logTagSync, emoji: .success, message: "Read infinite folder: \(serverUrl)")

            for file in files {
                if file.directory {
                    let metadata = await NCManageDatabase.shared.convertFileToMetadataAsync(file)
                    await NCManageDatabase.shared.createDirectory(metadata: metadata)
                } else {
                    if await isFileDifferent(ocId: file.ocId, fileName: file.fileName, etag: file.etag, metadatasInDownload: metadatasInDownload, userId: userId, urlBase: urlBase) {
                        let metadata = await NCManageDatabase.shared.convertFileToMetadataAsync(file)
                        metadata.session = self.sessionDownloadBackground
                        metadata.sessionSelector = NCGlobal.shared.selectorSynchronizationOffline
                        metadata.sessionTaskIdentifier = 0
                        metadata.sessionError = ""
                        metadata.status = NCGlobal.shared.metadataStatusWaitDownload
                        metadata.sessionDate = Date()

                        await NCManageDatabase.shared.addMetadataAsync(metadata)

                        nkLog(tag: self.global.logTagSync, emoji: .start, message: "File download: \(file.serverUrl)/\(file.fileName)")
                    }
                }

                let diffDate = Date().timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
                NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Synchronization \(serverUrl) in \(diffDate)")

                self.database.addMetadatas(metadatasDirectory)
                self.database.addDirectories(metadatas: metadatasDirectory)

                self.database.setMetadatasSessionInWaitDownload(metadatas: metadatasSynchronizationOffline,
                                                                session: self.sessionDownloadBackground,
                                                                selector: self.global.selectorSynchronizationOffline)
                self.database.setDirectorySynchronizationDate(serverUrl: serverUrl, account: account)

                completion(0, metadatasSynchronizationOffline.count)
            } else {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Synchronization \(serverUrl), \(error.errorCode)")

                completion(error.errorCode, metadatasSynchronizationOffline.count)
            }
        }
    }

    @discardableResult
    func synchronization(account: String, serverUrl: String, add: Bool) async -> (errorCode: Int, num: Int) {
        await withUnsafeContinuation({ continuation in
            synchronization(account: account, serverUrl: serverUrl, add: add) { errorCode, num in
                continuation.resume(returning: (errorCode, num))
            }
        })
    }

    func isSynchronizable(ocId: String, fileName: String, etag: String) -> Bool {
        if let metadata = self.database.getMetadataFromOcId(ocId),
           metadata.status == self.global.metadataStatusDownloading || metadata.status == self.global.metadataStatusWaitDownload {
            return false
        }
        let localFile = self.database.getResultsTableLocalFile(predicate: NSPredicate(format: "ocId == %@", ocId))?.first
        if localFile?.etag != etag || NCUtilityFileSystem().fileProviderStorageSize(ocId, fileNameView: fileName) == 0 {
            return true
        } else {
            return false
        }

            await self.database.setDirectorySynchronizationDateAsync(serverUrl: serverUrl, account: account)
        } else {
            nkLog(tag: self.global.logTagSync, emoji: .error, message: "Read infinite folder: \(serverUrl), error: \(results.error.errorCode)")
        }

        nkLog(tag: self.global.logTagSync, emoji: .stop, message: "Stop read infinite folder: \(serverUrl)")
    }

    internal func isFileDifferent(ocId: String,
                                  fileName: String,
                                  etag: String,
                                  metadatasInDownload: [tableMetadata]?,
                                  userId: String,
                                  urlBase: String) async -> Bool {
        let match = metadatasInDownload?.contains { $0.ocId == ocId } ?? false
        if match {
            return false
        }

        guard let localFile = await NCManageDatabase.shared.getTableLocalFileAsync(predicate: NSPredicate(format: "ocId == %@", ocId)) else {
            return true
        }
        let fileNamePath = self.utilityFileSystem.getDirectoryProviderStorageOcId(ocId, fileName: fileName, userId: userId, urlBase: urlBase)
        let size = await self.utilityFileSystem.fileSizeAsync(atPath: fileNamePath)
        let isDifferent = (localFile.etag != etag) || size == 0

        return isDifferent
    }
}
