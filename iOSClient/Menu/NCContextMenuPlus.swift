// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import NextcloudKit

@MainActor
class NCContextMenuPlus: NSObject {
    struct CreatorMenuInfo {
        let titleKey: String
        let templateId: String
        let icon: String
        let sortOrder: Int
    }

    let menuToolbar: UIToolbar?
    let controller: NCMainTabBarController?

    internal var windowScene: UIWindowScene? {
        SceneManager.shared.getWindowScene(controller: controller)
    }

    init(menuToolbar: UIToolbar?, controller: NCMainTabBarController?) {
        self.menuToolbar = menuToolbar
        self.controller = controller
    }

    nonisolated static func menuInfo(for ext: String) -> CreatorMenuInfo? {
        switch ext.lowercased() {
        case "docx":
            return CreatorMenuInfo(titleKey: "_create_new_document_", templateId: "document", icon: "doc.text", sortOrder: 0)
        case "xlsx":
            return CreatorMenuInfo(titleKey: "_create_new_spreadsheet_", templateId: "spreadsheet", icon: "tablecells", sortOrder: 1)
        case "pptx":
            return CreatorMenuInfo(titleKey: "_create_new_presentation_", templateId: "presentation", icon: "play.rectangle", sortOrder: 2)
        default:
            return nil
        }
    }

    func create(session: NCSession.Session) async {
        guard let controller, let menuToolbar else {
            return
        }
        let capabilities = await NCManageDatabase.shared.getCapabilities(account: session.account) ?? NKCapabilities.Capabilities()
        let utilityFileSystem = NCUtilityFileSystem()
        let utility = NCUtility()
        let serverUrl = controller.currentServerUrl()

        let isDirectoryE2EE = await NCUtilityFileSystem().isDirectoryE2EEAsync(serverUrl: serverUrl, urlBase: session.urlBase, userId: session.userId, account: session.account)
        let directory = await NCManageDatabase.shared.getTableDirectoryAsync(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", session.account, serverUrl))
        let isNetworkReachable = NextcloudKit.shared.isNetworkReachable()
        let titleCreateFolder = isDirectoryE2EE ? NSLocalizedString("_create_folder_e2ee_", comment: "") : NSLocalizedString("_create_folder_", comment: "")
        let imageCreateFolder = isDirectoryE2EE ? NCImageCache.shared.getFolderEncrypted() : NCImageCache.shared.getFolder()

        var menuActionElement: [UIMenuElement] = []
        var menuE2EEElement: [UIMenuElement] = []
        var menuTextElement: [UIMenuElement] = []
        var menuDirectEditingElement: [UIMenuElement] = []
        var menuRichDocumentElement: [UIMenuElement] = []
        var menuOnlyOfficeElement: [UIMenuElement] = []

        // ------------------------------- ACTION

        menuActionElement.append(UIAction(title: NSLocalizedString("_upload_photos_videos_", comment: ""),
                                          image: UIImage(named: "file_photo_menu")!.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
            NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
                if hasPermission {
                    DispatchQueue.main.async {
                        NCPhotosPickerViewController(controller: controller, maxSelectedAssets: 0, singleSelectedMode: false)
                    }
                }
            }
        })

        menuActionElement.append(UIAction(title: NSLocalizedString("_upload_file_", comment: ""),
                                          image: UIImage(named: "uploadFile")!.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
            DispatchQueue.main.async {
                controller.documentPickerViewController = NCDocumentPickerViewController(controller: controller, isViewerMedia: false, allowsMultipleSelection: true)
            }
        })

        menuActionElement.append(UIAction(title: NSLocalizedString("_scans_document_", comment: ""),
                                          image: utility.loadImage(named: "scan", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
            DispatchQueue.main.async {
                NCDocumentCamera.shared.openScannerDocument(viewController: controller)
            }
        })

        menuActionElement.append(UIAction(title: NSLocalizedString("_create_voice_memo_", comment: ""),
                                          image: UIImage(named: "microphoneMenu")!.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
            NCAskAuthorization().askAuthorizationAudioRecord(controller: controller) { hasPermission in
                if hasPermission {
                    DispatchQueue.main.async {
                        if let viewController = UIStoryboard(name: "NCAudioRecorderViewController", bundle: nil).instantiateInitialViewController() as? NCAudioRecorderViewController {
                            viewController.controller = controller
                            viewController.modalTransitionStyle = .crossDissolve
                            viewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                            controller.present(viewController, animated: true, completion: nil)
                        }
                    }
                }
            }
        })

        menuActionElement.append(UIAction(title: titleCreateFolder,
                                          image: imageCreateFolder) { _ in
            DispatchQueue.main.async {
                let alertController = UIAlertController.createFolderWith(
                    serverUrl: serverUrl,
                    session: session,
                    sceneIdentifier: controller.sceneIdentifier,
                    capabilities: capabilities) { error in
                        if error != .success {
                            Task {
                                await showErrorBanner(windowScene: self.windowScene,
                                                      text: error.errorDescription,
                                                      errorCode: error.errorCode)
                            }
                        }
                    }
                controller.present(alertController, animated: true, completion: nil)
            }
        })

        // ------------------------------- E2EE

        if serverUrl == utilityFileSystem.getHomeServer(session: session),
           NCPreferences().isEndToEndEnabled(account: session.account),
           isNetworkReachable {
            menuE2EEElement.append(UIAction(title: NSLocalizedString("_create_folder_e2ee_", comment: ""),
                                            image: NCImageCache.shared.getFolderEncrypted()) { _ in
                DispatchQueue.main.async {
                    let alertController = UIAlertController.createFolderWith(
                        serverUrl: serverUrl,
                        session: session,
                        markE2ee: true,
                        sceneIdentifier: controller.sceneIdentifier,
                        capabilities: capabilities) { error in
                            if error != .success {
                                Task {
                                    await showErrorBanner(windowScene: self.windowScene,
                                                          text: error.errorDescription,
                                                          errorCode: error.errorCode)
                                }
                            }
                        }
                    controller.present(alertController, animated: true, completion: nil)
                }
            })
        }

        // ------------------------------- RICHDOCUMENT TEXT

        if NCBrandOptions.shared.isServerVersion(capabilities, greaterOrEqualTo: .v18),
           directory?.richWorkspace == nil,
           !isDirectoryE2EE,
           isNetworkReachable {
            menuTextElement.append(UIAction(title: NSLocalizedString("_add_folder_info_", comment: ""),
                                            image: UIImage(named: "addFolderInfo")!.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
                Task { @MainActor in
                    let richWorkspaceCommon = NCRichWorkspaceCommon()
                    if let viewController = controller.currentViewController() {
                        if await NCManageDatabase.shared.getMetadataAsync(
                            predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView LIKE[c] %@",
                                                   session.account,
                                                   serverUrl,
                                                   NCGlobal.shared.fileNameRichWorkspace.lowercased())) == nil {
                            richWorkspaceCommon.createViewerNextcloudText(serverUrl: serverUrl, viewController: viewController, controller: controller, session: session)
                        } else {
                            richWorkspaceCommon.openViewerNextcloudText(serverUrl: serverUrl, viewController: viewController, controller: controller, session: session)
                        }
                    }
                }
            })
        }

        if isNetworkReachable,
           let creator = capabilities.directEditingCreators.first(where: { $0.editor == "text" }),
           !isDirectoryE2EE {
            menuTextElement.append(UIAction(title: NSLocalizedString("_create_nextcloudtext_document_", comment: ""),
                                            image: UIImage(named: "file_txt_menu")!.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
                Task {
                    guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                        return
                    }
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
                    if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                        viewController.editorId = NCGlobal.shared.editorText
                        viewController.creatorId = creator.identifier
                        viewController.typeTemplate = NCGlobal.shared.editorText
                        viewController.serverUrl = serverUrl
                        viewController.titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                        viewController.controller = controller
                        controller.present(navigationController, animated: true, completion: nil)
                    }
                }
            })
        }

        // ------------------------------- WEB EDITORS

        if isNetworkReachable,
           !isDirectoryE2EE {

            // ------------------------------- COLLABORA
            if capabilities.richDocumentsEnabled {
                menuRichDocumentElement.append(UIAction(title: NSLocalizedString("_create_new_document_", comment: ""),
                                                        image: UIImage(named: "create_file_document")!.resizeImage(size: CGSize(width: 24, height: 24))) { _ in
                    
                    guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                        return
                    }
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                    if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                        viewController.editorId = NCGlobal.shared.editorCollabora
                        viewController.typeTemplate = NCGlobal.shared.templateDocument
                        viewController.serverUrl = serverUrl
                        viewController.titleForm = NSLocalizedString("_create_new_document_", comment: "")
                        viewController.controller = controller
                        controller.present(navigationController, animated: true, completion: nil)
                    }
                })

                menuRichDocumentElement.append(UIAction(title: NSLocalizedString("_create_new_spreadsheet_", comment: ""),
                                                        image: UIImage(named: "create_file_xls")!.resizeImage(size: CGSize(width: 24, height: 24))) { _ in
                    
                    guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                        return
                    }
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                    if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                        viewController.editorId = NCGlobal.shared.editorCollabora
                        viewController.typeTemplate = NCGlobal.shared.templateSpreadsheet
                        viewController.serverUrl = serverUrl
                        viewController.titleForm = NSLocalizedString("_create_new_spreadsheet_", comment: "")
                        viewController.controller = controller
                        controller.present(navigationController, animated: true, completion: nil)
                    }
                })

                menuRichDocumentElement.append(UIAction(title: NSLocalizedString("_create_new_presentation_", comment: ""),
                                                        image: UIImage(named: "create_file_ppt")!.resizeImage(size: CGSize(width: 24, height: 24))) { _ in
                    
                    guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                        return
                    }
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet

                    if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                        viewController.editorId = NCGlobal.shared.editorCollabora
                        viewController.typeTemplate = NCGlobal.shared.templatePresentation
                        viewController.serverUrl = serverUrl
                        viewController.titleForm = NSLocalizedString("_create_new_presentation_", comment: "")
                        viewController.controller = controller
                        controller.present(navigationController, animated: true, completion: nil)
                    }
                })
            }

            // ------------------------------- DIRECT EDITING CREATORS (onlyoffice, eurooffice, …)

            let creatorsByEditor = Dictionary(grouping: capabilities.directEditingCreators, by: \.editor)
            for editorId in creatorsByEditor.keys.sorted() {
                guard NCDirectEditorAdapter.resolve(from: [editorId]) != nil,
                      editorId != "text" else { continue }

                let sortedCreators = creatorsByEditor[editorId]!
                    .compactMap { creator -> (NKEditorDetailsCreator, CreatorMenuInfo)? in
                        guard let info = NCContextMenuPlus.menuInfo(for: creator.ext) else { return nil }
                        return (creator, info)
                    }
                    .sorted { $0.1.sortOrder < $1.1.sortOrder }

                for (creator, info) in sortedCreators {
                    menuDirectEditingElement.append(UIAction(
                        title: NSLocalizedString(info.titleKey, comment: ""),
                        image: utility.loadImage(named: info.icon, colors: [info.iconColor])
                    ) { _ in
                        Task { @MainActor in
                            let createDocument = NCCreate()
                            let fileExt: String
                            let templateIdentifier: String
                            if creator.templates {
                                let result = await createDocument.getTemplate(editorId: editorId, templateId: info.templateId, account: session.account)
                                fileExt = result.ext
                                templateIdentifier = result.selectedTemplate.identifier
                            } else {
                                fileExt = creator.ext
                                templateIdentifier = ""
                            }
                            var titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                            switch creator.identifier {
                            case "onlyoffice_docx":
                                titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")

                            case "onlyoffice_xlsx":
                                titleForm = NSLocalizedString("_create_new_spreadsheet_", comment: "")

                            case "onlyoffice_pptx":
                                titleForm = NSLocalizedString("_create_new_presentation_", comment: "")

                            default:
                                titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                            }
                            
                            guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() else {
                                return
                            }
                            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
                            if let viewController = (navigationController as? UINavigationController)?.topViewController as? NCCreateFormUploadDocuments {
                                viewController.editorId = NCGlobal.shared.editorOnlyoffice
                                viewController.creatorId = creator.identifier
                                viewController.typeTemplate = templateIdentifier//NCGlobal.shared.templateDocument
                                viewController.serverUrl = serverUrl
                                viewController.titleForm = titleForm //NSLocalizedString("_create_nextcloudtext_document_", comment: "")
                                viewController.controller = controller
                                controller.present(navigationController, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }

        let menuAction = UIMenu(title: "", options: .displayInline, children: menuActionElement)
        let menuText = UIMenu(title: "", options: .displayInline, children: menuTextElement)
        let menuE2EE = UIMenu(title: "", options: .displayInline, children: menuE2EEElement)
        let menuDirectEditing = UIMenu(title: "", options: .displayInline, children: menuDirectEditingElement)
        let menuRichDocument = UIMenu(title: "", options: .displayInline, children: menuRichDocumentElement)
        let menuOnlyOffice = UIMenu(title: "", options: .displayInline, children: menuOnlyOfficeElement)

        let plusMenu = UIMenu(children: [menuAction, menuE2EE, menuText, menuRichDocument, menuDirectEditing])

        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .thin)
        let plusImage = UIImage(systemName: "plus.circle.fill", withConfiguration: config)

        if let plusItem = menuToolbar.items?.first {
            plusItem.menu = plusMenu
        } else {
            let plusItem = UIBarButtonItem(image: plusImage, style: .plain, target: nil, action: nil)
//            plusItem.tintColor = NCBrandColor.shared.getElement(account: session.account)
            plusItem.tintColor = NCBrandColor.shared.customer
            plusItem.menu = plusMenu
            menuToolbar.setItems([plusItem], animated: false)
            menuToolbar.sizeToFit()
            menuToolbar.alpha = 1
        }

        // E2EE Offile disable
        if !isNetworkReachable, isDirectoryE2EE {
            menuToolbar.items?.first?.isEnabled = false
        } else {
            menuToolbar.items?.first?.isEnabled = true
        }
    }

    @MainActor
    func hiddenPlusButton(_ isHidden: Bool, animation: Bool = true) {
        guard let menuToolbar else {
            return
        }
        let tx = 200.0
        if isHidden {
            if menuToolbar.transform.tx == tx {
                menuToolbar.alpha = 0
                return
            }
            if animation {
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
                    menuToolbar.transform = CGAffineTransform(translationX: tx, y: 0)
                    menuToolbar.alpha = 0
                })
            } else {
                menuToolbar.transform = CGAffineTransform(translationX: tx, y: 0)
                menuToolbar.alpha = 0
            }
        } else {
            if menuToolbar.transform.tx == 0.0 {
                menuToolbar.alpha = 1
                return
            }
            if animation {
                UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                    menuToolbar.transform = .identity
                    menuToolbar.alpha = 1
                })
            } else {
                menuToolbar.transform = .identity
                menuToolbar.alpha = 1
            }
        }
    }

    @MainActor
    func resetPlusButtonAlpha(animated: Bool = true) {
        guard let menuToolbar else {
            return
        }
        let update = {
            menuToolbar.alpha = 1.0
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: update)
        } else {
            update()
        }
    }
}

@MainActor
extension NCContextMenuPlus.CreatorMenuInfo {
    var iconColor: UIColor {
        switch templateId {
        case "spreadsheet": return NCBrandColor.shared.spreadsheetIconColor
        case "presentation": return NCBrandColor.shared.presentationIconColor
        default: return NCBrandColor.shared.documentIconColor
        }
    }
}
