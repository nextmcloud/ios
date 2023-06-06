//
//  NCShareAdvancePermissionHeader.swift
//  Nextcloud
//
//  Created by T-systems on 10/08/21.
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

class NCShareAdvancePermissionHeader: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var fullWidthImageView: UIImageView!
    var ocId = ""
        
    func setupUI(with metadata: tableMetadata) {
        backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        fileName.textColor = NCBrandColor.shared.label
        info.textColor = NCBrandColor.shared.textInfo
        backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag)) {
            fullWidthImageView.image = NCUtility.shared.getImageMetadata(metadata, for: frame.height)
            fullWidthImageView.contentMode = .scaleAspectFill
            imageView.isHidden = true
        } else {
            if metadata.directory {
                imageView.image = UIImage.init(named: "folder")
            } else if !metadata.iconName.isEmpty {
                imageView.image = UIImage.init(named: metadata.iconName)
            } else {
                imageView.image = UIImage.init(named: "file")
            }
        }
        favorite.setNeedsUpdateConstraints()
        favorite.layoutIfNeeded()
        fileName.text = metadata.fileNameView
        fileName.textColor = NCBrandColor.shared.fileFolderName
        if metadata.favorite {
            favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
        } else {
            favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
        }
        info.textColor = NCBrandColor.shared.optionItem
        info.text = CCUtility.transformedSize(metadata.size) + ", " + CCUtility.dateDiff(metadata.date as Date)
    }
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }
        NCNetworking.shared.favoriteMetadata(metadata) { error in
            if error == .success {
                guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) else { return }
                if metadata.favorite {
                    self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                } else {
                    self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                }
            } else {
                NCContentPresenter.shared.showError(error: error)
            }
        }
    }
}
