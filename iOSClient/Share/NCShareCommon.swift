// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import DropDown

enum NCShareCommon {
    static let shareTypeUser = 0
    static let shareTypeGroup = 1
    static let shareTypeLink = 3
    static let shareTypeEmail = 4
    static let shareTypeContact = 5
    static let shareTypeFederated = 6
    static let shareTypeTeam = 7
    static let shareTypeGuest = 8
    static let shareTypeFederatedGroup = 9
    static let shareTypeRoom = 10

    static let itemTypeFile = "file"
    static let itemTypeFolder = "folder"

    static func createLinkAvatar(imageName: String, colorCircle: UIColor) -> UIImage? {
        let size: CGFloat = 200

        let bottomImage = UIImage(named: "circle_fill")!.image(color: colorCircle, size: size / 2)
        let topImage = NCUtility().loadImage(named: imageName, colors: [NCBrandColor.shared.iconImageColor])
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

    static func getImageShareType(shareType: Int, isDropDown:Bool = false) -> UIImage? {

        switch shareType {
        case NCShareCommon.shareTypeUser:
            return UIImage(named: "shareTypeEmail")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeGroup:
            return UIImage(named: "shareTypeGroup")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeLink:
            return UIImage(named: "shareTypeLink")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeEmail:
            return UIImage(named: isDropDown ? "email" : "shareTypeUser")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeContact:
            return UIImage(named: "shareTypeUser")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeFederated:
//            return UIImage(named: "shareTypeUser")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
            return UIImage(named: isDropDown ? "shareTypeUser" : "shareTypeEmail")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeTeam:
//            return UIImage(named: "shareTypeTeam")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
            return UIImage(named: "shareTypeCircles")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeGuest:
            return UIImage(named: "shareTypeUser")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeFederatedGroup:
            return UIImage(named: "shareTypeGroup")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        case NCShareCommon.shareTypeRoom:
            return UIImage(named: "shareTypeRoom")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        default:
            return UIImage(named: "shareTypeUser")?.withTintColor(NCBrandColor.shared.textColor, renderingMode: .alwaysOriginal)
        }
    }
    
    static func isLinkShare(shareType: Int) -> Bool {
        return shareType == NCShareCommon.shareTypeLink
    }
    
    static func isExternalUserShare(shareType: Int) -> Bool {
        return shareType == NCShareCommon.shareTypeEmail
    }
    
    static func isInternalUser(shareType: Int) -> Bool {
        return shareType == NCShareCommon.shareTypeUser
    }
    
    static func isFileTypeAllowedForEditing(fileExtension: String, shareType: Int) -> Bool {
        if fileExtension == "md" || fileExtension == "txt" {
            return true
        } else {
            return isInternalUser(shareType: shareType)
        }
    }
    
    static func isEditingEnabled(isDirectory: Bool, fileExtension: String, shareType: Int) -> Bool {
        if !isDirectory {//file
            return isFileTypeAllowedForEditing(fileExtension: fileExtension, shareType: shareType)
        } else {
            return true
        }
    }
    
    static func isFileDropOptionVisible(isDirectory: Bool, shareType: Int) -> Bool {
        return (isDirectory && (isLinkShare(shareType: shareType) || isExternalUserShare(shareType: shareType)))
    }
    
    static func isCurrentUserIsFileOwner(fileOwnerId: String) -> Bool {
        if let currentUser = NCManageDatabase.shared.getActiveTableAccount(), currentUser.userId == fileOwnerId {
            return true
        }
        return false
    }
    
    static func canReshare(withPermission permission: String) -> Bool {
        return permission.contains(NCPermissions().permissionCanShare)
    }
}
