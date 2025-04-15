// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import DropDown
import NextcloudKit

enum NCShareCommon {
    static let itemTypeFile = "file"
    static let itemTypeFolder = "folder"

    static func createLinkAvatar(imageName: String, colorCircle: UIColor) -> UIImage? {
        let size: CGFloat = 200

        let bottomImage = UIImage(named: "circle_fill")!.image(color: colorCircle, size: size / 2)
        let topImage = UIImage(named: imageName)!.image(color: .white, size: size / 2)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, UIScreen.main.scale)
        bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: size, height: size)))
        topImage.draw(in: CGRect(origin: CGPoint(x: size / 4, y: size / 4), size: CGSize(width: size / 2, height: size / 2)))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    static func copyLink(link: String, viewController: UIViewController, sender: Any) {
        let objectsToShare = [link]

        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
                activityViewController.popoverPresentationController?.sourceView = sender as? UIView
                activityViewController.popoverPresentationController?.sourceRect = (sender as AnyObject).bounds
            }
        }
        DispatchQueue.main.async {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    static func getImageShareType(shareType: Int) -> UIImage? {
        typealias type = NKShare.ShareType

        switch shareType {
        case type.group.rawValue:
            return UIImage(named: "shareTypeGroup")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case type.publicLink.rawValue:
            return UIImage(named: "shareTypeLink")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case type.email.rawValue:
            return UIImage(named: "shareTypeEmail")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case type.team.rawValue:
            return UIImage(named: "shareTypeTeam")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case type.federatedGroup.rawValue:
            return UIImage(named: "shareTypeGroup")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case type.talkConversation.rawValue:
            return UIImage(named: "shareTypeRoom")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        default:
            return UIImage(named: "shareTypeUser")?.imageColor(NCBrandColor.shared.label)
        }
    }
    
    func isLinkShare(shareType: Int) -> Bool {
        return shareType == SHARE_TYPE_LINK
    }
    
    func isExternalUserShare(shareType: Int) -> Bool {
        return shareType == SHARE_TYPE_EMAIL
    }
    
    func isInternalUser(shareType: Int) -> Bool {
        return shareType == SHARE_TYPE_USER
    }
    
    func isFileTypeAllowedForEditing(fileExtension: String, shareType: Int) -> Bool {
        if fileExtension == "md" || fileExtension == "txt" {
            return true
        } else {
            return isInternalUser(shareType: shareType)
        }
    }
    
    func isEditingEnabled(isDirectory: Bool, fileExtension: String, shareType: Int) -> Bool {
        if !isDirectory {//file
            return isFileTypeAllowedForEditing(fileExtension: fileExtension, shareType: shareType)
        } else {
            return true
        }
    }
    
    func isFileDropOptionVisible(isDirectory: Bool, shareType: Int) -> Bool {
        return (isDirectory && (isLinkShare(shareType: shareType) || isExternalUserShare(shareType: shareType)))
    }
    
    func isCurrentUserIsFileOwner(fileOwnerId: String) -> Bool {
        if let currentUser = NCManageDatabase.shared.getActiveTableAccount(), currentUser.userId == fileOwnerId {
            return true
        }
        return false
    }
    
    func canReshare(withPermission permission: String) -> Bool {
        return permission.contains(NCPermissions().permissionCanShare)
    }
}
