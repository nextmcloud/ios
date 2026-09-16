//
//  SetPDFPasswordSwitchView.swift
//  Nextcloud
//
//  Created by Sumit on 10/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation
import XLForm

class SetPDFPasswordSwitchView: XLFormBaseCell{
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        switchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
    }
    
    override func configure() {
        super.configure()
        self.switchControl.isEnabled = false
    }
    
    override func update() {
        super.update()
        
        if let rowValue = rowDescriptor.value as? String {
            if (rowValue == "disable_switch"){
                self.switchControl.isEnabled = false
                self.switchControl.isOn = false
            }else if(rowValue == "enable_switch"){
                self.switchControl.isEnabled = true
            }
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
