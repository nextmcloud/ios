//
//  NCShareUserCell.swift
//  Nextcloud
//
//  Created by Henrik Storch on 15.11.2021.
//  Copyright © 2021 Henrik Storch. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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

import UIKit
import DropDown
import NextcloudKit

class NCShareUserCell: UITableViewCell, NCCellProtocol {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var btnQuickStatus: UIButton!
    @IBOutlet weak var labelQuickStatus: UILabel!
    @IBOutlet weak var imagePermissionType: UIImageView!
    @IBOutlet weak var imageRightArrow: UIImageView!
    @IBOutlet weak var imageExpiredDateSet: UIImageView!
    @IBOutlet weak var imagePasswordSet: UIImageView!
    @IBOutlet weak var imageAllowedPermission: UIImageView!
    @IBOutlet weak var leadingContraintofImageRightArrow: NSLayoutConstraint!

    private var index = IndexPath()

    var tableShare: tableShare?
    var isDirectory = false
    let utility = NCUtility()
    weak var delegate: NCShareUserCellDelegate?

    var indexPath: IndexPath {
        get { return index }
        set { index = newValue }
    }
    var avatarImageView: UIImageView? {
        return imageItem
    }
    var fileUser: String? {
        get { return tableShare?.shareWith }
        set {}
    }

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellUIAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setupCellUIAppearance()
        }
    }

    // MARK: - Configure
    func configure(with share: tableShare?, at indexPath: IndexPath, isDirectory: Bool, userId: String) {
        self.indexPath = indexPath
        self.tableShare = share
        self.isDirectory = isDirectory
        setupCellUI(userId: userId)
    }

    // MARK: - UI Setup
    private func setupCellUIAppearance() {
//        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        buttonMenu.contentMode = .scaleAspectFill
//        buttonMenu.setImage(NCImageCache.images.buttonMore.image(color: NCBrandColor.shared.brand, size: 24), for: .normal)
        buttonMenu.setImage(NCImageCache.shared.getImageButtonMore().image(color: NCBrandColor.shared.brand, size: 24), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.shareBlueColor
        labelTitle.textColor = NCBrandColor.shared.label
        imageRightArrow.image = UIImage(named: "rightArrow")?.image(color: NCBrandColor.shared.shareBlueColor)
        imageExpiredDateSet.image = UIImage(named: "calenderNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        imagePasswordSet.image = UIImage(named: "lockNew")?.image(color: NCBrandColor.shared.shareBlueColor)

        imagePermissionType.image = imagePermissionType.image?.image(color: NCBrandColor.shared.shareBlueColor)
        updatePermissionUI()
    }

    private func updatePermissionUI() {
        guard let tableShare = tableShare else { return }

        let permissions = NCPermissions()

        if tableShare.permissions == permissions.permissionCreateShare {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_just_upload_", comment: "")
            imagePermissionType.image = UIImage(named: "upload")?.image(color: NCBrandColor.shared.shareBlueColor)
        } else if permissions.isAnyPermissionToEdit(tableShare.permissions) {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_edit_", comment: "")
            imagePermissionType.image = UIImage(named: "editNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        } else {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_only_view_", comment: "")
            imagePermissionType.image = UIImage(named: "showPasswordNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        }

        imagePasswordSet.isHidden = tableShare.password.isEmpty
        imageExpiredDateSet.isHidden = (tableShare.expirationDate == nil)
        
        leadingContraintofImageRightArrow.constant = (imagePasswordSet.isHidden && imageExpiredDateSet.isHidden) ? 0 : 5
    }

    private func setupCellUI(userId: String) {
        guard let tableShare = tableShare else { return }

        let permissions = NCPermissions()
        labelTitle.text = tableShare.shareWithDisplayname

        let isOwner = tableShare.uidOwner == userId || tableShare.uidFileOwner == userId
        isUserInteractionEnabled = isOwner
        buttonMenu.isHidden = !isOwner
        buttonMenu.accessibilityLabel = NSLocalizedString("_more_", comment: "")

        btnQuickStatus.setTitle("", for: .normal)
        btnQuickStatus.isEnabled = true
        btnQuickStatus.accessibilityHint = NSLocalizedString("_user_sharee_footer_", comment: "")
        btnQuickStatus.contentHorizontalAlignment = .left

        setupCellUIAppearance()
//        let permissionValue = tableShare.permissions
//
//        if permissionValue == permissions.permissionCreateShare {
//            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_just_upload_", comment: "")
//            imagePermissionType.image = UIImage(named: "upload")?.imageColor(NCBrandColor.shared.shareBlueColor)
//        } else if permissions.isAnyPermissionToEdit(permissionValue) {
//            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_edit_", comment: "")
//            imagePermissionType.image = UIImage(named: "editNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
//        } else {
//            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_only_view_", comment: "")
//            imagePermissionType.image = UIImage(named: "showPasswordNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
//        }
    }
    
    func setupCellUI(userId: String, session: NCSession.Session, metadata: tableMetadata) {
        guard let tableShare = tableShare else {
            return
        }
        self.accessibilityCustomActions = [UIAccessibilityCustomAction(
            name: NSLocalizedString("_show_profile_", comment: ""),
            target: self,
            selector: #selector(tapAvatarImage(_:)))]
        labelTitle.text = (tableShare.shareWithDisplayname.isEmpty ? tableShare.shareWith : tableShare.shareWithDisplayname)

        let type = getTypeString(tableShare)
        if !type.isEmpty {
            labelTitle.text?.append(" (\(type))")
        }

        labelTitle.lineBreakMode = .byTruncatingMiddle
        labelTitle.textColor = NCBrandColor.shared.textColor
        isUserInteractionEnabled = true
        labelQuickStatus.isHidden = false
        imageRightArrow.isHidden = false
        buttonMenu.isHidden = false
        buttonMenu.accessibilityLabel = NSLocalizedString("_more_", comment: "")
        imageItem.image = NCShareCommon.getImageShareType(shareType: tableShare.shareType)

        let status = utility.getUserStatus(userIcon: tableShare.userIcon, userStatus: tableShare.userStatus, userMessage: tableShare.userMessage)
        imageStatus.image = status.statusImage
        self.status.text = status.statusMessage

        // If the initiator or the recipient is not the current user, show the list of sharees without any options to edit it.
        if tableShare.uidOwner != userId && tableShare.uidFileOwner != userId {
            isUserInteractionEnabled = false
            labelQuickStatus.isHidden = true
            imageRightArrow.isHidden = true
            buttonMenu.isHidden = true
        }

        btnQuickStatus.accessibilityHint = NSLocalizedString("_user_sharee_footer_", comment: "")
        btnQuickStatus.setTitle("", for: .normal)
        btnQuickStatus.contentHorizontalAlignment = .left

        if NCSharePermissions.canEdit(tableShare.permissions, isDirectory: isDirectory) { // Can edit
            labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
        } else if tableShare.permissions == NKShare.Permission.read.rawValue { // Read only
            labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
        } else { // Custom permissions
            labelQuickStatus.text = NSLocalizedString("_custom_permissions_", comment: "")
        }

        let fileName = NCSession.shared.getFileName(urlBase: session.urlBase, user: tableShare.shareWith)
        let results = NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName)

        imageItem.contentMode = .scaleAspectFill

        if tableShare.shareType == NKShare.ShareType.team.rawValue {
            imageItem.image = utility.loadImage(named: "custom.person.3.circle.fill", colors: [NCBrandColor.shared.iconImageColor2])
        } else if results.image == nil {
            imageItem.image = utility.loadUserImage(for: tableShare.shareWith, displayName: tableShare.shareWithDisplayname, urlBase: metadata.urlBase)
        } else {
            imageItem.image = results.image
        }

        if !(results.tblAvatar?.loaded ?? false),
           NCNetworking.shared.downloadAvatarQueue.operations.filter({ ($0 as? NCOperationDownloadAvatar)?.fileName == fileName }).isEmpty {
            NCNetworking.shared.downloadAvatarQueue.addOperation(NCOperationDownloadAvatar(user: tableShare.shareWith, fileName: fileName, account: metadata.account, view: self))
        }
    }

    private func getTypeString(_ tableShare: tableShareV2) -> String {
        switch tableShare.shareType {
        case NKShare.ShareType.federatedCloud.rawValue:
            return NSLocalizedString("_remote_", comment: "")
        case NKShare.ShareType.federatedGroup.rawValue:
            return NSLocalizedString("_remote_group_", comment: "")
        case NKShare.ShareType.talkConversation.rawValue:
            return NSLocalizedString("_conversation_", comment: "")
        default:
            return ""
        }
    }

    @objc func tapAvatarImage(_ sender: UITapGestureRecognizer) {
        delegate?.showProfile(with: tableShare, sender: sender)
    }

    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @IBAction func quickStatusClicked(_ sender: Any) {
        delegate?.quickStatus(with: tableShare, sender: sender)
    }
}

protocol NCShareUserCellDelegate: AnyObject {
    func tapMenu(with tableShare: tableShare?, sender: Any)
    func showProfile(with tableComment: tableShare?, sender: Any)
    func quickStatus(with tableShare: tableShare?, sender: Any)
}

// MARK: - NCSearchUserDropDownCell

class NCSearchUserDropDownCell: DropDownCell, NCCellProtocol {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var imageShareeType: UIImageView!
    @IBOutlet weak var centerTitleConstraint: NSLayoutConstraint!

    private var user: String = ""
    private var index = IndexPath()
    private let utilityFileSystem = NCUtilityFileSystem()

    var indexPath: IndexPath {
        get { return index }
        set { index = newValue }
    }
    var avatarImageView: UIImageView? {
        return imageItem
    }
    var fileUser: String? {
        get { return user }
        set { user = newValue ?? "" }
    }

    func setupCell(sharee: NKSharee, session: NCSession.Session) {
        let utility = NCUtility()
//        imageItem.image = NCShareCommon.getImageShareType(shareType: sharee.shareType)
        imageShareeType.image = NCShareCommon.getImageShareType(shareType: sharee.shareType, isDropDown: true)
        let status = utility.getUserStatus(userIcon: sharee.userIcon, userStatus: sharee.userStatus, userMessage: sharee.userMessage)

        if let statusImage = status.statusImage {
            imageStatus.image = statusImage
            imageStatus.makeCircularBackground(withColor: .systemBackground)
        }

        self.status.text = status.statusMessage
        if self.status.text?.count ?? 0 > 0 {
            centerTitleConstraint.constant = -5
        } else {
            centerTitleConstraint.constant = 0
        }

        /*
        imageItem.image = utility.loadUserImage(for: sharee.shareWith, displayName: nil, urlBase: session.urlBase)

        let fileName = NCSession.shared.getFileName(urlBase: session.urlBase, user: sharee.shareWith)
        let results = NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName)

        if results.image == nil {
            let etag = NCManageDatabase.shared.getTableAvatar(fileName: fileName)?.etag
            let fileNameLocalPath = utilityFileSystem.createServerUrl(serverUrl: utilityFileSystem.directoryUserData, fileName: fileName)

            NextcloudKit.shared.downloadAvatar(
                user: sharee.shareWith,
                fileNameLocalPath: fileNameLocalPath,
                sizeImage: NCGlobal.shared.avatarSize,
                avatarSizeRounded: NCGlobal.shared.avatarSizeRounded,
                etagResource: etag,
                account: session.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: session.account,
                                                                                                    path: sharee.shareWith,
                                                                                                    name: "downloadAvatar")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                } completion: { _, imageAvatar, _, etag, _, error in
                    if error == .success, let etag = etag, let imageAvatar = imageAvatar {
                        NCManageDatabase.shared.addAvatar(fileName: fileName, etag: etag)
                        self.imageItem.image = imageAvatar
                    } else if error.errorCode == NCGlobal.shared.errorNotModified, let imageAvatar = NCManageDatabase.shared.setAvatarLoaded(fileName: fileName) {
                        self.imageItem.image = imageAvatar
                    }
                }
        }
         */
    }
}
