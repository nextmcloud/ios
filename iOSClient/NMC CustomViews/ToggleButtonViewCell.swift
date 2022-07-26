//
//  ToggleButtonViewCell.swift
//  Nextcloud
//
//  Created by Sumit on 27/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation

class ToggleButtonViewCell: XLFormBaseCell{
    
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        switchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
        if rowDescriptor.tag == "autoUpload" {
            bottomLine.isHidden = true
            topLine.isHidden = true
        }
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        // Do something
        
        if value {
            //on
            self.rowDescriptor.value = value
        }else{
            self.rowDescriptor.value = value
        }
    }
}

