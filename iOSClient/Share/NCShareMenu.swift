//
//  NCShareMenu.swift
//  Nextcloud
//
//  Created by T-systems on 29/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareMenu: NSObject {
    
//    func toggleMenu(viewController: UIViewController, key: String, sortButton: UIButton?, serverUrl: String, hideDirectoryOnTop: Bool = false) {
    func toggleMenu(viewController: UIViewController) {
        
        let menuViewController = UIStoryboard.init(name: "NCMenu", bundle: nil).instantiateInitialViewController() as! NCMenu
        var actions = [NCMenuAction]()
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_open_in_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "viewInFolder").imageColor(NCBrandColor.shared.brandElement),
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterShareViewIn)
                }
            )
        )
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_advance_permissions_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "pencil").imageColor(NCBrandColor.shared.brandElement),
                selected: CCUtility.getMediaSortDate() == "date",
                on: true,
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterShareAdvancePermission)
                    //                    self.reloadDataSource()
                }
            )
        )
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_send_new_email_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "shareTypeEmail").imageColor(NCBrandColor.shared.brandElement),
                selected: CCUtility.getMediaSortDate() == "creationDate",
                on: true,
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterShareSendEmail)
                    //                    self.reloadDataSource()
                }
            )
        )
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_share_unshare_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "delete").imageColor(NCBrandColor.shared.brandElement),
                selected: CCUtility.getMediaSortDate() == "uploadDate",
                on: true,
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterShareUnshare)
                    //                    self.reloadDataSource()
                }
            )
        )
        
        menuViewController.actions = actions
        
        let menuPanelController = NCMenuPanelController()
        menuPanelController.parentPresenter = viewController
        menuPanelController.delegate = menuViewController
        menuPanelController.set(contentViewController: menuViewController)
        menuPanelController.track(scrollView: menuViewController.tableView)
        
        viewController.present(menuPanelController, animated: true, completion: nil)
    }
}
