//
//  NCTrashSectionHeaderFooter.swift
//  Nextcloud
//
//  Created by A200073704 on 09/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

class NCTrashSectionHeaderMenu: UICollectionReusableView {

    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var buttonSwitch: UIButton!
    @IBOutlet weak var buttonOrder: UIButton!
    @IBOutlet weak var buttonOrderWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    weak var delegate: NCTrashSectionHeaderMenuDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        buttonSwitch.setImage(UIImage(named: "switchList")!.image(color: NCBrandColor.shared.gray, size: 25), for: .normal)

        buttonOrder.setTitle("", for: .normal)
        buttonOrder.setTitleColor(NCBrandColor.shared.brandElement, for: .normal)

        buttonMore.setImage(UIImage(named: "more")!.image(color: NCBrandColor.shared.gray, size: 25), for: .normal)

        separator.backgroundColor = .separator
        separatorHeightConstraint.constant = 0.5

        backgroundColor = .systemBackground
    }

    func setTitleSorted(datasourceTitleButton: String) {

        let title = NSLocalizedString(datasourceTitleButton, comment: "")
        let size = title.size(withAttributes: [.font: buttonOrder.titleLabel?.font as Any])

        buttonOrder.setTitle(title, for: .normal)
        buttonOrderWidthConstraint.constant = size.width + 5
    }

    func setStatusButton(datasource: [tableTrash]) {

        if datasource.isEmpty {
            buttonSwitch.isEnabled = false
            buttonOrder.isEnabled = false
            buttonMore.isEnabled = false
        } else {
            buttonSwitch.isEnabled = true
            buttonOrder.isEnabled = true
            buttonMore.isEnabled = true
        }
    }

    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapMoreHeaderMenu(sender: sender)
    }

    @IBAction func touchUpInsideSwitch(_ sender: Any) {
        delegate?.tapSwitchHeaderMenu(sender: sender)
    }

    @IBAction func touchUpInsideOrder(_ sender: Any) {
        delegate?.tapOrderHeaderMenu(sender: sender)
    }
}

protocol NCTrashSectionHeaderMenuDelegate: AnyObject {
    func tapSwitchHeaderMenu(sender: Any)
    func tapMoreHeaderMenu(sender: Any)
    func tapOrderHeaderMenu(sender: Any)
}

class NCTrashSectionFooter: UICollectionReusableView {

    @IBOutlet weak var labelFooter: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        labelFooter.textColor = NCBrandColor.shared.gray
    }

    func setTitleLabelFooter(datasource: [tableTrash]) {

        var folders: Int = 0, foldersText = ""
        var files: Int = 0, filesText = ""
        var size: Int64 = 0

        for record: tableTrash in datasource {
            if record.directory {
                folders += 1
            } else {
                files += 1
                size += record.size
            }
        }

        if folders > 1 {
            foldersText = "\(folders) " + NSLocalizedString("_folders_", comment: "")
        } else if folders == 1 {
            foldersText = "1 " + NSLocalizedString("_folder_", comment: "")
        }

        if files > 1 {
            filesText = "\(files) " + NSLocalizedString("_files_", comment: "") + " " + CCUtility.transformedSize(size)
        } else if files == 1 {
            filesText = "1 " + NSLocalizedString("_file_", comment: "") + " " + CCUtility.transformedSize(size)
        }

        if foldersText.isEmpty {
            labelFooter.text = filesText
        } else if filesText.isEmpty {
            labelFooter.text = foldersText
        } else {
            labelFooter.text = foldersText + ", " + filesText
        }
    }
}
