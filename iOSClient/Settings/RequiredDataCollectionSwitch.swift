//
//  RequiredDataCollectionSwitch.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class RequiredDataCollectionSwitch: XLFormBaseCell {
                
        @IBOutlet weak var cellLabel: UILabel!
        @IBOutlet weak var requiredDataCollectionSwitchControl: UISwitch!
        
        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            //requiredDataCollectionSwitchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
        }
        
        override func configure() {
            super.configure()
            
            requiredDataCollectionSwitchControl.isOn = true
            requiredDataCollectionSwitchControl.isEnabled = false
        }
        
        override func update() {
            super.update()
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.white
            self.selectedBackgroundView = backgroundView
        }
}
