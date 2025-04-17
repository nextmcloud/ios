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
    let utility = NCUtility()
    let utilityFileSystem = NCUtilityFileSystem()
    
    func setupUI(with metadata: tableMetadata) {
        backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        fileName.textColor = NCBrandColor.shared.label
        info.textColor = NCBrandColor.shared.textInfo
        backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        if FileManager.default.fileExists(atPath: utilityFileSystem.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag)) {
            fullWidthImageView.image = utility.getImageMetadata(metadata, for: frame.height)
        if let image = NCUtility().getImage(ocId: metadata.ocId, etag: metadata.etag, ext: NCGlobal.shared.previewExt1024) {
            fullWidthImageView.image = image
            fullWidthImageView.contentMode = .scaleAspectFill
            imageView.isHidden = true
        } else {
            if metadata.directory {
                imageView.image = UIImage.init(named: "folder")
                imageView.image = metadata.e2eEncrypted ? NCImageCache.shared.getFolderEncrypted() : NCImageCache.shared.getFolder()
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
            favorite.setImage(utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite], size: 24), for: .normal)
        } else {
            favorite.setImage(utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.textInfo], size: 24), for: .normal)
        }
        info.textColor = NCBrandColor.shared.optionItem
        info.text = utilityFileSystem.transformedSize(metadata.size) + ", " + utility.dateDiff(metadata.date as Date)
    }
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }
        NCNetworking.shared.favoriteMetadata(metadata) { error in
            if error == .success {
                guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) else { return }
                if metadata.favorite {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite], size: 24), for: .normal)
                } else {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.textInfo], size: 24), for: .normal)
                }
            } else {
                NCContentPresenter().showError(error: error)
            }
        }
    }
}
