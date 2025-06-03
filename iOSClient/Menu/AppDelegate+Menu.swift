//
//  AppDelegate+Menu.swift
//  Nextcloud
//
//  Created by Philippe Weidmann on 24.01.20.
//  Copyright © 2020 Philippe Weidmann. All rights reserved.
//  Copyright © 2020 Marino Faggiana All rights reserved.
//
//  Author Philippe Weidmann <philippe.weidmann@infomaniak.com>
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

extension AppDelegate {
    func toggleMenu(controller: NCMainTabBarController, sender: Any?) {
        var actions: [NCMenuAction] = []
        let session = NCSession.shared.getSession(controller: controller)
        let directEditingCreators = NCManageDatabase.shared.getDirectEditingCreators(account: session.account)
        let serverUrl = controller.currentServerUrl()
        let isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(serverUrl: serverUrl, account: session.account)
        let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", session.account, serverUrl))
        let utility = NCUtility()

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_upload_photos_videos_", comment: ""), icon: UIImage(named: "file_photo_menu")!.image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                title: NSLocalizedString("_upload_photos_videos_", comment: ""),
                icon: UIImage(named: "file_photo_menu")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                sender: sender,
                action: { _ in
                    NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
                        if hasPermission {NCPhotosPickerViewController(controller: controller, maxSelectedAssets: 0, singleSelectedMode: false)
                        }
                    }
                }
            )
        )

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_upload_file_", comment: ""), icon: UIImage(named: "uploadFile")!.image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                title: NSLocalizedString("_upload_file_", comment: ""),
                icon: UIImage(named: "uploadFile")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                sender: sender,
                action: { _ in
                    controller.documentPickerViewController = NCDocumentPickerViewController(controller: controller, isViewerMedia: false, allowsMultipleSelection: true)
                }
            )
        )

        if NextcloudKit.shared.isNetworkReachable() && directEditingCreators != nil && directEditingCreators!.contains(where: { $0.editor == NCGlobal.shared.editorText}) && !isDirectoryE2EE {
            actions.append(
                NCMenuAction(title: NSLocalizedString("_create_nextcloudtext_document_", comment: ""), icon: UIImage(named: "file_txt_menu")!.image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                NCMenuAction(title: NSLocalizedString("_create_nextcloudtext_document_", comment: ""),
                             icon: UIImage(named: "file_txt_menu")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                             sender: sender,
                             action: { _ in
                    let directEditingCreator = directEditingCreators!.first(where: { $0.editor == NCGlobal.shared.editorText})!
                    guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                        return
                    }
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
                    if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                        viewController.editorId = NCGlobal.shared.editorText
                        viewController.creatorId = directEditingCreator.identifier
                        viewController.typeTemplate = NCGlobal.shared.editorText
                        viewController.serverUrl = appDelegate.activeServerUrl
                        viewController.titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                        appDelegate.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
                        viewController.serverUrl = serverUrl
                        viewController.titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                        controller.present(navigationController, animated: true, completion: nil)
                    }
                })
            )
        }

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_scans_document_", comment: ""), icon: NCUtility().loadImage(named: "scan").image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                title: NSLocalizedString("_scans_document_", comment: ""),
                icon: NCUtility().loadImage(named: "scan").image(color: NCBrandColor.shared.iconColor, size: 50),
                sender: sender,
                action: { _ in
                    NCDocumentCamera.shared.openScannerDocument(viewController: controller)
                }
            )
        )

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_create_voice_memo_", comment: ""), icon: UIImage(named: "microphoneMenu")!.image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                title: NSLocalizedString("_create_voice_memo_", comment: ""),
                icon: UIImage(named: "microphoneMenu")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                sender: sender,
                action: { _ in
                    NCAskAuthorization().askAuthorizationAudioRecord(viewController: controller) { hasPermission in
                        if hasPermission {
                            if let viewController = UIStoryboard(name: "NCAudioRecorderViewController", bundle: nil).instantiateInitialViewController() as? NCAudioRecorderViewController {
                                viewController.controller = controller
                                viewController.modalTransitionStyle = .crossDissolve
                                viewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                                controller.present(viewController, animated: true, completion: nil)
                            }
                        }
                    }
                }
            )
        )

        if NCKeychain().isEndToEndEnabled(account: session.account) {
            actions.append(.seperator(order: 0, sender: sender))
        }

        let titleCreateFolder = isDirectoryE2EE ? NSLocalizedString("_create_folder_e2ee_", comment: "") : NSLocalizedString("_create_folder_", comment: "")
        let imageCreateFolder = isDirectoryE2EE ? UIImage(named: "encryptedfolder")!.image(color: NCBrandColor.shared.iconColor, size: 50) : UIImage(named: "addFolder")!
        actions.append(
            NCMenuAction(title: titleCreateFolder,
                         icon: imageCreateFolder,
                         sender: sender,
                         action: { _ in
                             let alertController = UIAlertController.createFolder(serverUrl: serverUrl, session: session, sceneIdentifier: controller.sceneIdentifier)
                             controller.present(alertController, animated: true, completion: nil)
                         }
                        )
        )

        // Folder encrypted (ONLY ROOT)
        if !isDirectoryE2EE && NCKeychain().isEndToEndEnabled(account: appDelegate.account) && (NCUtilityFileSystem().getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId) == appDelegate.activeServerUrl) {
        if !isDirectoryE2EE && NCKeychain().isEndToEndEnabled(account: session.account) && (NCUtilityFileSystem().getHomeServer(session: session) == serverUrl) {
            actions.append(
                NCMenuAction(title: NSLocalizedString("_create_folder_e2ee_", comment: ""),
                             icon: UIImage(named: "encryptedfolder")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                             sender: sender,
                             action: { _ in
                                 let alertController = UIAlertController.createFolder(serverUrl: serverUrl, session: session, markE2ee: true, sceneIdentifier: controller.sceneIdentifier)
                                 controller.present(alertController, animated: true, completion: nil)
                             })
            )
        }

        if NCKeychain().isEndToEndEnabled(account: session.account) {
            actions.append(.seperator(order: 0, sender: sender))
        }

        if NCCapabilities.shared.getCapabilities(account: session.account).capabilityServerVersionMajor >= NCGlobal.shared.nextcloudVersion18 && directory?.richWorkspace == nil && !isDirectoryE2EE && NextcloudKit.shared.isNetworkReachable() {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_add_folder_info_", comment: ""), icon: UIImage(named: "addFolderInfo")!.image(color: NCBrandColor.shared.iconColor, size: 50), action: { _ in
                    title: NSLocalizedString("_add_folder_info_", comment: ""),
                    icon: UIImage(named: "addFolderInfo")!.image(color: NCBrandColor.shared.iconColor, size: 50),
                    sender: sender,
                    action: { _ in
                        let richWorkspaceCommon = NCRichWorkspaceCommon()
                        if let viewController = controller.currentViewController() {
                            if NCManageDatabase.shared.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView LIKE[c] %@",
                                                                                session.account,
                                                                                serverUrl,
                                                                                NCGlobal.shared.fileNameRichWorkspace.lowercased())) == nil {
                                richWorkspaceCommon.createViewerNextcloudText(serverUrl: serverUrl, viewController: viewController, session: session)
                            } else {
                                richWorkspaceCommon.openViewerNextcloudText(serverUrl: serverUrl, viewController: viewController, session: session)
                            }
                        }
                    }
                )
            )
        }

        if NextcloudKit.shared.isNetworkReachable() && directEditingCreators != nil && directEditingCreators!.contains(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficeDocx}) && !isDirectoryE2EE {
            let directEditingCreator = directEditingCreators!.first(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficeDocx})!
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_document_", comment: ""), icon: UIImage(named: "create_file_document")!, action: { _ in
                    title: NSLocalizedString("_create_new_document_", comment: ""),
                    icon: UIImage(named: "create_file_document")!,
                    sender: sender,
                    action: { _ in
//                        let createDocument = NCCreateDocument()
                        guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                            return
                        }
                        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                        if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                            viewController.editorId = NCGlobal.shared.editorOnlyoffice
                            viewController.creatorId = directEditingCreator.identifier
                            viewController.typeTemplate = NCGlobal.shared.templateDocument
                            viewController.serverUrl = serverUrl
                            viewController.titleForm = NSLocalizedString("_create_new_document_", comment: "")

                            controller.present(navigationController, animated: true, completion: nil)
                        }
                    }
                )
            )
        }

        if NextcloudKit.shared.isNetworkReachable() && directEditingCreators != nil && directEditingCreators!.contains(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficeXlsx}) && !isDirectoryE2EE {
            let directEditingCreator = directEditingCreators!.first(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficeXlsx})!
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_spreadsheet_", comment: ""), icon: UIImage(named: "create_file_xls")!, action: { _ in
                    title: NSLocalizedString("_create_new_spreadsheet_", comment: ""),
                    icon: UIImage(named: "create_file_xls")!,
                    sender: sender,
                    action: { _ in
//                        let createDocument = NCCreateDocument()
                        guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                            return
                        }
                        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                        if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                            viewController.editorId = NCGlobal.shared.editorOnlyoffice
                            viewController.creatorId = directEditingCreator.identifier
                            viewController.typeTemplate = NCGlobal.shared.templateSpreadsheet
                            viewController.serverUrl = serverUrl
                            viewController.titleForm = NSLocalizedString("_create_new_spreadsheet_", comment: "")

                            controller.present(navigationController, animated: true, completion: nil)
                        }
                    }
                )
            )
        }

        if NextcloudKit.shared.isNetworkReachable() && directEditingCreators != nil && directEditingCreators!.contains(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficePptx}) && !isDirectoryE2EE {
            let directEditingCreator = directEditingCreators!.first(where: { $0.editor == NCGlobal.shared.editorOnlyoffice && $0.identifier == NCGlobal.shared.onlyofficePptx})!
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_presentation_", comment: ""), icon: UIImage(named: "create_file_ppt")!, action: { _ in
                    title: NSLocalizedString("_create_new_presentation_", comment: ""),
                    icon: UIImage(named: "create_file_ppt")!,
                    sender: sender,
                    action: { _ in
//                        let createDocument = NCCreateDocument()
                        guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                            return
                        }
                        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                        if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                            viewController.editorId = NCGlobal.shared.editorOnlyoffice
                            viewController.creatorId = directEditingCreator.identifier
                            viewController.typeTemplate = NCGlobal.shared.templatePresentation
                            viewController.serverUrl = serverUrl
                            viewController.titleForm = NSLocalizedString("_create_new_presentation_", comment: "")

                            controller.present(navigationController, animated: true, completion: nil)
                        }
                    }
                )
            )
        }

        if NCCapabilities.shared.getCapabilities(account: session.account).capabilityRichDocumentsEnabled {
            if NextcloudKit.shared.isNetworkReachable() && !isDirectoryE2EE {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_document_", comment: ""), icon: UIImage(named: "create_file_document")!, action: { _ in
                        title: NSLocalizedString("_create_new_document_", comment: ""),
                        icon: UIImage(named: "create_file_document")!,
                        sender: sender,
                        action: { _ in
//                            let createDocument = NCCreateDocument()
                            guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                                return
                            }
                            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                            if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                                viewController.editorId = NCGlobal.shared.editorCollabora
                                viewController.typeTemplate = NCGlobal.shared.templateDocument
                                viewController.serverUrl = serverUrl
                                viewController.titleForm = NSLocalizedString("_create_new_document_", comment: "")

                                controller.present(navigationController, animated: true, completion: nil)
                            }
                        }
                    )
                )

                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_spreadsheet_", comment: ""), icon: UIImage(named: "create_file_xls")!, action: { _ in
                        title: NSLocalizedString("_create_new_spreadsheet_", comment: ""),
                        icon: UIImage(named: "create_file_xls")!,
                        sender: sender,
                        action: { _ in
//                            let createDocument = NCCreateDocument()
                            guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                                return
                            }
                            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                            if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                                viewController.editorId = NCGlobal.shared.editorCollabora
                                viewController.typeTemplate = NCGlobal.shared.templateSpreadsheet
                                viewController.serverUrl = serverUrl
                                viewController.titleForm = NSLocalizedString("_create_new_spreadsheet_", comment: "")

                                controller.present(navigationController, animated: true, completion: nil)
                            }
                        }
                    )
                )

                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_presentation_", comment: ""), icon: UIImage(named: "create_file_ppt")!, action: { _ in
                        title: NSLocalizedString("_create_new_presentation_", comment: ""),
                        icon: UIImage(named: "create_file_ppt")!,
                        sender: sender,
                        action: { _ in
//                            let createDocument = NCCreateDocument()
                            guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                                return
                            }
                            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                            if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                                viewController.editorId = NCGlobal.shared.editorCollabora
                                viewController.typeTemplate = NCGlobal.shared.templatePresentation
                                viewController.serverUrl = serverUrl
                                viewController.titleForm = NSLocalizedString("_create_new_presentation_", comment: "")

                                controller.present(navigationController, animated: true, completion: nil)
                            }
                        }
                    )
                )
            }
        }

//        controller.presentMenu(with: actions, controller: controller, sender: sender)
        AnalyticsHelper.shared.trackEvent(eventName: .EVENT__ACTION_BUTTON)
        controller.presentMenu(with: actions)
    }
}
