// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import SwiftUI
import NextcloudKit

struct NavigationCollectionViewCommon {
    var serverUrl: String
    var navigationController: UINavigationController?
    var viewController: NCCollectionViewCommon
}

class NCMainTabBarController: UITabBarController {
    var sceneIdentifier: String = UUID().uuidString
    var account: String = "" {
        didSet {
            // NCImageCache.shared.controller = self
        }
    }
    var availableNotifications: Bool = false
    var documentPickerViewController: NCDocumentPickerViewController?
    let navigationCollectionViewCommon = ThreadSafeArray<NavigationCollectionViewCommon>()
    private var previousIndex: Int?
    private let groupDefaults = UserDefaults(suiteName: NCBrandOptions.shared.capabilitiesGroup)
    private var checkUserDelaultErrorInProgress: Bool = false
    private var timer: Timer?
    private var timerTask: Task<Void, Never>?
    private let global = NCGlobal.shared

    var window: UIWindow? {
        return SceneManager.shared.getWindow(controller: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        if #available(iOS 17.0, *) {
            traitOverrides.horizontalSizeClass = .compact
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil, queue: .main) { [weak self] notification in
        NCNetworking.shared.controller = self
        NCImageCache.shared.controller = self

        NCDownloadAction.shared.setup(sceneIdentifier: sceneIdentifier)

        tabBar.tintColor = NCBrandColor.shared.getElement(account: account)

        // File
        if let item = tabBar.items?[0] {
            item.title = NSLocalizedString("_home_", comment: "")
            item.image = UIImage(systemName: "folder.fill")
            item.selectedImage = item.image
            item.tag = 100
        }

        // Favorite
        if let item = tabBar.items?[1] {
            item.title = NSLocalizedString("_favorites_", comment: "")
            item.image = UIImage(systemName: "star.fill")
            item.selectedImage = item.image
            item.tag = 101
        }

        // Media
        if let item = tabBar.items?[2] {
            item.title = NSLocalizedString("_media_", comment: "")
            item.image = UIImage(systemName: "photo.fill")
            item.selectedImage = item.image
            item.tag = 102
        }

        // Activity
        if let item = tabBar.items?[3] {
            item.title = NSLocalizedString("_activity_", comment: "")
            item.image = UIImage(systemName: "bolt.fill")
            item.selectedImage = item.image
            item.tag = 103
        }

        // More
        if let item = tabBar.items?[4] {
            item.title = NSLocalizedString("_more_", comment: "")
            item.image = UIImage(systemName: "ellipsis.circle.fill")
            item.selectedImage = item.image
            item.tag = 104
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.global.notificationCenterChangeTheming), object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo as? NSDictionary,
               let account = userInfo["account"] as? String,
               let tabBar = self?.tabBar as? NCMainTabBar,
               self?.account == account {
                let color = NCBrandColor.shared.getElement(account: account)
                tabBar.color = color
                tabBar.tintColor = color
                tabBar.setNeedsDisplay()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterCheckUserDelaultErrorDone), object: nil, queue: nil) { notification in
            if let userInfo = notification.userInfo,
               let account = userInfo["account"] as? String,
               let controller = userInfo["controller"] as? NCMainTabBarController,
               account == self.account,
               controller == self {
                self.checkUserDelaultErrorInProgress = false
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.timerTask?.cancel()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if UIApplication.shared.applicationState == .active {
                    self.timerCheckServerError()
            if !isAppInBackground {
                self.timerTask = Task { @MainActor [weak self] in
                    await self?.timerCheck()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previousIndex = selectedIndex

        if NCBrandOptions.shared.enforce_passcode_lock && NCPreferences().passcode.isEmptyOrNil {
            let vc = UIHostingController(rootView: SetupPasscodeView(isLockActive: .constant(false)))
            vc.isModalInPresentation = true

            present(vc, animated: true)
        }
    }

    private func timerCheckServerError() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            NCNetworking.shared.checkServerError(account: self.account, controller: self) {
                self.timerCheckServerError()
                /// Update right bar button item
                if let navigationController = self.selectedViewController as? NCMainNavigationController {
                    navigationController.updateRightBarButtonItems(self.tabBar.items?[0])
                }
                /// Update Activity tab bar
                if let item = self.tabBar.items?[3] {
                    let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: self.account)
                    item.isEnabled = capabilities.activityEnabled
                }
    @MainActor
    private func timerCheck() async {
        var nanoseconds: UInt64 = 3_000_000_000

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard isViewLoaded, view.window != nil else {
                continue
            }

            let capabilities = await NKCapabilities.shared.getCapabilities(for: self.account)

            // Check error
            await NCNetworking.shared.checkServerError(account: self.account, controller: self)

            // Update right bar button item
            if let navigationController = self.selectedViewController as? NCMainNavigationController {
                let transferCount = await navigationController.updateRightBarButtonItems(self.tabBar.items?[0])
                nanoseconds = transferCount == 0 ? 3_000_000_000 : 1_500_000_000
            }
            // Update Activity tab bar
            if let item = self.tabBar.items?[3] {
                item.isEnabled = capabilities.activityEnabled
            }
        }
    }

    func currentViewController() -> UIViewController? {
        return (selectedViewController as? UINavigationController)?.topViewController
    }

    func currentServerUrl() -> String {
        let session = NCSession.shared.getSession(account: account)
        var serverUrl = NCUtilityFileSystem().getHomeServer(session: session)
        let viewController = currentViewController()
        if let collectionViewCommon = viewController as? NCCollectionViewCommon {
            if !collectionViewCommon.serverUrl.isEmpty {
                serverUrl = collectionViewCommon.serverUrl
            }
        }
        return serverUrl
    }
}

extension NCMainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if previousIndex == tabBarController.selectedIndex {
            scrollToTop(viewController: viewController)
        }
        previousIndex = tabBarController.selectedIndex
    }

    private func scrollToTop(viewController: UIViewController) {
        guard let navigationController = viewController as? UINavigationController,
              let topViewController = navigationController.topViewController else { return }

        if let scrollView = topViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: true)
        }
    }
}
