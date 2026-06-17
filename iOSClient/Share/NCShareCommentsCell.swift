// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

// MARK: - NCShareCommentsCell

class NCShareCommentsCell: UITableViewCell, NCCellProtocol {

    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var labelUser: UILabel!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelMessage: UILabel!

    private var index = IndexPath()

    var tableComments: tableComments?
    weak var delegate: NCShareCommentsCellDelegate?

    var indexPath: IndexPath {
        get { return index }
        set { index = newValue }
    }
    var avatarImageView: UIImageView? {
        return imageItem
    }
    var fileUser: String? {
        get { return tableComments?.actorId }
        set {}
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAvatarImage(_:)))
        imageItem?.addGestureRecognizer(tapGesture)
    }

    @objc func tapAvatarImage(_ sender: UITapGestureRecognizer) {
        self.delegate?.showProfile(with: tableComments, sender: sender)
    }

    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableComments, sender: sender)
    }
}

protocol NCShareCommentsCellDelegate: AnyObject {
    func tapMenu(with tableComments: tableComments?, sender: Any)
    func showProfile(with tableComment: tableComments?, sender: Any)
}
