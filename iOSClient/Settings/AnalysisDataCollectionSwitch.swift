//
//  AnalysisDataCollectionSwitch.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


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
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.white
            self.selectedBackgroundView = backgroundView
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
