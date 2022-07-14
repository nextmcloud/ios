//
//  NCShareQuickStatusMenu.swift
//  Nextcloud
//
//  Created by TSI-mc on 30/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareQuickStatusMenu: NSObject {

    func toggleMenu(viewController: UIViewController, directory: Bool, tableShare: tableShare) {

        print(tableShare.permissions)
        let menuViewController = UIStoryboard(name: "NCMenu", bundle: nil).instantiateInitialViewController() as! NCMenu
        var actions = [NCMenuAction]()

        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_share_read_only_", comment: ""),
                icon: UIImage(),
                selected: tableShare.permissions == (NCGlobal.shared.permissionReadShare + NCGlobal.shared.permissionShareShare) || tableShare.permissions == NCGlobal.shared.permissionReadShare,
                on: false,
                action: { _ in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusReadOnly, object: tableShare)
                }
            )
        )

        actions.append(
            NCMenuAction(
                title: directory ? NSLocalizedString("_share_allow_upload_", comment: "") : NSLocalizedString("_share_editing_", comment: ""),
                icon: UIImage(),
                selected: hasUploadPermission(tableShare: tableShare),
                on: false,
                action: { _ in
                    NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusEditing, object: tableShare)
                }
            )
        )
        
        if directory,
           NCShareCommon.shared.isFileDropOptionVisible(isDirectory: directory, shareType: tableShare.shareType) {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_share_file_drop_", comment: ""),
                    icon: tableShare.permissions == NCGlobal.shared.permissionCreateShare ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) ?? UIImage() : UIImage(),
                    selected: false,
                    on: false,
                    action: { menuAction in
                        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterStatusFileDrop, object: tableShare)
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

    fileprivate func hasUploadPermission(tableShare: tableShare) -> Bool {
        let uploadPermissions = [
            NCGlobal.shared.permissionMaxFileShare,
            NCGlobal.shared.permissionMaxFolderShare,
            NCGlobal.shared.permissionDefaultFileRemoteShareNoSupportShareOption,
            NCGlobal.shared.permissionDefaultFolderRemoteShareNoSupportShareOption]
        return uploadPermissions.contains(tableShare.permissions)
    }
}
