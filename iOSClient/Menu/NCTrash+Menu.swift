//
//  NCTrash+Menu.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/03/2021.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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
import FloatingPanel
import NextcloudKit

extension NCTrash {
    func toggleMenuMore(with objectId: String, image: UIImage?, isGridCell: Bool, sender: Any?) {
        guard let tblTrash = self.database.getTableTrash(fileId: objectId, account: session.account)
        else {
            return
        }
        guard isGridCell
        else {
            let alert = UIAlertController(title: NSLocalizedString("_want_delete_", comment: ""), message: tblTrash.trashbinFileName, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("_delete_", comment: ""), style: .destructive, handler: { _ in
                Task {
                    await self.deleteItems(with: [objectId])
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
            self.present(alert, animated: true, completion: nil)
            return
        }

        var actions: [NCMenuAction] = []

        var iconHeader: UIImage!
        if let icon = image { //utility.getImage(ocId: resultTableTrash.fileId, etag: resultTableTrash.fileName, ext: NCGlobal.shared.previewExt512) {
            iconHeader = icon
        } else {
            if tblTrash.directory {
                iconHeader = NCImageCache.shared.getFolder()
            } else {
                iconHeader = NCImageCache.shared.getImageFile()
            }
        }

        actions.append(
            NCMenuAction(
                title: tblTrash.trashbinFileName,
                icon: iconHeader,
                action: nil
            )
        )

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_restore_", comment: ""),
                icon: utility.loadImage(named: "restore", colors: [NCBrandColor.shared.iconColor]),
                action: { _ in
                    self.restoreItem(with: objectId)
                }
            )
        )

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_delete_", comment: ""),
//                destructive: true,
                icon: utility.loadImage(named: "trash", colors: [NCBrandColor.shared.iconColor]),
//                sender: sender,
                action: { _ in
                    Task {
                        await self.deleteItems(with: [objectId])
                    }
                }
            )
        )

        presentMenu(with: actions)
//        presentMenu(with: actions, controller: controller, sender: sender)
    }
    
    var selectActions: [NCMenuAction] {
        var actions = [NCMenuAction]()
        actions.append(.cancelAction {
            self.toggleSelect()
        })
        if fileSelect.count != selectableDataSource.count {
//            actions.append(.selectAllAction(action: collectionViewSelectAll))
            actions.append(.selectAllAction(action: selectAll))
        }

        guard !fileSelect.isEmpty else { return actions }
        actions.append(contentsOf: [
            NCMenuAction(
                title: NSLocalizedString("_trash_restore_selected_", comment: ""),
                icon: utility.loadImage(named: "restore").image(color: NCBrandColor.shared.iconColor, size: 50),
                action: { _ in
                    self.fileSelect.forEach(self.restoreItem)
                    self.toggleSelect()
                }
            ),
            NCMenuAction(
                title: NSLocalizedString("_trash_delete_selected_", comment: ""),
                icon: utility.loadImage(named: "trash").image(color: NCBrandColor.shared.iconColor, size: 50),
                action: { _ in
                    let alert = UIAlertController(title: NSLocalizedString("_trash_delete_selected_", comment: ""), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_delete_", comment: ""), style: .destructive, handler: { _ in
                        self.fileSelect.forEach { file in
                            Task {
                                await self.deleteItems(with: [file])
                            }
                        }
                        self.toggleSelect()
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel, handler: { _ in }))
                    self.present(alert, animated: true, completion: nil)
                }
            )
        ])
        return actions
    }

    func toggleMenuMoreHeader() {

        var actions: [NCMenuAction] = []

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_trash_restore_all_", comment: ""),
                icon: utility.loadImage(named: "restore").image(color: NCBrandColor.shared.iconColor, size: 50),
                action: { _ in
                    self.datasource?.forEach({ self.restoreItem(with: $0.fileId) })
                }
            )
        )

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_trash_delete_all_", comment: ""),
                icon: utility.loadImage(named: "trash").image(color: NCBrandColor.shared.iconColor, size: 50),
                action: { _ in
                    let alert = UIAlertController(title: NSLocalizedString("_trash_delete_all_description_", comment: ""), message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_trash_delete_all_", comment: ""), style: .destructive, handler: { _ in
                        Task {
                            await self.emptyTrash()
                        }
                    }))

                    alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
                    self.present(alert, animated: true, completion: nil)
                }
            )
        )
        presentMenu(with: actions)
//        presentMenu(with: actions, controller: controller, sender: sender)
    }
}
