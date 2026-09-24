// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

class NCMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageVisualEffect: UIVisualEffectView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!

    var ocId: String = ""
    var date: Date?

    override func awakeFromNib() {
        super.awakeFromNib()
        initCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initCell()
    }

    func initCell() {
        imageStatus.image = nil
        imageItem.image = nil
        imageVisualEffect.alpha = 0.4
//        imageSelect.image = NCImageCache.shared.getImageCheckedYes(color: color)
        imageVisualEffect.isHidden = true
        imageSelect.isHidden = true
    }

    func selected(_ status: Bool, color: UIColor) {
        if status {
//            imageSelect.isHidden = false
            imageVisualEffect.isHidden = false
            imageSelect.image = NCImageCache.shared.getImageCheckedYes(color: color)
        } else {
//            imageSelect.isHidden = true
            imageVisualEffect.isHidden = true
            imageSelect.image = NCImageCache.shared.getImageCheckedNo(color: color)
        }
    }
}
