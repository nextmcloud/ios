//
//  NCShareEmailFieldCell.swift
//  Nextcloud
//
//  Created by A200020526 on 01/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit
import MarqueeLabel
import NextcloudKit

enum Tag {
    static let searchField = 999
}

class NCShareEmailFieldCell: UITableViewCell {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var labelOrLink: UILabel!
    @IBOutlet weak var btnContact: UIButton!
    @IBOutlet weak var labelSeparator1: UILabel!
    @IBOutlet weak var labelSeparator2: UILabel!
    @IBOutlet weak var labelSendLinkByMail: UILabel!
    @IBOutlet weak var labelSharedWithBy: UILabel!
    @IBOutlet weak var labelResharingAllowed: UILabel!
    @IBOutlet weak var topConstraintResharingView: NSLayoutConstraint!
    @IBOutlet weak var viewOrLinkSeparator: UIView!

    var ocId = ""

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setupCell(with metadata: tableMetadata) {
        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        ocId = metadata.ocId

        configureSearchField()
        configureContactButton()
        configureLabels()
        updateCanReshareUI()
        
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func configureSearchField() {
        searchField.layer.cornerRadius = 5
        searchField.layer.masksToBounds = true
        searchField.layer.borderWidth = 1
        searchField.layer.borderColor = NCBrandColor.shared.label.cgColor
        searchField.text = ""
        searchField.textColor = NCBrandColor.shared.label
        searchField.attributedPlaceholder = NSAttributedString(
            string: NSLocalizedString("_shareLinksearch_placeholder_", comment: ""),
            attributes: [.foregroundColor: NCBrandColor.shared.gray60]
        )
        searchField.tag = Tag.searchField
        setDoneButton(sender: searchField)
    }

    private func configureContactButton() {
        btnContact.layer.cornerRadius = 5
        btnContact.layer.masksToBounds = true
        btnContact.layer.borderWidth = 1
        btnContact.layer.borderColor = NCBrandColor.shared.label.cgColor
        btnContact.tintColor = NCBrandColor.shared.label
        let contactImage = NCUtility().loadImage(named: "contact").image(color: NCBrandColor.shared.label, size: 24)
        btnContact.setImage(contactImage, for: .normal)
    }

    private func configureLabels() {
        labelOrLink.text = NSLocalizedString("_share_or_", comment: "")
        labelSendLinkByMail.text = NSLocalizedString("_share_send_link_by_mail_", comment: "")
        labelSharedWithBy.text = NSLocalizedString("_share_received_shares_text_", comment: "")
        labelResharingAllowed.text = NSLocalizedString("_share_reshare_allowed_", comment: "")
        
        labelSendLinkByMail.textColor = NCBrandColor.shared.label
        labelSharedWithBy.textColor = NCBrandColor.shared.label
        labelResharingAllowed.textColor = NCBrandColor.shared.label
    }

    func updateCanReshareUI() {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }

        let isCurrentUser = NCShareCommon().isCurrentUserIsFileOwner(fileOwnerId: metadata.ownerId)
        let canReshare = (metadata.sharePermissionsCollaborationServices & NCPermissions().permissionShareShare) != 0

        labelSharedWithBy.isHidden = isCurrentUser
        labelResharingAllowed.isHidden = isCurrentUser

        if !canReshare {
            searchField.isUserInteractionEnabled = false
            searchField.alpha = 0.5
            btnContact.isEnabled = false
            btnContact.alpha = 0.5
        }

        if !isCurrentUser {
            let ownerName = metadata.ownerDisplayName
            let fullText = NSLocalizedString("_share_received_shares_text_", comment: "") + " " + ownerName
            let attributed = NSMutableAttributedString(string: fullText)

            if let range = fullText.range(of: ownerName) {
                let nsRange = NSRange(range, in: fullText)
                attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: nsRange)
            }

            labelSharedWithBy.attributedText = attributed
            labelSharedWithBy.numberOfLines = 0

            labelResharingAllowed.text = canReshare
                ? NSLocalizedString("_share_reshare_allowed_", comment: "")
                : NSLocalizedString("_share_reshare_not_allowed_", comment: "")

            topConstraintResharingView.constant = 15
        } else {
            topConstraintResharingView.constant = 0
        }

        viewOrLinkSeparator.isHidden = !canReshare
    }

    func updateShareUI(ocId: String, count: Int) {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }

        let isCurrentUser = NCShareCommon().isCurrentUserIsFileOwner(fileOwnerId: metadata.ownerId)
        let canReshare = (metadata.sharePermissionsCollaborationServices & NCPermissions().permissionShareShare) != 0

        if !isCurrentUser {
            if canReshare {
                labelOrLink.isHidden = true
                labelSeparator1.isHidden = true
                labelSeparator2.isHidden = true
            }
        }
    }

    @objc func cancelDatePicker() {
        self.searchField.endEditing(true)
    }

    private func setDoneButton(sender: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: NSLocalizedString("_done_", comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancelDatePicker)
        )
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([space, doneButton], animated: false)
        sender.inputAccessoryView = toolbar
    }

    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        // Hook for favorite action if needed
    }

    @IBAction func touchUpInsideDetails(_ sender: UIButton) {
        // Hook for toggling detail visibility if needed
    }

    @objc func longTap(_ sender: UIGestureRecognizer) {
        let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_copied_path_")
        NCContentPresenter().showInfo(error: error)
    }
}
