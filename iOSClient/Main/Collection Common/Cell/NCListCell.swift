//
//  NCListCell.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 24/10/2018.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
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

class NCListCell: UICollectionViewCell, UIGestureRecognizerDelegate, NCCellProtocol {
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var imageFavorite: UIImageView!
    @IBOutlet weak var imageLocal: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelInfoSeparator: UILabel!
    @IBOutlet weak var labelSubinfo: UILabel!
    @IBOutlet weak var imageShared: UIImageView!
    @IBOutlet weak var buttonShared: UIButton!
    @IBOutlet weak var imageMore: UIImageView!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var labelShared: UILabel!
    @IBOutlet weak var imageItemLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var subInfoTrailingConstraint: NSLayoutConstraint!

    private var ocId = ""
    private var ocIdTransfer = ""
    private var user = ""

    weak var listCellDelegate: NCListCellDelegate?
    var namedButtonMore = ""

    var fileAvatarImageView: UIImageView? {
        return imageShared
    }
    var fileOcId: String? {
        get { return ocId }
        set { ocId = newValue ?? "" }
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
    var fileSubinfoLabel: UILabel? {
        get { return labelSubinfo }
        set { labelSubinfo = newValue }
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
    var fileSharedImage: UIImageView? {
        get { return imageShared }
        set { imageShared = newValue }
    }
    var fileMoreImage: UIImageView? {
        get { return imageMore }
        set { imageMore = newValue }
    }
    var cellSeparatorView: UIView? {
        get { return separator }
        set { separator = newValue }
    }

    var fileSharedLabel: UILabel? {
        get { return labelShared }
        set { labelShared = newValue }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initCell()
    }

    func initCell() {
        
        imageItem.layer.cornerRadius = 6
        imageItem.layer.masksToBounds = true

        // use entire cell as accessibility element
        accessibilityHint = nil
        accessibilityLabel = nil
        accessibilityValue = nil
        isAccessibilityElement = true

        progressView.tintColor = NCBrandColor.shared.brand
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 0.5)
        progressView.trackTintColor = .clear
        imageSelect.isHidden = true

        let longPressedGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gestureRecognizer:)))
        longPressedGesture.minimumPressDuration = 0.5
        longPressedGesture.delegate = self
        longPressedGesture.delaysTouchesBegan = true
        self.addGestureRecognizer(longPressedGesture)

        separator.backgroundColor = .separator
        separatorHeightConstraint.constant = 0.5
        titleInfoTrailingDefault()

        labelTitle.text = ""
        labelInfo.text = ""
        labelTitle.textColor = .label
        labelInfo.textColor = .systemGray
        labelSubinfo.textColor = .systemGray
        setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCImageCache.images.buttonMore)
        imageMore.isHidden = false
        buttonMore.isHidden = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        initCell()
    }

    override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
        return nil
    }

    @IBAction func touchUpInsideShare(_ sender: Any) {
        listCellDelegate?.tapShareListItem(with: ocId, ocIdTransfer: ocIdTransfer, sender: sender)
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        listCellDelegate?.tapMoreListItem(with: ocId, ocIdTransfer: ocIdTransfer, namedButtonMore: namedButtonMore, image: imageItem.image, sender: sender)
    }

    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        listCellDelegate?.longPressListItem(with: ocId, ocIdTransfer: ocIdTransfer, namedButtonMore: namedButtonMore, gestureRecognizer: gestureRecognizer)
    }
    
    @objc func longPressInsideMore(gestureRecognizer: UILongPressGestureRecognizer) {
        listCellDelegate?.longPressMoreListItem(with: ocId, namedButtonMore: namedButtonMore, gestureRecognizer: gestureRecognizer)
    }

    fileprivate func setA11yActions() {
        let moreName = namedButtonMore == NCGlobal.shared.buttonMoreStop ? "_cancel_" : "_more_"
        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: NSLocalizedString("_share_", comment: ""),
                target: self,
                selector: #selector(touchUpInsideShare(_:))),
            UIAccessibilityCustomAction(
                name: NSLocalizedString(moreName, comment: ""),
                target: self,
                selector: #selector(touchUpInsideMore(_:)))
        ]
    }

    func titleInfoTrailingFull() {
        subInfoTrailingConstraint.constant = 10
    }

    func titleInfoTrailingDefault() {
        subInfoTrailingConstraint.constant = 90
    }

    func setButtonMore(named: String, image: UIImage) {
        namedButtonMore = named
        imageMore.image = image

        setA11yActions()
    }

    func hideButtonMore(_ status: Bool) {
        imageMore.isHidden = status
        buttonMore.isHidden = status
    }

    func hideButtonShare(_ status: Bool) {
        imageShared.isHidden = status
        buttonShared.isHidden = status
    }

    func hideSeparator(_ status: Bool) {
        separator.isHidden = status
    }

    func selectMode(_ status: Bool) {
        if status {
            imageItemLeftConstraint.constant = 45
            imageSelect.isHidden = false
            imageMore.isHidden = true
            buttonShared.isHidden = true
            buttonMore.isHidden = true
            accessibilityCustomActions = nil
        } else {
            imageItemLeftConstraint.constant = 10
            imageSelect.isHidden = true
            imageMore.isHidden = false
            buttonShared.isHidden = false
            buttonMore.isHidden = false
            backgroundView = nil
            setA11yActions()
        }
    }
    
    func selected(_ status: Bool, isEditMode: Bool) {
        // NMC-1190 - iOS - Files - Deleting files while files are still uploading won't delete properly : to fix this issue remove check for !metadata.isInTransfer in below line
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId), !metadata.isInTransfer, !metadata.e2eEncrypted else {
            backgroundView = nil
            separator.isHidden = false
            imageSelect.isHidden = true

            return
        }

        if status {
            var blurEffect: UIVisualEffect?
            var blurEffectView: UIView?
            if traitCollection.userInterfaceStyle == .dark {
                blurEffect = UIBlurEffect(style: .dark)
                blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView?.backgroundColor = .black
            } else {
                blurEffect = UIBlurEffect(style: .extraLight)
                blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView?.backgroundColor = .lightGray
            }
            blurEffectView?.frame = self.bounds
            blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            backgroundView = blurEffectView
            imageSelect.image = NCImageCache.images.checkedYes
            separator.isHidden = true
        } else {
            imageSelect.image = NCImageCache.images.checkedNo
            backgroundView = nil
            separator.isHidden = false
        }
    }

    func writeInfoDateSize(date: NSDate, size: Int64) {
        labelInfo.text = NCUtility().dateDiff(date as Date) + " · " + NCUtilityFileSystem().transformedSize(size)
        labelSubinfo.text = ""
    }

    func setAccessibility(label: String, value: String) {
        accessibilityLabel = label
        accessibilityValue = value
    }
}

protocol NCListCellDelegate: AnyObject {
    func tapShareListItem(with ocId: String, ocIdTransfer: String, sender: Any)
    func tapMoreListItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, image: UIImage?, sender: Any)
    func longPressMoreListItem(with ocId: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer)
    func longPressListItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer)
}

// MARK: - List Layout

class NCListLayout: UICollectionViewFlowLayout {
    var itemHeight: CGFloat = 60

    override init() {
        super.init()

        sectionHeadersPinToVisibleBounds = false

        minimumInteritemSpacing = 0
        minimumLineSpacing = 1

        self.scrollDirection = .vertical
        self.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var itemSize: CGSize {
        get {
            if let collectionView = collectionView {
                let itemWidth: CGFloat = collectionView.frame.width
                return CGSize(width: itemWidth, height: self.itemHeight)
            }
            return CGSize(width: 100, height: 100)
        }
        set {
            super.itemSize = newValue
        }
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
}
