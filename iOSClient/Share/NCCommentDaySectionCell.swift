//
//  NCCommentDaySectionCell.swift
//  Nextcloud
//
//  Created by A200073704 on 22/09/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class NCCommentDaySectionCell: UITableViewCell {
    
    @IBOutlet weak var daySectionView: UIView!
    @IBOutlet weak var dayLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        daySectionView.backgroundColor = NCBrandColor.shared.lightMagenta
        daySectionView.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
