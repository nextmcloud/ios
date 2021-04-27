//
//  TextTableViewCell.swift
//  Nextcloud
//
//  Created by Ashu on 23/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class TextTableViewCell: XLFormBaseCell {

    @IBOutlet weak var labelFileName: UILabel!
    @IBOutlet weak var fileNameTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
    }
}
