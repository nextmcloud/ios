//
//  NCMenuAction.swift
//  Nextcloud
//
//  Created by Henrik Storch on 17.02.22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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
import UIKit
import NextcloudKit
import SVGKit

class NCMenuAction {
    let accessibilityIdentifier: String?
    let title: String
    let boldTitle: Bool
    let details: String?
    let icon: UIImage
    let selectable: Bool
    var onTitle: String?
    var onIcon: UIImage?
    let destructive: Bool
    var selected: Bool = false
    var isOn: Bool = false
    var action: ((_ menuAction: NCMenuAction) -> Void)?
    var rowHeight: CGFloat { self.title == NCMenuAction.seperatorIdentifier ? NCMenuAction.seperatorHeight : self.details != nil ? 76 : 56 }
    var order: Int = 0

    init(title: String, boldTitle: Bool = false, destructive: Bool = false, details: String? = nil, icon: UIImage, order: Int = 0, accessibilityIdentifier: String? = nil, action: ((_ menuAction: NCMenuAction) -> Void)?) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.title = title
        self.boldTitle = boldTitle
        self.destructive = destructive
        self.details = details
        self.icon = icon
        self.action = action
        self.selectable = false
        self.order = order
    }

    init(title: String, boldTitle: Bool = false, destructive: Bool = false, details: String? = nil, icon: UIImage, onTitle: String? = nil, onIcon: UIImage? = nil, selected: Bool, on: Bool, order: Int = 0, accessibilityIdentifier: String? = nil, action: ((_ menuAction: NCMenuAction) -> Void)?) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.title = title
        self.boldTitle = boldTitle
        self.destructive = destructive
        self.details = details
        self.icon = icon
        self.onTitle = onTitle ?? title
        self.onIcon = onIcon ?? icon
        self.action = action
        self.selected = selected
        self.isOn = on
        self.selectable = true
        self.order = order
    }
}

// MARK: - Actions

extension NCMenuAction {
    static let seperatorIdentifier = "NCMenuAction.SEPARATOR"
    static let seperatorHeight: CGFloat = 0.5

    /// A static seperator, with no actions, text, or icons
    static func seperator(order: Int = 0) -> NCMenuAction {
        return NCMenuAction(title: seperatorIdentifier, icon: UIImage(), order: order, action: nil)
    }

    /// Select all items
    static func selectAllAction(action: @escaping () -> Void) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_select_all_", comment: ""),
            icon: NCUtility().loadImage(named: "checkmark.circle.fill", colors: [NCBrandColor.shared.iconColor]),
            action: { _ in action() }
        )
    }

    /// Cancel
    static func cancelAction(action: @escaping () -> Void) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_cancel_", comment: ""),
            icon: NCUtility().loadImage(named: "xmark", colors: [NCBrandColor.shared.iconColor]),
            action: { _ in action() }
        )
    }

    /// Delete files either from cache or from Nextcloud
    static func deleteAction(selectedMetadatas: [tableMetadata], metadataFolder: tableMetadata? = nil, controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        var titleDelete = NSLocalizedString("_delete_", comment: "")
        var message = NSLocalizedString("_want_delete_", comment: "")
        var icon = "trash"
        var destructive = false
        var color = NCBrandColor.shared.iconColor
        let permissions = NCPermissions()

        if selectedMetadatas.count > 1 {
            titleDelete = NSLocalizedString("_delete_selected_files_", comment: "")
            destructive = true
        } else if let metadata = selectedMetadatas.first {
            if NCManageDatabase.shared.isMetadataShareOrMounted(metadata: metadata, metadataFolder: metadataFolder) {
                titleDelete = NSLocalizedString("_leave_share_", comment: "")
                message = NSLocalizedString("_want_leave_share_", comment: "")
                icon = "person.2.slash"
            } else if metadata.directory {
                titleDelete = NSLocalizedString("_delete_folder_", comment: "")
                destructive = true
            } else {
                titleDelete = NSLocalizedString("_delete_file_", comment: "")
                destructive = true
            }

            if let metadataFolder = metadataFolder {
                let isShare = metadata.permissions.contains(permissions.permissionShared) && !metadataFolder.permissions.contains(permissions.permissionShared)
                let isMounted = metadata.permissions.contains(permissions.permissionMounted) && !metadataFolder.permissions.contains(permissions.permissionMounted)
                if isShare || isMounted {
                    titleDelete = NSLocalizedString("_leave_share_", comment: "")
                    icon = "person.2.slash"
                }
            }
        } // else: no metadata selected

        let canDeleteServer = selectedMetadatas.allSatisfy { !$0.lock }
        var fileList = ""
        for (ix, metadata) in selectedMetadatas.enumerated() {
            guard ix < 3 else { fileList += "\n - ..."; break }
            fileList += "\n - " + metadata.fileNameView
        }
        if destructive { color = .red }

        return NCMenuAction(
            title: titleDelete,
            destructive: destructive,
            icon: NCUtility().loadImage(named: icon, colors: [color]),
            order: order,
            action: { _ in
                let alertController = UIAlertController.deleteFileOrFolder(titleString: titleDelete + "?", message: message + fileList, canDeleteServer: canDeleteServer, selectedMetadatas: selectedMetadatas, sceneIdentifier: controller?.sceneIdentifier) { _ in
                    completion?()
                }

                controller?.present(alertController, animated: true, completion: nil)
            })
    }

    /// Open "share view" (activity VC) to open files in another app
    static func share(selectedMetadatas: [tableMetadata], controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_open_in_", comment: ""),
            icon: NCUtility().loadImage(named: "open_file",colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                NCActionCenter.shared.openActivityViewController(selectedMetadata: selectedMetadatas, controller: controller)
                completion?()
            }
        )
    }

    /// Set (or remove) a file as *available offline*. Downloads the file if not downloaded already
    static func setAvailableOfflineAction(selectedMetadatas: [tableMetadata], isAnyOffline: Bool, viewController: UIViewController, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: isAnyOffline ? NSLocalizedString("_remove_available_offline_", comment: "") : NSLocalizedString("_set_available_offline_", comment: ""),
            icon: NCUtility().loadImage(named: "offlineMenu", colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                if !isAnyOffline, selectedMetadatas.count > 3 {
                    let alert = UIAlertController(
                        title: NSLocalizedString("_set_available_offline_", comment: ""),
                        message: NSLocalizedString("_select_offline_warning_", comment: ""),
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_continue_", comment: ""), style: .default, handler: { _ in
                        selectedMetadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
                        completion?()
                    }))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))
                    viewController.present(alert, animated: true)
                } else {
                    selectedMetadatas.forEach { NCActionCenter.shared.setMetadataAvalableOffline($0, isOffline: isAnyOffline) }
                    completion?()
                }
            }
        )
    }
    
    /// Copy files to pasteboard
    static func copyAction(selectOcId: [String], viewController: UIViewController, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_copy_file_", comment: ""),
            icon: NCUtility().loadImage(named: "copy", colors: [NCBrandColor.shared.iconImageColor]),
            order: order,
            action: { _ in
                NCActionCenter.shared.copyPasteboard(pasteboardOcIds: selectOcId, viewController: viewController)
                completion?()
            }
        )
    }

    
    /// Open view that lets the user move or copy the files within Nextcloud
    static func moveOrCopyAction(selectedMetadatas: [tableMetadata], viewController: UIViewController, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
    static func copyAction(fileSelect: [String], controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_copy_file_", comment: ""),
            icon: NCUtility().loadImage(named: "copy", colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                NCActionCenter.shared.copyPasteboard(pasteboardOcIds: selectOcId, viewController: viewController)
                completion?()
            }
        )
    }

    
    /// Open view that lets the user move or copy the files within Nextcloud
    static func moveOrCopyAction(selectedMetadatas: [tableMetadata], controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_move_or_copy_", comment: ""),
            icon: NCUtility().loadImage(named: "move", colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
//                var fileNameError: NKError?
//
//                for metadata in selectedMetadatas {
//                    if let sceneIdentifier = metadata.sceneIdentifier,
//                       let controller = SceneManager.shared.getController(sceneIdentifier: sceneIdentifier),
//                       let checkError = FileNameValidator.checkFileName(metadata.fileNameView, account: controller.account) {
//
//                        fileNameError = checkError
//                        break
//                    }
//                }
//
//                if let fileNameError {
//                    viewController.present(UIAlertController.warning(message: "\(fileNameError.errorDescription) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true, completion: nil)
//                } else {
//                    let controller = viewController.tabBarController as? NCMainTabBarController
//                    NCActionCenter.shared.openSelectView(items: selectedMetadatas, controller: controller)
//                    completion?()
//                }
                NCActionCenter.shared.openSelectView(items: selectedMetadatas, controller: controller)
                completion?()
            }
        )
    }

    /// Lock or unlock a file using *files_lock*
    static func lockUnlockFiles(shouldLock: Bool, metadatas: [tableMetadata], order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        let titleKey: String
        if metadatas.count == 1 {
            titleKey = shouldLock ? "_lock_file_" : "_unlock_file_"
        } else {
            titleKey = shouldLock ? "_lock_selected_files_" : "_unlock_selected_files_"
        }
        let imageName = !shouldLock ? "lock_open" : "lock"
        return NCMenuAction(
            title: NSLocalizedString(titleKey, comment: ""),
            icon: NCUtility().loadImage(named: imageName, colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                for metadata in metadatas where metadata.lock != shouldLock {
                    NCNetworking.shared.lockUnlockFile(metadata, shoulLock: shouldLock)
                }
                completion?()
            }
        )
    }
    
    /// Open "share view" (activity VC) to open files in another app
    static func openInAction(selectedMetadatas: [tableMetadata], controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_open_in_", comment: ""),
            icon: NCUtility().loadImage(named: "open_file",colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                NCActionCenter.shared.openActivityViewController(selectedMetadata: selectedMetadatas, controller: controller)
                completion?()
            }
        )
    }

    /// Save selected files to user's photo library
    static func saveMediaAction(selectedMediaMetadatas: [tableMetadata], controller: NCMainTabBarController?, order: Int = 0, completion: (() -> Void)? = nil) -> NCMenuAction {
        var title: String = NSLocalizedString("_save_selected_files_", comment: "")
        var icon = NCUtility().loadImage(named: "save_files",colors: [NCBrandColor.shared.iconColor])
        if selectedMediaMetadatas.allSatisfy({ NCManageDatabase.shared.getMetadataLivePhoto(metadata: $0) != nil }) {
            title = NSLocalizedString("_livephoto_save_", comment: "")
            icon = NCUtility().loadImage(named: "livephoto")
        }

        return NCMenuAction(
            title: title,
            icon: icon,
            order: order,
            action: { _ in
                for metadata in selectedMediaMetadatas {
                    if let metadataMOV = NCManageDatabase.shared.getMetadataLivePhoto(metadata: metadata) {
                        NCNetworking.shared.saveLivePhotoQueue.addOperation(NCOperationSaveLivePhoto(metadata: metadata, metadataMOV: metadataMOV, hudView: controller?.view ?? UIView()))
                    } else {
                        if NCUtilityFileSystem().fileProviderStorageExists(metadata) {
                            NCActionCenter.shared.saveAlbum(metadata: metadata, controller: controller)
                        } else {
                            if NCNetworking.shared.downloadQueue.operations.filter({ ($0 as? NCOperationDownload)?.metadata.ocId == metadata.ocId }).isEmpty {
                                NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: metadata, selector: NCGlobal.shared.selectorSaveAlbum))
                            }
                        }
                    }
                }
                completion?()
            }
        )
    }
    
    /// Open AirPrint view to print a single file
    static func printAction(metadata: tableMetadata, order: Int = 0) -> NCMenuAction {
        NCMenuAction(
            title: NSLocalizedString("_print_", comment: ""),
            icon: NCUtility().loadImage(named: "printer", colors: [NCBrandColor.shared.iconColor]),
            order: order,
            action: { _ in
                if NCUtilityFileSystem().fileProviderStorageExists(metadata) {
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDownloadedFile, userInfo: ["ocId": metadata.ocId, "selector": NCGlobal.shared.selectorPrint, "error": NKError(), "account": metadata.account, "ocIdTransfer": metadata.ocIdTransfer])
                } else {
                    NCNetworking.shared.downloadQueue.addOperation(NCOperationDownload(metadata: metadata, selector: NCGlobal.shared.selectorPrint))
                }
           }
        )
    }
    
    // MARK: - Print

    static func printDocument(metadata: tableMetadata) {

        let fileNameURL = URL(fileURLWithPath: NCUtilityFileSystem().getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView))
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)

        printInfo.jobName = fileNameURL.lastPathComponent
        printInfo.outputType = metadata.isImage ? .photo : .general
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true

        guard !UIPrintInteractionController.canPrint(fileNameURL) else {
            printController.printingItem = fileNameURL
            printController.present(animated: true)
            return
        }

        // can't print without data
        guard let data = try? Data(contentsOf: fileNameURL) else { return }

        if let svg = SVGKImage(data: data) {
            printController.printingItem = svg.uiImage
            printController.present(animated: true)
            return
        }

        guard let text = String(data: data, encoding: .utf8) else { return }
        let formatter = UISimpleTextPrintFormatter(text: text)
        formatter.perPageContentInsets.top = 72
        formatter.perPageContentInsets.bottom = 72
        formatter.perPageContentInsets.left = 72
        formatter.perPageContentInsets.right = 72
        printController.printFormatter = formatter
        printController.present(animated: true)
    }
}
