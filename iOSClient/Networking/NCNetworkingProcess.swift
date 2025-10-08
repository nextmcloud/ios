// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2023 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import Photos
import RealmSwift

actor NCNetworkingProcess {
    static let shared = NCNetworkingProcess()

    private let utilityFileSystem = NCUtilityFileSystem()
    private let global = NCGlobal.shared
    private let networking = NCNetworking.shared

    private var currentTask: Task<Void, Never>?
    private var enableControllingScreenAwake = true
    private var currentAccount = ""

    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.nextcloud.timerProcess", qos: .utility)
    private var lastUsedInterval: TimeInterval = 4
    private let maxInterval: TimeInterval = 4
    private let minInterval: TimeInterval = 2

    private init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterPlayerIsPlaying), object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }

            Task {
                await self.setScreenAwake(false)
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterPlayerStoppedPlaying), object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }

            Task {
                await self.setScreenAwake(true)
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }

            Task {
                await self.stopTimer()
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if UIApplication.shared.applicationState == .active {
                    self.startTimer()
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }

            Task {
                await self.startTimer(interval: self.maxInterval)
            }
        }
    }

    private func setScreenAwake(_ enabled: Bool) {
        enableControllingScreenAwake = enabled
    }

    func setCurrentAccount(_ account: String) {
        currentAccount = account
    }

    func startTimer(interval: TimeInterval) async {
        let isActive = await MainActor.run {
            UIApplication.shared.applicationState == .active
        }
        guard isActive else {
            return
        }

        await stopTimer()

        lastUsedInterval = interval
        let newTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        newTimer.schedule(deadline: .now() + interval, repeating: interval)

        newTimer.setEventHandler { [weak self] in
            guard let self else { return }
            Task {
                await self.handleTimerTick()
            }
        }

        timer = newTimer
        newTimer.resume()
    }

    func stopTimer() async {
        timer?.cancel()
        timer = nil
    }

    private func handleTimerTick() async {
        if currentTask != nil {
            print("[NKLOG] current task is running")
            return
        }

        currentTask = Task {
            defer {
                currentTask = nil
            }

            guard networking.isOnline,
                  !currentAccount.isEmpty,
                  networking.noServerErrorAccount(currentAccount)
            else {
                return
            }

            let metadatas = await NCManageDatabase.shared.getMetadatasAsync(predicate: NSPredicate(format: "status != %d", self.global.metadataStatusNormal))
            if !metadatas.isEmpty {
                let tasks = await networking.getAllDataTask()
                let hasSyncTask = tasks.contains { $0.taskDescription == global.taskDescriptionSynchronization }
                let resultsScreenAwake = metadatas.filter { global.metadataStatusForScreenAwake.contains($0.status) }

                if enableControllingScreenAwake {
                    ScreenAwakeManager.shared.mode = resultsScreenAwake.isEmpty && !hasSyncTask ? .off : NCPreferences().screenAwakeMode
                }

                await runMetadataPipelineAsync()

                // TODO: Check temperature

                if lastUsedInterval != minInterval {
                    await startTimer(interval: minInterval)
                }
            } else {
                // Remove upload asset
                await removeUploadedAssetsIfNeeded()

                if lastUsedInterval != maxInterval {
                    await startTimer(interval: maxInterval)
                }
            }
        }
    }

    private func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            let applicationState = UIApplication.shared.applicationState
            self.lockQueue.async {
                guard !self.hasRun,
                      self.networking.isOnline,
                      let results = self.database.getResultsMetadatas(predicate: NSPredicate(format: "status != %d", self.global.metadataStatusNormal))?.freeze()
                else { return }
                self.hasRun = true

                /// Keep screen awake
                ///
                Task {
                    let tasks = await self.networking.getAllDataTask()
                    let hasSynchronizationTask = tasks.contains { $0.taskDescription == NCGlobal.shared.taskDescriptionSynchronization }
                    let resultsTransfer = results.filter { self.global.metadataStatusInTransfer.contains($0.status) }

                    if !self.enableControllingScreenAwake { return }

                    if resultsTransfer.isEmpty && !hasSynchronizationTask {
                        ScreenAwakeManager.shared.mode = .off
                    } else {
                        ScreenAwakeManager.shared.mode = NCKeychain().screenAwakeMode
                    }
                }

                if results.isEmpty {

                    /// Remove Photo CameraRoll
                    ///
                    if NCKeychain().removePhotoCameraRoll,
                       applicationState == .active,
                       let localIdentifiers = self.database.getAssetLocalIdentifiersUploaded(),
                       !localIdentifiers.isEmpty {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.deleteAssets(PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil) as NSFastEnumeration)
                        }, completionHandler: { _, _ in
                            self.database.clearAssetLocalIdentifiers(localIdentifiers)
                            self.hasRun = false
                        })
                    } else {
                        self.hasRun = false
                    }
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterUpdateBadgeNumber,
                                                                object: nil,
                                                                userInfo: ["counterDownload": 0,
                                                                           "counterUpload": 0])
                } else {
                    Task { [weak self] in
                        guard let self else { return }
                        await self.start()
                        self.hasRun = false
                    }
                }
            }
        })
    }

    @discardableResult
    private func start() async -> (counterDownloading: Int, counterUploading: Int) {
        let applicationState = await checkApplicationState()
        let httpMaximumConnectionsPerHostInDownload = NCBrandOptions.shared.httpMaximumConnectionsPerHostInDownload
        var httpMaximumConnectionsPerHostInUpload = NCBrandOptions.shared.httpMaximumConnectionsPerHostInUpload
        let sessionUploadSelectors = [global.selectorUploadFileNODelete, global.selectorUploadFile, global.selectorUploadAutoUpload]
        let metadatasDownloading = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusDownloading))
        let metadatasUploading = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusUploading))
        let metadatasUploadError: [tableMetadata] = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusUploadError), sortedByKeyPath: "sessionDate", ascending: true) ?? []
        let isWiFi = networking.networkReachability == NKCommon.TypeReachability.reachableEthernetOrWiFi
        var counterDownloading = metadatasDownloading.count
        var counterUploading = metadatasUploading.count

        database.realmRefresh()

        /// ------------------------ WEBDAV
        ///
        let metadatas = database.getMetadatas(predicate: NSPredicate(format: "status IN %@", global.metadataStatusWaitWebDav))
        if !metadatas.isEmpty {
            let error = await metadataStatusWaitWebDav()
            if error {
                return (counterDownloading, counterUploading)
    private func removeUploadedAssetsIfNeeded() async {
        guard NCPreferences().removePhotoCameraRoll,
              let localIdentifiers = await NCManageDatabase.shared.getAssetLocalIdentifiersUploadedAsync(),
              !localIdentifiers.isEmpty else {
            return
        }

         _ = await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(
                    PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil) as NSFastEnumeration
                )
            }, completionHandler: { completed, _ in
                continuation.resume(returning: completed)
            })
        }

        await NCManageDatabase.shared.clearAssetLocalIdentifiersAsync(localIdentifiers)
    }

    private func runMetadataPipelineAsync() async {
        let database = NCManageDatabase.shared
        let metadatas = await database.getMetadatasAsync(predicate: NSPredicate(format: "status != %d", self.global.metadataStatusNormal), withLimit: NCBrandOptions.shared.numMaximumProcess)
        guard let metadatas,
              !metadatas.isEmpty else {
            return
        }

        let counterDownloading = metadatas.filter { $0.status == self.global.metadataStatusDownloading }.count
        let counterUploading = metadatas.filter { $0.status == self.global.metadataStatusUploading }.count
        let processRate: Double = Double(counterDownloading + counterUploading) / Double(NCBrandOptions.shared.numMaximumProcess)

        // if less than 20% exit
        if processRate > 0.2 {
            nkLog(debug: "Process rate \(processRate)")
            return
        }
        var availableProcess = NCBrandOptions.shared.numMaximumProcess - (counterDownloading + counterUploading)

        /// ------------------------ WEBDAV
        let waitWebDav = metadatas.filter { self.global.metadataStatusWaitWebDav.contains($0.status) }
        if !waitWebDav.isEmpty {
            let (_, error) = await metadataStatusWaitWebDav(metadatas: Array(waitWebDav))
            if error != .success {
                return
            }
        }

        /// ------------------------ DOWNLOAD
        ///
        let limitDownload = httpMaximumConnectionsPerHostInDownload - counterDownloading
        let metadatasWaitDownload = self.database.getMetadatas(predicate: NSPredicate(format: "session == %@ AND status == %d", networking.sessionDownloadBackground, global.metadataStatusWaitDownload), numItems: limitDownload, sorted: "sessionDate", ascending: true)
        let httpMaximumConnectionsPerHostInDownload = NCBrandOptions.shared.httpMaximumConnectionsPerHostInDownload
        var counterDownloading = metadatas.filter { $0.status == self.global.metadataStatusDownloading }.count
        let limitDownload = max(0, httpMaximumConnectionsPerHostInDownload - counterDownloading)

        // ------------------------ DOWNLOAD
        let filteredDownload = metadatas
            .filter { $0.session == self.networking.sessionDownloadBackground && $0.status == NCGlobal.shared.metadataStatusWaitDownload }
            .sorted { ($0.sessionDate ?? Date.distantFuture) < ($1.sessionDate ?? Date.distantFuture) }
            .prefix(availableProcess)
        let metadatasWaitDownload = Array(filteredDownload)

        for metadata in metadatasWaitDownload where counterDownloading < httpMaximumConnectionsPerHostInDownload {
            /// Check Server Error
            guard networking.noServerErrorAccount(metadata.account) else {
                continue
            }

            counterDownloading += 1
            networking.download(metadata: metadata, withNotificationProgressTask: true)
        }
        if counterDownloading == 0 {
            let metadatasDownloadError: [tableMetadata] = self.database.getMetadatas(predicate: NSPredicate(format: "session == %@ AND status == %d", networking.sessionDownloadBackground, global.metadataStatusDownloadError), sortedByKeyPath: "sessionDate", ascending: true) ?? []
            for metadata in metadatasDownloadError {
                // Verify COUNTER ERROR
                if let transfer = NCTransferProgress.shared.get(ocIdTransfer: metadata.ocIdTransfer),
                   transfer.countError > 3 {
                    continue
                }
                self.database.setMetadataSession(ocId: metadata.ocId,
                                                 sessionError: "",
                                                 status: global.metadataStatusWaitDownload)
            }
        }

        /// ------------------------ UPLOAD
        ///

        /// In background max 2 upload otherwise iOS Termination Reason: RUNNINGBOARD 0xdead10cc
        if applicationState == .background {
            httpMaximumConnectionsPerHostInUpload = 2
        }

        /// E2EE - only one for time
        for metadata in metadatasUploading.unique(map: { $0.serverUrl }) {
            if metadata.isDirectoryE2EE {
                return (counterDownloading, counterUploading)
            }
        }

        /// CHUNK - only one for time
        if !metadatasUploading.filter({ $0.chunk > 0 }).isEmpty {
            return (counterDownloading, counterUploading)
        }

        for sessionSelector in sessionUploadSelectors where counterUploading < httpMaximumConnectionsPerHostInUpload {
            let limitUpload = httpMaximumConnectionsPerHostInUpload - counterUploading
            let metadatasWaitUpload = self.database.getMetadatas(predicate: NSPredicate(format: "sessionSelector == %@ AND status == %d", sessionSelector, global.metadataStatusWaitUpload), numItems: limitUpload, sorted: "sessionDate", ascending: true)
        var httpMaximumConnectionsPerHostInUpload = NCBrandOptions.shared.httpMaximumConnectionsPerHostInUpload
        for metadata in metadatasWaitDownload {
            availableProcess -= 1
            await networking.downloadFileInBackground(metadata: metadata)
        }

        // TEST AVAILABLE PROCESS
        guard availableProcess > 0 else {
            return
        }

        // ------------------------ UPLOAD

        // CHUNK or  E2EE - only one for time
        let hasUploadingMetadataWithChunksOrE2EE = metadatas.filter { $0.status == NCGlobal.shared.metadataStatusUploading && ($0.chunk > 0 || $0.e2eEncrypted == true) }
        if !hasUploadingMetadataWithChunksOrE2EE.isEmpty {
            return
        }

        let isWiFi = self.networking.networkReachability == NKTypeReachability.reachableEthernetOrWiFi
        let sessionUploadSelectors = [self.global.selectorUploadFileNODelete, self.global.selectorUploadFile, self.global.selectorUploadAutoUpload]
        for sessionSelector in sessionUploadSelectors {

            let filteredUpload = metadatas
                .filter { $0.sessionSelector == sessionSelector && $0.status == NCGlobal.shared.metadataStatusWaitUpload }
                .sorted { ($0.sessionDate ?? Date.distantFuture) < ($1.sessionDate ?? Date.distantFuture) }
                .prefix(availableProcess)
            let metadatasWaitUpload = Array(filteredUpload)

            if !metadatasWaitUpload.isEmpty {
                nkLog(debug: "PROCESS (UPLOAD \(sessionSelector)) find \(metadatasWaitUpload.count) items")
            }

            for metadata in metadatasWaitUpload where counterUploading < httpMaximumConnectionsPerHostInUpload {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                if NCTransferProgress.shared.get(ocIdTransfer: metadata.ocIdTransfer) != nil {
                    NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Process auto upload skipped file: \(metadata.serverUrl)/\(metadata.fileNameView), because is already in session.")
                    continue
                }

            for metadata in metadatasWaitUpload {
                guard availableProcess > 0 else {
                    return
                }
                let metadatas = await NCCameraRoll().extractCameraRoll(from: metadata)

                // no extract photo
                if metadatas.isEmpty {
                    await database.deleteMetadataAsync(id: metadata.ocId)
                }

                for metadata in metadatas {
                    guard timer != nil else {
                        return
                    }

                    /// NO WiFi
                    if !isWiFi && metadata.session == networking.sessionUploadBackgroundWWan { continue }
                    if applicationState != .active && (isInDirectoryE2EE || metadata.chunk > 0) { continue }
                    if let metadata = self.database.setMetadataStatus(ocId: metadata.ocId, status: global.metadataStatusUploading) {
                        /// find controller
                        var controller: NCMainTabBarController?
                        if let sceneIdentifier = metadata.sceneIdentifier, !sceneIdentifier.isEmpty {
                            controller = SceneManager.shared.getController(sceneIdentifier: sceneIdentifier)
                        } else {
                            for ctlr in SceneManager.shared.getControllers() {
                                let account = await ctlr.account
                                if account == metadata.account {
                                    controller = ctlr
                                }
                            }

                            if controller == nil {
                                controller = await UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController

                    await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                           status: global.metadataStatusUploading)

                    /// find controller
                    var controller: NCMainTabBarController?
                    if let sceneIdentifier = metadata.sceneIdentifier, !sceneIdentifier.isEmpty {
                        controller = SceneManager.shared.getController(sceneIdentifier: sceneIdentifier)
                    }

                    if controller == nil {
                        for ctlr in SceneManager.shared.getControllers() {
                            let account = await ctlr.account
                            if account == metadata.account {
                                controller = ctlr
                            }
                        }
                    }

                        networking.upload(metadata: metadata, controller: controller)
                        if isInDirectoryE2EE || metadata.chunk > 0 {
                            httpMaximumConnectionsPerHostInUpload = 1
                        }
                        counterUploading += 1
                    if controller == nil {
                        controller = await UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
                    }

                    // With E2EE or CHUNK upload and exit
                    if metadata.isDirectoryE2EE {
                        await NCNetworkingE2EEUpload().upload(metadata: metadata, controller: controller)
                        return
                    } else if metadata.chunk > 0 {
                        let controller = controller

                        Task { @MainActor in
                            var numChunks = 0
                            var counterUpload: Int = 0
                            var taskHandler: URLSessionTask?
                            let hud = NCHud(controller?.view)
                            hud.pieProgress(text: NSLocalizedString("_wait_file_preparation_", comment: ""), tapToCancelDetailText: true) {
                                NotificationCenter.default.postOnMainThread(name: NextcloudKit.shared.nkCommonInstance.notificationCenterChunkedFileStop.rawValue)
                            }

                            await NCNetworking.shared.uploadChunkFile(metadata: metadata) { num in
                                numChunks = num
                            } counterChunk: { counter in
                                hud.progress(num: Float(counter), total: Float(numChunks))
                            } startFilesChunk: { _ in
                                hud.pieProgress(text: NSLocalizedString("_keep_active_for_upload_", comment: ""), tapToCancelDetailText: true) {
                                    taskHandler?.cancel()
                                }
                            } requestHandler: { _ in
                                hud.progress(num: Float(counterUpload), total: Float(numChunks))
                                counterUpload += 1
                            } taskHandler: { task in
                                taskHandler = task
                            } assembling: {
                                hud.setText(NSLocalizedString("_wait_", comment: ""))
                            }

                            hud.dismiss()
                        }
                        return
                    } else {
                        await networking.uploadFileInBackground(metadata: metadata)
                    }
                    availableProcess -= 1
                }
            }
        }

        /// No upload available ? --> Retry Upload in Error
        ///
        if counterUploading == 0 {
            for metadata in metadatasUploadError {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                // VeriCheckfy COUNTER ERROR
                if let transfer = NCTransferProgress.shared.get(ocIdTransfer: metadata.ocIdTransfer),
                   transfer.countError > 3 {
                    continue
                }
                /// Check QUOTA
                if metadata.sessionError.contains("\(global.errorQuota)") {
                    NextcloudKit.shared.getUserProfile(account: metadata.account) { _, userProfile, _, error in
                        if error == .success, let userProfile, userProfile.quotaFree > 0, userProfile.quotaFree > metadata.size {
                            self.database.setMetadataSession(ocId: metadata.ocId,
                                                             session: self.networking.sessionUploadBackground,
                                                             sessionError: "",
                                                             status: self.global.metadataStatusWaitUpload)
                        }
                    }
                } else {
                    self.database.setMetadataSession(ocId: metadata.ocId,
                                                     session: self.networking.sessionUploadBackground,
                                                     sessionError: "",
                                                     status: global.metadataStatusWaitUpload)
                    let results = await NextcloudKit.shared.getUserMetadataAsync(account: metadata.account, userId: metadata.userId)
                    let results = await NextcloudKit.shared.getUserMetadataAsync(account: metadata.account, userId: metadata.userId) { task in
                        Task {
                            let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                        path: metadata.userId,
                                                                                                        name: "getUserMetadata")
                            await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                        }
                    }
                    if results.error == .success, let userProfile = results.userProfile, userProfile.quotaFree > 0, userProfile.quotaFree > metadata.size {
                        await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                               session: self.networking.sessionUploadBackground,
                                                               sessionError: "",
                                                               status: self.global.metadataStatusWaitUpload)
                    }
                } else {
                    await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                           session: self.networking.sessionUploadBackground,
                                                           sessionError: "",
                                                           status: global.metadataStatusWaitUpload)
                }
            }
        }

        return (counterDownloading, counterUploading)
    }

    private func checkApplicationState() async -> UIApplication.State {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let appState = UIApplication.shared.applicationState
                continuation.resume(returning: appState)
            }
        }
    }

    private func metadataStatusWaitWebDav() async -> Bool {
        var returnError: Bool = false
        let options = NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)

        /// ------------------------ CREATE FOLDER
        ///
        if let metadatasWaitCreateFolder = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitCreateFolder), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitCreateFolder.isEmpty {
            for metadata in metadatasWaitCreateFolder {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                let error = await networking.createFolder(fileName: metadata.fileName, serverUrl: metadata.serverUrl, overwrite: true, withPush: false, sceneIdentifier: nil, session: NCSession.shared.getSession(account: metadata.account), options: options)
                if error != .success {
                    if metadata.sessionError.isEmpty {
                        let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
                        let message = String(format: NSLocalizedString("_create_folder_error_", comment: ""), serverUrlFileName)
                        NCContentPresenter().messageNotification(message, error: error, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, priority: .max)
                    }
                    returnError = true
                }
    private func metadataStatusWaitWebDav(metadatas: [tableMetadata]) async -> (status: Int?, error: NKError) {
        let networking = NCNetworking.shared
        let database = NCManageDatabase.shared

        /// ------------------------ CREATE FOLDER
        ///
        let metadatasWaitCreateFolder = metadatas.filter { $0.status == global.metadataStatusWaitCreateFolder }.sorted { $0.serverUrl < $1.serverUrl }
        for metadata in metadatasWaitCreateFolder {
            guard timer != nil else {
                return (global.metadataStatusWaitCreateFolder, .cancelled)
            }
            var error: NKError = .success

            if metadata.sessionSelector == self.global.selectorUploadAutoUpload {
                error = await networking.createFolderForAutoUpload(serverUrlFileName: metadata.serverUrlFileName, account: metadata.account)
                if error != .success {
                    return (global.metadataStatusWaitCreateFolder, error)
                }
            } else {
                error = await networking.createFolder(fileName: metadata.fileName,
                                                      serverUrl: metadata.serverUrl,
                                                      overwrite: true,
                                                      session: NCSession.shared.getSession(account: metadata.account),
                                                      selector: metadata.sessionSelector)
            }

            if let sceneIdentifier = metadata.sceneIdentifier {
                await networking.transferDispatcher.notifyDelegates(forScene: sceneIdentifier) { delegate in
                    delegate.transferChange(status: self.global.networkingStatusCreateFolder,
                                            metadata: metadata,
                                            error: error)
                } others: { delegate in
                    delegate.transferReloadData(serverUrl: metadata.serverUrl, status: nil)
                }
            } else {
                await networking.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferChange(status: self.global.networkingStatusCreateFolder,
                                            metadata: metadata,
                                            error: error)
                }
            }

            if error != .success {
                return (global.metadataStatusWaitCreateFolder, error)
            }
        }

        /// ------------------------ COPY
        ///
        if let metadatasWaitCopy = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitCopy), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitCopy.isEmpty {
            for metadata in metadatasWaitCopy {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
        let metadatasWaitCopy = metadatas.filter { $0.status == global.metadataStatusWaitCopy }.sorted { $0.serverUrl < $1.serverUrl }
        for metadata in metadatasWaitCopy {
            guard timer != nil else {
                return (global.metadataStatusWaitCopy, .cancelled)
            }

            let destination = metadata.destination
            var serverUrlFileNameDestination = utilityFileSystem.createServerUrl(serverUrl: destination, fileName: metadata.fileName)
            let overwrite = (metadata.storeFlag as? NSString)?.boolValue ?? false

            /// Within same folder
            if metadata.serverUrl == destination {
                let fileNameCopy = await NCNetworking.shared.createFileName(fileNameBase: metadata.fileName, account: metadata.account, serverUrl: metadata.serverUrl)
                serverUrlFileNameDestination = utilityFileSystem.createServerUrl(serverUrl: destination, fileName: fileNameCopy)
            }

            let resultCopy = await NextcloudKit.shared.copyFileOrFolderAsync(serverUrlFileNameSource: metadata.serverUrlFileName, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: overwrite, account: metadata.account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                path: serverUrlFileNameDestination,
                                                                                                name: "copyFileOrFolder")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }

            await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                   status: global.metadataStatusNormal)

            if resultCopy.error == .success {
                let result = await NCNetworking.shared.readFileAsync(serverUrlFileName: serverUrlFileNameDestination, account: metadata.account)
                if result.error == .success, let metadata = result.metadata {
                    await database.addMetadataAsync(metadata)
                }

                let serverUrlTo = metadata.serverUrlTo
                let serverUrlFileNameSource = metadata.serverUrl + "/" + metadata.fileName
                var serverUrlFileNameDestination = serverUrlTo + "/" + metadata.fileName
                let overwrite = (metadata.storeFlag as? NSString)?.boolValue ?? false
            await networking.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferCopy(metadata: metadata, destination: destination, error: resultCopy.error)
            }

                /// Within same folder
                if metadata.serverUrl == serverUrlTo {
                    let fileNameCopy = await NCNetworking.shared.createFileName(fileNameBase: metadata.fileName, account: metadata.account, serverUrl: metadata.serverUrl)
                    serverUrlFileNameDestination = serverUrlTo + "/" + fileNameCopy
                }

                let result = await networking.copyFileOrFolder(serverUrlFileNameSource: serverUrlFileNameSource, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: overwrite, account: metadata.account, options: options)

                database.setMetadataCopyMove(ocId: metadata.ocId, serverUrlTo: "", overwrite: nil, status: global.metadataStatusNormal)

                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterCopyMoveFile, userInfo: ["serverUrl": metadata.serverUrl, "account": metadata.account, "dragdrop": false, "type": "copy"])

                if result.error == .success {

                    NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterGetServerData, userInfo: ["serverUrl": metadata.serverUrl])
                    NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterGetServerData, userInfo: ["serverUrl": serverUrlTo])

                } else {
                    NCContentPresenter().showError(error: result.error)
                }
            if resultCopy.error != .success {
                return (global.metadataStatusWaitCopy, resultCopy.error)
            }
        }

        /// ------------------------ MOVE
        ///
        if let metadatasWaitMove = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitMove), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitMove.isEmpty {
            for metadata in metadatasWaitMove {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                let serverUrlTo = metadata.serverUrlTo
                let serverUrlFileNameSource = metadata.serverUrl + "/" + metadata.fileName
                let serverUrlFileNameDestination = serverUrlTo + "/" + metadata.fileName
                let overwrite = (metadata.storeFlag as? NSString)?.boolValue ?? false

                let result = await networking.moveFileOrFolder(serverUrlFileNameSource: serverUrlFileNameSource, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: overwrite, account: metadata.account, options: options)

                database.setMetadataCopyMove(ocId: metadata.ocId, serverUrlTo: "", overwrite: nil, status: global.metadataStatusNormal)

                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterCopyMoveFile, userInfo: ["serverUrl": metadata.serverUrl, "account": metadata.account, "dragdrop": false, "type": "move"])

                if result.error == .success {
                    if metadata.directory {
                        self.database.deleteDirectoryAndSubDirectory(serverUrl: utilityFileSystem.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName), account: result.account)
                    } else {
        let metadatasWaitMove = metadatas.filter { $0.status == global.metadataStatusWaitMove }.sorted { $0.serverUrl < $1.serverUrl }
        for metadata in metadatasWaitMove {
            guard timer != nil else {
                return (global.metadataStatusWaitMove, .cancelled)
            }

            let destination = metadata.destination
            let serverUrlFileNameDestination = utilityFileSystem.createServerUrl(serverUrl: destination, fileName: metadata.fileName)
            let overwrite = (metadata.storeFlag as? NSString)?.boolValue ?? false

            let resultMove = await NextcloudKit.shared.moveFileOrFolderAsync(serverUrlFileNameSource: metadata.serverUrlFileName, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: overwrite, account: metadata.account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                path: serverUrlFileNameDestination,
                                                                                                name: "moveFileOrFolder")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }

            await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                   status: global.metadataStatusNormal)

            if resultMove.error == .success {
                let result = await NCNetworking.shared.readFileAsync(serverUrlFileName: serverUrlFileNameDestination, account: metadata.account)
                if result.error == .success, let metadata = result.metadata {
                    await self.database.addMetadataAsync(metadata)
                }
                // Remove source metadata
                if metadata.directory {
                    let serverUrl = utilityFileSystem.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName)
                    await self.database.deleteDirectoryAndSubDirectoryAsync(serverUrl: serverUrl,
                                                                            account: result.account)
                } else {
                    do {
                        try FileManager.default.removeItem(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
                    } catch { }
                    await self.database.deleteVideoAsync(metadata.ocId)
                    await self.database.deleteMetadataOcIdAsync(metadata.ocId)
                    await self.database.deleteLocalFileOcIdAsync(metadata.ocId)
                    // LIVE PHOTO
                    if let metadataLive = await self.database.getMetadataLivePhotoAsync(metadata: metadata) {
                        do {
                            try FileManager.default.removeItem(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
                        } catch { }
                        self.database.deleteVideo(metadata: metadata)
                        self.database.deleteMetadataOcId(metadata.ocId)
                        self.database.deleteLocalFileOcId(metadata.ocId)
                        // LIVE PHOTO
                        if let metadataLive = self.database.getMetadataLivePhoto(metadata: metadata) {
                            do {
                                try FileManager.default.removeItem(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadataLive.ocId))
                            } catch { }
                            self.database.deleteVideo(metadata: metadataLive)
                            self.database.deleteMetadataOcId(metadataLive.ocId)
                            self.database.deleteLocalFileOcId(metadataLive.ocId)
                        }
                        await self.database.deleteVideoAsync(metadataLive.ocId)
                        await self.database.deleteMetadataOcIdAsync(metadataLive.ocId)
                        await self.database.deleteLocalFileOcIdAsync(metadataLive.ocId)
                    }

                    NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterGetServerData, userInfo: ["serverUrl": metadata.serverUrl])
                    NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterGetServerData, userInfo: ["serverUrl": serverUrlTo])

                } else {
                    NCContentPresenter().showError(error: result.error)
                    // Remove directory
                    if metadata.directory {
                        let serverUrl = utilityFileSystem.createServerUrl(serverUrl: metadata.serverUrl, fileName: metadata.fileName)
                        await database.deleteDirectoryAndSubDirectoryAsync(serverUrl: serverUrl,
                                                                           account: result.account)
                    }
                    await database.addMetadataAsync(metadata)
                }
            }

            await networking.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferMove(metadata: metadata, destination: destination, error: resultMove.error)
            }

            if resultMove.error != .success {
                return (global.metadataStatusWaitMove, resultMove.error)
            }
        }

        /// ------------------------ FAVORITE
        ///
        if let metadatasWaitFavorite = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitFavorite), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitFavorite.isEmpty {
            for metadata in metadatasWaitFavorite {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                let session = NCSession.Session(account: metadata.account, urlBase: metadata.urlBase, user: metadata.user, userId: metadata.userId)
                let fileName = utilityFileSystem.getFileNamePath(metadata.fileName, serverUrl: metadata.serverUrl, session: session)
                let error = await networking.setFavorite(fileName: fileName, favorite: metadata.favorite, account: metadata.account, options: options)

                if error == .success {
                    database.setMetadataFavorite(ocId: metadata.ocId, favorite: nil, saveOldFavorite: nil, status: global.metadataStatusNormal)
                } else {
                    let favorite = (metadata.storeFlag as? NSString)?.boolValue ?? false
                    database.setMetadataFavorite(ocId: metadata.ocId, favorite: favorite, saveOldFavorite: nil, status: global.metadataStatusNormal)
                }

                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterFavoriteFile, userInfo: ["ocId": metadata.ocId, "serverUrl": metadata.serverUrl])
        let metadatasWaitFavorite = metadatas.filter { $0.status == global.metadataStatusWaitFavorite }.sorted { $0.serverUrl < $1.serverUrl }
        for metadata in metadatasWaitFavorite {
            guard timer != nil else {
                return (global.metadataStatusWaitFavorite, .cancelled)
            }

            let session = NCSession.Session(account: metadata.account, urlBase: metadata.urlBase, user: metadata.user, userId: metadata.userId)
            let fileName = utilityFileSystem.getFileNamePath(metadata.fileName, serverUrl: metadata.serverUrl, session: session)
            let resultsFavorite = await NextcloudKit.shared.setFavoriteAsync(fileName: fileName, favorite: metadata.favorite, account: metadata.account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                path: fileName,
                                                                                                name: "setFavorite")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }

            if resultsFavorite.error == .success {
                await database.setMetadataFavoriteAsync(ocId: metadata.ocId,
                                                        favorite: nil,
                                                        saveOldFavorite: nil,
                                                        status: global.metadataStatusNormal)
            } else {
                let favorite = (metadata.storeFlag as? NSString)?.boolValue ?? false
                await database.setMetadataFavoriteAsync(ocId: metadata.ocId,
                                                        favorite: favorite,
                                                        saveOldFavorite: nil,
                                                        status: global.metadataStatusNormal)
            }

            await networking.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferChange(status: self.global.networkingStatusFavorite,
                                        metadata: metadata,
                                        error: resultsFavorite.error)
            }

            if resultsFavorite.error != .success {
                return (global.metadataStatusWaitFavorite, resultsFavorite.error)
            }
        }

        /// ------------------------ RENAME
        ///
        if let metadatasWaitRename = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitRename), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitRename.isEmpty {
            for metadata in metadatasWaitRename {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                let serverUrlFileNameSource = metadata.serveUrlFileName
                let serverUrlFileNameDestination = metadata.serverUrl + "/" + metadata.fileName
                let result = await networking.moveFileOrFolder(serverUrlFileNameSource: serverUrlFileNameSource, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: false, account: metadata.account, options: options)
        let metadatasWaitRename = metadatas.filter { $0.status == global.metadataStatusWaitRename }.sorted { $0.serverUrl < $1.serverUrl }
        for metadata in metadatasWaitRename {
            guard timer != nil else {
                return (global.metadataStatusWaitRename, .cancelled)
            }

            let serverUrlFileNameSource = metadata.serverUrlFileName
            let serverUrlFileNameDestination = utilityFileSystem.createServerUrl(serverUrl: metadata.serverUrl, fileName: metadata.fileName)
            let resultRename = await NextcloudKit.shared.moveFileOrFolderAsync(serverUrlFileNameSource: serverUrlFileNameSource, serverUrlFileNameDestination: serverUrlFileNameDestination, overwrite: false, account: metadata.account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                path: serverUrlFileNameSource,
                                                                                                name: "moveFileOrFolder")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }

                if result.error == .success {
                    database.setMetadataServeUrlFileNameStatusNormal(ocId: metadata.ocId)
                } else {
                    database.restoreMetadataFileName(ocId: metadata.ocId)
                }
            if resultRename.error == .success {
                await database.setMetadataServerUrlFileNameStatusNormalAsync(ocId: metadata.ocId)
            } else {
                await database.restoreMetadataFileNameAsync(ocId: metadata.ocId)
            }

            await networking.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferChange(status: NCGlobal.shared.networkingStatusRename,
                                        metadata: metadata,
                                        error: resultRename.error)
            }

                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterRenameFile, userInfo: ["serverUrl": metadata.serverUrl, "account": metadata.account, "error": result.error])
            if resultRename.error != .success {
                return (global.metadataStatusWaitRename, resultRename.error)
            }
        }

        /// ------------------------ DELETE
        ///
        if let metadatasWaitDelete = self.database.getMetadatas(predicate: NSPredicate(format: "status == %d", global.metadataStatusWaitDelete), sortedByKeyPath: "serverUrl", ascending: true), !metadatasWaitDelete.isEmpty {
            for metadata in metadatasWaitDelete {
                /// Check Server Error
                guard networking.noServerErrorAccount(metadata.account) else {
                    continue
                }

                let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
                let result = await networking.deleteFileOrFolder(serverUrlFileName: serverUrlFileName, account: metadata.account, options: options)

                if result.error == .success || result.error.errorCode == NCGlobal.shared.errorResourceNotFound {
                guard timer != nil else {
                    return (global.metadataStatusWaitDelete, .cancelled)
                }

                let resultDelete = await NextcloudKit.shared.deleteFileOrFolderAsync(serverUrlFileName: metadata.serverUrlFileName, account: metadata.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                    path: metadata.serverUrlFileName,
                                                                                                    name: "deleteFileOrFolder")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                }

                if resultDelete.error == .success || resultDelete.error.errorCode == NCGlobal.shared.errorResourceNotFound {
                    do {
                        try FileManager.default.removeItem(atPath: self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, userId: metadata.userId, urlBase: metadata.urlBase))
                    } catch { }

                    NCImageCache.shared.removeImageCache(ocIdPlusEtag: metadata.ocId + metadata.etag)

                    await database.deleteVideoAsync(metadata.ocId)
                    if !metadata.livePhotoFile.isEmpty {
                        await database.deleteMetadataAsync(id: metadata.livePhotoFile)
                    }
                    await database.deleteMetadataAsync(id: metadata.ocId)
                    await database.deleteLocalFileAsync(id: metadata.ocId)

                    if metadata.directory {
                        let serverUrl = utilityFileSystem.createServerUrl(serverUrl: metadata.serverUrl, fileName: metadata.fileName)
                        await database.deleteDirectoryAndSubDirectoryAsync(serverUrl: serverUrl,
                                                                           account: metadata.account)
                    }
                } else {
                    self.database.setMetadataStatus(ocId: metadata.ocId, status: self.global.metadataStatusNormal)

                    metadatasError[metadata] = .success
                } else {
                    await database.setMetadataSessionAsync(ocId: metadata.ocId,
                                                           status: global.metadataStatusNormal)
                    metadatasError[metadata] = resultDelete.error
                    returnError = resultDelete.error
                }

                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteFile, userInfo: ["ocId": [metadata.ocId], "error": result.error])
            }
        }

        return returnError
    }

    // MARK: - Public

    func refreshProcessingTask() async -> (counterDownloading: Int, counterUploading: Int) {
        await withCheckedContinuation { continuation in
            self.lockQueue.sync {
                guard !self.hasRun, networking.isOnline else { return }
                self.hasRun = true

                Task { [weak self] in
                    guard let self else { return }
                    let result = await self.start()
                    self.hasRun = false
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func createProcessUploads(metadatas: [tableMetadata], verifyAlreadyExists: Bool = false, completion: @escaping (_ items: Int) -> Void = {_ in}) {
        var metadatasForUpload: [tableMetadata] = []
        for metadata in metadatas {
            if verifyAlreadyExists {
                if self.database.getMetadata(predicate: NSPredicate(format: "account == %@ && serverUrl == %@ && fileName == %@ && session != ''",
                                                                    metadata.account,
                                                                    metadata.serverUrl,
                                                                    metadata.fileName)) != nil {
                    continue
                }
            }
            metadatasForUpload.append(metadata)
        }
        self.database.addMetadatas(metadatasForUpload)
        completion(metadatasForUpload.count)
            NCNetworking.shared.notifyAllDelegates { delegate in
            await networking.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferChange(status: self.global.networkingStatusDelete,
                                        metadatasError: metadatasError)
            }

            if returnError != .success {
                return (global.metadataStatusWaitDelete, returnError)
            }
        }

        return (nil, .success)
    }
}
