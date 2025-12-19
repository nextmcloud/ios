//
//  CreateLinkFooterView.swift
//  Nextcloud
//
//  Created by A106551118 on 12/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//


import UIKit

class CreateLinkFooterView: UITableViewHeaderFooterView {
    
    static let reuseIdentifier = "CreateLinkFooterView"
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("_create_new_link_", comment: ""), for: .normal)
        button.setTitleColor(UIColor.label, for: .normal)
//        button.setTitleColor(NCBrandColor.shared.shareBlackColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = NCBrandColor.shared.label.cgColor
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var createButtonAction: (() -> Void)?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        createButton.layer.borderColor = NCBrandColor.shared.label.cgColor
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(createButton)
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            createButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            createButton.heightAnchor.constraint(equalToConstant: 40),
            
            separator.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor) // ensures correct height
        ])
        
        createButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        createButtonAction?()
    }
}
