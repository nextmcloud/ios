//
//  MagentaCloudVersionView.swift
//  Nextcloud
//
//  Created by A200073704 on 11/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import Foundation


class MagentaCloudVersionView: XLFormBaseCell{
    
    
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
    }
}
