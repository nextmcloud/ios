// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

protocol NCTrashCellProtocol {
    var objectId: String { get set }
    var labelTitle: UILabel! { get set }
    var labelInfo: UILabel! { get set }
    var imageItem: UIImageView! { get set }
    var account: String { get set }

    func selected(_ status: Bool, isEditMode: Bool, account: String)
}

extension NCTrashCellProtocol where Self: UICollectionViewCell {
    mutating func setupCellUI(tableTrash: tableTrash, image: UIImage?) {
        self.objectId = tableTrash.fileId
        self.labelTitle.text = tableTrash.trashbinFileName
        self.labelTitle.textColor = NCBrandColor.shared.textColor
        if self is NCTrashListCell {
            self.labelInfo?.text = NCUtility().getRelativeDateTitle(tableTrash.trashbinDeletionTime as Date)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            self.labelInfo?.text = dateFormatter.string(from: tableTrash.trashbinDeletionTime as Date)
        }
        if tableTrash.directory {
            self.imageItem.image = NCImageCache.shared.getFolder()
        } else {
            self.imageItem.image = image
//            self.labelInfo?.text = (self.labelInfo?.text ?? "") + " · " + NCUtilityFileSystem().transformedSize(tableTrash.size)
        }
        self.labelInfo?.text = (self.labelInfo?.text ?? "") + " · " + NCUtilityFileSystem().transformedSize(tableTrash.size)
        self.accessibilityLabel = tableTrash.trashbinFileName + ", " + (self.labelInfo?.text ?? "")
    }
}
