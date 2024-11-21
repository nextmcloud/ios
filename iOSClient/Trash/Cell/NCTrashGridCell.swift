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
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var imageFavorite: UIImageView!
    @IBOutlet weak var imageLocal: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var imageVisualEffect: UIVisualEffectView!
    @IBOutlet weak var progressView: UIProgressView!

    internal var objectId = ""
    var indexPath = IndexPath()
    private var user = ""

    weak var delegate: NCGridCellDelegate?

    internal var objectId = ""
    var indexPath = IndexPath()
    var account = ""
    var user = ""

    weak var delegate: NCTrashGridCellDelegate?
    var namedButtonMore = ""

    var fileObjectId: String? {
        get { return objectId }
        set { objectId = newValue ?? "" }
    }
    var filePreviewImageView: UIImageView? {
        get { return imageItem }
        set { imageItem = newValue }
    }
    var fileUser: String? {
        get { return user }
        set { user = newValue ?? "" }
    }
    var fileTitleLabel: UILabel? {
        get { return labelTitle }
        set { labelTitle = newValue }
    }
    var fileInfoLabel: UILabel? {
        get { return labelInfo }
        set { labelInfo = newValue }
    }
    var fileProgressView: UIProgressView? {
        get { return progressView }
        set { progressView = newValue }
    }
    var fileSelectImage: UIImageView? {
        get { return imageSelect }
        set { imageSelect = newValue }
    }
    var fileStatusImage: UIImageView? {
        get { return imageStatus }
        set { imageStatus = newValue }
    }
    var fileLocalImage: UIImageView? {
        get { return imageLocal }
        set { imageLocal = newValue }
    }
    var fileFavoriteImage: UIImageView? {
        get { return imageFavorite }
        set { imageFavorite = newValue }
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
        isAccessibilityElement = true

        imageItem.layer.cornerRadius = 6
        imageItem.layer.masksToBounds = true

        imageVisualEffect.layer.cornerRadius = 6
        imageVisualEffect.clipsToBounds = true
        imageVisualEffect.alpha = 0.5

        progressView.tintColor = NCBrandColor.shared.brandElement
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 0.5)
        progressView.trackTintColor = .clear

        labelTitle.text = ""
        labelInfo.text = ""
        labelTitle.textColor = .label
        labelInfo.textColor = .systemGray
    }

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        return nil
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapMoreGridItem(with: objectId, image: imageItem.image, sender: sender)
    }


    fileprivate func setA11yActions() {
        let moreName = namedButtonMore == NCGlobal.shared.buttonMoreStop ? "_cancel_" : "_more_"
        
        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("_more_", comment: ""),
                target: self,
                selector: #selector(touchUpInsideMore))
        ]
    }
    
    func setButtonMore(named: String, image: UIImage) {
        namedButtonMore = named
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
            imageSelect.image = NCImageCache.images.checkedNo
            imageSelect.image = NCImageCache.shared.getImageCheckedNo()
            imageVisualEffect.isHidden = true
        }
    }

    func writeInfoDateSize(date: NSDate, size: Int64) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current

        labelInfo.text = dateFormatter.string(from: date as Date) + " · " + NCUtilityFileSystem().transformedSize(size)
    }

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }
}
