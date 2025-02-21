//
//  NCCollectionViewCommon+SelectTabBar.swift
//  Nextcloud
//
//  Created by Milen on 01.03.24.
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
import Foundation
import NextcloudKit

extension NCCollectionViewCommon: NCCollectionViewCommonSelectTabBarDelegate {
    func selectAll() {
        if !fileSelect.isEmpty, self.dataSource.getMetadatas().count == fileSelect.count {
            fileSelect = []
        } else {
            fileSelect = self.dataSource.getMetadatas().compactMap({ $0.ocId })
        }
        tabBarSelect?.update(fileSelect: fileSelect, metadatas: getSelectedMetadatas(), userId: session.userId)
        self.collectionView.reloadData()
    }

    func delete() {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad { alertStyle = .alert }
        let alertController = UIAlertController(title: NSLocalizedString("_confirm_delete_selected_", comment: ""), message: nil, preferredStyle: alertStyle)
        let metadatas = getSelectedMetadatas()
        let canDeleteServer = metadatas.allSatisfy { !$0.lock }

        if canDeleteServer {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .destructive) { _ in
                NCNetworking.shared.deleteMetadatas(metadatas, sceneIdentifier: self.controller?.sceneIdentifier)
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
                self.setEditMode(false)
            })
        }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_remove_local_file_", comment: ""), style: .default) { (_: UIAlertAction) in
            let copyMetadatas = metadatas

            Task {
                var error = NKError()
                var ocId: [String] = []
                for metadata in copyMetadatas where error == .success {
                    error = await NCNetworking.shared.deleteCache(metadata, sceneIdentifier: self.controller?.sceneIdentifier)
                    if error == .success {
                        ocId.append(metadata.ocId)
                    }
                }
                NotificationCenter.default.postOnMainThread(name: self.global.notificationCenterDeleteFile, userInfo: ["ocId": ocId, "error": error])
            }
            self.setEditMode(false)
        })

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel) { (_: UIAlertAction) in })
        self.present(alertController, animated: true, completion: nil)
    }

    func move() {
        let metadatas = getSelectedMetadatas()

        NCActionCenter.shared.openSelectView(items: metadatas, controller: self.controller)
        setEditMode(false)
    }

    func share() {
        let metadatas = getSelectedMetadatas()
        NCActionCenter.shared.openActivityViewController(selectedMetadata: metadatas, controller: self.controller)
        setEditMode(false)
    }

    func saveAsAvailableOffline(isAnyOffline: Bool) {
        let metadatas = getSelectedMetadatas()
        if !isAnyOffline, metadatas.count > 3 {
            let alert = UIAlertController(
                title: NSLocalizedString("_set_available_offline_", comment: ""),
                message: NSLocalizedString("_select_offline_warning_", comment: ""),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("_continue_", comment: ""), style: .default, handler: { _ in
                metadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
                self.setEditMode(false)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
            self.present(alert, animated: true)
        } else {
            metadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
            setEditMode(false)
        }
    }

    func lock(isAnyLocked: Bool) {
        let metadatas = getSelectedMetadatas()
        for metadata in metadatas where metadata.lock == isAnyLocked {
            NCNetworking.shared.lockUnlockFile(metadata, shoulLock: !isAnyLocked)
        }
        setEditMode(false)
    }

    func getSelectedMetadatas() -> [tableMetadata] {
        var selectedMetadatas: [tableMetadata] = []
        for ocId in fileSelect {
            guard let metadata = database.getMetadataFromOcId(ocId) else { continue }
            selectedMetadatas.append(metadata)
        }
        return selectedMetadatas
    }

    func setEditMode(_ editMode: Bool) {
        isEditMode = editMode
        fileSelect.removeAll()

        if editMode {
            navigationItem.leftBarButtonItems = nil
        } else {
            ///Magentacloud branding changes hide user account button on left navigation bar
           ///Magentacloud branding changes hide user account button on left navigation bar
//            setNavigationLeftItems()
        }
        (self.navigationController as? NCMainNavigationController)?.setNavigationRightItems()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = !editMode
        navigationItem.hidesBackButton = editMode
        searchController(enabled: !editMode)
        self.collectionView.reloadData()
    }
    
    /// If explicit `isOn` is not set, it will invert `isEditMode`
    func toggleSelect(isOn: Bool? = nil) {
        DispatchQueue.main.async {
            self.isEditMode = isOn ?? !self.isEditMode
            self.selectOcId.removeAll()
            self.setNavigationLeftItems()
            self.setNavigationRightItems()
            self.collectionView.reloadData()
        }
    }

    func createMenuActions() -> [NCMenuAction] {
        var actions = [NCMenuAction]()

        actions.append(.cancelAction {
            self.toggleSelect()
        })
        if selectOcId.count != dataSource.getMetadataSourceForAllSections().count {
            actions.append(.selectAllAction(action: selectAll))
        }

        guard !selectOcId.isEmpty else { return actions }

        actions.append(.seperator(order: 0))

        var selectedMetadatas: [tableMetadata] = []
        var selectedMediaMetadatas: [tableMetadata] = []
        var isAnyOffline = false
        var isAnyFolder = false
        var isAnyLocked = false
        var canUnlock = true
        var canOpenIn = false
        var isDirectoryE2EE = false

        for ocId in selectOcId {
            guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { continue }
            if metadata.e2eEncrypted {
                selectOcId.removeAll(where: {$0 == metadata.ocId})
            } else {
                selectedMetadatas.append(metadata)
            }

            if [NKCommon.TypeClassFile.image.rawValue, NKCommon.TypeClassFile.video.rawValue].contains(metadata.classFile) {
                selectedMediaMetadatas.append(metadata)
            }
            if metadata.directory { isAnyFolder = true }
            if metadata.lock {
                isAnyLocked = true
                if metadata.lockOwner != appDelegate.userId {
                    canUnlock = false
                }
            }

            guard !isAnyOffline else { continue }
            if metadata.directory,
               let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, metadata.serverUrl + "/" + metadata.fileName)) {
                isAnyOffline = directory.offline
            } else if let localFile = NCManageDatabase.shared.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) {
                isAnyOffline = localFile.offline
            } // else: file is not offline, continue

            if !metadata.directory {
                canOpenIn = true
            }

            if metadata.isDirectoryE2EE {
                isDirectoryE2EE = true
            }
        }
        
        if canOpenIn {
            actions.append(.share(selectedMetadatas: selectedMetadatas, viewController: self, completion: { self.toggleSelect() }))
        }

        if !isAnyFolder, canUnlock, !NCGlobal.shared.capabilityFilesLockVersion.isEmpty {
            actions.append(.lockUnlockFiles(shouldLock: !isAnyLocked, metadatas: selectedMetadatas, completion: { self.toggleSelect() }))
        }

        if !selectedMediaMetadatas.isEmpty {
            var title: String = NSLocalizedString("_save_selected_files_", comment: "")
            var icon = NCUtility().loadImage(named: "save_files",colors: [NCBrandColor.shared.iconImageColor])
            if selectedMediaMetadatas.allSatisfy({ NCManageDatabase.shared.getMetadataLivePhoto(metadata: $0) != nil }) {
                title = NSLocalizedString("_livephoto_save_", comment: "")
                icon = NCUtility().loadImage(named: "livephoto")
            }

            actions.append(NCMenuAction(
                title: title,
                icon: icon,
                order: 0,
                action: { _ in
                    for metadata in selectedMediaMetadatas {
                        if let metadataMOV = NCManageDatabase.shared.getMetadataLivePhoto(metadata: metadata) {
                            NCNetworking.shared.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: metadata, metadataMOV: metadataMOV, hudView: self.view))
                        } else {
                            if NCUtilityFileSystem().fileProviderStorageExists(metadata) {
                                NCActionCenter.shared.saveAlbum(metadata: metadata, controller: self.tabBarController as? NCMainTabBarController)
                            } else {
                                if NCNetworking.shared.downloadQueue.operations.filter({ ($0 as? NCOperationDownload)?.metadata.ocId == metadata.ocId }).isEmpty {
                                    NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: metadata, selector: NCGlobal.shared.selectorSaveAlbum))
                                }
                            }
                        }
                    }
                    self.toggleSelect()
                }
            )
            )
        }
        actions.append(.setAvailableOfflineAction(selectedMetadatas: selectedMetadatas, isAnyOffline: isAnyOffline, viewController: self, completion: {
            self.reloadDataSource()
            self.toggleSelect()
        }))
        
        if !isDirectoryE2EE {
            actions.append(.moveOrCopyAction(selectedMetadatas: selectedMetadatas, viewController: self, indexPath: [], completion: { self.toggleSelect() }))
            actions.append(.copyAction(selectOcId: selectOcId, viewController: self, completion: { self.toggleSelect() }))
        }
        actions.append(.deleteAction(selectedMetadatas: selectedMetadatas, indexPaths: [], viewController: self, completion: { self.toggleSelect() }))
        return actions
    }

}
