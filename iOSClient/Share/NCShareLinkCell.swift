//
//  NCShareLinkCell.swift
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
import NextcloudKit

class NCShareLinkCell: UITableViewCell {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonDetail: UIButton!
    @IBOutlet weak var buttonCopy: UIButton!
    @IBOutlet weak var btnQuickStatus: UIButton!
    @IBOutlet weak var imagePermissionType: UIImageView!
    @IBOutlet weak var imageExpiredDateSet: UIImageView!
    @IBOutlet weak var imagePasswordSet: UIImageView!
    @IBOutlet weak var imageAllowedPermission: UIImageView!
    @IBOutlet weak var imageRightArrow: UIImageView!
    @IBOutlet weak var labelQuickStatus: UILabel!
    @IBOutlet weak var leadingContraintofImageRightArrow: NSLayoutConstraint!

    private let iconShareSize: CGFloat = 200

    weak var delegate: NCShareLinkCellDelegate?
    
    var tableShare: tableShare?
    var isInternalLink = false
    var isDirectory = false
    var indexPath = IndexPath()

    override func prepareForReuse() {
        super.prepareForReuse()
        isInternalLink = false
        tableShare = nil
    }

    func setupCellUI(titleAppendString: String? = nil) {
        var menuImageName = "ellipsis"
        let permissions = NCPermissions()
        
        menuButton.isHidden = isInternalLink
        descriptionLabel.isHidden = !isInternalLink
        copyButton.isHidden = !isInternalLink && tableShare == nil
        statusStackView.isHidden = isInternalLink

        copyButton.setImage(UIImage(systemName: "doc.on.doc")?.withTintColor(.label, renderingMode: .alwaysOriginal), for: .normal)
        copyButton.accessibilityLabel = NSLocalizedString("_copy_", comment: "")
        
        menuButton.accessibilityLabel = NSLocalizedString("_more_", comment: "")
        menuButton.accessibilityIdentifier = "showShareLinkDetails"
        
        if isInternalLink {
            labelTitle.text = NSLocalizedString("_share_internal_link_", comment: "")
            descriptionLabel.text = NSLocalizedString("_share_internal_link_des_", comment: "")
            imageItem.image = NCUtility().loadImage(named: "square.and.arrow.up.circle.fill", colors: [NCBrandColor.shared.iconImageColor2])
        } else {
            labelTitle.text = NSLocalizedString("_share_link_", comment: "")
            
            if let titleAppendString {
                labelTitle.text?.append(" (\(titleAppendString))")
            }
            
            if let tableShare = tableShare {
                if !tableShare.label.isEmpty {
                    labelTitle.text? += " (\(tableShare.label))"
                }
            } else {
                menuImageName = "plus"
                menuButton.accessibilityLabel = NSLocalizedString("_add_", comment: "")
                menuButton.accessibilityIdentifier = "addShareLink"
            }
            
            imageItem.image = NCUtility().loadImage(named: "link.circle.fill", colors: [NCBrandColor.shared.getElement(account: tableShare?.account)])
            menuButton.setImage(NCUtility().loadImage(named: menuImageName, colors: [NCBrandColor.shared.iconImageColor]), for: .normal)
        }
        
        labelTitle.textColor = NCBrandColor.shared.textColor
        
        statusStackView.isHidden = true
        
        if let tableShare {
            statusStackView.isHidden = false
            labelQuickStatus.text = NSLocalizedString("_custom_permissions_", comment: "")

            if NCSharePermissions.canEdit(tableShare.permissions, isDirectory: isDirectory) { // Can edit
                labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
            }
            if NCSharePermissions.getPermissionValue(canRead: false, canCreate: true, canEdit: false, canDelete: false, canShare: false, isDirectory: isDirectory) == tableShare.permissions { // File request
                labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
            }
            if NCSharePermissions.getPermissionValue(canCreate: false, canEdit: false, canDelete: false, canShare: true, isDirectory: isDirectory) == tableShare.permissions { // Read only
                labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
            }

            if tableShare.shareType == NKShare.ShareType.email.rawValue {
                labelTitle.text = tableShare.shareWithDisplayname
                imageItem.image = NCUtility().loadImage(named: "envelope.circle.fill", colors: [NCBrandColor.shared.getElement(account: tableShare.account)])
            }
        }
        
        statusStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openQuickStatus)))
        labelQuickStatus.textColor = NCBrandColor.shared.customer
        imageDownArrow.image = utility.loadImage(named: "arrowtriangle.down.circle", colors: [NCBrandColor.shared.customer])
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setupCellAppearance()
        }
    }

    func configure(with share: tableShare?, at indexPath: IndexPath, isDirectory: Bool, title: String) {
        self.tableShare = share
        self.indexPath = indexPath
        self.isDirectory = isDirectory
        setupCellAppearance(titleAppendString: title)

//        let shareLinksCountString = shareLinksCount > 0 ? String(shareLinksCount) : ""
//        setupCellAppearance(titleAppendString: shareLinksCountString)
//        setupCellAppearance(titleAppendString: String(shareLinksCount))
    }

    private func setupCellAppearance(titleAppendString: String? = nil) {
        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        labelTitle.textColor = NCBrandColor.shared.label
        labelQuickStatus.textColor = NCBrandColor.shared.shareBlueColor

        buttonDetail.setTitleColor(NCBrandColor.shared.shareBlackColor, for: .normal)
        buttonCopy.setImage(UIImage(named: "share")?.image(color: NCBrandColor.shared.brand, size: 24), for: .normal)

        imageRightArrow.image = UIImage(named: "rightArrow")?.imageColor(NCBrandColor.shared.shareBlueColor)
        imageExpiredDateSet.image = UIImage(named: "calenderNew")?.imageColor(NCBrandColor.shared.shareBlueColor)
        imagePasswordSet.image = UIImage(named: "lockNew")?.imageColor(NCBrandColor.shared.shareBlueColor)

        buttonDetail.setTitle(NSLocalizedString("_share_details_", comment: ""), for: .normal)
        labelTitle.text = NSLocalizedString("_share_link_", comment: "")

        if let tableShare = tableShare, let titleAppendString {
            if !tableShare.label.isEmpty {
                labelTitle.text? += " (\(tableShare.label))"
            } else {
                labelTitle.text?.append(" \(titleAppendString)")
            }
        }
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

    // MARK: - Actions

    @IBAction func touchUpInsideCopy(_ sender: Any) {
        delegate?.tapCopy(with: tableShare, sender: sender)
    }

    @IBAction func touchUpInsideDetail(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @IBAction func quickStatusClicked(_ sender: UIButton) {
        delegate?.quickStatus(with: tableShare, sender: sender)
    }
}

protocol NCShareLinkCellDelegate: AnyObject {
    func tapCopy(with tableShare: tableShare?, sender: Any)
    func tapMenu(with tableShare: tableShare?, sender: Any)
    func quickStatus(with tableShare: tableShare?, sender: Any)
}
