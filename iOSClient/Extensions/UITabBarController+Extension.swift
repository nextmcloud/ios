// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

extension UITabBarController {

    // https://stackoverflow.com/questions/6131205/how-to-find-topmost-view-controller-on-ios
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }

    func getSelectedTabIndex() -> Int? {
        // 1. Access the window through the scene delegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }

        // 2. Identify the UITabBarController
        if let tabBarController = rootVC as? UITabBarController {
            return tabBarController.selectedIndex
        } else if let presentedTabBar = rootVC.presentedViewController as? UITabBarController {
            return presentedTabBar.selectedIndex
        }

        return nil
    }
}
