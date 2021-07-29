//
//  SaveSettingsCustomButtonCell.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class SaveSettingsCustomButtonCell: XLFormButtonCell {
                
    @IBOutlet weak var saveSettingsButton: UIButton!
    
        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            self.backgroundColor = NCBrandColor.shared.backgroundForm
            self.selectionStyle = .none
            
            saveSettingsButton.addTarget(self, action: #selector(saveButtonClicked), for: .touchUpInside)

        }
        
        override func configure() {
            super.configure()
            saveSettingsButton.backgroundColor = NCBrandColor.shared.brand
            saveSettingsButton.tintColor = UIColor.white
            saveSettingsButton.layer.cornerRadius = 5
            saveSettingsButton.layer.borderWidth = 1
            saveSettingsButton.layer.borderColor = NCBrandColor.shared.brand.cgColor

        }
        
        override func update() {
            super.update()
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = NCBrandColor.shared.backgroundForm
            self.selectedBackgroundView = backgroundView
        }
    
    @objc func saveButtonClicked(sender: UIButton) {
        self.rowDescriptor.value = sender
    
    }
  
}
