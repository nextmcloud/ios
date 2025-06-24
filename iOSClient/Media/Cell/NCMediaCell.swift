//
//  NCMediaCell.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/02/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
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

class NCMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageVisualEffect: UIVisualEffectView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var label: UILabel!

    var ocId: String = ""
    var datePhotosOriginal: Date?
    private var objectId: String = ""
    private var user: String = ""
    
    var filePreviewImageView: UIImageView? {
        get { return imageItem }
        set {}
    }

    var fileObjectId: String? {
        get { return objectId }
        set { objectId = newValue ?? "" }
    }

    var fileUser: String? {
        get { return user }
        set { user = newValue ?? "" }
    }

    var fileDate: Date? {
        get { return datePhotosOriginal }
        set {
            datePhotosOriginal = newValue
            if let datePhotosOriginal {
                label.text = NCUtility().getTitleFromDate(datePhotosOriginal)
            }
        }
    }

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
        imageSelect.image = NCImageCache.shared.getImageCheckedYes()
        imageVisualEffect.isHidden = true
        imageSelect.isHidden = true
    }

    func selected(_ status: Bool) {
        if status {
//            imageSelect.isHidden = false
            imageVisualEffect.isHidden = false
            imageSelect.image = NCImageCache.shared.getImageCheckedYes()
        } else {
//            imageSelect.isHidden = true
            imageVisualEffect.isHidden = true
            imageSelect.image = NCImageCache.shared.getImageCheckedNo()
        }
    }
}
