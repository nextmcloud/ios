//
//  MagentaCloudVersionView.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class MagentaCloudVersionView: XLFormBaseCell{
    
    
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
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
}
