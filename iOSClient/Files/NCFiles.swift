//
//  NCFiles.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 26/09/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
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
import RealmSwift
import SwiftUI

class NCFiles: NCCollectionViewCommon {
    @IBOutlet weak var plusButton: UIButton!

    internal var fileNameBlink: String?
    internal var fileNameOpen: String?
    internal var matadatasHash: String = ""
    internal var semaphoreReloadDataSource = DispatchSemaphore(value: 1)
    private var timerProcess: Timer?

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
        plusButton.backgroundColor = NCBrandColor.shared.getElement(account: session.account)
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
                        controller.availableNotifications = false
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
                self.gridLayout.column = CGFloat(self.layoutForView?.columnGrid ?? 3)

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

                self.dataSource.removeAll()
                self.reloadDataSource()
                self.getServerData()
            }
        }
        self.timerProcess = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.setNavigationRightItems(enableMenu: false)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetPlusButtonAlpha()
        reloadDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.dataSource.isEmpty() {
            self.blinkCell(fileName: self.fileNameBlink)
            self.openFile(fileName: self.fileNameOpen)
            self.fileNameBlink = nil
            self.fileNameOpen = nil
        }

        Task {
            // Plus Menu reload
            let capabilities = await database.getCapabilities(account: self.session.account) ?? NKCapabilities.Capabilities()
            await mainNavigationController?.createPlusMenu(session: self.session, capabilities: capabilities)
            // Server data
            if !isSearchingMode {
                await getServerData()
            }
        }

        self.showTipAutoUpload()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        fileNameBlink = nil
        fileNameOpen = nil
    }

    // MARK: - Action

    @IBAction func plusButtonAction(_ sender: UIButton) {
        resetPlusButtonAlpha()
        if let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController {
            let serverUrl = controller.currentServerUrl()
            if let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", NCSession.shared.getSession(controller: controller).account, serverUrl)) {
                if !directory.permissions.contains("CK") {
                    let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_no_permission_add_file_")
                    NCContentPresenter().showWarning(error: error)
                    return
                }
            }

            let fileFolderPath = NCUtilityFileSystem().getFileNamePath("", serverUrl: serverUrl, session: NCSession.shared.getSession(controller: controller))
            let fileFolderName = (serverUrl as NSString).lastPathComponent

            if !FileNameValidator.checkFolderPath(fileFolderPath, account: controller.account) {
                controller.present(UIAlertController.warning(message: "\(String(format: NSLocalizedString("_file_name_validator_error_reserved_name_", comment: ""), fileFolderName)) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true)

                return
            }

            self.appDelegate.toggleMenu(controller: controller)
        }
        
    }
    
    // MARK: - DataSource

    override func reloadDataSource() {
        guard !isSearchingMode
        else {
            return super.reloadDataSource()
        }

        // Watchdog: this is only a fail safe "dead lock", I don't think the timeout will ever be called but at least nothing gets stuck, if after 5 sec. (which is a long time in this routine), the semaphore is still locked
        //
        if self.semaphoreReloadDataSource.wait(timeout: .now() + 5) == .timedOut {
            self.semaphoreReloadDataSource.signal()
        }

        var predicate = self.defaultPredicate
        let predicateDirectory = NSPredicate(format: "account == %@ AND serverUrl == %@", session.account, self.serverUrl)
        let dataSourceMetadatas = self.dataSource.getMetadatas()

        if NCKeychain().getPersonalFilesOnly(account: session.account) {
            predicate = self.personalFilesOnlyPredicate
        }

        self.metadataFolder = database.getMetadataFolder(session: session, serverUrl: self.serverUrl)
        self.richWorkspaceText = database.getTableDirectory(predicate: predicateDirectory)?.richWorkspace

        let metadatas = self.database.getResultsMetadatasPredicate(predicate, layoutForView: layoutForView)
        self.dataSource = NCCollectionViewDataSource(metadatas: metadatas, layoutForView: layoutForView)

        if metadatas.isEmpty {
            self.semaphoreReloadDataSource.signal()
            return super.reloadDataSource()
        }

        self.dataSource.caching(metadatas: metadatas, dataSourceMetadatas: dataSourceMetadatas) {
            self.semaphoreReloadDataSource.signal()
            super.reloadDataSource()
        }
    }

    override func getServerData(refresh: Bool = false) async {
        await super.getServerData()

        defer {
            stopGUIGetServerData()
            startSyncMetadata(metadatas: self.dataSource.getMetadatas())
        }

        Task {
            await networking.networkingTasks.cancel(identifier: "\(self.serverUrl)_NCFiles")
        }
        guard !isSearchingMode else {
            return networkSearch()
        }

        func downloadMetadata(_ metadata: tableMetadata) -> Bool {
            let fileSize = utilityFileSystem.fileProviderStorageSize(metadata.ocId, fileNameView: metadata.fileNameView)
            guard fileSize > 0 else { return false }

            if let localFile = database.getResultsTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))?.first {
                if localFile.etag != metadata.etag {
                    return true
                }
            }
            return false
        }

        DispatchQueue.global().async {
            self.networkReadFolder { metadatas, isChanged, error in
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()

                    if isChanged || self.isNumberOfItemsInAllSectionsNull {
                        self.reloadDataSource()
                    }
                }

                if error == .success {
                    let metadatas: [tableMetadata] = metadatas ?? self.dataSource.getMetadatas()
                    for metadata in metadatas where !metadata.directory && downloadMetadata(metadata) {
                        self.database.setMetadatasSessionInWaitDownload(metadatas: [metadata],
                                                                        session: NCNetworking.shared.sessionDownload,
                                                                        selector: NCGlobal.shared.selectorDownloadFile,
                                                                        sceneIdentifier: self.controller?.sceneIdentifier)
                        NCNetworking.shared.download(metadata: metadata, withNotificationProgressTask: true)
                    }
                    /// Recommendation
                    if self.isRecommendationActived {
                        Task.detached {
                            await NCNetworking.shared.createRecommendations(session: self.session)
                        }
                    }
                }
            }
        }
    }

    private func networkReadFolder(completion: @escaping (_ metadatas: [tableMetadata]?, _ isDataChanged: Bool, _ error: NKError) -> Void) {
        NCNetworking.shared.readFile(serverUrlFileName: serverUrl, account: session.account) { task in
            self.dataSourceTask = task
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }
        }
        guard resultsReadFile.error == .success, let metadata = resultsReadFile.metadata else {
            return (nil, resultsReadFile.error, false)
        }

        await self.database.updateDirectoryRichWorkspaceAsync(metadata.richWorkspace, account: resultsReadFile.account, serverUrl: serverUrl)
        let tableDirectory = await self.database.getTableDirectoryAsync(ocId: metadata.ocId)

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
        let (account, metadataFolder, metadatas, error) = await NCNetworking.shared.readFolderAsync(serverUrl: serverUrl,
                                                                                                    account: session.account,
                                                                                                    options: options) { task in
            self.dataSourceTask = task
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }

        guard error == .success else {
            return (nil, error, false)
        }

        if let metadataFolder {
            self.metadataFolder = metadataFolder.detachedCopy()
            self.richWorkspaceText = metadataFolder.richWorkspace
        }

        guard let metadataFolder,
              isDirectoryE2EE,
              NCKeychain().isEndToEndEnabled(account: account),
              await !NCNetworkingE2EE().isInUpload(account: account, serverUrl: serverUrl) else {
            return (metadatas, error, true)
        }

        /// E2EE
        let lock = await self.database.getE2ETokenLockAsync(account: account, serverUrl: serverUrl)
        let results = await NCNetworkingE2EE().getMetadata(fileId: metadataFolder.ocId, e2eToken: lock?.e2eToken, account: account)

        let results = await NCNetworkingE2EE().getMetadata(fileId: ocId, e2eToken: lock?.e2eToken, account: account)

        nkLog(tag: self.global.logTagE2EE, message: "Get metadata with error: \(results.error.errorCode)")
        nkLog(tag: self.global.logTagE2EE, message: "Get metadata with metadata: \(results.e2eMetadata ?? ""), signature: \(results.signature ?? ""), version \(results.version ?? "")", minimumLogLevel: .verbose)

        guard results.error == .success,
              let e2eMetadata = results.e2eMetadata,
              let version = results.version else {

            // No metadata fount, re-send it
            if results.error.errorCode == NCGlobal.shared.errorResourceNotFound {
                NCContentPresenter().showInfo(description: "Metadata not found")
                let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, account: account)
                if error != .success {
                    await showErrorBanner(controller: self.controller,
                                          errorDescription: error.errorDescription,
                                          errorCode: error.errorCode)
                }
            } else {
                // show error
                Task {@MainActor in
                    await showErrorBanner(controller: self.controller,
                                          errorDescription: error.errorDescription,
                                          errorCode: error.errorCode)
                }
            }

            return(metadatas, error, reloadRequired)
        }

        let errorDecodeMetadata = await NCEndToEndMetadata().decodeMetadata(e2eMetadata, signature: results.signature, serverUrl: serverUrl, session: self.session)
        nkLog(debug: "Decode e2ee metadata with error: \(errorDecodeMetadata.errorCode)")

        if errorDecodeMetadata == .success {
            let capabilities = await NKCapabilities.shared.getCapabilities(for: self.session.account)
            if version == "v1", capabilities.e2EEApiVersion == NCGlobal.shared.e2eeVersionV20 {
                NCContentPresenter().showInfo(description: "Conversion metadata v1 to v2 required, please wait...")
                nkLog(tag: self.global.logTagE2EE, message: "Conversion v1 to v2")
                NCActivityIndicator.shared.start()

                let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, updateVersionV1V2: true, account: account)
                if error != .success {
                    Task {@MainActor in
                        await showErrorBanner(controller: self.controller,
                                              errorDescription: error.errorDescription,
                                              errorCode: error.errorCode)
                    }
                }
                NCActivityIndicator.shared.stop()
            }
        } else {
            // Client Diagnostic
            await self.database.addDiagnosticAsync(account: account, issue: NCGlobal.shared.diagnosticIssueE2eeErrors)
            Task {@MainActor in
                await showErrorBanner(controller: self.controller,
                                      errorDescription: error.errorDescription,
                                      errorCode: error.errorCode)
            }
        }
    }

    func blinkCell(fileName: String?) {
        if let fileName = fileName, let metadata = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", session.account, self.serverUrl, fileName)) {
            let indexPath = self.dataSource.getIndexPathMetadata(ocId: metadata.ocId).indexPath
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

    func openFile(fileName: String?) {
        if let fileName = fileName, let metadata = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", session.account, self.serverUrl, fileName)) {
            let indexPath = self.dataSource.getIndexPathMetadata(ocId: metadata.ocId).indexPath
            if let indexPath = indexPath {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.collectionView(self.collectionView, didSelectItemAt: indexPath)
                }
            }
        }
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
            if let navigationController = UIStoryboard(name: "NCIntro", bundle: nil).instantiateInitialViewController() as? UINavigationController {
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true)
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

//        (self.navigationController as? NCMainNavigationController)?.setNavigationLeftItems()
    }
}
