// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2023 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import Alamofire
import NextcloudKit

class NCContextMenu: NSObject {
    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()
    let database = NCManageDatabase.shared
    let global = NCGlobal.shared
    let networking = NCNetworking.shared

    let metadata: tableMetadata
    let sceneIdentifier: String
    let viewController: UIViewController
    let image: UIImage?

    init(metadata: tableMetadata, viewController: UIViewController, sceneIdentifier: String, image: UIImage?) {
        self.metadata = metadata
        self.viewController = viewController
        self.sceneIdentifier = sceneIdentifier
        self.image = image
    }

    func viewMenu() -> UIMenu {
        var downloadRequest: DownloadRequest?
        var titleDeleteConfirmFile = NSLocalizedString("_delete_file_", comment: "")
        let metadataMOV = self.database.getMetadataLivePhoto(metadata: metadata)
        let hud = NCHud(viewController.view)
        var titleSave: String = NSLocalizedString("_save_selected_files_", comment: "")
        if metadataMOV != nil { titleSave = NSLocalizedString("_livephoto_save_", comment: "") }
        let serverUrl = metadata.serverUrl + "/" + metadata.fileName
        var isOffline: Bool = false

        if metadata.directory, let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", metadata.account, serverUrl)) {
            isOffline = directory.offline
        } else if let localFile = NCManageDatabase.shared.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) {
            isOffline = localFile.offline
        }
        
        if metadata.directory { titleDeleteConfirmFile = NSLocalizedString("_delete_folder_", comment: "") }

        // MENU ITEMS

        let detail = UIAction(title: NSLocalizedString("_details_", comment: ""),
                              image: utility.loadImage(named: "info.circle")) { _ in
            NCDownloadAction.shared.openShare(viewController: self.viewController, metadata: self.metadata, page: .activity)
        }
        
        let titleOffline = isOffline ? NSLocalizedString("_remove_available_offline_", comment: "") :  NSLocalizedString("_set_available_offline_", comment: "")

        let offline = UIAction(title: titleOffline, image: utility.loadImage(named: "cloudDownload", colors: [NCBrandColor.shared.iconImageColor])) { _ in
            Task {
                await NCDownloadAction.shared.setMetadataAvalableOffline(self.metadata, isOffline: isOffline)
                if let viewController = self.viewController as? NCCollectionViewCommon {
                    await viewController.reloadDataSource()
                }
            }
        }
        
        let print = UIAction(title: NSLocalizedString("_print_", comment: ""), image: UIImage(systemName: "printer") ) { _ in
//            NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: metadata, selector: NCGlobal.shared.selectorPrint))
            NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: self.metadata, selector: NCGlobal.shared.selectorPrint))

        }
        
        let moveCopy = UIAction(title: NSLocalizedString("_move_or_copy_", comment: ""), image: UIImage(systemName: "arrow.up.right.square")) { action in
            let controller = self.viewController.tabBarController as? NCMainTabBarController
            NCDownloadAction.shared.openSelectView(items: [self.metadata], controller: controller)//viewController as? NCMainTabBarController)
        }
        
        let rename = UIAction(title: NSLocalizedString("_rename_", comment: ""), image: UIImage(systemName: "pencil")) { action in
            if let vcRename = UIStoryboard(name: "NCRenameFile", bundle: nil).instantiateInitialViewController() as? NCRenameFile {
                vcRename.metadata = self.metadata
                vcRename.imagePreview = self.image
//                vcRename.indexPath = indexPath
                let popup = NCPopupViewController(contentController: vcRename, popupWidth: vcRename.width, popupHeight: vcRename.height)
                self.viewController.present(popup, animated: true)
            }
        }
        
        let decrypt = UIAction(title: NSLocalizedString("_e2e_remove_folder_encrypted_", comment: ""), image: UIImage(systemName: "lock") ) { action in
            Task {
                let results = await NextcloudKit.shared.markE2EEFolderAsync(fileId: self.metadata.fileId, delete: true, account: self.metadata.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: self.metadata.account,
                                                                                                    path: self.metadata.fileId,
                                                                                                    name: "markE2EEFolder")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                }
                if results.error == .success {
                    await self.database.deleteE2eEncryptionAsync(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", self.metadata.account, self.metadata.serverUrlFileName))
                    await self.database.setMetadataEncryptedAsync(ocId: self.metadata.ocId, encrypted: false)
//                    await self.reloadDataSource()
                } else {
                    NCContentPresenter().messageNotification(NSLocalizedString("_e2e_error_", comment: ""), error: results.error, delay: NCGlobal.shared.dismissAfterSecond, type: .error)
                }
            }
        }
        
        let encrypt = UIAction(title: NSLocalizedString("_e2e_set_folder_encrypted_", comment: ""), image: UIImage(systemName: "lock") ) { action in
            Task {
                let error = await NCNetworkingE2EEMarkFolder().markFolderE2ee(account: self.metadata.account, serverUrlFileName: self.metadata.serverUrlFileName, userId: self.metadata.userId)
                if error != .success {
                    NCContentPresenter().showError(error: error)
                }
            }
        }

        let favorite = UIAction(title: metadata.favorite ?
                                NSLocalizedString("_remove_favorites_", comment: "") :
                                NSLocalizedString("_add_favorites_", comment: ""),
                                image: utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])) { _ in
            self.networking.favoriteMetadata(self.metadata) { error in
                if error != .success {
                    NCContentPresenter().showError(error: error)
                }
            }
        }

        let openIn = UIAction(title: NSLocalizedString("_open_in_", comment: ""),
                             image: utility.loadImage(named: "square.and.arrow.up") ) { _ in
            if self.utilityFileSystem.fileProviderStorageExists(self.metadata) {
                Task {
                    await self.networking.transferDispatcher.notifyAllDelegates { delegate in
                        let metadata = self.metadata.detachedCopy()
                        metadata.sessionSelector = self.global.selectorOpenIn
                        delegate.transferChange(status: self.global.networkingStatusDownloaded,
                                                metadata: metadata,
                                                error: .success)
                    }
                }
            } else {
                Task { @MainActor in
                    guard let metadata = await self.database.setMetadataSessionInWaitDownloadAsync(ocId: self.metadata.ocId,
                                                                                                   session: self.networking.sessionDownload,
                                                                                                   selector: self.global.selectorOpenIn,
                                                                                                   sceneIdentifier: self.sceneIdentifier) else {
                        return
                    }

                    hud.ringProgress(text: NSLocalizedString("_downloading_", comment: ""), tapToCancelDetailText: true) {
                        if let request = downloadRequest {
                            request.cancel()
                        }
                    }

                    let results = await self.networking.downloadFile(metadata: metadata) { request in
                        downloadRequest = request
                    } progressHandler: { progress in
                        hud.progress(progress.fractionCompleted)
                    }
                    if results.nkError == .success || results.afError?.isExplicitlyCancelledError ?? false {
                        hud.dismiss()
                    } else {
                        hud.error(text: results.nkError.errorDescription)
                    }
                }
            }
        }

        let viewInFolder = UIAction(title: NSLocalizedString("_view_in_folder_", comment: ""),
                                    image: UIImage(systemName: "arrow.forward.square")) { _ in
            NCDownloadAction.shared.openFileViewInFolder(serverUrl: self.metadata.serverUrl, fileNameBlink: self.metadata.fileName, fileNameOpen: nil, sceneIdentifier: self.sceneIdentifier)
        }
        
        let save = UIAction(title: titleSave,
                            image: UIImage(systemName: "square.and.arrow.down")) { _ in
            if let metadataMOV = metadataMOV {
                NCNetworking.shared.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: self.metadata, metadataMOV: metadataMOV, hudView: self.viewController.view))
            } else {
                if self.utilityFileSystem.fileProviderStorageExists(self.metadata) {
                    NCDownloadAction.shared.saveAlbum(metadata: self.metadata, controller: self.viewController as? NCMainTabBarController)
                } else {
                    Task { @MainActor in
                        guard let metadata = await self.database.setMetadataSessionInWaitDownloadAsync(ocId: self.metadata.ocId,
                                                                                                       session: self.networking.sessionDownload,
                                                                                                       selector: self.global.selectorSaveAlbum,
                                                                                                       sceneIdentifier: self.sceneIdentifier) else {
                            return
                        }

                        hud.ringProgress(text: NSLocalizedString("_downloading_", comment: ""), tapToCancelDetailText: true) {
                            if let request = downloadRequest {
                                request.cancel()
                            }
                        }

                        let results = await self.networking.downloadFile(metadata: metadata) { request in
                            downloadRequest = request
                        } progressHandler: { progress in
                            hud.progress(progress.fractionCompleted)
                        }
                        if results.nkError == .success || results.afError?.isExplicitlyCancelledError ?? false {
                            hud.dismiss()
                        } else {
                            hud.error(text: results.nkError.errorDescription)
                        }
                    }
                }
            }
        }
        
        let copy = UIAction(title: NSLocalizedString("_copy_file_", comment: ""),
                            image: UIImage(systemName: "doc.on.doc")) { _ in
            NCDownloadAction.shared.copyPasteboard(pasteboardOcIds: [self.metadata.ocId], controller: self.viewController as? NCMainTabBarController)
        }

        let share = UIAction(title: NSLocalizedString("_share_", comment: ""),
                             image: utility.loadImage(named: "square.and.arrow.up") ) { _ in
            if self.utilityFileSystem.fileProviderStorageExists(self.metadata) {
                Task {
                    await self.networking.transferDispatcher.notifyAllDelegates { delegate in
                        let metadata = self.metadata.detachedCopy()
                        metadata.sessionSelector = self.global.selectorOpenIn
                        delegate.transferChange(status: self.global.networkingStatusDownloaded,
                                                metadata: metadata,
                                                error: .success)
                    }
                }
            } else {
                Task { @MainActor in
                    guard let metadata = await self.database.setMetadataSessionInWaitDownloadAsync(ocId: self.metadata.ocId,
                                                                                                   session: self.networking.sessionDownload,
                                                                                                   selector: self.global.selectorOpenIn,
                                                                                                   sceneIdentifier: self.sceneIdentifier) else {
                        return
                    }

                    hud.ringProgress(text: NSLocalizedString("_downloading_", comment: ""), tapToCancelDetailText: true) {
                        if let request = downloadRequest {
                            request.cancel()
                        }
                    }

                    let results = await self.networking.downloadFile(metadata: metadata) { request in
                        downloadRequest = request
                    } progressHandler: { progress in
                        hud.progress(progress.fractionCompleted)
                    }
                    if results.nkError == .success || results.afError?.isExplicitlyCancelledError ?? false {
                        hud.dismiss()
                    } else {
                        hud.error(text: results.nkError.errorDescription)
                    }
                }
            }
        }

        let livePhotoSave = UIAction(title: NSLocalizedString("_livephoto_save_", comment: ""), image: utility.loadImage(named: "livephoto")) { _ in
            if let metadataMOV = metadataMOV {
                self.networking.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: self.metadata, metadataMOV: metadataMOV, hudView: self.viewController.view))
            }
        }

        let modify = UIAction(title: NSLocalizedString("_modify_", comment: ""),
                              image: utility.loadImage(named: "pencil.tip.crop.circle")) { _ in
            Task { @MainActor in
                if self.utilityFileSystem.fileProviderStorageExists(self.metadata) {
                    await self.networking.transferDispatcher.notifyAllDelegates { delegate in
                        let metadata = self.metadata.detachedCopy()
                        metadata.sessionSelector = self.global.selectorLoadFileQuickLook
                        delegate.transferChange(status: self.global.networkingStatusDownloaded,
                                                metadata: metadata,
                                                error: .success)
                    }
                } else {
                    guard let metadata = await self.database.setMetadataSessionInWaitDownloadAsync(ocId: self.metadata.ocId,
                                                                                                   session: self.networking.sessionDownload,
                                                                                                   selector: self.global.selectorLoadFileQuickLook,
                                                                                                   sceneIdentifier: self.sceneIdentifier) else {
                        return
                    }

                    hud.ringProgress(text: NSLocalizedString("_downloading_", comment: "")) {
                        if let request = downloadRequest {
                            request.cancel()
                        }
                    }

                    let results = await self.networking.downloadFile(metadata: metadata) { request in
                        downloadRequest = request
                    } progressHandler: { progress in
                        hud.progress(progress.fractionCompleted)
                    }
                    if results.nkError == .success || results.afError?.isExplicitlyCancelledError ?? false {
                        hud.dismiss()
                    } else {
                        hud.error(text: results.nkError.errorDescription)
                    }
                }
            }
        }

        let deleteConfirmFile = UIAction(title: titleDeleteConfirmFile,
                                         image: utility.loadImage(named: "trash"), attributes: .destructive) { _ in

            var alertStyle = UIAlertController.Style.actionSheet
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertStyle = .alert
            }
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: alertStyle)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_delete_file_", comment: ""), style: .destructive) { _ in
                if let viewController = self.viewController as? NCCollectionViewCommon {
                    Task {
                        await self.networking.setStatusWaitDelete(metadatas: [self.metadata], sceneIdentifier: self.sceneIdentifier)
                        await viewController.reloadDataSource()
                    }
                }
                if let viewController = self.viewController as? NCMedia {
                    Task {
                        await viewController.deleteImage(with: self.metadata.ocId)
                    }
                }
            })
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel) { _ in })
            self.viewController.present(alertController, animated: true, completion: nil)
        }

        let deleteConfirmLocal = UIAction(title: NSLocalizedString("_remove_local_file_", comment: ""),
                                          image: utility.loadImage(named: "trash"), attributes: .destructive) { _ in
            Task {
                var metadatasError: [tableMetadata: NKError] = [:]
                let error = await self.networking.deleteCache(self.metadata, sceneIdentifier: self.sceneIdentifier)
                metadatasError[self.metadata.detachedCopy()] = error

                await self.networking.transferDispatcher.notifyAllDelegates { delegate in
                    delegate.transferChange(status: self.global.networkingStatusDelete,
                                            metadatasError: metadatasError)
                }
            }
        }

        let deleteSubMenu = UIMenu(title: NSLocalizedString("_delete_file_", comment: ""),
                                   image: utility.loadImage(named: "trash"),
                                   options: .destructive,
                                   children: [deleteConfirmLocal, deleteConfirmFile])

        // ------ MENU -----

//        var menu: [UIMenuElement] = []
//
//        if self.networking.isOnline {
//            if metadata.directory {
//                if metadata.isDirectoryE2EE || metadata.e2eEncrypted {
////                    menu.append(favorite)
//                } else {
//                    menu.append(favorite)
//                    menu.append(deleteConfirmFile)
//                }
//                return UIMenu(title: "", children: [detail, UIMenu(title: "", options: .displayInline, children: menu)])
//            } else {
//                if metadata.lock {
//                    menu.append(favorite)
//                    menu.append(share)
//
//                    if self.database.getMetadataLivePhoto(metadata: metadata) != nil {
//                        menu.append(livePhotoSave)
//                    }
//                } else {
//                    menu.append(favorite)
//                    menu.append(share)
//
//                    if self.database.getMetadataLivePhoto(metadata: metadata) != nil {
//                        menu.append(livePhotoSave)
//                    }
//
//                    if viewController is NCMedia {
//                        menu.append(viewInFolder)
//                    }
//
//                    // MODIFY WITH QUICK LOOK
//                    if metadata.isModifiableWithQuickLook {
//                        menu.append(modify)
//                    }
//
//                    if viewController is NCMedia {
//                        menu.append(deleteConfirmFile)
//                    } else {
//                        menu.append(deleteSubMenu)
//                    }
//                }
//                return UIMenu(title: "", children: [detail, UIMenu(title: "", options: .displayInline, children: menu)])
//            }
//        } else {
//            return UIMenu()
//        }
        
        if metadata.directory {
            let serverUrlHome = utilityFileSystem.getHomeServer(urlBase: metadata.urlBase, userId: metadata.userId)
            let isEncryptionDisabled = metadata.canUnsetDirectoryAsE2EE
            let isEncrytptionEnabled = metadata.serverUrl == serverUrlHome && metadata.canSetDirectoryAsE2EE
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
            
            if (metadata.contentType != "image/svg+xml") && (metadata.classFile == NKTypeClassFile.image.rawValue || metadata.classFile == NKTypeClassFile.video.rawValue) {
                children.insert(save, at: 2)
            }
            
            if !metadata.e2eEncrypted, (metadata.contentType != "image/svg+xml") && (metadata.classFile == NKTypeClassFile.image.rawValue || metadata.contentType == "application/pdf" || metadata.contentType == "com.adobe.pdf") {
                children.insert(print, at: 2)
            }
            
            if !metadata.e2eEncrypted {
                if viewController is NCMedia {
                    children.insert(viewInFolder, at: children.count - 1)
                }
            }
            
            if (!metadata.isDirectoryE2EE && metadata.contentType != "image/gif" && metadata.contentType != "image/svg+xml") && (metadata.contentType == "com.adobe.pdf" || metadata.contentType == "application/pdf" || metadata.classFile == NKTypeClassFile.image.rawValue) {
                children.insert(modify, at: children.count - 1)
            }
            
            let submenu = UIMenu(title: "", options: .displayInline, children: children)
            let capabilities = NCNetworking.shared.capabilities[metadata.account] ?? NKCapabilities.Capabilities()
            guard (!capabilities.fileSharingApiEnabled && !capabilities.filesComments && capabilities.activity.isEmpty) == false else { return submenu }
            let childrenArray = metadata.isDirectoryE2EE ? [submenu] : [detail, submenu]
            return UIMenu(title: "", children: childrenArray)
        }
    }
}
