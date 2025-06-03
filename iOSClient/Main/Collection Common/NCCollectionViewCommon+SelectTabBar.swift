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

extension NCCollectionViewCommon: NCCollectionViewCommonSelectTabBarDelegate, NCSelectableNavigationView {
    
    func selectAll() {
        fileSelect = selectableDataSource.compactMap({ $0.primaryKeyValue })
        tabBarSelect?.update(fileSelect: fileSelect, metadatas: getSelectedMetadatas(), userId: session.userId)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.setNavigationRightItems(enableMenu: false)
        }
    }

    func delete() {
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad { alertStyle = .alert }
        let alertController = UIAlertController(title: NSLocalizedString("_confirm_delete_selected_", comment: ""), message: nil, preferredStyle: alertStyle)
        let metadatas = getSelectedMetadatas()
        let canDeleteServer = metadatas.allSatisfy { !$0.lock }

        if canDeleteServer {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .destructive) { _ in
                NCNetworking.shared.setStatusWaitDelete(metadatas: metadatas, sceneIdentifier: self.controller?.sceneIdentifier)
                self.setEditMode(false)
                self.reloadDataSource()
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .destructive) { [self] _ in
//                NCNetworking.shared.deleteMetadatas(metadatas, sceneIdentifier: self.controller?.sceneIdentifier)
//                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
//                toggleSelect()
            })
        }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_remove_local_file_", comment: ""), style: .default) { [self] (_: UIAlertAction) in
            let copyMetadatas = metadatas

            Task {
                var error = NKError()
                for metadata in copyMetadatas where error == .success {
                    error = await NCNetworking.shared.deleteCache(metadata, sceneIdentifier: self.controller?.sceneIdentifier)
                }
            }
            toggleSelect()
        })

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel) { (_: UIAlertAction) in })
        self.present(alertController, animated: true, completion: nil)
    }

    func move() {
        let metadatas = getSelectedMetadatas()

        NCDownloadAction.shared.openSelectView(items: metadatas, controller: self.controller)
        setEditMode(false)
//        NCActionCenter.shared.openSelectView(items: metadatas, controller: self.controller)
//        toggleSelect()
    }

    func share() {
        let metadatas = getSelectedMetadatas()
        NCDownloadAction.shared.openActivityViewController(selectedMetadata: metadatas, controller: self.controller, sender: nil)
        setEditMode(false)
//        NCActionCenter.shared.openActivityViewController(selectedMetadata: metadatas, controller: self.controller)
//        toggleSelect()
    }

    func saveAsAvailableOffline(isAnyOffline: Bool) {
        let metadatas = getSelectedMetadatas()
        if !isAnyOffline, metadatas.count > 3 {
            let alert = UIAlertController(
                title: NSLocalizedString("_set_available_offline_", comment: ""),
                message: NSLocalizedString("_select_offline_warning_", comment: ""),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("_continue_", comment: ""), style: .default, handler: { _ in
                metadatas.forEach { NCDownloadAction.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
                self.setEditMode(false)
//            alert.addAction(UIAlertAction(title: NSLocalizedString("_continue_", comment: ""), style: .default, handler: { [self] _ in
//                metadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
//                toggleSelect()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
            self.present(alert, animated: true)
        } else {
            metadatas.forEach { NCDownloadAction.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
            setEditMode(false)
//            metadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
//            toggleSelect()
        }
    }

    func lock(isAnyLocked: Bool) {
        let metadatas = getSelectedMetadatas()
        for metadata in metadatas where metadata.lock == isAnyLocked {
            NCNetworking.shared.lockUnlockFile(metadata, shoulLock: !isAnyLocked)
        }
        toggleSelect()
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

        navigationItem.hidesBackButton = editMode
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !editMode
        searchController(enabled: !editMode)
        isHiddenPlusButton(editMode)

        if editMode {
            navigationItem.leftBarButtonItems = nil
        } else {
           ///Magentacloud branding changes hide user account button on left navigation bar
            setNavigationLeftItems()
        }

        navigationController?.interactivePopGestureRecognizer?.isEnabled = !editMode
        navigationItem.hidesBackButton = editMode
        searchController(enabled: !editMode)
        self.setNavigationRightItems(enableMenu: true)
        self.collectionView.reloadData()
    }

    func convertLivePhoto(metadataFirst: tableMetadata?, metadataLast: tableMetadata?) {
        if let metadataFirst, let metadataLast {
            Task {
                let userInfo: [String: Any] = ["serverUrl": metadataFirst.serverUrl,
                                               "account": metadataFirst.account]

                await NCNetworking.shared.setLivePhoto(metadataFirst: metadataFirst, metadataLast: metadataLast, userInfo: userInfo)
            }
        }
        setEditMode(false)
    }
    
    /// If explicit `isOn` is not set, it will invert `isEditMode`
    func toggleSelect(isOn: Bool? = nil) {
        DispatchQueue.main.async {
            self.isEditMode = isOn ?? !self.isEditMode
            self.setEditMode(self.isEditMode)
        }
    }

    func createMenuActions() -> [NCMenuAction] {
        var actions = [NCMenuAction]()

        actions.append(.cancelAction {
            self.toggleSelect()
        })
        if fileSelect.count != selectableDataSource.count {
            actions.append(.selectAllAction(action: selectAll))
        }

        guard !fileSelect.isEmpty else { return actions }

        actions.append(.seperator(order: 0))

        var selectedMetadatas: [tableMetadata] = []
        var selectedMediaMetadatas: [tableMetadata] = []
        var isAnyOffline = false
        var isAnyFolder = false
        var isAnyLocked = false
        var canUnlock = true
        var canOpenIn = false
        var isDirectoryE2EE = false

        for ocId in fileSelect {
            guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { continue }
            if metadata.e2eEncrypted {
                fileSelect.removeAll(where: {$0 == metadata.ocId})
            } else {
                selectedMetadatas.append(metadata)
            }

            if [NKCommon.TypeClassFile.image.rawValue, NKCommon.TypeClassFile.video.rawValue].contains(metadata.classFile) {
                selectedMediaMetadatas.append(metadata)
            }
            if metadata.directory { isAnyFolder = true }
            if metadata.lock {
                isAnyLocked = true
                if metadata.lockOwner != session.userId {
                    canUnlock = false
                }
            }

            guard !isAnyOffline else { continue }
            if metadata.directory,
               let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", session.account, metadata.serverUrl + "/" + metadata.fileName)) {
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
            actions.append(.openInAction(selectedMetadatas: selectedMetadatas, controller: self.controller, completion: { self.toggleSelect() }))
        }

        if !isAnyFolder, canUnlock, !NCCapabilities.shared.getCapabilities(account: controller?.account).capabilityFilesLockVersion.isEmpty {
            actions.append(.lockUnlockFiles(shouldLock: !isAnyLocked, metadatas: selectedMetadatas, completion: { self.toggleSelect() }))
        }

        if !selectedMediaMetadatas.isEmpty {
            actions.append(.saveMediaAction(selectedMediaMetadatas: selectedMediaMetadatas, controller: self.controller, completion: { self.toggleSelect() }))
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

    func setNavigationRightItems(enableMenu: Bool = false) {
        DispatchQueue.main.async {
            if self.isEditMode {
                let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain) { self.presentMenu(with: self.createMenuActions())}
                self.navigationItem.rightBarButtonItems = [more]
            } else {
                let select = UIBarButtonItem(title: NSLocalizedString("_select_", comment: ""), style: UIBarButtonItem.Style.plain) { self.toggleSelect() }
                let notification = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, action: self.tapNotification)
                if self.layoutKey == NCGlobal.shared.layoutViewFiles {
                    self.navigationItem.rightBarButtonItems = [select, notification]
                } else {
                    self.navigationItem.rightBarButtonItems = [select]
                }
                let transfer = UIBarButtonItem(image: UIImage(systemName: "arrow.left.arrow.right.circle.fill"), style: .plain, action: self.tapTransfer)
                let resultsCount = self.database.getResultsMetadatas(predicate: NSPredicate(format: "status != %i", NCGlobal.shared.metadataStatusNormal))?.count ?? 0

                if self.layoutKey == NCGlobal.shared.layoutViewFiles {
                    self.navigationItem.rightBarButtonItems = resultsCount > 0 ? [select, notification, transfer] : [select, notification]
                } else {
                    self.navigationItem.rightBarButtonItems = [select]
                }
            }
            guard self.layoutKey == NCGlobal.shared.layoutViewFiles else { return }
            self.navigationItem.title = self.titleCurrentFolder
        }
    }
    
    func onListSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutGrid {
            headerMenu?.buttonSwitch.accessibilityLabel = NSLocalizedString("_grid_view_", comment: "")
            layoutForView?.layout = NCGlobal.shared.layoutList
            NCManageDatabase.shared.setLayoutForView(account: session.account, key: layoutKey, serverUrl: serverUrl, layout: layoutForView?.layout)
            self.groupByField = "name"
            if self.dataSource.groupByField != self.groupByField {
                self.dataSource.changeGroupByField(self.groupByField)
            }
            self.saveLayout(layoutForView!)
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(self.listLayout, animated: true) {_ in self.isTransitioning = false }
        }
    }

    func onGridSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutList {
            headerMenu?.buttonSwitch.accessibilityLabel = NSLocalizedString("_list_view_", comment: "")
            layoutForView?.layout = NCGlobal.shared.layoutGrid
            NCManageDatabase.shared.setLayoutForView(account: session.account, key: layoutKey, serverUrl: serverUrl, layout: layoutForView?.layout)
            if isSearchingMode {
                self.groupByField = "name"
            } else {
                self.groupByField = "classFile"
            }
            if self.dataSource.groupByField != self.groupByField {
                self.dataSource.changeGroupByField(self.groupByField)
            }
            self.saveLayout(layoutForView!)
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(self.gridLayout, animated: true) {_ in self.isTransitioning = false }
        }
    }
}
