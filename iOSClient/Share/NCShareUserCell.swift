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

    var tableShare: tableShare? {
        didSet {
            // When permissions or related fields change (e.g., via Advanced permissions),
            // refresh the permission UI and accessory indicators.
            updatePermissionUI()
            // Also update title if display name changed.
            if let share = tableShare {
                labelTitle.text = share.shareWithDisplayname
                applyIconsIfNeeded()
            }
        }
    }
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
        applyIconsIfNeeded()
    }

    func refresh(with share: tableShare?, userId: String) {
        self.tableShare = share
        setupCellUI(userId: userId)
        applyIconsIfNeeded()
    }

    // MARK: - UI Setup
    
    private func setupCellUI(userId: String) {
        guard let tableShare = tableShare else { return }

        labelTitle.text = tableShare.shareWithDisplayname

        let isOwner = tableShare.uidOwner == userId || tableShare.uidFileOwner == userId
        isUserInteractionEnabled = isOwner
        buttonMenu.isHidden = !isOwner
        buttonMenu.accessibilityLabel = NSLocalizedString("_more_", comment: "")

        btnQuickStatus.setTitle("", for: .normal)
        btnQuickStatus.isEnabled = true
        btnQuickStatus.accessibilityHint = NSLocalizedString("_user_sharee_footer_", comment: "")
        btnQuickStatus.contentHorizontalAlignment = .left

        imageExpiredDateSet.isHidden = true
        imagePasswordSet.isHidden = true
        
        setupCellUIAppearance()
        updatePermissionUI()
    }
    
    private func setupCellUIAppearance() {
        labelQuickStatus.textColor = NCBrandColor.shared.shareBlueColor
        labelTitle.textColor = NCBrandColor.shared.label
        imageRightArrow.image = UIImage(named: "rightArrow")?.image(color: NCBrandColor.shared.shareBlueColor)
        imageExpiredDateSet.image = UIImage(named: "calenderNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        imagePasswordSet.image = UIImage(named: "lockNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        buttonMenu.setImage(NCImageCache.shared.getImageButtonMore().image(color: NCBrandColor.shared.brand, size: 24), for: .normal)

        imagePermissionType.image = imagePermissionType.image?.image(color: NCBrandColor.shared.shareBlueColor)
        // Permission UI is updated via tableShare didSet or explicit refresh
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

        applyIconsIfNeeded()
    }
    
    // Ensures calendar icon visibility is correctly applied after configure/refresh
    func applyIconsIfNeeded() {
        guard let tableShare = tableShare else { return }
        imagePasswordSet.isHidden = tableShare.password.isEmpty
        // Show calendar icon when an expiration date is set
        imageExpiredDateSet.isHidden = (tableShare.expirationDate == nil)
        // Adjust spacing accordingly
        leadingContraintofImageRightArrow.constant = (imagePasswordSet.isHidden && imageExpiredDateSet.isHidden) ? 0 : 5
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

    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @IBAction func quickStatusClicked(_ sender: Any) {
        delegate?.tapQuickStatus(with: tableShare, sender: sender)
    }
    
    @objc func openQuickStatus(_ sender: UIGestureRecognizer) {
        delegate?.tapQuickStatus(with: tableShare, sender: sender.view ?? sender)
    }
}

protocol NCShareUserCellDelegate: AnyObject {
    func tapMenu(with tableShare: tableShare?, sender: Any)
    func tapProfileMenu(with tableShare: tableShare?) -> UIMenu?
    func tapQuickStatus(with tableShare: tableShare?, sender: Any)
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
    }
}

