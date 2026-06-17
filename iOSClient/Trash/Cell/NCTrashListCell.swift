// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

protocol NCTrashListCellDelegate: AnyObject {
    func tapRestoreListItem(with objectId: String, image: UIImage?, sender: Any)
    func tapMoreListItem(with objectId: String, image: UIImage?, sender: Any)
}

class NCTrashListCell: UICollectionViewCell, NCTrashCellProtocol {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var imageItemLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var imageRestore: UIImageView!
    @IBOutlet weak var imageMore: UIImageView!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var buttonRestore: UIButton!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    weak var delegate: NCTrashListCellDelegate?
    var identifier = ""

    var statusImg: UIImageView? {
        get { return imageStatus }
        set { imageStatus = newValue }
    }
    var account = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        initCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initCell()
    }

    func initCell() {
        isAccessibilityElement = true

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("_restore_", comment: ""),
                target: self,
                selector: #selector(touchUpInsideRestore(_:))),
            UIAccessibilityCustomAction(
                name: NSLocalizedString("_delete_", comment: ""),
                target: self,
                selector: #selector(touchUpInsideMore(_:)))

        ]

//        imageRestore.image = NCUtility().loadImage(named: "arrow.counterclockwise", colors: [NCBrandColor.shared.iconImageColor])
//        imageMore.image = NCUtility().loadImage(named: "trash", colors: [.red])
        imageRestore.image = NCUtility().loadImage(named: "restore", colors: [NCBrandColor.shared.iconImageColor])
        imageMore.image = NCUtility().loadImage(named: "trashIcon", colors: [NCBrandColor.shared.iconImageColor]) //NCUtility().loadImage(named: "trashIcon", colors: [.red])
        image.layer.cornerRadius = 6
        image.layer.masksToBounds = true

        separator.backgroundColor = .separator
        separatorHeightConstraint.constant = 0.5
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapMoreListItem(with: identifier, image: image.image, sender: sender)
    }

    @IBAction func touchUpInsideRestore(_ sender: Any) {
        delegate?.tapRestoreListItem(with: identifier, image: image.image, sender: sender)
    }

    func selected(_ status: Bool, isEditMode: Bool, account: String) {
        if isEditMode {
            imageItemLeftConstraint.constant = 45
            imageSelect.isHidden = false
            imageRestore.isHidden = true
            buttonRestore.isHidden = true
            imageMore.isHidden = true
            buttonMore.isHidden = true
        } else {
            imageItemLeftConstraint.constant = 10
            imageSelect.isHidden = true
            imageRestore.isHidden = false
            buttonRestore.isHidden = false
            imageMore.isHidden = false
            buttonMore.isHidden = false
            backgroundView = nil
        }
        if status {
            var blurEffectView: UIView?
            blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            blurEffectView?.backgroundColor = .lightGray
            blurEffectView?.frame = self.bounds
            blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageSelect.image = NCImageCache.shared.getImageCheckedYes()
            backgroundView = blurEffectView
            separator.isHidden = true
        } else {
            imageSelect.image = NCImageCache.shared.getImageCheckedNo()
            backgroundView = nil
            separator.isHidden = false
        }

    }
}
