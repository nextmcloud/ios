// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

protocol NCShareAdvanceFooterDelegate: AnyObject {
    var isNewShare: Bool { get }
    func dismissShareAdvanceView(shouldSave: Bool)
}

class NCShareAdvancePermissionFooter: UIView {
    @IBOutlet weak var buttonCancel: UIButton!
    @IBOutlet weak var buttonNext: UIButton!
    weak var delegate: NCShareAdvanceFooterDelegate?

    func setupUI(delegate: NCShareAdvanceFooterDelegate?, account: String) {
        self.delegate = delegate
        buttonCancel.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        buttonNext.addTarget(self, action: #selector(nextClicked), for: .touchUpInside)
        buttonCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        buttonNext.setTitle(NSLocalizedString(delegate?.isNewShare == true ? "_next_" : "_apply_changes_", comment: ""), for: .normal)
        buttonCancel.layer.cornerRadius = 10
        buttonCancel.layer.masksToBounds = true
        buttonCancel.layer.borderWidth = 1
        buttonCancel.layer.borderColor = NCBrandColor.shared.textColor2.cgColor
        buttonCancel.backgroundColor = .secondarySystemBackground
        buttonCancel.addTarget(self, action: #selector(cancelClicked(_:)), for: .touchUpInside)
        buttonCancel.setTitleColor(NCBrandColor.shared.textColor2, for: .normal)

        buttonNext.setTitle(NSLocalizedString(delegate?.isNewShare == true ? "_share_" : "_save_", comment: ""), for: .normal)
        buttonNext.layer.cornerRadius = 25
        buttonNext.layer.masksToBounds = true
        buttonNext.backgroundColor = NCBrandColor.shared.getElement(account: account)
        buttonNext.addTarget(self, action: #selector(nextClicked(_:)), for: .touchUpInside)

        addShadow(location: .top)
        layer.cornerRadius = 10
        layer.masksToBounds = true
        backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        buttonCancel.setTitleColor(NCBrandColor.shared.label, for: .normal)
        buttonCancel.layer.borderColor = NCBrandColor.shared.label.cgColor
        buttonCancel.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        buttonNext.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        buttonNext.setTitleColor(.white, for: .normal)
        buttonNext.layer.cornerRadius = 10
        buttonNext.layer.masksToBounds = true
    }

    @objc func cancelClicked(_ sender: Any?) {
        delegate?.dismissShareAdvanceView(shouldSave: false)
    }

    @objc func nextClicked(_ sender: Any?) {
        delegate?.dismissShareAdvanceView(shouldSave: true)
    }
}
