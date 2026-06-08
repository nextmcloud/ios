// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

class NCPhotoCell: UICollectionViewCell, UIGestureRecognizerDelegate, NCCellMainProtocol {
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageVisualEffect: UIVisualEffectView!

    var metadata: tableMetadata?
    var previewImg: UIImageView? {
        get { return imageItem }
        set { imageItem = newValue }
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
        accessibilityHint = nil
        accessibilityLabel = nil
        accessibilityValue = nil

        imageItem.image = nil

        imageVisualEffect.isHidden = false
        imageVisualEffect.effect = nil
        imageVisualEffect.alpha = 0
        imageVisualEffect.isUserInteractionEnabled = false
        imageVisualEffect.backgroundColor = UIColor.white.withAlphaComponent(0.2)
    }

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        return nil
    }

    @objc private func handleTapObserver(_ g: UITapGestureRecognizer) {
        let location = g.location(in: contentView)

        if buttonMore.frame.contains(location) {
            delegate?.onMenuIntent(with: metadata)
        }
    }

    func setButtonMore(image: UIImage) {
        buttonMore.setImage(image, for: .normal)
    }

    func hideButtonMore(_ status: Bool) {
       // buttonMore.isHidden = status NO MORE USED
    }

    func hideImageStatus(_ status: Bool) {
        imageStatus.isHidden = status
    }

    func selected(_ status: Bool, isEditMode: Bool) {
        // E2EE - remove encrypt folder selection
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId), metadata.e2eEncrypted {
    func selected(_ status: Bool, isEditMode: Bool, color: UIColor) {
        imageVisualEffect.alpha = status ? 1 : 0
        imageSelect.alpha = status ? 1 : 0
        imageSelect.image = NCImageCache.shared.getImageCheckedYes(color: color)
        // E2EE - remove encrypt folder selection
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(self.metadata?.ocId), metadata.e2eEncrypted {
            imageSelect.isHidden = true
        } else {
            imageSelect.isHidden = isEditMode ? false : true
        }
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

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }
}

extension NCCollectionViewCommon {
    // MARK: - LAYOUT PHOTO
    //
    func photoCell(cell: NCPhotoCell, indexPath: IndexPath, metadata: tableMetadata) -> NCPhotoCell {
        let ext = global.getSizeExtension(column: self.numberOfColumns)

        cell.metadata = metadata

        // Image
        //
        if let image = NCImageCache.shared.getImageCache(ocId: metadata.ocId, etag: metadata.etag, ext: ext) {
            cell.previewImg?.image = image
            cell.previewImg?.contentMode = .scaleAspectFill
        } else {
            if isPinchGestureActive || ext == global.previewExt512 || ext == global.previewExt1024 {
                cell.previewImg?.image = self.utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: ext, userId: metadata.userId, urlBase: metadata.urlBase)
            }

            DispatchQueue.global(qos: .userInteractive).async {
                let image = self.utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: ext, userId: metadata.userId, urlBase: metadata.urlBase)
                if let image {
                    self.imageCache.addImageCache(ocId: metadata.ocId, etag: metadata.etag, image: image, ext: ext, cost: indexPath.row)
                    DispatchQueue.main.async {
                        cell.previewImg?.image = image
                        cell.previewImg?.contentMode = .scaleAspectFill
                    }
                } else {
                    DispatchQueue.main.async {
                        cell.previewImg?.contentMode = .scaleAspectFit
                        if metadata.iconName.isEmpty {
                            cell.previewImg?.image = NCImageCache.shared.getImageFile()
                        } else {
                            cell.previewImg?.image = self.utility.loadImage(named: metadata.iconName, useTypeIconFile: true, account: metadata.account)
                        }
                    }
                }
            }
        }

        // Edit mode
        //
        if fileSelect.contains(metadata.ocId) {
            cell.selected(true, isEditMode: isEditMode, color: NCBrandColor.shared.getElement(account: session.account))
        } else {
            cell.selected(false, isEditMode: isEditMode, color: NCBrandColor.shared.getElement(account: session.account))
        }

        return cell
    }
}
