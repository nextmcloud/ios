//
//  CommentShareButtonSelectionTableViewCell.swift
//  Nextcloud
//
//  Created by A200073704 on 19/09/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class CommentShareButtonSelectionTableViewCell: UITableViewCell {
   // private var share: NCShare = NCShare()
    @IBOutlet weak var shareUIView: UIView!
    @IBOutlet weak var commentsUIView: UIView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareUnderlineView: UIView!
    @IBOutlet weak var commentsUnderlineView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI(isShareSelected: Bool){
        
        shareButton.setTitle(NSLocalizedString("_sharing_", comment: ""), for: .normal)
        commentButton.setTitle(NSLocalizedString("_comments_", comment: ""), for: .normal)
        shareUnderlineView.backgroundColor = isShareSelected ? NCBrandColor.shared.customer : NCBrandColor.shared.graySoft
        commentsUnderlineView.backgroundColor = isShareSelected ? NCBrandColor.shared.graySoft : NCBrandColor.shared.customer
        if isShareSelected {
            shareButton.setTitleColor(NCBrandColor.shared.customer, for: .normal)
            commentButton.setTitleColor(NCBrandColor.shared.label, for: .normal)
        } else {
            commentButton.setTitleColor(NCBrandColor.shared.customer, for: .normal)
            shareButton.setTitleColor(NCBrandColor.shared.label, for: .normal)
            
        }
    }
}
