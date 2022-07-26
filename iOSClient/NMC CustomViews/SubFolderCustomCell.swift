//
//  subFolderCustomCell.swift
//  Nextcloud
//
//  Created by Sumit on 29/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation

class SubFolderCustomCell: XLFormBaseCell{
    @IBOutlet weak var subFolderLabel: UILabel!
    
    @IBOutlet weak var subFolderSwitch: UISwitch!
    
    var disableSwitch: Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        subFolderSwitch.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
    }
    
    override func configure() {
        super.configure()
        self.subFolderSwitch.isEnabled = false
    }
    
    override func update() {
        super.update()        
        if let rowValue = rowDescriptor.value as? String {
            if (rowValue == "disable_switch"){
                self.subFolderSwitch.isEnabled = false
                self.subFolderSwitch.isOn = false
            }else if(rowValue == "enable_switch"){
                self.subFolderSwitch.isEnabled = true
            }
        }
        
    }

    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        // Do something
        if value {
            self.rowDescriptor.value = value
        }else{
            self.rowDescriptor.value = value
        }
    }
}
