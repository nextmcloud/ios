//
//  NCViewer.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 07/02/2020.
//  Copyright © 2020 Marino Faggiana All rights reserved.
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

extension NCViewer {
    func toggleMenu(controller: NCMainTabBarController?, metadata: tableMetadata, webView: Bool, imageIcon: UIImage?, indexPath: IndexPath = IndexPath()) {
        guard let metadata = self.database.getMetadataFromOcId(metadata.ocId),
              let controller else { return }
        var actions = [NCMenuAction]()
        let localFile = self.database.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
        let isOffline = localFile?.offline == true

        //
        // VIEW IN FOLDER
        //
        if !webView {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_view_in_folder_", comment: ""),
                    icon: utility.loadImage(named: "arrow.forward.square", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        NCActionCenter.shared.openFileViewInFolder(serverUrl: metadata.serverUrl, fileNameBlink: metadata.fileName, fileNameOpen: nil, sceneIdentifier: controller.sceneIdentifier)
                    }
                )
            )
        }

        //
        // FAVORITE
        // Workaround: PROPPATCH doesn't work
        // https://github.com/nextcloud/files_lock/issues/68
        if !metadata.lock, !metadata.isDirectoryE2EE{
            actions.append(
                NCMenuAction(
                    title: metadata.favorite ? NSLocalizedString("_remove_favorites_", comment: "") : NSLocalizedString("_add_favorites_", comment: ""),
                    icon: utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite]),
                    action: { _ in
                        NCNetworking.shared.favoriteMetadata(metadata) { error in
                            if error != .success {
                                NCContentPresenter().showError(error: error)
                            }
                        }
                    }
                )
            )
        }

        //
        // OFFLINE
        //
        if !webView, metadata.canSetAsAvailableOffline {
            actions.append(.setAvailableOfflineAction(selectedMetadatas: [metadata], isAnyOffline: isOffline, viewController: controller))
        }

        //
        // SHARE
        //
        if !webView, metadata.canShare {
            actions.append(.share(selectedMetadatas: [metadata], controller: controller))
        }
        
        //
        // PRINT
        //
        if !webView, metadata.isPrintable {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_print_", comment: ""),
                    icon: utility.loadImage(named: "printer", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        if self.utilityFileSystem.fileProviderStorageExists(metadata) {
                            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile, userInfo: ["ocId": metadata.ocId, "selector": NCGlobal.shared.selectorPrint, "error": NKError(), "account": metadata.account, "ocIdTransfer": metadata.ocIdTransfer])
                        } else {
                            NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: metadata, selector: NCGlobal.shared.selectorPrint))
                        }
                    }
                )
            )
        }
        
        //
        // SAVE CAMERA ROLL
        //
        if !webView, metadata.isSavebleInCameraRoll {
            actions.append(.saveMediaAction(selectedMediaMetadatas: [metadata], controller: controller))
        }


        //
        // RENAME
        //
        if !webView, metadata.isRenameable, !metadata.isDirectoryE2EE {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_rename_", comment: ""),
                    icon: utility.loadImage(named: "rename", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in

                        if let vcRename = UIStoryboard(name: "NCRenameFile", bundle: nil).instantiateInitialViewController() as? NCRenameFile {

                            vcRename.metadata = metadata
                            vcRename.disableChangeExt = true
                            vcRename.imagePreview = imageIcon
                            vcRename.indexPath = indexPath

                            let popup = NCPopupViewController(contentController: vcRename, popupWidth: vcRename.width, popupHeight: vcRename.height)

                            controller.present(popup, animated: true)
                        }
                    }
                )
            )
        }

        //
        // COPY - MOVE
        //
        if !webView, metadata.isCopyableMovable {
            actions.append(.moveOrCopyAction(selectedMetadatas: [metadata], controller: controller))
        }
        
        // COPY IN PASTEBOARD
        //
        if !webView, metadata.isCopyableInPasteboard, !metadata.isDirectoryE2EE {
            actions.append(.copyAction(fileSelect: [metadata.ocId], controller: controller))
        }

        //
        // PDF
        //
        if metadata.isPDF {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_search_", comment: ""),
                    icon: utility.loadImage(named: "search", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterMenuSearchTextPDF)
                    }
                )
            )

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_go_to_page_", comment: ""),
                    icon: utility.loadImage(named: "go-to-page", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterMenuGotToPageInPDF)
                    }
                )
            )
        }

        //
        // MODIFY WITH QUICK LOOK
        //
        if !webView, metadata.isModifiableWithQuickLook {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_modify_", comment: ""),
                    icon: utility.loadImage(named: "pencil.tip.crop.circle", colors: [NCBrandColor.shared.iconColor]),
                    action: { _ in
                        if self.utilityFileSystem.fileProviderStorageExists(metadata) {
                            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile,
                                                                        object: nil,
                                                                        userInfo: ["ocId": metadata.ocId,
                                                                                   "ocIdTransfer": metadata.ocIdTransfer,
                                                                                   "session": metadata.session,
                                                                                   "selector": NCGlobal.shared.selectorLoadFileQuickLook,
                                                                                   "error": NKError(),
                                                                                   "account": metadata.account],
                                                                        second: 0.5)
                        } else {
                            guard let metadata = self.database.setMetadatasSessionInWaitDownload(metadatas: [metadata],
                                                                                                 session: NCNetworking.shared.sessionDownload,
                                                                                                 selector: NCGlobal.shared.selectorLoadFileQuickLook,
                                                                                                 sceneIdentifier: controller.sceneIdentifier) else { return }
                            NCNetworking.shared.download(metadata: metadata, withNotificationProgressTask: true)
                        }
                    }
                )
            )
        }

        //
        // DELETE
        //
        if !webView, metadata.isDeletable {
            actions.append(.deleteAction(selectedMetadatas: [metadata], metadataFolder: nil, controller: controller))
        }

        controller.presentMenu(with: actions)
    }
}
