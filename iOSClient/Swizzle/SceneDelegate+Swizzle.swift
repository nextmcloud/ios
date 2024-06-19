//
//  SceneDelegate+Swizzle.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 14/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

extension SceneDelegate: SwizzleDelegate {
    
    @objc func swizzle_scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.scene(scene, willConnectTo: session, options: connectionOptions)
        AnalyticsHelper.shared.trackAppVersion()
        if let userAccount = NCManageDatabase.shared.getActiveAccount() {
            AnalyticsHelper.shared.trackUsedStorageData(quotaUsed: userAccount.quotaUsed)
        }
    }
    
    static func setup() {
        swizzleMethod(anyClass: self, originalSelector: #selector(scene(_:willConnectTo:options:)), swizzledSelector: #selector(swizzle_scene(_:willConnectTo:options:)))
    }
}
