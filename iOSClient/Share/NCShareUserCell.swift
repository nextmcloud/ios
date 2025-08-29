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

    // MARK: - IBOutlets
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var btnQuickStatus: UIButton!
    @IBOutlet weak var labelQuickStatus: UILabel!
    @IBOutlet weak var imagePermissionType: UIImageView!
    @IBOutlet weak var imageRightArrow: UIImageView!
    @IBOutlet weak var imageExpiredDateSet: UIImageView!
    @IBOutlet weak var imagePasswordSet: UIImageView!
    @IBOutlet weak var imageAllowedPermission: UIImageView!
    @IBOutlet weak var leadingContraintofImageRightArrow: NSLayoutConstraint!

    // MARK: - Properties
    private var indexPathInternal = IndexPath()
    var tableShare: tableShare?
    var isDirectory: Bool = false
    weak var delegate: NCShareUserCellDelegate?

    var indexPath: IndexPath {
        get { indexPathInternal }
        set { indexPathInternal = newValue }
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
        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        buttonMenu.contentMode = .scaleAspectFill
        buttonMenu.setImage(NCImageCache.images.buttonMore.image(color: NCBrandColor.shared.brand, size: 24), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.shareBlueColor
        labelTitle.textColor = NCBrandColor.shared.label
        imageRightArrow.image = UIImage(named: "rightArrow")?.imageColor(NCBrandColor.shared.shareBlueColor)
        imageExpiredDateSet.image = UIImage(named: "calenderNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
        imagePasswordSet.image = UIImage(named: "lockNew")?.imageColor(NCBrandColor.shared.shareBlueColor)

        imagePermissionType.image = imagePermissionType.image?.imageColor(NCBrandColor.shared.shareBlueColor)
        updatePermissionUI()
    }

    private func updatePermissionUI() {
        guard let tableShare = tableShare else { return }

        let permissions = NCPermissions()

        if tableShare.permissions == permissions.permissionCreateShare {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_just_upload_", comment: "")
            imagePermissionType.image = UIImage(named: "upload")?.imageColor(NCBrandColor.shared.shareBlueColor)
        } else if permissions.isAnyPermissionToEdit(tableShare.permissions) {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_edit_", comment: "")
            imagePermissionType.image = UIImage(named: "editNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
        } else {
            labelQuickStatus.text = NSLocalizedString("_share_quick_permission_everyone_can_only_view_", comment: "")
            imagePermissionType.image = UIImage(named: "showPasswordNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
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

    // MARK: - Actions
    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @IBAction func quickStatusClicked(_ sender: Any) {
        delegate?.quickStatus(with: tableShare, sender: sender)
    }

    @objc func tapAvatarImage(_ sender: UITapGestureRecognizer) {
        delegate?.showProfile(with: tableShare, sender: sender)
    }
}

protocol NCShareUserCellDelegate: AnyObject {
    func tapMenu(with tableShare: tableShare?, sender: Any)
    func showProfile(with tableComment: tableShare?, sender: Any)
    func quickStatus(with tableShare: tableShare?, sender: Any)
}

class NCSearchUserDropDownCell: DropDownCell, NCCellProtocol {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var imageShareeType: UIImageView!
    @IBOutlet weak var centerTitleConstraint: NSLayoutConstraint!

    private var userIdentifier: String = ""
    private var currentIndexPath = IndexPath()

    // MARK: - NCCellProtocol

    var indexPath: IndexPath {
        get { currentIndexPath }
        set { currentIndexPath = newValue }
    }

    var fileAvatarImageView: UIImageView? {
        imageItem
    }

    var fileUser: String? {
        get { userIdentifier }
        set { userIdentifier = newValue ?? "" }
    }

    // MARK: - Setup

    func setupCell(sharee: NKSharee, session: NCSession.Session) {
        let utility = NCUtility()
        let shareCommon = NCShareCommon()

        imageShareeType.image = shareCommon.getImageShareType(shareType: sharee.shareType, isDropDown: true)

        let userStatus = utility.getUserStatus(userIcon: sharee.userIcon,
                                               userStatus: sharee.userStatus,
                                               userMessage: sharee.userMessage)

        if let statusImage = userStatus.statusImage {
            imageStatus.image = statusImage
            imageStatus.makeCircularBackground(withColor: .systemBackground)
        }

        statusLabel.text = userStatus.statusMessage
        centerTitleConstraint.constant = (statusLabel.text?.isEmpty == false) ? -5 : 0
    }
}
