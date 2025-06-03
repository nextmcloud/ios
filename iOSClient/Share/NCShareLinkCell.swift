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

class NCShareLinkCell: UITableViewCell {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonCopy: UIButton!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var btnQuickStatus: UIButton!
    @IBOutlet weak var imageDownArrow: UIImageView!
    @IBOutlet weak var labelQuickStatus: UILabel!

    private let iconShare: CGFloat = 200
    var tableShare: tableShare?
    weak var delegate: NCShareLinkCellDelegate?
    var isInternalLink = false
    var indexPath = IndexPath()

    override func prepareForReuse() {
        super.prepareForReuse()
        isInternalLink = false
        tableShare = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        buttonMenu.contentMode = .scaleAspectFill
        imageItem.image = UIImage(named: "sharebylink")?.image(color: NCBrandColor.shared.label, size: 30)
        buttonCopy.setImage(UIImage.init(named: "shareCopy")!.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
        buttonMenu.setImage(NCImageCache.images.buttonMore.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
        buttonMenu.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.customer
    }

    func setupCellUI() {
        let permissions = NCPermissions()
        guard let tableShare = tableShare else {
            return
        }
        contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        labelTitle.textColor = NCBrandColor.shared.label
        
        if tableShare.permissions == permissions.permissionCreateShare {
            labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
        } else {
            // Read Only
            if permissions.isAnyPermissionToEdit(tableShare.permissions) {
                labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
            } else {
                labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
            }
        }
    }
    
    @IBAction func touchUpInsideCopy(_ sender: Any) {
        delegate?.tapCopy(with: tableShare, sender: sender)
    }
    
    @IBAction func touchUpInsideMenu(_ sender: Any) {
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
