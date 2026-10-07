// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2021 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

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
    }

    private func setupCellAppearance(titleAppendString: String? = nil) {
//        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        labelTitle.textColor = NCBrandColor.shared.label
        labelQuickStatus.textColor = NCBrandColor.shared.shareBlueColor

        buttonDetail.setTitleColor(NCBrandColor.shared.shareBlackColor, for: .normal)
        buttonCopy.setImage(UIImage(named: "share")?.image(color: NCBrandColor.shared.brand, size: 24), for: .normal)

        imageRightArrow.image = UIImage(named: "rightArrow")?.image(color: NCBrandColor.shared.shareBlueColor)
        imageExpiredDateSet.image = UIImage(named: "calenderNew")?.image(color: NCBrandColor.shared.shareBlueColor)
        imagePasswordSet.image = UIImage(named: "lockNew")?.image(color: NCBrandColor.shared.shareBlueColor)

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

    // MARK: - Actions

    @IBAction func touchUpInsideCopy(_ sender: Any) {
        delegate?.tapCopy(with: tableShare, sender: sender)
    }

    @IBAction func touchUpInsideDetail(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @IBAction func quickStatusClicked(_ sender: UIButton) {
        delegate?.tapQuickStatus(with: tableShare, sender: sender)
    }
    
    @IBAction func touchUpCopy(_ sender: Any) {
        delegate?.tapCopy(with: tableShare, sender: sender)
    }

    @IBAction func touchUpMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender)
    }

    @objc func openQuickStatus(_ sender: UITapGestureRecognizer) {
        delegate?.tapQuickStatus(with: tableShare, sender: sender.view ?? sender)
    }
}

protocol NCShareLinkCellDelegate: AnyObject {
    func tapCopy(with tableShare: tableShare?, sender: Any)
    func tapMenu(with tableShare: tableShare?, sender: Any)
    func tapQuickStatus(with tableShare: tableShare?, sender: Any)
}
