//
//  NCShareQuickStatusMenu.swift
//  Nextcloud
//
//  Created by TSI-mc on 16/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//  Copyright © 2021 TSI-mc. All rights reserved.
//

import UIKit

class NCShareQuickStatusMenu: NSObject {
    
    var currentStatus = ""
    
    func toggleMenu(viewController: UIViewController, directory: Bool, directoryType: String, fileExtension: String?, status: Int, shareType: Int) {
        
        print(status)
//        self.currentStatus = status
        let menuViewController = UIStoryboard.init(name: "NCMenu", bundle: nil).instantiateInitialViewController() as! NCMenu
        
        let isRead = (!CCUtility.isAnyPermission(toEdit: status) && status !=  NCGlobal.shared.permissionCreateShare)
        let isEdit = (CCUtility.isAnyPermission(toEdit: status) && status != NCGlobal.shared.permissionCreateShare)
        
        var actions = [NCMenuAction]()
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_share_read_only_", comment: ""),
                icon: isRead ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) ?? UIImage() : UIImage(),
                selected: false,
                on: false,
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusReadOnly)
                }
            )
        )

        if NCShareCommon.shared.isEditingEnabled(isDirectory: directory, fileExtension: fileExtension ?? "", shareType: shareType) {
            actions.append(
                NCMenuAction(
                    title: directory ? NSLocalizedString("_share_editing_", comment: "") : NSLocalizedString("_share_editing_", comment: ""),
                    icon: isEdit ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) ?? UIImage() : UIImage(),
                    selected: false,
                    on: false,
                    action: { menuAction in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusEditing)
                    }
                )
            )
        }
        
        if directory,
           NCShareCommon.shared.isFileDropOptionVisible(isDirectory: directory, shareType: shareType) {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_share_file_drop_", comment: ""),
                    icon: status == NCGlobal.shared.permissionCreateShare ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) ?? UIImage() : UIImage(),
                    selected: false,
                    on: false,
                    action: { menuAction in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusFileDrop)
                    }
                )
            )
        }

        menuViewController.actions = actions

        let menuPanelController = NCMenuPanelController()
        menuPanelController.parentPresenter = viewController
        menuPanelController.delegate = menuViewController
        menuPanelController.set(contentViewController: menuViewController)
        menuPanelController.track(scrollView: menuViewController.tableView)

        viewController.present(menuPanelController, animated: true, completion: nil)
    }
}

