//
//  AlbumsViewController.swift
//  Nextcloud
//
//  Created by Dhanesh on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import UIKit
import SwiftUI

class AlbumsViewController: UIViewController {
    
    @Environment(\.localAccount) var localAccount: String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let albumsRootView = AlbumsRootView()
            .environment(\.localAccount, appDelegate.account)
        
        let hostingController = UIHostingController(rootView: albumsRootView)
        
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
        
        // Needed, since we use NCViewerMediaPage to show the media, which expects this!
        navigationController?.navigationBar.prefersLargeTitles = false
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = NCBrandColor.shared.customer
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
            .tintColor = NCBrandColor.shared.customer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // NCViewerMediaPage messes up with the NavigationBar, so this is needed everytime on view's appearance
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

struct AccountKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var localAccount: String {
        get { self[AccountKey.self] }
        set { self[AccountKey.self] = newValue }
    }
}
