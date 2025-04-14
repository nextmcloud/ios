//
//  NCMedia+Menu.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/03/2021.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
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
import FloatingPanel
import NextcloudKit

extension NCMedia {
    func tapSelect() {
        self.isEditMode = false
        self.fileSelect.removeAll()
        self.collectionView?.reloadData()
    }

    func selectAll() {
        if !fileSelect.isEmpty, self.dataSource.metadatas.count == fileSelect.count {
            fileSelect = []
        } else {
            fileSelect = self.dataSource.metadatas.compactMap({ $0.ocId })
        }
        self.collectionView.reloadData()
    }

    func toggleMenu() {

        var actions: [NCMenuAction] = []

        defer { presentMenu(with: actions) }

        if !isEditMode {
            if let metadatas = self.metadatas, !metadatas.isEmpty {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_select_", comment: ""),
                        icon: utility.loadImage(named: "selectFull", colors: [NCBrandColor.shared.iconColor]),
                        action: { _ in
                            self.isEditMode = true
                        }
                    )
                )
            }

            actions.append(.seperator(order: 0))

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_viewimage_show_", comment: ""),
                    icon: utility.loadImage(named: showOnlyImages ? "nocamera" : "file_photo_menu", colors: [NCBrandColor.shared.iconColor]),
                    selected: showOnlyImages,
                    on: true,
                    action: { _ in
                        self.showOnlyImages = true
                        self.showOnlyVideos = false
                        self.loadDataSource()
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_viewvideo_show_", comment: ""),
                    icon: utility.loadImage(named: showOnlyVideos ? "videono" : "videoyes", colors: [NCBrandColor.shared.iconColor]),
                    selected: showOnlyVideos,
                    on: true,
                    action: { _ in
                        self.showOnlyImages = false
                        self.showOnlyVideos = true
                        self.loadDataSource()
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_show_all_", comment: ""),
                    icon: utility.loadImage(named: "photo.on.rectangle.angled", colors: [NCBrandColor.shared.iconColor]),
                    selected: !showOnlyImages && !showOnlyVideos,
                    on: true,
                    action: { _ in
                        self.showOnlyImages = false
                        self.showOnlyVideos = false
                        self.loadDataSource()
                    }
                )
            )

            actions.append(.seperator(order: 0))

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_select_media_folder_", comment: ""),
                    icon: utility.loadImage(named: "folder", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        if let navigationController = UIStoryboard(name: "NCSelect", bundle: nil).instantiateInitialViewController() as? UINavigationController,
                           let viewController = navigationController.topViewController as? NCSelect {

                            viewController.delegate = self
                            viewController.typeOfCommandView = .select
                            viewController.type = "mediaFolder"

                            self.present(navigationController, animated: true, completion: nil)
                        }
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_by_modified_date_", comment: ""),
                    icon: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconColor]),
                    selected: NCKeychain().mediaSortDate == "date",
                    on: true,
                    action: { _ in
                        NCKeychain().mediaSortDate = "date"
                        self.loadDataSource()
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_by_created_date_", comment: ""),
                    icon: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconColor]),
                    selected: NCKeychain().mediaSortDate == "creationDate",
                    on: true,
                    action: { _ in
                        NCKeychain().mediaSortDate = "creationDate"
                        self.loadDataSource()
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_media_by_upload_date_", comment: ""),
                    icon: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconColor]),
                    selected: NCKeychain().mediaSortDate == "uploadDate",
                    on: true,
                    action: { _ in
                        NCKeychain().mediaSortDate = "uploadDate"
                        self.loadDataSource()
                    }
                )
            )

        } else {

            //
            // CANCEL
            //
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_cancel_", comment: ""),
                    icon: utility.loadImage(named: "xmark", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in self.tapSelect() }
                )
            )

            if fileSelect.count != dataSource.metadatas.count {
                actions.append(.selectAllAction(action: selectAll))
            }
            guard !fileSelect.isEmpty else { return }
            
            actions.append(.seperator(order: 0))

            let selectedMetadatas = fileSelect.compactMap(NCManageDatabase.shared.getMetadataFromOcId)

            //
            // OPEN IN
            //
            actions.append(.openInAction(selectedMetadatas: selectedMetadatas, controller: self.controller, completion: tapSelect))

            //
            // SAVE TO PHOTO GALLERY
            //
            actions.append(.saveMediaAction(selectedMediaMetadatas: selectedMetadatas, controller: self.controller, completion: tapSelect))

            //
            // COPY - MOVE
            //
            actions.append(.moveOrCopyAction(selectedMetadatas: selectedMetadatas, controller: self.controller, completion: tapSelect))

            //
            // COPY
            //
            actions.append(.copyAction(fileSelect: fileSelect, controller: self.controller, completion: tapSelect))

            //
            // DELETE
            // can't delete from cache because is needed for NCMedia view, and if locked can't delete from server either.
            if !selectedMetadatas.contains(where: { $0.lock && $0.lockOwner != session.userId }) {
                actions.append(.deleteAction(selectedMetadatas: selectedMetadatas, controller: self.controller, completion: tapSelect))
            }
        }
    }
}
