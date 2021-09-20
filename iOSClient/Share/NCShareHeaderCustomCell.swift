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
        self.backgroundColor = NCBrandColor.shared.backgroundView
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
        
        if rowDescriptor.tag == "kNMCShareHeaderCustomCell" {
            
        }
    }
}
