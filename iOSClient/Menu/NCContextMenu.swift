//
//  NCContextMenu.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 10/01/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
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
import Alamofire
import NextcloudKit
import JGProgressHUD

class NCContextMenu: NSObject {
    
    // swiftlint:disable force_cast
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // swiftlint:enable force_cast

    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()

    func viewMenu(ocId: String, indexPath: IndexPath, viewController: UIViewController, image: UIImage?) -> UIMenu {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return UIMenu() }

        var downloadRequest: DownloadRequest?
        var titleDeleteConfirmFile = NSLocalizedString("_delete_file_", comment: "")
        var titleSave: String = NSLocalizedString("_save_selected_files_", comment: "")
        let metadataMOV = NCManageDatabase.shared.getMetadataLivePhoto(metadata: metadata)

        if metadata.directory { titleDeleteConfirmFile = NSLocalizedString("_delete_folder_", comment: "") }
        if metadataMOV != nil { titleSave = NSLocalizedString("_livephoto_save_", comment: "") }
        
        let serverUrl = metadata.serverUrl + "/" + metadata.fileName
        var isOffline: Bool = false

        if metadata.directory, let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, serverUrl)) {
            isOffline = directory.offline
        } else if let localFile = NCManageDatabase.shared.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) {
            isOffline = localFile.offline
        }

        let hud = JGProgressHUD()
        hud.indicatorView = JGProgressHUDRingIndicatorView()
        hud.textLabel.text = NSLocalizedString("_downloading_", comment: "")
        hud.detailTextLabel.text = NSLocalizedString("_tap_to_cancel_", comment: "")
        if let indicatorView = hud.indicatorView as? JGProgressHUDRingIndicatorView { indicatorView.ringWidth = 1.5 }
        hud.tapOnHUDViewBlock = { _ in
            if let request = downloadRequest {
                request.cancel()
            }
        }

        // MENU ITEMS

        let detail = UIAction(title: NSLocalizedString("_details_", comment: "")) { _ in
            NCActionCenter.shared.openShare(viewController: viewController, metadata: metadata, page: .activity)
        }
        
        let titleOffline = isOffline ? NSLocalizedString("_remove_available_offline_", comment: "") :  NSLocalizedString("_set_available_offline_", comment: "")

        let offline = UIAction(title: titleOffline, image: UIImage(systemName: "tray.and.arrow.down")) { _ in
            NCActionCenter.shared.setMetadataAvalableOffline(metadata, isOffline: isOffline)
            if let viewController = viewController as? NCCollectionViewCommon {
                viewController.reloadDataSource()
            }
        }
        
        let print = UIAction(title: NSLocalizedString("_print_", comment: ""), image: UIImage(systemName: "printer") ) { _ in
            NCNetworking.shared.download(metadata: metadata, selector: NCGlobal.shared.selectorPrint) { _, _ in }
        }
        
        let moveCopy = UIAction(title: NSLocalizedString("_move_or_copy_", comment: ""), image: UIImage(systemName: "arrow.up.right.square")) { action in
            NCActionCenter.shared.openSelectView(items: [metadata], indexPath: [indexPath])
        }
        
        let rename = UIAction(title: NSLocalizedString("_rename_", comment: ""), image: UIImage(systemName: "pencil")) { action in
            if let vcRename = UIStoryboard(name: "NCRenameFile", bundle: nil).instantiateInitialViewController() as? NCRenameFile {
                vcRename.metadata = metadata
                vcRename.imagePreview = image
                vcRename.indexPath = indexPath
                let popup = NCPopupViewController(contentController: vcRename, popupWidth: vcRename.width, popupHeight: vcRename.height)
                viewController.present(popup, animated: true)
            }
        }
        
        let decrypt = UIAction(title: NSLocalizedString("_e2e_remove_folder_encrypted_", comment: ""), image: UIImage(systemName: "lock") ) { action in
            NextcloudKit.shared.markE2EEFolder(fileId: metadata.fileId, delete: true) { _, error in
                if error == .success {
                    NCManageDatabase.shared.deleteE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", self.appDelegate.account, serverUrl))
                    NCManageDatabase.shared.setDirectory(serverUrl: serverUrl, serverUrlTo: nil, etag: nil, ocId: nil, fileId: nil, encrypted: false, richWorkspace: nil, account: metadata.account)
                    NCManageDatabase.shared.setMetadataEncrypted(ocId: metadata.ocId, encrypted: false)

                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeStatusFolderE2EE, userInfo: ["serverUrl": metadata.serverUrl])
                } else {
                    NCContentPresenter().messageNotification(NSLocalizedString("_e2e_error_", comment: ""), error: error, delay: NCGlobal.shared.dismissAfterSecond, type: .error)
                }
            }
        }
        
        let encrypt = UIAction(title: NSLocalizedString("_e2e_set_folder_encrypted_", comment: ""), image: UIImage(systemName: "lock") ) { action in
            Task {
                let error = await NCNetworkingE2EEMarkFolder().markFolderE2ee(account: metadata.account, fileName: metadata.fileName, serverUrl: metadata.serverUrl, userId: metadata.userId)
                if error != .success {
                    NCContentPresenter().showError(error: error)
                }
            }
        }

        let favorite = UIAction(title: metadata.favorite ?
                                NSLocalizedString("_remove_favorites_", comment: "") :
                                NSLocalizedString("_add_favorites_", comment: ""),
                                image: utility.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite)) { _ in
            NCNetworking.shared.favoriteMetadata(metadata) { error in
                if error != .success {
                    NCContentPresenter().showError(error: error)
                }
            }
        }

        let openIn = UIAction(title: NSLocalizedString("_open_in_", comment: ""),
                              image: UIImage(systemName: "square.and.arrow.up") ) { _ in
            if self.utilityFileSystem.fileProviderStorageExists(metadata) {
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile, userInfo: ["ocId": metadata.ocId, "selector": NCGlobal.shared.selectorOpenIn, "error": NKError(), "account": metadata.account])
            } else {
                hud.show(in: viewController.view)
                NCNetworking.shared.download(metadata: metadata, selector: NCGlobal.shared.selectorOpenIn, notificationCenterProgressTask: false) { request in
                    downloadRequest = request
                } progressHandler: { progress in
                    hud.progress = Float(progress.fractionCompleted)
                } completion: { afError, error in
                    if error == .success || afError?.isExplicitlyCancelledError ?? false {
                        hud.dismiss()
                    } else {
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = error.description
                        hud.dismiss(afterDelay: NCGlobal.shared.dismissAfterSecond)
                    }
                }
            }
        }

        let viewInFolder = UIAction(title: NSLocalizedString("_view_in_folder_", comment: ""),
                                    image: UIImage(systemName: "arrow.forward.square")) { _ in
            NCActionCenter.shared.openFileViewInFolder(serverUrl: metadata.serverUrl, fileNameBlink: metadata.fileName, fileNameOpen: nil)
        }

        let save = UIAction(title: titleSave,
                            image: UIImage(systemName: "square.and.arrow.down")) { _ in
            if let metadataMOV = metadataMOV {
                if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                    appDelegate.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: metadata, metadataMOV: metadataMOV))
                }
            } else {
                if self.utilityFileSystem.fileProviderStorageExists(metadata) {
                    NCActionCenter.shared.saveAlbum(metadata: metadata)
                } else {
                    hud.show(in: viewController.view)
                    NCNetworking.shared.download(metadata: metadata, selector: NCGlobal.shared.selectorSaveAlbum, notificationCenterProgressTask: false) { request in
                        downloadRequest = request
                    } progressHandler: { progress in
                        hud.progress = Float(progress.fractionCompleted)
                    } completion: { afError, error in
                        if error == .success || afError?.isExplicitlyCancelledError ?? false {
                            hud.dismiss()
                        } else {
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.textLabel.text = error.description
                            hud.dismiss(afterDelay: NCGlobal.shared.dismissAfterSecond)
                        }
                    }
                }
            }
        }
        
        let copy = UIAction(title: NSLocalizedString("_copy_file_", comment: ""),
                            image: UIImage(systemName: "doc.on.doc")) { _ in
            NCActionCenter.shared.copyPasteboard(pasteboardOcIds: [metadata.ocId])
        }

        let modify = UIAction(title: NSLocalizedString("_modify_", comment: ""),
                              image: UIImage(systemName: "pencil.tip.crop.circle")) { _ in
            if self.utilityFileSystem.fileProviderStorageExists(metadata) {
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile, userInfo: ["ocId": metadata.ocId, "selector": NCGlobal.shared.selectorLoadFileQuickLook, "error": NKError(), "account": metadata.account])
            } else {
                hud.show(in: viewController.view)
                NCNetworking.shared.download(metadata: metadata, selector: NCGlobal.shared.selectorLoadFileQuickLook, notificationCenterProgressTask: false) { request in
                    downloadRequest = request
                } progressHandler: { progress in
                    hud.progress = Float(progress.fractionCompleted)
                } completion: { afError, error in
                    if error == .success || afError?.isExplicitlyCancelledError ?? false {
                        hud.dismiss()
                    } else {
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = error.description
                        hud.dismiss(afterDelay: NCGlobal.shared.dismissAfterSecond)
                    }
                }
            }
        }

        let deleteConfirmFile = UIAction(title: titleDeleteConfirmFile,
                                         image: UIImage(systemName: "trash"), attributes: .destructive) { _ in

            var alertStyle = UIAlertController.Style.actionSheet
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertStyle = .alert
            }
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: alertStyle)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_delete_file_", comment: ""), style: .destructive) { _ in
                let hud = JGProgressHUD()
                hud.textLabel.text = NSLocalizedString("_deletion_progess_", comment: "")
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                   let view = appDelegate.window?.rootViewController?.view {
                    hud.show(in: view)
                }
                Task {
                    var ocId: [String] = []
                    let error = await NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: false)
                    if error == .success {
                        ocId.append(metadata.ocId)
                    } else {
                        NCContentPresenter().showError(error: error)
                    }
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteFile, userInfo: ["ocId": ocId, "indexPath": [indexPath], "onlyLocalCache": false, "error": error, "hud": hud])
                }
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel) { _ in })
            viewController.present(alertController, animated: true, completion: nil)
        }

        let deleteConfirmLocal = UIAction(title: NSLocalizedString("_remove_local_file_", comment: ""),
                                          image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            Task {
                var ocId: [String] = []
                let error = await NCNetworking.shared.deleteMetadata(metadata, onlyLocalCache: true)
                if error == .success {
                    ocId.append(metadata.ocId)
                } else {
                    NCContentPresenter().showError(error: error)
                }
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteFile, userInfo: ["ocId": ocId, "indexPath": [indexPath], "onlyLocalCache": true, "error": error])
            }
        }

        let deleteSubMenu = UIMenu(title: NSLocalizedString("_delete_file_", comment: ""),
                                   image: UIImage(systemName: "trash"),
                                   options: .destructive,
                                   children: [deleteConfirmLocal, deleteConfirmFile])

        // ------ MENU -----

        if metadata.directory {
            let serverUrlHome = utilityFileSystem.getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId)
            let isEncryptionDisabled = metadata.isDirectoryUnsettableE2EE
            let isEncrytptionEnabled = metadata.serverUrl == serverUrlHome && metadata.isDirectoySettableE2EE
            let submenu = UIMenu(title: "", options: .displayInline, children: isEncrytptionEnabled ? [favorite, offline, rename, moveCopy, encrypt, deleteSubMenu] : [favorite, offline, rename, moveCopy, deleteSubMenu])
            let childrenArray = metadata.e2eEncrypted ? ( isEncryptionDisabled ? [offline, decrypt] : (metadata.serverUrl == serverUrlHome) ? [offline] : [offline, deleteSubMenu]) : [detail,submenu]
            return UIMenu(title: "", children: childrenArray)

        } else {
            
            var children: [UIMenuElement] = metadata.e2eEncrypted ? [openIn, copy, deleteSubMenu] : [offline, openIn, deleteSubMenu]

            if !metadata.lock {
                // Workaround: PROPPATCH doesn't work (favorite)
                // https://github.com/nextcloud/files_lock/issues/68
                if !metadata.isDirectoryE2EE {
                    children.insert(favorite, at: 0)
                    children.insert(moveCopy, at: 2)
                    children.insert(rename, at: 3)
                    children.insert(copy, at: 3)
                }
            }
            
            children.append(deleteSubMenu)
            
            if (metadata.contentType != "image/svg+xml") && (metadata.classFile == NKCommon.TypeClassFile.image.rawValue || metadata.classFile == NKCommon.TypeClassFile.video.rawValue) {
                children.insert(save, at: 2)
            }
            
            if !metadata.e2eEncrypted, (metadata.contentType != "image/svg+xml") && (metadata.classFile == NKCommon.TypeClassFile.image.rawValue || metadata.contentType == "application/pdf" || metadata.contentType == "com.adobe.pdf") {
                children.insert(print, at: 2)
            }
            
            if !metadata.e2eEncrypted {
                if viewController is NCMedia {
                    children.insert(viewInFolder, at: children.count - 1)
                }
            }
            
            if (!metadata.isDirectoryE2EE && metadata.contentType != "image/gif" && metadata.contentType != "image/svg+xml") && (metadata.contentType == "com.adobe.pdf" || metadata.contentType == "application/pdf" || metadata.classFile == NKCommon.TypeClassFile.image.rawValue) {
                children.insert(modify, at: children.count - 1)
            }
            
            let submenu = UIMenu(title: "", options: .displayInline, children: children)
            guard appDelegate.disableSharesView == false else { return submenu }
            let childrenArray = metadata.isDirectoryE2EE ? [submenu] : [detail, submenu]
            return UIMenu(title: "", children: childrenArray)
        }
    }
}
