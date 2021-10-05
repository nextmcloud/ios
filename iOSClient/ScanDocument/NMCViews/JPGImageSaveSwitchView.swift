//
//  JPGmageSaveSwitchView.swift
//  Nextcloud
//
//  Created by Sumit on 04/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class JPGImageSaveSwitchView: XLFormBaseCell{
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
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        self.selectedBackgroundView = backgroundView
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