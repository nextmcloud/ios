//
//  NCCollectionViewCommon+SelectTabBarDelegate.swift
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

import Foundation
import NextcloudKit

extension NCCollectionViewCommon: NCSelectableNavigationView, NCCollectionViewCommonSelectTabBarDelegate {
    func setNavigationRightItems(enableMenu: Bool = false) {
        if isEditMode {
            let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain) { self.presentMenu(with: self.createMenuActions())}
            navigationItem.rightBarButtonItems = [more]
        } else {
            let select = UIBarButtonItem(title: NSLocalizedString("_select_", comment: ""), style: UIBarButtonItem.Style.plain) { self.toggleSelect() }
            let notification = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, action: tapNotification)
            if layoutKey == NCGlobal.shared.layoutViewFiles {
                navigationItem.rightBarButtonItems = [select, notification]
            } else {
                navigationItem.rightBarButtonItems = [select]
            }
        }
        guard layoutKey == NCGlobal.shared.layoutViewFiles else { return }
        navigationItem.title = titleCurrentFolder
    }

    func onListSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutGrid {
            headerMenu?.buttonSwitch.accessibilityLabel = NSLocalizedString("_grid_view_", comment: "")
            layoutForView?.layout = NCGlobal.shared.layoutList
            NCManageDatabase.shared.setLayoutForView(account: appDelegate.account, key: layoutKey, serverUrl: serverUrl, layout: layoutForView?.layout)
            self.groupByField = "name"
            if self.dataSource.groupByField != self.groupByField {
                self.dataSource.changeGroupByField(self.groupByField)
            }

            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(self.listLayout, animated: true) {_ in self.isTransitioning = false }
        }
    }

    func onGridSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutList {
            headerMenu?.buttonSwitch.accessibilityLabel = NSLocalizedString("_list_view_", comment: "")
            layoutForView?.layout = NCGlobal.shared.layoutGrid
            NCManageDatabase.shared.setLayoutForView(account: appDelegate.account, key: layoutKey, serverUrl: serverUrl, layout: layoutForView?.layout)
            if isSearchingMode {
                self.groupByField = "name"
            } else {
                self.groupByField = "classFile"
            }
            if self.dataSource.groupByField != self.groupByField {
                self.dataSource.changeGroupByField(self.groupByField)
            }

            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(self.gridLayout, animated: true) {_ in self.isTransitioning = false }
        }
    }

    func selectAll() {
        collectionViewSelectAll()
    }

    func delete(selectedMetadatas: [tableMetadata]) {
        let alertController = UIAlertController(
            title: NSLocalizedString("_confirm_delete_selected_", comment: ""),
            message: nil,
            preferredStyle: .alert)

        let canDeleteServer = selectedMetadatas.allSatisfy { !$0.lock }

        if canDeleteServer {
            let copyMetadatas = selectedMetadatas

            alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .destructive) { _ in
                Task {
                    var error = NKError()
                    var ocId: [String] = []
                    for metadata in copyMetadatas where error == .success {
                        error = await NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: false)
                        if error == .success {
                            ocId.append(metadata.ocId)
                        }
                    }
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteFile, userInfo: ["ocId": ocId, "indexPath": self.selectIndexPaths, "onlyLocalCache": false, "error": error])
                }

                self.toggleSelect()
            })
        }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_remove_local_file_", comment: ""), style: .default) { (_: UIAlertAction) in
            let copyMetadatas = selectedMetadatas

            Task {
                var error = NKError()
                var ocId: [String] = []
                for metadata in copyMetadatas where error == .success {
                    error = await NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: true)
                    if error == .success {
                        ocId.append(metadata.ocId)
                    }
                }
                if error != .success {
                    NCContentPresenter().showError(error: error)
                }
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteFile, userInfo: ["ocId": ocId, "indexPath": self.selectIndexPaths, "onlyLocalCache": true, "error": error])
                self.toggleSelect()
            }
        })

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel) { (_: UIAlertAction) in })
        self.viewController.present(alertController, animated: true, completion: nil)
    }

    func move(selectedMetadatas: [tableMetadata]) {
        NCActionCenter.shared.openSelectView(items: selectedMetadatas, indexPath: self.selectIndexPaths)
        self.toggleSelect()
    }

    func share(selectedMetadatas: [tableMetadata]) {
        NCActionCenter.shared.openActivityViewController(selectedMetadata: selectedMetadatas)
        self.toggleSelect()
    }

    func saveAsAvailableOffline(selectedMetadatas: [tableMetadata], isAnyOffline: Bool) {
        if !isAnyOffline, selectedMetadatas.count > 3 {
            let alert = UIAlertController(
                title: NSLocalizedString("_set_available_offline_", comment: ""),
                message: NSLocalizedString("_select_offline_warning_", comment: ""),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("_continue_", comment: ""), style: .default, handler: { _ in
                selectedMetadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
                self.toggleSelect()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
            self.viewController.present(alert, animated: true)
        } else {
            selectedMetadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
            self.toggleSelect()
        }
    }

    func lock(selectedMetadatas: [tableMetadata], isAnyLocked: Bool) {
        for metadata in selectedMetadatas where metadata.lock == isAnyLocked {
            NCNetworking.shared.lockUnlockFile(metadata, shoulLock: !isAnyLocked)
        }

        self.toggleSelect()
    }

    func createMenuActions() -> [NCMenuAction] {
        var actions = [NCMenuAction]()

        actions.append(.cancelAction {
            self.toggleSelect()
        })
        if selectOcId.count != selectableDataSource.count {
            actions.append(.selectAllAction(action: collectionViewSelectAll))
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
            actions.append(.openInAction(selectedMetadatas: selectedMetadatas, viewController: self, completion: { self.toggleSelect() }))
        }

        if !isAnyFolder, canUnlock, !NCGlobal.shared.capabilityFilesLockVersion.isEmpty {
            actions.append(.lockUnlockFiles(shouldLock: !isAnyLocked, metadatas: selectedMetadatas, completion: { self.toggleSelect() }))
        }

        if !selectedMediaMetadatas.isEmpty {
            actions.append(.saveMediaAction(selectedMediaMetadatas: selectedMediaMetadatas, completion: { self.toggleSelect() }))
        }
        actions.append(.setAvailableOfflineAction(selectedMetadatas: selectedMetadatas, isAnyOffline: isAnyOffline, viewController: self, completion: {
            self.reloadDataSource()
            self.toggleSelect()
        }))
        
        if !isDirectoryE2EE {
            actions.append(.moveOrCopyAction(selectedMetadatas: selectedMetadatas, indexPath: selectIndexPaths, completion: { self.toggleSelect() }))
            actions.append(.copyAction(selectOcId: selectOcId, completion: { self.toggleSelect() }))
        }
        actions.append(.deleteAction(selectedMetadatas: selectedMetadatas, indexPath: selectIndexPaths, viewController: self, completion: { self.toggleSelect() }))
        return actions
    }
}
