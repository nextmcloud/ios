//
//  NCShareSectionHeaderView.swift
//  Nextcloud
//
//  Created by A200020526 on 04/03/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareSectionHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelSharingInfo: UILabel!
    @IBOutlet weak var fullWidthImageView: UIImageView!
    @IBOutlet weak var canShareInfoView: UIView!
    @IBOutlet weak var sharedByLabel: UILabel!
    @IBOutlet weak var resharingAllowedLabel: UILabel!
    @IBOutlet weak var sharedByImageView: UIImageView!
    @IBOutlet weak var constraintTopSharingLabel: NSLayoutConstraint!

    var ocId = ""
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func setupUI() {
        labelSharing.text = NSLocalizedString("_sharing_", comment: "")
        labelSharingInfo.text = NSLocalizedString("_sharing_message_", comment: "")
        
        if UIScreen.main.bounds.width < 350 {
            constraintTopSharingLabel.constant = 15
        }
    }
    
    func updateCanReshareUI() {
        let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId)
        var isCurrentUser = true
        if let ownerId = metadata?.ownerId, !ownerId.isEmpty {
            isCurrentUser = NCShareCommon.shared.isCurrentUserIsFileOwner(fileOwnerId: ownerId)
        }
        let canReshare = NCShareCommon.shared.canReshare(withPermission: metadata?.permissions ?? "")
        canShareInfoView.isHidden = isCurrentUser
        labelSharingInfo.isHidden = !isCurrentUser
        
        if !isCurrentUser {
            sharedByImageView.image = UIImage(named: "cloudUpload")?.image(color: .systemBlue, size: 26)
            let ownerName = metadata?.ownerDisplayName ?? ""
            sharedByLabel.text = NSLocalizedString("_shared_with_you_by_", comment: "") + " " + ownerName
            let resharingAllowedMessage =  NSLocalizedString("_share_reshare_allowed_", comment: "")
            let resharingNotAllowedMessage = NSLocalizedString("_share_reshare_not_allowed_", comment: "")
            resharingAllowedLabel.text = canReshare ? resharingAllowedMessage  : resharingNotAllowedMessage
        }
    }
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
            NCNetworking.shared.favoriteMetadata(metadata) { error in
                if error == .success {
                    if !metadata.favorite {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                    } else {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                    }
                } else {
                    NCContentPresenter.shared.showError(error: error)
                }
            }
        }
    }
}
