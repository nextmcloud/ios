//
//  AutoUploadFolderCustomCell.swift
//  Nextcloud
//
//  Created by Sumit on 29/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class AutoUploadFolderCustomCell: XLFormBaseCell{
    
    
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var autoUploadSwitchControl: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        autoUploadSwitchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
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
