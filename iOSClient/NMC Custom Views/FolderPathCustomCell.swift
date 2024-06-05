//
//  FolderPathCustomCell.swift
//  Nextcloud
//
//  Created by A200073704 on 04/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

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
