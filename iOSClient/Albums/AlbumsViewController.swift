//
//  AlbumsController.swift
//  Nextcloud
//
//  Created by A200118228 on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import UIKit
import SwiftUI

class AlbumsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let viewModel = AlbumsListViewModel(account: appDelegate.account)
        let albumsView = AlbumsListScreen(viewModel: viewModel)
        
        let hostingController = UIHostingController(rootView: albumsView)
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}
