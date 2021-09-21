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
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
    }
    
    @objc func changeTheming() {
//        self.backgroundColor = NCBrandColor.shared.backgroundView
        self.backgroundColor = .clear
        self.titleLabel.textColor = NCBrandColor.shared.icon
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
