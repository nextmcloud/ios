// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import RealmSwift
import SwiftUI

class NCFiles: NCCollectionViewCommon {
    @IBOutlet weak var plusButton: UIButton!

    internal var fileNameBlink: String?
    internal var lastOffsetY: CGFloat = 0
    internal var lastScrollTime: TimeInterval = 0
    internal var accumulatedScrollDown: CGFloat = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        titleCurrentFolder = NCBrandOptions.shared.brand
        layoutKey = NCGlobal.shared.layoutViewFiles
        enableSearchBar = true
        headerRichWorkspaceDisable = false
        emptyTitle = "_files_no_files_"
        emptyDescription = "_no_file_pull_down_"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /// Plus Button
        let image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))

        plusButton.setTitle("", for: .normal)
        plusButton.setImage(image, for: .normal)
        plusButton.backgroundColor = NCBrandColor.shared.customer
        if let activeTableAccount = NCManageDatabase.shared.getActiveTableAccount() {
            self.plusButton.backgroundColor = NCBrandColor.shared.getElement(account: activeTableAccount.account)
        }
        plusButton.accessibilityLabel = NSLocalizedString("_accessibility_add_upload_", comment: "")
        plusButton.layer.cornerRadius = plusButton.frame.size.width / 2.0
        plusButton.layer.masksToBounds = false
        plusButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        plusButton.layer.shadowRadius = 3.0
        plusButton.layer.shadowOpacity = 0.5

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil, queue: nil) { _ in
            if let activeTableAccount = NCManageDatabase.shared.getActiveTableAccount() {
                self.plusButton.backgroundColor = NCBrandColor.shared.getElement(account: activeTableAccount.account)
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            Task {
                await self.stopSyncMetadata()
                await self.searchOperationHandle.cancel()
            }
        }

        if self.serverUrl.isEmpty {

            ///
            /// Set ServerURL when start (isEmpty)
            ///
            self.serverUrl = utilityFileSystem.getHomeServer(session: session)
            self.titleCurrentFolder = getNavigationTitle()

            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeUser), object: nil, queue: nil) { notification in
                if let userInfo = notification.userInfo, let account = userInfo["account"] as? String {
                    if let controller = userInfo["controller"] as? NCMainTabBarController,
                       controller == self.controller {
                        controller.account = account
                    } else {
                        return
                    }
                }

                self.navigationController?.popToRootViewController(animated: false)
                self.serverUrl = self.utilityFileSystem.getHomeServer(session: self.session)
                self.isSearchingMode = false
                self.isEditMode = false
                self.fileSelect.removeAll()
                self.layoutForView = self.database.getLayoutForView(account: self.session.account, key: self.layoutKey, serverUrl: self.serverUrl)

                if self.isLayoutList {
                    self.collectionView?.collectionViewLayout = self.listLayout
                } else if self.isLayoutGrid {
                    self.collectionView?.collectionViewLayout = self.gridLayout
                } else if self.isLayoutPhoto {
                    self.collectionView?.collectionViewLayout = self.mediaLayout
                }

                self.titleCurrentFolder = self.getNavigationTitle()
                ///Magentacloud branding changes hide user account button on left navigation bar
//                self.setNavigationLeftItems()

                Task {
                    await self.reloadDataSource()
                    await self.getServerData()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetPlusButtonAlpha()
        Task {
            await self.reloadDataSource()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.dataSource.isEmpty() {
            blinkCell(fileName: self.fileNameBlink)
            fileNameBlink = nil
        }

        Task {
            // Plus Menu reload
            await self.mainNavigationController?.menuPlus?.create(session: session)

            // Server data
            if !isSearchingMode {
                await getServerData()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Task {
            await stopSyncMetadata()
            await NCNetworking.shared.networkingTasks.cancel(identifier: "\(self.serverUrl)_NCFiles")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        fileNameBlink = nil
    }

    // MARK: - Action

    @IBAction func plusButtonAction(_ sender: UIButton) {
        resetPlusButtonAlpha()
        guard let controller else { return }
        let fileFolderPath = NCUtilityFileSystem().getFileNamePath("", serverUrl: serverUrl, session: NCSession.shared.getSession(controller: controller))
        let fileFolderName = (serverUrl as NSString).lastPathComponent
        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: controller.account)

        if let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", controller.account, serverUrl)) {
            if !directory.permissions.contains("CK") {
                let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_no_permission_add_file_")
                NCContentPresenter().showWarning(error: error)
                return
            }
        }

        if !FileNameValidator.checkFolderPath(fileFolderPath, account: controller.account, capabilities: capabilities) {
            controller.present(UIAlertController.warning(message: "\(String(format: NSLocalizedString("_file_name_validator_error_reserved_name_", comment: ""), fileFolderName)) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true)
            return
        }

        self.appDelegate.toggleMenu(controller: controller, sender: sender)
    }

    // MARK: - DataSource

    override func reloadDataSource() async {
        guard !isSearchingMode else {
            await super.reloadDataSource()
            return
        }

        let predicate: NSPredicate = {
            if NCKeychain().getPersonalFilesOnly(account: self.session.account) {
                return self.personalFilesOnlyPredicate
            } else {
                return self.defaultPredicate
            }
        }()

        self.metadataFolder = await self.database.getMetadataFolderAsync(session: self.session, serverUrl: self.serverUrl)
        if let tblDirectory = await self.database.getTableDirectoryAsync(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", self.session.account, self.serverUrl)) {
            self.richWorkspaceText = tblDirectory.richWorkspace
        }
        let metadatas = await self.database.getMetadatasAsync(predicate: predicate,
                                                              withLayout: self.layoutForView,
                                                              withAccount: self.session.account)

        self.dataSource = NCCollectionViewDataSource(metadatas: metadatas, layoutForView: layoutForView, account: session.account)
        await super.reloadDataSource()

        cachingAsync(metadatas: metadatas)
    }

    override func getServerData(refresh: Bool = false) async {
        await super.getServerData()

        defer {
            stopGUIGetServerData()
            startSyncMetadata(metadatas: self.dataSource.getMetadatas())
        }

        await networking.networkingTasks.cancel(identifier: "\(self.serverUrl)_NCFiles")

        guard !isSearchingMode else {
            await self.search()
            return
        }

        let resultsReadFolder = await networkReadFolderAsync(serverUrl: self.serverUrl, refresh: refresh)
        guard resultsReadFolder.error == .success, resultsReadFolder.reloadRequired else {
            return
        }

        let metadatasForDownload: [tableMetadata] = resultsReadFolder.metadatas ?? self.dataSource.getMetadatas()
        Task.detached(priority: .utility) {
            for metadata in metadatasForDownload where !metadata.directory {
                if await self.downloadMetadata(metadata) {
                    if let metadata = await self.database.setMetadataSessionInWaitDownloadAsync(ocId: metadata.ocId,
                                                                                                session: NCNetworking.shared.sessionDownload,
                                                                                                selector: NCGlobal.shared.selectorDownloadFile,
                                                                                                sceneIdentifier: self.controller?.sceneIdentifier) {
                        NCNetworking.shared.download(metadata: metadata)
                    }
                }
            }
        }

        await self.reloadDataSource()
    }

    private func downloadMetadata(_ metadata: tableMetadata) async -> Bool {
        let fileSize = utilityFileSystem.fileProviderStorageSize(metadata.ocId,
                                                                 fileName: metadata.fileNameView,
                                                                 userId: metadata.userId,
                                                                 urlBase: metadata.urlBase)
        guard fileSize > 0 else {
            return false
        }

        if let tblLocalFile = await database.getTableLocalFileAsync(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) {
            if tblLocalFile.etag != metadata.etag {
                return true
            }
        }
        return false
    }

    private func networkReadFolderAsync(serverUrl: String, forced: Bool) async -> (metadatas: [tableMetadata]?, error: NKError, reloadRequired: Bool) {
        var reloadRequired: Bool = false
        let account = session.account
        let resultsReadFile = await NCNetworking.shared.readFileAsync(serverUrlFileName: serverUrl, account: account) { task in
            Task {
                await NCNetworking.shared.networkingTasks.track(identifier: "\(self.serverUrl)_NCFiles", task: task)
            }
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }
        }
        guard resultsReadFile.error == .success, let metadata = resultsReadFile.metadata else {
            return (nil, resultsReadFile.error, false)
        }

        await self.database.updateDirectoryRichWorkspaceAsync(metadata.richWorkspace, account: account, serverUrl: serverUrl)
        let tableDirectory = await self.database.getTableDirectoryAsync(ocId: metadata.ocId)

        // Verify LivePhoto
        //
        reloadRequired = await networking.setLivePhoto(account: account)
        await NCManageDatabase.shared.deleteLivePhotoError()

        let shouldSkipUpdate: Bool = (
            !refresh &&
            tableDirectory?.etag == metadata.etag &&
            !metadata.e2eEncrypted &&
            !self.dataSource.isEmpty()
        )

        if shouldSkipUpdate {
            return (nil, NKError(), false)
        }

        startGUIGetServerData()

        let options = NKRequestOptions(timeout: 180)
        let resultsReadFolder = await NCNetworking.shared.readFolderAsync(
            serverUrl: serverUrl,
            account: account,
            options: options
        ) { task in
            Task {
                await NCNetworking.shared.networkingTasks.track(identifier: "\(self.serverUrl)_NCFiles", task: task)
            }
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }
        }

        guard resultsReadFolder.error == .success else {
            return(nil, resultsReadFolder.error, reloadRequired)
        }

        if let metadataFolder {
            self.metadataFolder = metadataFolder.detachedCopy()
            self.richWorkspaceText = metadataFolder.richWorkspace
        }

        guard e2eEncrypted,
              let metadatas = resultsReadFolder.metadatas,
              NCPreferences().isEndToEndEnabled(account: account),
              await !NCNetworkingE2EE().isInUpload(account: account, serverUrl: serverUrl) else {
            return(resultsReadFolder.metadatas, resultsReadFolder.error, reloadRequired)
        }

        //
        // E2EE section
        //

        let lock = await self.database.getE2ETokenLockAsync(account: account, serverUrl: serverUrl)
        let resultsE2eeGetMetadata = await NCNetworkingE2EE().getMetadata(fileId: ocId, e2eToken: lock?.e2eToken, account: account)

        guard resultsE2eeGetMetadata.error == .success,
              let e2eMetadata = resultsE2eeGetMetadata.e2eMetadata,
              let version = resultsE2eeGetMetadata.version else {
            if resultsE2eeGetMetadata.error.errorCode == NCGlobal.shared.errorResourceNotFound {
                let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, account: account)
                if error != .success {
                    await showErrorBanner(windowScene: windowScene,
                                          text: error.errorDescription,
                                          errorCode: error.errorCode)
                }
            } else {
                await showErrorBanner(windowScene: windowScene,
                                      text: resultsE2eeGetMetadata.error.errorDescription,
                                      errorCode: resultsE2eeGetMetadata.error.errorCode)
            }
            return(metadatas, resultsE2eeGetMetadata.error, reloadRequired)
        }

        var error = await NCEndToEndMetadata().decodeMetadata(e2eMetadata,
                                                              signature: resultsE2eeGetMetadata.signature,
                                                              serverUrl: serverUrl, session: self.session)

        if error == .success {
            let capabilities = await NKCapabilities.shared.getCapabilities(for: self.session.account)
            if version == "v1", capabilities.e2EEApiVersion.hasPrefix("2.") {
                await showInfoBanner(windowScene: windowScene, text: "Conversion metadata v1 to v2 required, please wait...")
                nkLog(tag: self.global.logTagE2EE, message: "Conversion v1 to v2")
                NCActivityIndicator.shared.start()

                error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, updateVersionV1V2: true, account: account)
                if error != .success {
                    await showErrorBanner(windowScene: windowScene, text: error.errorDescription, errorCode: error.errorCode)
                }
                NCActivityIndicator.shared.stop()
            }
        } else {
            // Client Diagnostic
            await self.database.addDiagnosticAsync(account: account, issue: NCGlobal.shared.diagnosticIssueE2eeErrors)
            await showErrorBanner(windowScene: windowScene, text: error.errorDescription, errorCode: error.errorCode)
        }

        // Error: Go back
        if error != .success {
            navigationController?.popViewController(animated: false)
        }
        return (metadatas, error, true)
    }

    func blinkCell(fileName: String?) {
        if let fileName = fileName, let metadata = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", session.account, self.serverUrl, fileName)) {
            let indexPath = self.dataSource.getIndexPathMetadata(ocId: metadata.ocId)
            if let indexPath = indexPath {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.3) {
                        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                    } completion: { _ in
                        if let cell = self.collectionView.cellForItem(at: indexPath) {
                            cell.backgroundColor = .darkGray
                            UIView.animate(withDuration: 2) {
                                cell.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
        }
    }

    func open(metadata: tableMetadata?) async {
        guard let metadata else {
            return
        }
        await didSelectMetadata(metadata, withOcIds: false)
    }

    override func resetPlusButtonAlpha(animated: Bool = true) {
        accumulatedScrollDown = 0
        let update = {
            self.plusButton.alpha = 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: update)
        } else {
            update()
        }
    }

    override func isHiddenPlusButton(_ isHidden: Bool) {
        if isHidden {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
                self.plusButton.transform = CGAffineTransform(translationX: 100, y: 0)
                self.plusButton.alpha = 0
            })
        } else {
            plusButton.transform = CGAffineTransform(translationX: 100, y: 0)
            plusButton.alpha = 0

            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.plusButton.transform = .identity
                self.plusButton.alpha = 1
            })
        }
    }

    // MARK: - NCAccountSettingsModelDelegate

    override func accountSettingsDidDismiss(tableAccount: tableAccount?, controller: NCMainTabBarController?) {
        let currentAccount = session.account

        if database.getAllTableAccount().isEmpty {
            let navigationController: UINavigationController?

            if NCBrandOptions.shared.disable_intro, let viewController = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin {
                navigationController = UINavigationController(rootViewController: viewController)
            } else {
                navigationController = UIStoryboard(name: "NCIntro", bundle: nil).instantiateInitialViewController() as? UINavigationController
            }

            UIApplication.shared.mainAppWindow?.rootViewController = navigationController
        } else if let account = tblAccount?.account, account != currentAccount {
            Task {
                await NCAccount().changeAccount(account, userProfile: nil, controller: controller)
            }
        } else if self.serverUrl == self.utilityFileSystem.getHomeServer(session: self.session) {
            self.titleCurrentFolder = getNavigationTitle()
            navigationItem.title = self.titleCurrentFolder
        }

        (self.navigationController as? NCMainNavigationController)?.setNavigationLeftItems()
    }
}
