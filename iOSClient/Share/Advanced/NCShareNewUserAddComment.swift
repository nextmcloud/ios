// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2006 TSI-mc
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

class NCShareNewUserAddComment: UIViewController, NCShareNavigationTitleSetting {

    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelNote: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSendShare: UIButton!
    @IBOutlet weak var buttonContainerView: UIView!
    let contentInsets: CGFloat = 16
    public var share: NCTableShareable!
    public var metadata: tableMetadata!
    var isNewShare: Bool { share is NCTableShareOptions }
    var networking: NCShareNetworking?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        changeTheming()
        setupHeader()
    }
    
    @objc func changeTheming() {
        self.view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.commentTextView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        commentTextView.textColor = NCBrandColor.shared.label
        btnCancel.setTitleColor(NCBrandColor.shared.label, for: .normal)
        btnCancel.layer.borderColor = NCBrandColor.shared.label.cgColor
        btnCancel.backgroundColor = .clear
        buttonContainerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        btnSendShare.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        btnSendShare.setTitleColor(.white, for: .normal)
        commentTextView.layer.borderColor = NCBrandColor.shared.label.cgColor
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.cornerRadius = 4.0
        commentTextView.showsVerticalScrollIndicator = false
        commentTextView.textContainerInset = UIEdgeInsets(top: contentInsets, left: contentInsets, bottom: contentInsets, right: contentInsets)
        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        btnCancel.layer.cornerRadius = 10
        btnCancel.layer.masksToBounds = true
        btnCancel.layer.borderWidth = 1
        btnSendShare.setTitle(NSLocalizedString("_send_share_", comment: ""), for: .normal)
        btnSendShare.layer.cornerRadius = 10
        btnSendShare.layer.masksToBounds = true
        labelSharing.text = NSLocalizedString("_sharing_", comment: "")
        labelNote.text = NSLocalizedString("_share_note_recipient_", comment: "")
        commentTextView.inputAccessoryView = UIToolbar.doneToolbar { [weak self] in
            self?.commentTextView.resignFirstResponder()
        }
    }
    
    func setupHeader(){
        guard let headerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as? NCShareAdvancePermissionHeader) else { return }
        headerView.ocId = metadata.ocId
        headerContainerView.addSubview(headerView)
        headerView.frame = headerContainerView.frame
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: headerContainerView.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: headerContainerView.rightAnchor).isActive = true
        headerView.setupUI(with: metadata)
    }

    @IBAction func cancelClicked(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func sendShareClicked(_ sender: Any) {
        share.note = commentTextView.text
        if isNewShare {
            networking?.createShare(option: share)
        } else {
            networking?.updateShare(option: share)
        }
        self.navigationController?.popToRootViewController(animated: true)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let globalTextViewFrame = commentTextView.superview?.convert(commentTextView.frame, to: nil) else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let portionCovoredByLeyboard = globalTextViewFrame.maxY - keyboardScreenEndFrame.minY

        if notification.name == UIResponder.keyboardWillHideNotification || portionCovoredByLeyboard < 0 {
            commentTextView.contentInset = .zero
        } else {
            commentTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: portionCovoredByLeyboard, right: 0)
        }
        commentTextView.scrollIndicatorInsets = commentTextView.contentInset
    }

    @objc func keyboardWillShow(notification: Notification) {
        if UIScreen.main.bounds.width <= 375 {
            if view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 200
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
