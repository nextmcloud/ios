//
//  UINavigationController+Extension.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 02/08/2022.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit

extension UINavigationController {

    // https://stackoverflow.com/questions/6131205/how-to-find-topmost-view-controller-on-ios
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController!.topMostViewController()
    }

    func setNavigationBarAppearance(textColor: UIColor = NCBrandColor.shared.textColor, backgroundColor: UIColor? = .systemBackground) {
        let appearance = UINavigationBarAppearance()

        if #available(iOS 26.0, *) {
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithTransparentBackground()
            if topViewController is NCMedia {
                // transparent
            } else {
                appearance.backgroundColor = backgroundColor
            }
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
        }
        appearance.titleTextAttributes = [.foregroundColor: textColor]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance

        navigationBar.tintColor = NCBrandColor.shared.brand
        navigationBar.prefersLargeTitles = false
    }
    
    func setMediaAppreance() {
        setNavigationBarHidden(true, animated: false)
    }
    
    func popupFromNavigationStack(context: String) {
        guard let nav = currentNavigationController() else {
            return
        }
        nav.popViewController(animated: true)
    }

    func currentNavigationController() -> UINavigationController? {
        // Try to find the key window's root and traverse to the visible navigation controller
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard let root = keyWindow?.rootViewController else { return nil }
        return findNavigationController(from: root)
    }

    func findNavigationController(from vc: UIViewController) -> UINavigationController? {
        if let nav = vc as? UINavigationController { return nav }
        if let tab = vc as? UITabBarController {
            if let selected = tab.selectedViewController, let nav = findNavigationController(from: selected) { return nav }
        }
        if let presented = vc.presentedViewController, let nav = findNavigationController(from: presented) { return nav }
        for child in vc.children {
            if let nav = findNavigationController(from: child) { return nav }
        }
        return vc.navigationController
    }
}
