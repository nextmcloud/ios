//
//  NCShareHeaderCustomCell.swift
//  Nextcloud
//
//  Created by T-systems on 11/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareHeaderCustomCell: XLFormBaseCell {

    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.backgroundColor = .clear
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
    }
    
    @objc func changeTheming() {
    }
    
    override func configure() {
        super.configure()
    }
    override func layoutSubviews() {
        trailingConstraint.constant = UIDevice.current.orientation.isLandscape ? 56 : 16
        leadingConstraint.constant = UIDevice.current.orientation.isLandscape ? 56 : 16
    }
    override func update() {
        self.backgroundColor = .clear
        self.titleLabel.textColor = NCBrandColor.shared.systemGray
        super.update()
        
        if rowDescriptor.tag == "kNMCShareHeaderCustomCell" {
            
        }
    }
}
