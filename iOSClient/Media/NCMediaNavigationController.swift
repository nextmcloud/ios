// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

class NCMediaNavigationController: NCMainNavigationController {

    // MARK: - Right

    override func setNavigationRightItems() async {
        guard let media = topViewController as? NCMedia else {
            return
        }

        if media.isEditMode {
            let select = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .plain) {
                media.setEditMode(false)
            }
            media.navigationItem.rightBarButtonItems = [select]
            media.tabBarSelect.show()
        } else {
            media.tabBarSelect.hide()
            await self.updateRightBarButtonItems()
        }
    }

    override func createRightMenu() async -> UIMenu? {
        guard let media = topViewController as? NCMedia else {
            return nil
        }
        let layoutForView = database.getLayoutForView(account: session.account, key: global.layoutViewMedia, serverUrl: "", layout: global.mediaLayoutRatio)
        var layout = layoutForView.layout
        // Overwrite default value
        if layout == global.layoutList {
            layout = global.mediaLayoutRatio
        }
        //
        let layoutTitle = (layout == global.mediaLayoutRatio) ? NSLocalizedString("_media_square_", comment: "") : NSLocalizedString("_media_ratio_", comment: "")
        let ratioImage = (layout == global.mediaLayoutRatio) ? "square-grid" : "ratio-grid"
        let layoutImage = utility.loadImage(named: ratioImage, colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor)

//        let layoutImage = (layout == global.mediaLayoutRatio) ? utility.loadImage(named: "square-grid", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor) : utility.loadImage(named: "ratio-grid", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor)
        let select = UIAction(title: NSLocalizedString("_select_", comment: ""),
                              image: utility.loadImage(named: "checkmark.circle", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
            media.setEditMode(true)
        }

        let viewFilterMenu = UIMenu(title: "", options: .displayInline, children: [
        UIAction(title: NSLocalizedString("_media_viewimage_show_", comment: ""),
                 image: UIImage(named: "photo")?.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor),
                 state: media.showOnlyImages ? .on : .off) { _ in
            media.showOnlyImages = true
            media.showOnlyVideos = false
            Task {
                await media.loadDataSource()
                await media.networkRemoveAll()
                await self.updateRightMenu()
            }
        },
            UIAction(title: NSLocalizedString("_media_viewvideo_show_", comment: ""),
                     image: UIImage(named: "video")?.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor),
                     state: media.showOnlyVideos ? .on : .off) { _ in
                media.showOnlyImages = false
                media.showOnlyVideos = true
                Task {
                    await media.loadDataSource()
                    await media.networkRemoveAll()
                    await self.updateRightMenu()
                }
            },
            UIAction(title: NSLocalizedString("_media_show_all_", comment: ""),
                     image: UIImage(named: "media")?.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor),
                     state: !media.showOnlyImages && !media.showOnlyVideos ? .on : .off) { _ in
                media.showOnlyImages = false
                media.showOnlyVideos = false
                Task {
                    await media.loadDataSource()
                    await media.networkRemoveAll()
                    await self.updateRightMenu()
                }
            }
        ])

        let viewLayoutMenu = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: layoutTitle, image: layoutImage) { _ in
                Task {
                    if layout == self.global.mediaLayoutRatio {
                        self.database.setLayoutForView(account: self.session.account, key: self.global.layoutViewMedia, serverUrl: "", layout: self.global.mediaLayoutSquare)
                        media.layoutType = self.global.mediaLayoutSquare
                    } else {
                        self.database.setLayoutForView(account: self.session.account, key: self.global.layoutViewMedia, serverUrl: "", layout: self.global.mediaLayoutRatio)
                        media.layoutType = self.global.mediaLayoutRatio
                    }
                    await self.updateRightMenu()
                    media.collectionViewReloadData()
                }
            }
        ])

        let viewFolderMedia = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: NSLocalizedString("_select_media_folder_", comment: ""),
                     image: UIImage(named: "mediaFolder")?.image(color: NCBrandColor.shared.iconImageColor, size: 24).withTintColor(NCBrandColor.shared.iconImageColor), handler: { _ in
                guard let navigationController = UIStoryboard(name: "NCSelect", bundle: nil).instantiateInitialViewController() as? UINavigationController,
                      let viewController = navigationController.topViewController as? NCSelect else { return }
                viewController.delegate = media
                viewController.typeOfCommandView = .select
                viewController.type = "mediaFolder"
                viewController.session = self.session
                self.present(navigationController, animated: true)
            })
        ])
        
        let actions: [UIAction] = [
            UIAction(
                title: NSLocalizedString("_media_by_modified_date_", comment: ""),
                image: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor),//, colors: [NCBrandColor.shared.iconImageColor]),
                state: NCPreferences().mediaSortDate == "date" ? .on : .off,
                handler: { _ in
                    NCPreferences().mediaSortDate = "date"
                    Task {
                        await media.loadDataSource()
                        await media.networkRemoveAll()
                        await self.updateRightMenu()
                    }
                }
            ),
            
            UIAction(
                title: NSLocalizedString("_media_by_created_date_", comment: ""),
                image: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor),//, colors: [NCBrandColor.shared.iconImageColor]),
                state: NCPreferences().mediaSortDate == "creationDate" ? .on : .off,
                handler: { _ in
                    NCPreferences().mediaSortDate = "creationDate"
                    Task {
                        await media.loadDataSource()
                        await media.networkRemoveAll()
                        await self.updateRightMenu()
                    }
                }
            ),
            
            UIAction(
                title: NSLocalizedString("_media_by_upload_date_", comment: ""),
                image: utility.loadImage(named: "sortFileNameAZ", colors: [NCBrandColor.shared.iconImageColor], size: 24).withTintColor(NCBrandColor.shared.iconImageColor),//, colors: [NCBrandColor.shared.iconImageColor]),
                state: NCPreferences().mediaSortDate == "uploadDate" ? .on : .off,
                handler: { _ in
                    NCPreferences().mediaSortDate = "uploadDate"
                    Task {
                        await media.loadDataSource()
                        await media.networkRemoveAll()
                        await self.updateRightMenu()
                    }
                }
            )
        ]

//        let zoomViewMediaFolder = UIMenu(title: "", options: .displayInline, children: [
//            UIMenu(title: NSLocalizedString("_zoom_", comment: ""), children: [
//                UIAction(title: NSLocalizedString("_zoom_out_", comment: ""), image: UIImage(systemName: "minus.magnifyingglass"), attributes: self.attributesZoomOut) { _ in
//                    UIView.animate(withDuration: 0.0, animations: {
//                        NCKeychain().mediaColumnCount = columnCount + 1
//                        self.createMenu()
//                        self.collectionViewReloadData()
//                    })
//                },
//                UIAction(title: NSLocalizedString("_zoom_in_", comment: ""), image: UIImage(systemName: "plus.magnifyingglass"), attributes: self.attributesZoomIn) { _ in
//                    UIView.animate(withDuration: 0.0, animations: {
//                        NCKeychain().mediaColumnCount = columnCount - 1
//                        self.createMenu()
//                        self.collectionViewReloadData()
//                    })
//                }
//            ]),
//            UIMenu(title: NSLocalizedString("_media_view_options_", comment: ""), children: [viewFilterMenu, viewLayoutMenu]),
//            UIAction(title: NSLocalizedString("_select_media_folder_", comment: ""), image: UIImage(systemName: "folder"), handler: { _ in
//                guard let navigationController = UIStoryboard(name: "NCSelect", bundle: nil).instantiateInitialViewController() as? UINavigationController,
//                      let viewController = navigationController.topViewController as? NCSelect else { return }
//                viewController.delegate = self
//                viewController.typeOfCommandView = .select
//                viewController.type = "mediaFolder"
//                self.present(navigationController, animated: true)
//            })
//        ])
        
//        let playFile = UIAction(title: NSLocalizedString("_play_from_files_", comment: ""),
//                                image: utility.loadImage(named: "CirclePlay").withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
//            guard let controller = self.controller else { return }
//            media.documentPickerViewController = NCDocumentPickerViewController(controller: controller, isViewerMedia: true, allowsMultipleSelection: false, viewController: media)
//        }
//
//        let playURL = UIAction(title: NSLocalizedString("_play_from_url_", comment: ""),
//                               image: utility.loadImage(named: "Link").withTintColor(NCBrandColor.shared.iconImageColor)) { _ in
//            let alert = UIAlertController(title: NSLocalizedString("_valid_video_url_", comment: ""), message: nil, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel, handler: nil))
//            alert.addTextField(configurationHandler: { textField in
//                textField.placeholder = "http://myserver.com/movie.mkv"
//            })
//            alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in
//                guard let stringUrl = alert.textFields?.first?.text, !stringUrl.isEmpty, let url = URL(string: stringUrl) else {
//                    return
//                }
//                let fileName = url.lastPathComponent
//                Task {
//                    let metadata = await self.database.createMetadataAsync(fileName: fileName,
//                                                                           ocId: NSUUID().uuidString,
//                                                                           serverUrl: "",
//                                                                           url: stringUrl,
//                                                                           session: self.session,
//                                                                           sceneIdentifier: self.controller?.sceneIdentifier)
//                    await self.database.addMetadataAsync(metadata)
//
//                    if let vc = await NCViewer().getViewerController(metadata: metadata, delegate: self) {
//                        self.navigationController?.pushViewController(vc, animated: true)
//                    }
//                }
//            }))
//            self.present(alert, animated: true)
//        }

        let mediaSortMenu = UIMenu(
            title: "",
            options: .displayInline,
            children: actions
        )
        return UIMenu(title: "", children: [select, viewFilterMenu, viewLayoutMenu, viewFolderMedia, mediaSortMenu])//, playFile, playURL])
    }
}
