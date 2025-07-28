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
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = NCBrandColor.shared.customer
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
