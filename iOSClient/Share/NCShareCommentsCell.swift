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
    private var avatarButton: UIButton!

    var tableComments: tableComments?
    weak var delegate: NCShareCommentsCellDelegate?

    var indexPath: IndexPath {
        get { return index }
        set { index = newValue }
    }
    var avatarImage: UIImageView? {
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
        
        avatarButton = UIButton(type: .system)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.backgroundColor = .clear
        contentView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: imageItem.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: imageItem.bottomAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: imageItem.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: imageItem.trailingAnchor)
        ])
        avatarButton.showsMenuAsPrimaryAction = true

        buttonMenu.showsMenuAsPrimaryAction = true
    }

    @objc func tapAvatarImage(_ sender: UITapGestureRecognizer) {
        avatarButton.menu = delegate?.openProfileMenu(with: tableComments)
    }

    @IBAction func touchUpInsideMenu(_ sender: Any) {
        buttonMenu.menu = delegate?.openCommentMenu(with: tableComments)
    }
}

protocol NCShareCommentsCellDelegate: AnyObject {
    func openCommentMenu(with tableComments: tableComments?) -> UIMenu?
    func openProfileMenu(with tableComment: tableComments?) -> UIMenu?
}
