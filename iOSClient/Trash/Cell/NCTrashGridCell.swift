//
//  NCTrashGridCell.swift
//  Nextcloud
//
//  Created by A200073704 on 27/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

protocol NCTrashGridCellDelegate: AnyObject {
    func tapMoreGridItem(with objectId: String, image: UIImage?, sender: Any)
}

class NCTrashGridCell: UICollectionViewCell, NCTrashCellProtocol {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelSubinfo: UILabel!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var imageVisualEffect: UIVisualEffectView!

    weak var delegate: NCTrashGridCellDelegate?
    var objectId = ""
    var indexPath = IndexPath()
    var account = ""
    var user = ""

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
        isAccessibilityElement = true

        imageItem.layer.cornerRadius = 6
        imageItem.layer.masksToBounds = true

        imageVisualEffect.layer.cornerRadius = 6
        imageVisualEffect.clipsToBounds = true
        imageVisualEffect.alpha = 0.5

        labelTitle.text = ""
        labelInfo.text = ""
        labelSubinfo.text = ""
    }

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        return nil
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapMoreGridItem(with: objectId, image: imageItem.image, sender: sender)
    }

    fileprivate func setA11yActions() {
        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("_more_", comment: ""),
                target: self,
                selector: #selector(touchUpInsideMore(_:)))
        ]
    }

    func setButtonMore(image: UIImage) {
        buttonMore.setImage(image, for: .normal)
        setA11yActions()
    }

    func hideButtonMore(_ status: Bool) {
        buttonMore.isHidden = status
    }

    func selected(_ status: Bool, isEditMode: Bool, account: String) {
        if isEditMode {
            buttonMore.isHidden = true
            accessibilityCustomActions = nil
        } else {
            buttonMore.isHidden = false
            setA11yActions()
        }
        if status {
            imageSelect.image = NCImageCache.shared.getImageCheckedYes()
            imageSelect.isHidden = false
            imageVisualEffect.isHidden = false
        } else {
            imageSelect.isHidden = true
            imageVisualEffect.isHidden = true
        }
    }

    func writeInfoDateSize(date: NSDate, size: Int64) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current

        labelInfo.text = dateFormatter.string(from: date as Date)
        labelSubinfo.text = NCUtilityFileSystem().transformedSize(size)
    }

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }
}

// MARK: - Grid Layout

class NCTrashGridLayout: UICollectionViewFlowLayout {

    var heightLabelPlusButton: CGFloat = 60
    var marginLeftRight: CGFloat = 10
    var itemForLine: CGFloat = 3
    var itemWidthDefault: CGFloat = 140

    // MARK: - View Life Cycle

    override init() {
        super.init()

        sectionHeadersPinToVisibleBounds = false

        minimumInteritemSpacing = 1
        minimumLineSpacing = marginLeftRight

        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsets(top: 10, left: marginLeftRight, bottom: 0, right: marginLeftRight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var itemSize: CGSize {
        get {
            if let collectionView = collectionView {

                if collectionView.frame.width < 400 {
                    itemForLine = 3
                } else {
                    itemForLine = collectionView.frame.width / itemWidthDefault
                }

                let itemWidth: CGFloat = (collectionView.frame.width - marginLeftRight * 2 - marginLeftRight * (itemForLine - 1)) / itemForLine
                let itemHeight: CGFloat = itemWidth + heightLabelPlusButton

                return CGSize(width: itemWidth, height: itemHeight)
            }

            // Default fallback
            return CGSize(width: itemWidthDefault, height: itemWidthDefault)
        }
        set {
            super.itemSize = newValue
        }
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
}
