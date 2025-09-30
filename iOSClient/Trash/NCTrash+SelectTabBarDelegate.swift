//
//  NCTrash+SelectTabBarDelegate.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 18/03/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
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
import UIKit

extension NCTrash: NCTrashSelectTabBarDelegate, NCSelectableNavigationView {
    func onListSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutGrid {
            layoutForView?.layout = NCGlobal.shared.layoutList
            self.database.setLayoutForView(account: session.account, key: layoutKey, serverUrl: "", layout: layoutForView?.layout)

            self.collectionView.reloadData()
            self.collectionView.setCollectionViewLayout(self.listLayout, animated: true)
        }
    }

    func onGridSelected() {
        if layoutForView?.layout == NCGlobal.shared.layoutList {
            layoutForView?.layout = NCGlobal.shared.layoutGrid
            self.database.setLayoutForView(account: session.account, key: layoutKey, serverUrl: "", layout: layoutForView?.layout)

            self.collectionView.reloadData()
            self.collectionView.setCollectionViewLayout(self.gridLayout, animated: true)
        }
    }

    func selectAll() {
        if !fileSelect.isEmpty, datasource?.count == fileSelect.count {
            fileSelect = []
        } else {
            fileSelect = (datasource?.compactMap({ $0.fileId }))!
        }
        tabBarSelect.update(selectOcId: fileSelect)
        collectionView.reloadData()
    }

    func recover() {
        fileSelect.forEach(restoreItem)
        setEditMode(false)
    }

    func delete() {
        let ocIds = fileSelect.map { $0 }
        setEditMode(false)

        Task {
            if ocIds.count > 0, ocIds.count == datasource?.count {
                await emptyTrash()
            } else {
                await self.deleteItems(with: ocIds)
            }
        }
    }

    func setEditMode(_ editMode: Bool) {
        isEditMode = editMode
        fileSelect.removeAll()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = !editMode
        navigationItem.hidesBackButton = editMode
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.setNavigationRightItems()
        }
    }
    
    func setNavigationRightItems(enableMenu: Bool = false) {
        if isEditMode {
            let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain) { self.presentMenu(with: self.selectActions)}
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
    
    func createMenuActions() -> [NCMenuAction] {
//        guard let layoutForView = NCManageDatabase.shared.getLayoutForView(account: session.account, key: layoutKey, serverUrl: "") else { return [] }
//
//        let select = UIAction(title: NSLocalizedString("_select_", comment: ""), image: .init(systemName: "checkmark.circle"), attributes: datasource.isEmpty ? .disabled : []) { _ in
//            self.setEditMode(true)
//        }
//
//        let list = UIAction(title: NSLocalizedString("_list_", comment: ""), image: .init(systemName: "list.bullet"), state: layoutForView.layout == NCGlobal.shared.layoutList ? .on : .off) { _ in
//            self.onListSelected()
////            self.setNavigationRightItems()
//        }
//
//        let grid = UIAction(title: NSLocalizedString("_icons_", comment: ""), image: .init(systemName: "square.grid.2x2"), state: layoutForView.layout == NCGlobal.shared.layoutGrid ? .on : .off) { _ in
//            self.onGridSelected()
////            self.setNavigationRightItems()
//        }
//
//        let viewStyleSubmenu = UIMenu(title: "", options: .displayInline, children: [list, grid])
//
        return []//[select, viewStyleSubmenu]
    }
}
