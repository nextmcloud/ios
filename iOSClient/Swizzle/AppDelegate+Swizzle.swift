//
//  AppDelegate+Swizzle.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 19/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

extension AppDelegate: SwizzleDelegate {
    @objc func swizzle_toggleMenu(mainTabBarController: NCMainTabBarController) {
        self.toggleMenu(mainTabBarController: mainTabBarController)
    }

//    static func setup() {
//        swizzleMethod(anyClass: self, originalSelector: #selector(toggleMenu(_:)), swizzledSelector: #selector(swizzle_toggleMenu(_:)))
//    }
}
