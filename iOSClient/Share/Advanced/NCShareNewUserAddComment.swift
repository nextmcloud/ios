//
//  NCShareNewUserAddComment.swift
//  Nextcloud
//
//  Created by TSI-mc on 21/06/21.
//  Copyright © 2022 All rights reserved.
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
//

import UIKit
import NextcloudKit

class NCShareNewUserAddComment: UIViewController, NCShareNavigationTitleSetting {

    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var sharingLabel: UILabel!
    @IBOutlet weak var noteTextField: UITextView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSendShare: UIButton!
    @IBOutlet weak var buttonContainerView: UIView!

    let contentInsets: CGFloat = 16
    var onDismiss: (() -> Void)?

    public var share: Shareable!
    public var metadata: tableMetadata!

    var isNewShare: Bool { share is NCTableShareOptions }
    var networking: NCShareNetworking?

    var isFromMenu: Bool = false
    ///
    /// The possible download limit associated with this share.
    ///
    /// This can only be created after the share has been actually created due to its requirement of the share token provided by the server.
    ///
    var downloadLimit: DownloadLimitViewModel = .unlimited
    var downloadLimitChanged: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitle()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        btnCancel.setTitleColor(NCBrandColor.shared.label, for: .normal)
        btnCancel.layer.borderColor = NCBrandColor.shared.label.cgColor
        btnCancel.backgroundColor = .clear
        buttonContainerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        btnSendShare.backgroundColor = NCBrandColor.shared.customer //setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        btnSendShare.setTitleColor(.white, for: .normal)

        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        btnCancel.layer.cornerRadius = 10
        btnCancel.layer.masksToBounds = true
        btnCancel.layer.borderWidth = 1
        btnSendShare.setTitle(NSLocalizedString("_send_share_", comment: ""), for: .normal)
        btnSendShare.layer.cornerRadius = 10
        btnSendShare.layer.masksToBounds = true

        if !self.isFromMenu {
            buttonContainerView.isHidden = true
        }
        
        sharingLabel.text = NSLocalizedString("_share_note_recipient_", comment: "")

        noteTextField.textContainerInset = UIEdgeInsets(top: contentInsets, left: contentInsets, bottom: contentInsets, right: contentInsets)
        noteTextField.text = share.note
        let toolbar = UIToolbar.toolbar {
            self.noteTextField.resignFirstResponder()
            self.noteTextField.text = ""
            self.share.note = ""
        } onDone: {
            self.noteTextField.resignFirstResponder()
            self.share.note = self.noteTextField.text
            if !self.isFromMenu {
                self.navigationController?.popViewController(animated: true)
            }
        }

        noteTextField.inputAccessoryView = toolbar.wrappedSafeAreaContainer

        guard let headerView = (Bundle.main.loadNibNamed("NCShareHeader", owner: self, options: nil)?.first as? NCShareHeader) else { return }
        headerContainerView.addSubview(headerView)
        headerView.frame = headerContainerView.frame
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: headerContainerView.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: headerContainerView.rightAnchor).isActive = true

        headerView.setupUI(with: metadata)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        share.note = noteTextField.text
        onDismiss?()
    }

    @IBAction func cancelClicked(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func sendShareClicked(_ sender: Any) {
        share.note = noteTextField.text
        if isNewShare {
            networking?.createShare(share, downloadLimit: self.downloadLimit)
        } else {
            networking?.updateShare(share, downloadLimit: self.downloadLimit, changeDownloadLimit: downloadLimitChanged)
        }
    
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let globalTextViewFrame = noteTextField.superview?.convert(noteTextField.frame, to: nil) else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let portionCovoredByLeyboard = globalTextViewFrame.maxY - keyboardScreenEndFrame.minY

        if notification.name == UIResponder.keyboardWillHideNotification || portionCovoredByLeyboard < 0 {
            noteTextField.contentInset = .zero
        } else {
            noteTextField.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: portionCovoredByLeyboard, right: 0)
        }

        noteTextField.scrollIndicatorInsets = noteTextField.contentInset
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
