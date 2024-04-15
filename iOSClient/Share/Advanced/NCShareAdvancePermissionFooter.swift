//
//  NCShareAdvancePermissionFooter.swift
//  Nextcloud
//
//  Created by T-systems on 09/08/21.
//  Copyright © 2022 Henrik Storch. All rights reserved.
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
//

import UIKit

protocol NCShareAdvanceFotterDelegate: AnyObject {
    var isNewShare: Bool { get }
    func dismissShareAdvanceView(shouldSave: Bool)
}

class NCShareAdvancePermissionFooter: UIView {
    @IBOutlet weak var buttonCancel: UIButton!
    @IBOutlet weak var buttonNext: UIButton!
    weak var delegate: NCShareAdvanceFotterDelegate?

    func setupUI(delegate: NCShareAdvanceFotterDelegate?) {
        self.delegate = delegate
        buttonCancel.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        buttonNext.addTarget(self, action: #selector(nextClicked), for: .touchUpInside)
        buttonCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        buttonNext.setTitle(NSLocalizedString(delegate?.isNewShare == true ? "_next_" : "_apply_changes_", comment: ""), for: .normal)
        buttonCancel.layer.cornerRadius = 10
        buttonCancel.layer.masksToBounds = true
        buttonCancel.layer.borderWidth = 1
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

    @objc func cancelClicked() {
        delegate?.dismissShareAdvanceView(shouldSave: false)
    }

    @objc func nextClicked() {
        delegate?.dismissShareAdvanceView(shouldSave: true)
    }
}
