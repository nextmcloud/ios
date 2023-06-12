//
//  OriginalFileNameCustomSwitchCell.swift
//  Nextcloud
//
//  Created by Sumit on 30/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class OriginalFileNameCustomSwitchCell: XLFormBaseCell{
    @IBOutlet weak var originalFileNameSwitch: UISwitch!
    
    @IBOutlet weak var originalFileNameTitle: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        originalFileNameSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
    }
    
    override func configure() {
        super.configure()
        
    }
    
    override func update() {
        super.update()
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn        
        if value {
            //on
            self.rowDescriptor.value = value
        }else{
            self.rowDescriptor.value = value
        }
    }

}
