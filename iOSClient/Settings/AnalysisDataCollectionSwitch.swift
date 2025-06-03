//
//  AnalysisDataCollectionSwitch.swift
//  Nextcloud
//
//  Created by A200073704 on 25/04/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

class AnalysisDataCollectionSwitch: XLFormBaseCell {
                
        @IBOutlet weak var cellLabel: UILabel!
        @IBOutlet weak var analysisDataCollectionSwitchControl: UISwitch!
        
        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            analysisDataCollectionSwitchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
            
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

