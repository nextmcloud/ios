//
//  NCCommentSectionTextFieldCell.swift
//  Nextcloud
//
//  Created by A200073704 on 22/09/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class NCCommentSectionTextFieldCell: UITableViewCell {

    @IBOutlet weak var commmentSearchField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateCommentSectionUI(isCommentSelected: Bool) {
       
        commmentSearchField.layer.cornerRadius = 5
        commmentSearchField.layer.masksToBounds = true
        commmentSearchField.layer.borderWidth = 1
        commmentSearchField.layer.borderColor = NCBrandColor.shared.label.cgColor
        self.commmentSearchField.text = ""
        commmentSearchField.tag = Tag.commmentSearchField
        commmentSearchField.textColor = NCBrandColor.shared.label
        commmentSearchField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("_message_placeholder_", comment: ""),
                                                               attributes: [NSAttributedString.Key.foregroundColor: NCBrandColor.shared.searchFieldPlaceHolder])
        
    }
    
}
