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
import NCCommunication

extension NCViewer {

    func toggleMenu(viewController: UIViewController, metadata: tableMetadata, webView: Bool, imageIcon: UIImage?) {

        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) else { return }

        var actions = [NCMenuAction]()
        var titleFavorite = NSLocalizedString("_add_favorites_", comment: "")
        if metadata.favorite { titleFavorite = NSLocalizedString("_remove_favorites_", comment: "") }
        let localFile = NCManageDatabase.shared.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
        let isFolderEncrypted = CCUtility.isFolderEncrypted(metadata.serverUrl, e2eEncrypted: metadata.e2eEncrypted, account: metadata.account, urlBase: metadata.urlBase)

        //
        // FAVORITE
        // Workaround: PROPPATCH doesn't work
        // https://github.com/nextcloud/files_lock/issues/68
        if !metadata.lock {
            actions.append(
                NCMenuAction(
                    title: titleFavorite,
                    icon: NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite),
                    action: { _ in
                        NCNetworking.shared.favoriteMetadata(metadata) { errorCode, errorDescription in
                            if errorCode != 0 {
                                NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                            }
                        }
                    }
                )
            )
        }

        //
        // ROTATE
        // OFFLINE
        //
        if (metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue && metadata.contentType != "image/svg+xml"), !metadata.livePhoto {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_rotate_", comment: ""),
                    icon: NCUtility.shared.loadImage(named: "rotate",color: NCBrandColor.shared.iconColor),
                    action: { menuAction in
                        NotificationCenter.default.postOnMainThread(name: NCBrandGlobal.shared.notificationImagePreviewRotateImage)
                    }
                )
            )
        }
        
        //
        // OPEN IN
        //
        actions.append(.openInAction(selectedMetadatas: [metadata], viewController: viewController))
        
        //
        // PRINT
        //
        if (metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue && metadata.contentType != "image/svg+xml") || metadata.contentType == "application/pdf" || metadata.contentType == "com.adobe.pdf" {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_print_", comment: ""),
                    icon: NCUtility.shared.loadImage(named: "printer",color: NCBrandColor.shared.iconColor),
                    action: { menuAction in
                        NCFunctionCenter.shared.openDownload(metadata: metadata, selector: NCGlobal.shared.selectorPrint)
                    }
                )
            )
        }
        
        //
        // CONVERSION VIDEO TO MPEG4 (MFFF Lib)
        //
#if MFFFLIB
        if metadata.classFile == NCCommunicationCommon.typeClassFile.video.rawValue {
            
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_video_conversion_", comment: ""),
                    icon: NCUtility.shared.loadImage(named: "film"),
                    action: { menuAction in
                        if let ncplayer = (viewController as? NCViewerMediaPage)?.currentViewController.ncplayer {
                            ncplayer.convertVideo()
                        }
                    }
                )
            )
        }
#endif
        
        //
        // SAVE IMAGE / VIDEO
        //
        if metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue || metadata.classFile == NCCommunicationCommon.typeClassFile.video.rawValue {
            actions.append(.saveMediaAction(selectedMediaMetadatas: [metadata]))
        }

        //
        // RENAME
        //
        if !webView, !metadata.lock {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_rename_", comment: ""),
                    icon: NCUtility.shared.loadImage(named: "rename",color: NCBrandColor.shared.iconColor),
                    action: { _ in

                        if let vcRename = UIStoryboard(name: "NCRenameFile", bundle: nil).instantiateInitialViewController() as? NCRenameFile {

                            vcRename.metadata = metadata
                            vcRename.disableChangeExt = true
                            vcRename.imagePreview = imageIcon
                            
                            let popup = NCPopupViewController(contentController: vcRename, popupWidth: vcRename.width, popupHeight: vcRename.height)
                            viewController.present(popup, animated: true)
                        }
                    }
                )
            )
        }

        //
        // VIEW IN FOLDER
        //
        if !webView {
            if appDelegate.activeFileViewInFolder == nil {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_view_in_folder_", comment: ""),
                        icon: NCUtility.shared.loadImage(named: "viewInFolder",color: NCBrandColor.shared.iconColor),
                        action: { _ in
                            NCFunctionCenter.shared.openFileViewInFolder(serverUrl: metadata.serverUrl, fileName: metadata.fileName)
                        }
                    )
                )
            }
        }

        //
        // DOWNLOAD IMAGE MAX RESOLUTION
        //
        if metadata.session == "" {
            if metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue && !CCUtility.fileProviderStorageExists(metadata) && metadata.session == "" {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_download_image_max_", comment: ""),
                        icon: NCUtility.shared.loadImage(named: "cloudDownload",color: NCBrandColor.shared.iconColor),
                        action: { _ in
                            NCNetworking.shared.download(metadata: metadata, selector: "") { _ in }
                        }
                    )
                )
            }
        }

        //
        // PDF
        //
        if metadata.contentType == "com.adobe.pdf" || metadata.contentType == "application/pdf" {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_search_", comment: ""),
                    icon: UIImage(named: "search")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                    action: { _ in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterMenuSearchTextPDF)
                    }
                )
            )
            
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_go_to_page_", comment: ""),
                    icon: NCUtility.shared.loadImage(named: "go-to-page").image(color: NCBrandColor.shared.iconColor, size: 50),
                    action: { _ in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterMenuGotToPageInPDF)
                    }
                )
            )
        }

        //
        // MODIFY
        //
        if #available(iOS 13.0, *) {
            if !isFolderEncrypted && metadata.contentType != "image/gif" && (metadata.contentType == "com.adobe.pdf" || metadata.contentType == "application/pdf" || metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue) {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_modify_", comment: ""),
                        icon: NCUtility.shared.loadImage(named: "pencil.tip.crop.circle",color: NCBrandColor.shared.iconColor),
                        action: { _ in
                            NCFunctionCenter.shared.openDownload(metadata: metadata, selector: NCGlobal.shared.selectorLoadFileQuickLook)
                        }
                    )
                )
            }
        }

        //
        // DELETE
        //
        if !webView {
            actions.append(.deleteAction(selectedMetadatas: [metadata], metadataFolder: nil, viewController: viewController))
        }
        viewController.presentMenu(with: actions)
    }
}
