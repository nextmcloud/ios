//
//  NCSectionHeaderFooter.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 09/10/2018.
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
import MarkdownKit

class NCSectionHeaderMenu: UICollectionReusableView, UIGestureRecognizerDelegate {

    @IBOutlet weak var buttonSwitch: UIButton!
    @IBOutlet weak var buttonOrder: UIButton!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var buttonTransfer: UIButton!
    @IBOutlet weak var imageButtonTransfer: UIImageView!
    @IBOutlet weak var labelTransfer: UILabel!
    @IBOutlet weak var progressTransfer: UIProgressView!
    @IBOutlet weak var transferSeparatorBottom: UIView!
    @IBOutlet weak var textViewRichWorkspace: UITextView!
    @IBOutlet weak var labelSection: UILabel!
    @IBOutlet weak var viewTransfer: UIView!
    @IBOutlet weak var viewButtonsView: UIView!
    @IBOutlet weak var viewSeparator: UIView!
    @IBOutlet weak var viewRichWorkspace: UIView!
    @IBOutlet weak var viewSection: UIView!

    @IBOutlet weak var viewTransferHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewButtonsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewSeparatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRichWorkspaceHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var transferSeparatorBottomHeightConstraint: NSLayoutConstraint!

    weak var delegate: NCSectionHeaderMenuDelegate?
    let utility = NCUtility()
    private var markdownParser = MarkdownParser()
    private var richWorkspaceText: String?
    private var textViewColor: UIColor?
    private let gradient: CAGradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear

        buttonSwitch.setImage(UIImage(systemName: "list.bullet")!.image(color: NCBrandColor.shared.iconColor, size: 25), for: .normal)

        buttonOrder.setTitle("", for: .normal)
        buttonOrder.setTitleColor(NCBrandColor.shared.brand, for: .normal)
        buttonMore.setImage(UIImage(named: "more")!.image(color: NCBrandColor.shared.iconColor, size: 25), for: .normal)

        // Gradient
        gradient.startPoint = CGPoint(x: 0, y: 0.50)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        viewRichWorkspace.layer.addSublayer(gradient)

        let tap = UITapGestureRecognizer(target: self, action: #selector(touchUpInsideViewRichWorkspace(_:)))
        tap.delegate = self
        viewRichWorkspace?.addGestureRecognizer(tap)

        viewSeparatorHeightConstraint.constant = 0.5
        viewSeparator.backgroundColor = .separator

        markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: 15), color: .label)
        markdownParser.header.font = UIFont.systemFont(ofSize: 25)
        if let richWorkspaceText = richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(richWorkspaceText)
        }
        textViewColor = .label

        labelSection.text = ""
        viewSectionHeightConstraint.constant = 0

        buttonTransfer.backgroundColor = .clear
        buttonTransfer.setImage(nil, for: .normal)
        buttonTransfer.layer.cornerRadius = 6
        buttonTransfer.layer.masksToBounds = true
        imageButtonTransfer.image = UIImage(systemName: "stop.circle")
        imageButtonTransfer.tintColor = .white
        labelTransfer.text = ""
        progressTransfer.progress = 0
        progressTransfer.tintColor = NCBrandColor.shared.brand
        progressTransfer.trackTintColor = NCBrandColor.shared.brand.withAlphaComponent(0.2)
        transferSeparatorBottom.backgroundColor = .separator
        transferSeparatorBottomHeightConstraint.constant = 0.5
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        gradient.frame = viewRichWorkspace.bounds
        setInterfaceColor()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setInterfaceColor()
    }

    // MARK: - View

    func setStatusButtonsView(enable: Bool) {

        buttonSwitch.isEnabled = enable
        buttonOrder.isEnabled = enable
        buttonMore.isEnabled = enable
    }

    func buttonMoreIsHidden(_ isHidden: Bool) {

        buttonMore.isHidden = isHidden
    }

    func setImageSwitchList() {

        buttonSwitch.setImage(UIImage(systemName: "list.bullet")!.image(color: NCBrandColor.shared.iconColor, width: 20, height: 15), for: .normal)
    }

    func setImageSwitchGrid() {

        buttonSwitch.setImage(UIImage(systemName: "square.grid.2x2")!.image(color: NCBrandColor.shared.iconColor, size: 20), for: .normal)
    }

    func setButtonsView(height: CGFloat) {

        viewButtonsViewHeightConstraint.constant = height
        if height == 0 {
            viewButtonsView.isHidden = true
        } else {
            viewButtonsView.isHidden = false
        }
    }

    func setSortedTitle(_ title: String) {

        let title = NSLocalizedString(title, comment: "")
        buttonOrder.setTitle(title, for: .normal)
    }

    // MARK: - RichWorkspace

    func setRichWorkspaceHeight(_ size: CGFloat) {

        viewRichWorkspaceHeightConstraint.constant = size
        if size == 0 {
            viewRichWorkspace.isHidden = true
        } else {
            viewRichWorkspace.isHidden = false
        }
    }

    func setInterfaceColor() {

        if traitCollection.userInterfaceStyle == .dark {
            gradient.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor.black.cgColor]
        } else {
            gradient.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor.white.cgColor]
        }
    }

    func setRichWorkspaceText(_ text: String?) {
        guard let text = text else { return }

        if text != self.richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(text)
            self.richWorkspaceText = text
        }
    }

    // MARK: - Transfer

    func setViewTransfer(isHidden: Bool, ocId: String? = nil, text: String? = nil, progress: Float? = nil) {

        labelTransfer.text = text
        viewTransfer.isHidden = isHidden
        progressTransfer.progress = 0

        if isHidden {
            viewTransferHeightConstraint.constant = 0
        } else {
            var image: UIImage?
            if let ocId,
               let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                image = utility.createFilePreviewImage(ocId: metadata.ocId, etag: metadata.etag, fileNameView: metadata.fileNameView, classFile: metadata.classFile, status: metadata.status, createPreviewMedia: true)?.darken()
                if image == nil {
                    image = UIImage(named: metadata.iconName)
                    buttonTransfer.backgroundColor = .lightGray
                } else {
                    buttonTransfer.backgroundColor = .clear
                }
                buttonTransfer.setImage(image, for: .normal)
            }
            viewTransferHeightConstraint.constant = NCGlobal.shared.heightHeaderTransfer
            if let progress {
                progressTransfer.progress = progress
            }
        }
    }

    // MARK: - Section

    func setSectionHeight(_ size: CGFloat) {

        viewSectionHeightConstraint.constant = size
        if size == 0 {
            viewSection.isHidden = true
        } else {
            viewSection.isHidden = false
        }
    }

    // MARK: - Action

    @IBAction func touchUpInsideSwitch(_ sender: Any) {
        delegate?.tapButtonSwitch(sender)
    }

    @IBAction func touchUpInsideOrder(_ sender: Any) {
        delegate?.tapButtonOrder(sender)
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapButtonMore(sender)
    }

    @IBAction func touchUpTransfer(_ sender: Any) {
       delegate?.tapButtonTransfer(sender)
    }

    @objc func touchUpInsideViewRichWorkspace(_ sender: Any) {
        delegate?.tapRichWorkspace(sender)
    }
}

protocol NCSectionHeaderMenuDelegate: AnyObject {
    func tapButtonSwitch(_ sender: Any)
    func tapButtonOrder(_ sender: Any)
    func tapButtonMore(_ sender: Any)
    func tapButtonTransfer(_ sender: Any)
    func tapRichWorkspace(_ sender: Any)
}

// optional func
extension NCSectionHeaderMenuDelegate {
    func tapButtonSwitch(_ sender: Any) {}
    func tapButtonOrder(_ sender: Any) {}
    func tapButtonMore(_ sender: Any) {}
    func tapButtonTransfer(_ sender: Any) {}
    func tapRichWorkspace(_ sender: Any) {}
}

// optional func
extension NCSectionFooterDelegate {
    func tapButtonSection(_ sender: Any, metadataForSection: NCMetadataForSection?) {}
}

//// https://stackoverflow.com/questions/16278463/darken-an-uiimage
//public extension UIImage {
//
//    private enum BlendMode {
//        case multiply // This results in colors that are at least as dark as either of the two contributing sample colors
//        case screen // This results in colors that are at least as light as either of the two contributing sample colors
//    }
//
//    // A level of zero yeilds the original image, a level of 1 results in black
//    func darken(level: CGFloat = 0.5) -> UIImage? {
//        return blend(mode: .multiply, level: level)
//    }
//
//    // A level of zero yeilds the original image, a level of 1 results in white
//    func lighten(level: CGFloat = 0.5) -> UIImage? {
//        return blend(mode: .screen, level: level)
//    }
//
//    private func blend(mode: BlendMode, level: CGFloat) -> UIImage? {
//        let context = CIContext(options: nil)
//
//        var level = level
//        if level < 0 {
//            level = 0
//        } else if level > 1 {
//            level = 1
//        }
//
//        let filterName: String
//        switch mode {
//        case .multiply: // As the level increases we get less white
//            level = abs(level - 1.0)
//            filterName = "CIMultiplyBlendMode"
//        case .screen: // As the level increases we get more white
//            filterName = "CIScreenBlendMode"
//        }
//
//        let blender = CIFilter(name: filterName)!
//        let backgroundColor = CIColor(color: UIColor(white: level, alpha: 1))
//
//        guard let inputImage = CIImage(image: self) else { return nil }
//        blender.setValue(inputImage, forKey: kCIInputImageKey)
//
//        guard let backgroundImageGenerator = CIFilter(name: "CIConstantColorGenerator") else { return nil }
//        backgroundImageGenerator.setValue(backgroundColor, forKey: kCIInputColorKey)
//        guard let backgroundImage = backgroundImageGenerator.outputImage?.cropped(to: CGRect(origin: CGPoint.zero, size: self.size)) else { return nil }
//        blender.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
//
//        guard let blendedImage = blender.outputImage else { return nil }
//
//        guard let cgImage = context.createCGImage(blendedImage, from: blendedImage.extent) else { return nil }
//        return UIImage(cgImage: cgImage)
//    }
//}
