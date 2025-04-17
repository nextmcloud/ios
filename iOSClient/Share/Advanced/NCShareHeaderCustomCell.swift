//
//  NCShareHeaderCustomCell.swift
//  Nextcloud
//
//  Created by T-systems on 11/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareHeaderCustomCell: XLFormBaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }
        
    override func configure() {
        super.configure()
    }
    
    override func update() {
        self.backgroundColor = .clear
        self.titleLabel.textColor = NCBrandColor.shared.systemGray
        super.update()
    }
}
