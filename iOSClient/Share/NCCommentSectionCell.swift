//
//  NCCommentSectionCell.swift
//  Nextcloud
//
//  Created by A200073704 on 22/09/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class NCCommentSectionCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var editCommentButton: UIButton!
    weak var delegate: NCCommentMenuCellDelegate?
    var tableComment: tableComments?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        descriptionTextView.textContainer.lineFragmentPadding = 0
        editCommentButton.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func  editButtonClicked(_ sender: Any) {
        guard let comment = tableComment else {
            return
        }
        delegate?.tapMenu(comment: comment)
    
    }
    

}

protocol NCCommentMenuCellDelegate: class {
    func tapMenu(comment: tableComments)
}
