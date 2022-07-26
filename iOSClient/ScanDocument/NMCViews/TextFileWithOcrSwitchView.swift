//
//  TextFileWithOcrSwitchView.swift
//  Nextcloud
//
//  Created by Sumit on 04/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation

class TextFileWithOcrSwitchView: XLFormBaseCell{
    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var cellLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        switchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
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
