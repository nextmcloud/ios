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

    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var buttonSwitch: UIButton!
    @IBOutlet weak var buttonOrder: UIButton!
    @IBOutlet weak var buttonOrderWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRichWorkspace: UIView!
    @IBOutlet weak var viewRichWorkspaceHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewRichWorkspace: UITextView!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    weak var delegate: NCSectionHeaderMenuDelegate?

    private var markdownParser = MarkdownParser()
    private var richWorkspaceText: String?
    private var textViewColor: UIColor?
    private let gradient: CAGradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear

        buttonSwitch.setImage(UIImage(named: "switchList")!.image(color: .gray, size: 25), for: .normal)

        buttonOrder.setTitle("", for: .normal)
        buttonOrder.setTitleColor(NCBrandColor.shared.brand, for: .normal)
        buttonMore.setImage(UIImage.init(named: "more")!.image(color: NCBrandColor.shared.iconColor, size: 25), for: .normal)

        // Gradient
        gradient.startPoint = CGPoint(x: 0, y: 0.50)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        viewRichWorkspace.layer.addSublayer(gradient)

        let tap = UITapGestureRecognizer(target: self, action: #selector(touchUpInsideViewRichWorkspace(_:)))
        tap.delegate = self
        viewRichWorkspace?.addGestureRecognizer(tap)

        separator.backgroundColor = .separator
        separatorHeightConstraint.constant = 0.5

        markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: 15), color: .label)
        markdownParser.header.font = UIFont.systemFont(ofSize: 25)
        if let richWorkspaceText = richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(richWorkspaceText)
        }
        textViewColor = .label
        setInterfaceColor()
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        gradient.frame = viewRichWorkspace.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setInterfaceColor()
    }

    //MARK: - View

    func setStatusButton(count: Int) {

        if count == 0 {
            buttonOrder.isEnabled = false
            buttonMore.isEnabled = false
        } else {
            buttonOrder.isEnabled = true
            buttonMore.isEnabled = true
        }
    }
    
    func setTitleSorted(datasourceTitleButton: String) {

        let title = NSLocalizedString(datasourceTitleButton, comment: "")
        let size = title.size(withAttributes: [.font: buttonOrder.titleLabel?.font as Any])

        buttonOrder.setTitle(title, for: .normal)
        buttonOrderWidthConstraint.constant = size.width + 5
    }

    //MARK: - RichWorkspace


    func setInterfaceColor() {

        if traitCollection.userInterfaceStyle == .dark {
            gradient.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor.black.cgColor]
        } else {
            gradient.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor.white.cgColor]
        }
    }

    func setRichWorkspaceText(richWorkspaceText: String?) {
        guard let richWorkspaceText = richWorkspaceText else { return }
        if richWorkspaceText != self.richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(richWorkspaceText)
            self.richWorkspaceText = richWorkspaceText
        }
    }

    // MARK: - Action

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapMoreHeader(sender: sender)
    }

    @IBAction func touchUpInsideSwitch(_ sender: Any) {
        delegate?.tapSwitchHeader(sender: sender)
    }

    @IBAction func touchUpInsideOrder(_ sender: Any) {
        delegate?.tapOrderHeader(sender: sender)
    }

    @objc func touchUpInsideViewRichWorkspace(_ sender: Any) {
        delegate?.tapRichWorkspace(sender: sender)
    }
}

protocol NCSectionHeaderMenuDelegate: AnyObject {
    func tapSwitchHeader(sender: Any)
    func tapMoreHeader(sender: Any)
    func tapOrderHeader(sender: Any)
    func tapRichWorkspace(sender: Any)
}

// optional func
extension NCSectionHeaderMenuDelegate {
    func tapSwitchHeader(sender: Any) {}
    func tapMoreHeader(sender: Any) {}
    func tapOrderHeader(sender: Any) {}
    func tapRichWorkspace(sender: Any) {}
}

class NCSectionFooter: UICollectionReusableView, NCSectionFooterDelegate {

    @IBOutlet weak var buttonSection: UIButton!
    @IBOutlet weak var activityIndicatorSection: UIActivityIndicatorView!
    @IBOutlet weak var labelSection: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonSectionHeightConstraint: NSLayoutConstraint!

    weak var delegate: NCSectionFooterDelegate?
    var metadataForSection: NCMetadataForSection?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.backgroundColor = UIColor.clear
        labelSection.textColor = UIColor.systemGray
        labelSection.text = ""
        self.buttonSection.tintColor = NCBrandColor.shared.customer
        separator.backgroundColor = .separator
        separatorHeightConstraint.constant = 0.5

        buttonIsHidden(true)
        activityIndicatorSection.isHidden = true
        activityIndicatorSection.color = .label
    }

    func setTitleLabel(directories: Int, files: Int, size: Int64) {

        var foldersText = ""
        var filesText = ""

        if directories > 1 {
            foldersText = "\(directories) " + NSLocalizedString("_folders_", comment: "")
        } else if directories == 1 {
            foldersText = "1 " + NSLocalizedString("_folder_", comment: "")
        }

        if files > 1 {
            filesText = "\(files) " + NSLocalizedString("_files_", comment: "") + " " + CCUtility.transformedSize(size)
        } else if files == 1 {
            filesText = "1 " + NSLocalizedString("_file_", comment: "") + " " + CCUtility.transformedSize(size)
        }

        if foldersText == "" {
            labelSection.text = filesText
        } else if filesText == "" {
            labelSection.text = foldersText
        } else {
            labelSection.text = foldersText + ", " + filesText
        }
    }

    func setTitleLabel(_ text: String) {

        labelSection.text = text
    }

    func setButtonText(_ text: String) {

        buttonSection.setTitle(text, for: .normal)
    }

    func separatorIsHidden(_ isHidden: Bool) {

        separator.isHidden = isHidden
    }

    func buttonIsHidden(_ isHidden: Bool) {

        buttonSection.isHidden = isHidden
        if isHidden {
            buttonSectionHeightConstraint.constant = 0
        } else {
            buttonSectionHeightConstraint.constant = NCGlobal.shared.heightFooterButton
        }
    }

    func showActivityIndicatorSection() {

        buttonSection.isHidden = true
        buttonSectionHeightConstraint.constant = NCGlobal.shared.heightFooterButton

        activityIndicatorSection.isHidden = false
        activityIndicatorSection.startAnimating()
    }

    func hideActivityIndicatorSection() {

        activityIndicatorSection.stopAnimating()
        activityIndicatorSection.isHidden = true
    }

    // MARK: - Action

    @IBAction func touchUpInsideButton(_ sender: Any) {
        delegate?.tapButtonSection(sender, metadataForSection: metadataForSection)
    }
}

protocol NCSectionFooterDelegate: AnyObject {
    func tapButtonSection(_ sender: Any, metadataForSection: NCMetadataForSection?)
}

// optional func
extension NCSectionFooterDelegate {
    func tapButtonSection(_ sender: Any, metadataForSection: NCMetadataForSection?) {}
}
