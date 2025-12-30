//
//  FolderPathCustomCell.swift
//  Nextcloud
//
//  Created by Sumit on 28/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation
//  Created by A200073704 on 04/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit
import XLForm

class FolderPathCustomCell: XLFormButtonCell{
    
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var folderImage: UIImageView!
    @IBOutlet weak var bottomLineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
        if (rowDescriptor.tag == "PhotoButtonDestinationFolder"){
            bottomLineView.isHidden = true
        }else{
            bottomLineView.isHidden = false
        }
    }
}
