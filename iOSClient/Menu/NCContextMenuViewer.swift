// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Milen Pivchev
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

/// A context menu created to be used universally with the different `NCViewer`s.
/// See ``NCViewerImage``, ``NCViewerMedia``, ``NCViewerPDF`` for usage details.
@MainActor
class NCContextMenuViewer: NSObject {
    let metadata: tableMetadata
    let controller: NCMainTabBarController?
    let webView: Bool
    let sender: Any?
    private let database = NCManageDatabase.shared
    private let utility = NCUtility()

    internal var sceneIdentifier: String {
        controller?.sceneIdentifier ?? ""
    }
    
    internal var windowScene: UIWindowScene? {
       SceneManager.shared.getWindowScene(controller: controller)
    }

    init(metadata: tableMetadata, controller: NCMainTabBarController?, webView: Bool, sender: Any?) {
        self.metadata = metadata
        self.controller = controller
        self.webView = webView
        self.sender = sender
    }

    func viewMenu() -> UIMenu? {
        guard let metadata = database.getMetadataFromOcId(metadata.ocId),
              let controller,
              let capabilities = NCNetworking.shared.capabilities[metadata.account] else {
            return nil
        }

        var menuElements: [UIMenuElement] = []
        let localFile = database.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
        let isOffline = localFile?.offline == true

        // DETAIL
        if NCNetworking.shared.isOnline,
           !(!capabilities.fileSharingApiEnabled && !capabilities.filesComments && capabilities.activity.isEmpty), !metadata.isDirectoryE2EE, !metadata.e2eEncrypted {
            menuElements.append(makeDetailAction(metadata: metadata, controller: controller))
        }

        // VIEW IN FOLDER
        if !webView {
            menuElements.append(makeViewInFolderAction(metadata: metadata, controller: controller))
        }

        // FAVORITE
        if !metadata.lock, !metadata.isDirectoryE2EE, !metadata.e2eEncrypted {
            menuElements.append(makeFavoriteAction(metadata: metadata, controller: controller))
        }

        // OFFLINE
        if !webView, metadata.canSetAsAvailableOffline {
            menuElements.append(ContextMenuActions.setAvailableOffline(metadatas: [metadata], isAnyOffline: isOffline, controller: controller))
        }

        // LIVE PHOTO
        if !webView,
           NCNetworking.shared.isOnline,
           let metadataMOV = NCManageDatabase.shared.getMetadataLivePhoto(metadata: metadata) {
            menuElements.append(makeSaveLivePhotoAction(metadata: metadata, metadataMOV: metadataMOV))
        }

        //
        // SAVE CAMERA ROLL
        //
        if !webView, metadata.isSavebleInCameraRoll {
            menuElements.append(ContextMenuActions.saveMediaAction(selectedMediaMetadatas: [metadata], controller: controller))
        }
        
        // SHARE
        if !webView, metadata.canShare {
            menuElements.append(ContextMenuActions.share(metadatas: [metadata], controller: controller, sender: sender))
        }
        
        //
        // RENAME
        //
        if !webView, metadata.isRenameable, !metadata.isDirectoryE2EE {
            menuElements.append(
                UIAction(
                    title: NSLocalizedString("_rename_", comment: ""),
                    image: NCUtility().loadImage(named: "rename", colors: [NCBrandColor.shared.iconImageColor]).withTintColor(NCBrandColor.shared.iconImageColor),
                    ) { _ in

                        if let vcRename = UIStoryboard(name: "NCRenameFile", bundle: nil).instantiateInitialViewController() as? NCRenameFile {

                            vcRename.metadata = metadata
                            vcRename.disableChangeExt = true
//                                vcRename.imagePreview = imageIcon
//                                vcRename.indexPath = indexPath

                            let popup = NCPopupViewController(contentController: vcRename, popupWidth: vcRename.width, popupHeight: vcRename.height)

                            controller.present(popup, animated: true)
                        }
                    }
                )
        }
    
        //
        // ADD TO ALBUM
        //
        // Check if file is image or video and add "Add to Album" action
        if metadata.isImage || metadata.isVideo {
            menuElements.append(UIAction(
                title: NSLocalizedString("_add_to_album", comment: ""),
                image: NCUtility().loadImage(named: "plus", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor),
                handler: { _ in
                    // Present existing albums UI to add this media item
                    NCMediaNavigationController.presentExistingAlbums(presentingController: controller, selectedPhotos: [metadata.ocId], account: metadata.account)
                }
            ))
        }
        
        // COPY - MOVE
        if !webView, metadata.isCopyableMovable {
            menuElements.append(ContextMenuActions.moveOrCopy(
                metadatas: [metadata],
                account: metadata.account,
                controller: controller
            ))
        }
        
        // COPY IN PASTEBOARD
        if !webView, metadata.isCopyableInPasteboard, !metadata.isDirectoryE2EE {
//                menuElements.append(ContextMenuActions.copyAction(fileSelect: [metadata.ocId], controller: controller))
        }

        // PDF ACTIONS
        if metadata.isPDF {
            menuElements.append(contentsOf: makePDFActions())
        }

        // MODIFY WITH QUICK LOOK
        if !webView, metadata.isModifiableWithQuickLook {
            menuElements.append(makeModifyWithQuickLookAction(metadata: metadata))
        }
        
        // DELETE
        if !webView, metadata.isDeletable {
            menuElements.append(ContextMenuActions.delete(metadatas: [metadata], controller: controller))
        }

        return UIMenu(title: "", children: menuElements)
    }

    // MARK: - Private Action Makers

    private func makeDetailAction(metadata: tableMetadata, controller: NCMainTabBarController) -> UIAction {
        UIAction(
            title: NSLocalizedString("_details_", comment: ""),
            image: UIImage(named: "share")?.image(color: NCBrandColor.shared.iconImageColor, size: 22).withTintColor(NCBrandColor.shared.iconImageColor)
        ) { _ in
            NCCreate().createShare(controller: controller,
                                   metadata: metadata,
                                   page: .activity)
        }
    }

    private func makeViewInFolderAction(metadata: tableMetadata, controller: NCMainTabBarController) -> UIAction {
        UIAction(
            title: NSLocalizedString("_view_in_folder_", comment: ""),
            image: NCUtility().loadImage(named: "arrow.forward.square", colors: [NCBrandColor.shared.iconImageColor]).withTintColor(NCBrandColor.shared.iconImageColor)
        ) { _ in
            Task {
                await NCNetworking.shared.blinkInFolder(serverUrl: metadata.serverUrl,
                                                        fileName: metadata.fileName,
                                                        sceneIdentifier: controller.sceneIdentifier)
            }
        }
    }

    private func makeFavoriteAction(metadata: tableMetadata, controller: NCMainTabBarController) -> UIAction {
        UIAction(
            title: metadata.favorite
                ? NSLocalizedString("_remove_favorites_", comment: "")
                : NSLocalizedString("_add_favorites_", comment: ""),
            image: utility.loadImage(named: metadata.favorite ? "star" : "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
        ) { _ in
            Task {
                await NCNetworking.shared.setStatusWaitFavorite(metadata)
            }
        }
    }

    private func makePDFActions() -> [UIAction] {
        [
            UIAction(
                title: NSLocalizedString("_search_", comment: ""),
                image: UIImage(named: "search")?.withTintColor(NCBrandColor.shared.iconImageColor)
            ) { _ in
                NotificationCenter.default.postOnMainThread(
                    name: NCGlobal.shared.notificationCenterMenuSearchTextPDF
                )
            },
            UIAction(
                title: NSLocalizedString("_go_to_page_", comment: ""),
                image: UIImage(named: "go-to-page")?.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)
            ) { _ in
                NotificationCenter.default.postOnMainThread(
                    name: NCGlobal.shared.notificationCenterMenuGotToPageInPDF
                )
            }
        ]
    }

    private func makeSaveLivePhotoAction(metadata: tableMetadata, metadataMOV: tableMetadata) -> UIAction {
        return UIAction(
            title: NSLocalizedString("_livephoto_save_", comment: ""),
            image: utility.loadImage(named: "livephoto", colors: [NCBrandColor.shared.iconImageColor])
        ) { _ in
            NCNetworking.shared.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: metadata, metadataMOV: metadataMOV, windowScene: self.windowScene))
        }
    }
    
    private func makeModifyWithQuickLookAction(metadata: tableMetadata) -> UIAction {
        return UIAction(
            title: NSLocalizedString("_modify_", comment: ""),
            image: utility.loadImage(named: "pencil.tip.crop.circle", colors: [NCBrandColor.shared.iconImageColor]).withTintColor(NCBrandColor.shared.iconImageColor)
        ) { _ in
            Task {
                if NCUtilityFileSystem().fileProviderStorageExists(metadata) {
                    await NCNetworking.shared.transferDispatcher.notifyAllDelegates { delegate in
                        delegate.transferChange(
                            status: NCGlobal.shared.networkingStatusDownloaded,
                            account: metadata.account,
                            fileName: metadata.fileName,
                            serverUrl: metadata.serverUrl,
                            selector: NCGlobal.shared.selectorLoadFileQuickLook,
                            ocId: metadata.ocId,
                            destination: nil,
                            error: .success
                        )
                    }
                } else {
                    if let metadata = await NCManageDatabase.shared.setMetadataSessionInWaitDownloadAsync(
                        ocId: metadata.ocId,
                        session: NCNetworking.shared.sessionDownload,
                        selector: NCGlobal.shared.selectorLoadFileQuickLook,
                        sceneIdentifier: self.sceneIdentifier
                    ) {
                        await NCNetworking.shared.downloadFile(metadata: metadata)
                    }
                }
            }
        }
    }
}
