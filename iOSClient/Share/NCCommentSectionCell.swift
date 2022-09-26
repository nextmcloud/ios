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
    @IBOutlet weak var discriptionLabel: UILabel!
    @IBOutlet weak var editCommentButton: UIButton!
    weak var delegate: NCCommentMenuCellDelegate?
  
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func commentSection(isCommentSelected: Bool) {
        
        editCommentButton.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
    
    }
    
    @IBAction func  editButtonClicked(_ sender: Any) {
        
        delegate?.tapMenu()
    
    }
    

}

protocol NCCommentMenuCellDelegate: class {
    func tapMenu()
}
