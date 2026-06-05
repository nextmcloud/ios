//
//  NCShareEmailLinkHeaderView.swift
//  Nextcloud
//
//  Created by A106551118 on 12/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import UIKit

class NCShareEmailLinkHeaderView: UITableViewHeaderFooterView {
    private let label = UILabel()
    static let reuseIdentifier = "NCShareEmailLinkHeaderView"

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = NCBrandColor.shared.textColor
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            label.heightAnchor.constraint(equalToConstant: 30),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
        ])
    }

    func configure(text: String) {
        label.text = text
    }
}
