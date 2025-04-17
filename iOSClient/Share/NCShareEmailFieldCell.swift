//
//  NCShareEmailFieldCell.swift
//  Nextcloud
//
//  Created by A200020526 on 01/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

enum Tag {
    static let searchField = 999
}

class NCShareEmailFieldCell: UITableViewCell {
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var btnCreateLink: UIButton!
    @IBOutlet weak var labelYourShare: UILabel!
    @IBOutlet weak var labelShareByMail: UILabel!
    @IBOutlet weak var btnContact: UIButton!
    @IBOutlet weak var labelNoShare: UILabel!
    @IBOutlet weak var heightLabelNoShare: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupCell()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupCell(){
        self.btnCreateLink.setTitle(NSLocalizedString("_create_link_", comment: ""), for: .normal)
        self.btnCreateLink.layer.cornerRadius = 7
        self.btnCreateLink.layer.masksToBounds = true
        self.btnCreateLink.layer.borderWidth = 1
        self.btnCreateLink.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.btnCreateLink.titleLabel!.adjustsFontSizeToFitWidth = true
        self.btnCreateLink.titleLabel!.minimumScaleFactor = 0.5
        self.btnCreateLink.layer.borderColor = NCBrandColor.shared.label.cgColor
        self.btnCreateLink.setTitleColor(NCBrandColor.shared.label, for: .normal)
        self.btnCreateLink.backgroundColor = .clear
        
        self.labelShareByMail.text = NSLocalizedString("personal_share_by_mail", comment: "")
        self.labelShareByMail.textColor = NCBrandColor.shared.shareByEmailTextColor
        
        labelYourShare.text = NSLocalizedString("_your_shares_", comment: "")
        
        searchField.layer.cornerRadius = 5
        searchField.layer.masksToBounds = true
        searchField.layer.borderWidth = 1
        self.searchField.text = ""
        searchField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("_shareLinksearch_placeholder_", comment: ""),
                                                               attributes: [NSAttributedString.Key.foregroundColor: NCBrandColor.shared.gray60])
        searchField.textColor = NCBrandColor.shared.label
        searchField.layer.borderColor = NCBrandColor.shared.label.cgColor
        searchField.tag = Tag.searchField
        setDoneButton(sender: searchField)
        
        btnContact.layer.cornerRadius = 5
        btnContact.layer.masksToBounds = true
        btnContact.layer.borderWidth = 1
        btnContact.layer.borderColor = NCBrandColor.shared.label.cgColor
        btnContact.tintColor = NCBrandColor.shared.label
        btnContact.setImage(NCUtility().loadImage(named: "contact", colors: [NCBrandColor.shared.label], size: 24), for: .normal)
        btnContact.setImage(NCUtility().loadImage(named: "contact").image(color: NCBrandColor.shared.label, size: 24), for: .normal)
        labelNoShare.textColor = NCBrandColor.shared.textInfo
        labelNoShare.numberOfLines = 0
        labelNoShare.font = UIFont.systemFont(ofSize: 17)
        labelNoShare.text = NSLocalizedString("no_shares_created", comment: "")
    }
    
    @objc func cancelDatePicker() {
        self.searchField.endEditing(true)
    }
    
    func setDoneButton(sender: UITextField) {
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("_done_", comment: ""), style: .plain, target: self, action: #selector(cancelDatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton, doneButton], animated: false)
        sender.inputAccessoryView = toolbar
    }
}
