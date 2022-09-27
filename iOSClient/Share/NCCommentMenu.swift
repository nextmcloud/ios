//
//  NCCommentMenu.swift
//  Nextcloud
//
//  Created by A200073704 on 23/09/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class NCCommentMenu: NSObject {
    
    func toggleMenu(viewController: UIViewController) {
        
        let menuViewController = UIStoryboard.init(name: "NCMenu", bundle: nil).instantiateInitialViewController() as! NCMenu
        var actions = [NCMenuAction]()
        
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_edit_comment_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "rename").imageColor(NCBrandColor.shared.label),
                action: { menuAction in
                    print("Edit Comment")
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterEditCommentAction)
                }
            )
        )
        
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_delete_comment_", comment: ""),
                icon: NCUtility.shared.loadImage(named: "delete").imageColor(NCBrandColor.shared.label),
                action: { menuAction in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterDeleteCommentAction)
                    print("Delete Comment")
                   
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


