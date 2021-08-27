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
//    func toggleMenu(viewController: UIViewController, key: String, sortButton: UIButton?, serverUrl: String, hideDirectoryOnTop: Bool = false) {
    
    var currentStatus = ""
    
    func toggleMenu(viewController: UIViewController, directory: Bool, directoryType: String, status: Int, shareType: Int) {
        
        print(status)
//        self.currentStatus = status
        let menuViewController = UIStoryboard.init(name: "NCMenu", bundle: nil).instantiateInitialViewController() as! NCMenu
        var actions = [NCMenuAction]()
        print(status)
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_share_read_only_", comment: ""),
                icon: status == NCGlobal.shared.permissionReadShare ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) as! UIImage : UIImage(),
                selected: false,
                on: false,
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusReadOnly)
                }
            )
        )

        if directoryType == "document" || directoryType == "directory" {
            actions.append(
                NCMenuAction(
                    title: directory ? NSLocalizedString("_share_allow_upload_", comment: "") : NSLocalizedString("_share_editing_", comment: ""),
                    icon: (status == NCGlobal.shared.permissionMaxFileShare || status == NCGlobal.shared.permissionMaxFolderShare ||  status == NCGlobal.shared.permissionDefaultFileRemoteShareNoSupportShareOption) ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) as! UIImage : UIImage(),
                    selected: false,
                    on: false,
                    action: { menuAction in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusEditing)
                    }
                )
            )
        } else if directoryType != "image" || directoryType !=  "audio" {
            actions.append(
                NCMenuAction(title: directory ? NSLocalizedString("_share_allow_upload_", comment: "") : NSLocalizedString("_share_editing_", comment: ""),
                             icon: (status == NCGlobal.shared.permissionMaxFileShare || status == NCGlobal.shared.permissionMaxFolderShare ||  status == NCGlobal.shared.permissionDefaultFileRemoteShareNoSupportShareOption) ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) as! UIImage : UIImage(),
                             selected: false,
                             on: false,
                             action: { menuAction in
                                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusEditing)
                             }
                )
            )
        }
        
        if directory {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_share_file_drop_", comment: ""),
                    icon: UIImage(),
                    selected: status == NCGlobal.shared.permissionCreateShare,
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

