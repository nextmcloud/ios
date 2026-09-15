//
//  NCSharePaging.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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

import UIKit
import NextcloudKit
import MarqueeLabel
import NextcloudKitUI
import TagListView
import SwiftUI

protocol NCSharePagingContent {
    var textField: UITextField? { get }
}

class NCSharePaging: UIViewController {
    private weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
    private var currentVC: NCSharePagingContent?
    private let applicationHandle = NCApplicationHandle()
    private let tabModel = NCSharePagingTabModel()
    private weak var headerView: NCShareHeader?
    private var pageVCs: [UIViewController] = []
    private var contentHost: UIHostingController<NCSharePagingContentView>?

    var metadata = tableMetadata()
    var controller: NCMainTabBarController?
    private let shareCreateTrigger = CreateUnifiedShareTrigger()

    private var internalLink: String {
        metadata.urlBase + "/index.php/f/" + metadata.fileId
    }
    var pages: [NCBrandOptions.NCInfoPagingTab] = []

    private var initialPage: NCBrandOptions.NCInfoPagingTab = .activity
    var page: NCBrandOptions.NCInfoPagingTab {
        get {
            guard isViewLoaded else { return initialPage }
            let index = tabModel.selection
            return (index < pages.count) ? pages[index] : initialPage
        }
        set {
            initialPage = newValue
            if isViewLoaded, let index = pages.firstIndex(of: newValue) {
                tabModel.selection = index
            }
        }
    }

    private var currentVC: NCSharePagingContent? {
        let index = tabModel.selection
        guard index < pageVCs.count else { return nil }
        return pageVCs[index] as? NCSharePagingContent
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        title = NSLocalizedString("_details_", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(exitTapped(_:))
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("_close_", comment: "")

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // *** MUST BE THE FIRST ONE ***
        pagingViewController.metadata = metadata
        pagingViewController.backgroundColor = .systemBackground
        pagingViewController.menuBackgroundColor = .systemBackground
        pagingViewController.selectedBackgroundColor = .systemBackground
        pagingViewController.indicatorColor = NCBrandColor.shared.brand
        pagingViewController.textColor = NCBrandColor.shared.textColor
        pagingViewController.selectedTextColor = NCBrandColor.shared.brand

        // Pagination
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)

        // Customization
        pagingViewController.indicatorOptions = .visible(
            height: 1,
            zIndex: Int.max,
            spacing: .zero,
            insets: .zero
        )
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .systemGroupedBackground

        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)
        host.view.translatesAutoresizingMaskIntoConstraints = false

        let topAnchor = headerView?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        self.contentHost = host
    }

    private func makeViewController(for tab: NCBrandOptions.NCInfoPagingTab) -> UIViewController {
        // The old Parchment menu floated over the child view, so children inset by menuHeight (50).
        // The new SwiftUI layout places the picker above the content, so no inset is needed.
        let height: CGFloat = 0

        switch tab {
        case .activity:
            guard let viewController = UIStoryboard(name: "NCActivity", bundle: nil).instantiateInitialViewController() as? NCActivity else {
                return UIViewController()
            }
            viewController.height = height
            viewController.showComments = true
            viewController.didSelectItemEnable = false
            viewController.metadata = metadata
            viewController.objectType = "files"
            viewController.account = metadata.account
            viewController.usesGroupedBackground = true
            return viewController
        case .sharing:
            let capabilities = NCNetworking.shared.capabilities[metadata.account] ?? NKCapabilities.Capabilities()

            // Newer servers get the unified share list; older ones keep the legacy NCShare UI.
            if capabilities.unifiedSharingEnabled {
                let brandColor = Color(NCBrandColor.shared.getElement(account: metadata.account))
                let listView = UnifiedShareListView(account: metadata.account, sourceId: metadata.fileId, internalLink: internalLink, isDirectory: metadata.directory, tint: brandColor, createTrigger: shareCreateTrigger) { [weak self] error in
                    guard let self else { return }

                    Task {
                        let windowScene = SceneManager.shared.getWindowScene(controller: self.controller)
                        await showErrorBanner(windowScene: windowScene, error: error)
                    }
                }

                return UIHostingController(rootView: listView.tint(brandColor))
            }

            guard let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "sharing") as? NCShare else {
                return UIViewController()
            }
            viewController.metadata = metadata
            viewController.height = height
            viewController.controller = controller
            return viewController
        case .details:
            return NCShareDetailsViewController(metadata: metadata)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Re-evaluate in-app messages after viewDidAppear
        MoEngageAnalytics.shared.displayInAppNotificationSafely(reason: "viewDidAppear")

        currentVC = pagingViewController.pageViewController.selectedViewController as? NCSharePagingContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarAppearance()

        let capabilities = NCNetworking.shared.capabilities[metadata.account] ?? NKCapabilities.Capabilities()

        if !capabilities.fileSharingApiEnabled && !capabilities.filesComments && capabilities.activity.isEmpty {
            self.dismiss(animated: false, completion: nil)
        }

//        pagingViewController.menuItemSize = .fixed(
//            width: self.view.bounds.width / CGFloat(self.pages.count),
//            height: 40)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await NCNetworking.shared.transferDispatcher.notifyAllDelegates { delegate in
                delegate.transferReloadDataSource(serverUrl: self.metadata.serverUrl, requestData: false, status: nil)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.currentVC?.textField?.resignFirstResponder()
    }

    // MARK: - NotificationCenter & Keyboard & TextField

    @objc func keyboardWillShow(notification: Notification) {
         let frameEndUserInfoKey = UIResponder.keyboardFrameEndUserInfoKey

         guard let info = notification.userInfo,
               let textField = currentVC?.textField,
               let centerObject = textField.superview?.convert(textField.center, to: nil),
               let keyboardFrame = info[frameEndUserInfoKey] as? CGRect
         else { return }

        let diff = keyboardFrame.origin.y - centerObject.y - textField.frame.height
         if diff < 0 {
             view.frame.origin.y = diff
         }
     }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }

    @objc func exitTapped(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func applicationDidEnterBackground(notification: Notification) {
        self.dismiss(animated: false, completion: nil)
    }
}

// MARK: - SwiftUI tab content

@Observable
final class NCSharePagingTabModel {
    var selection: Int = 0
}

struct NCSharePagingContentView: View {
    @Bindable var model: NCSharePagingTabModel
    let tint: Color
    let titles: [String]
    let pageVCs: [UIViewController]
    var onSelectionChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $model.selection) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Text(title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(NSLocalizedString("_sections_", comment: ""))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .tint(tint)

            TabView(selection: $model.selection) {
                ForEach(Array(pageVCs.enumerated()), id: \.offset) { index, viewController in
                    NCViewControllerRepresentable(viewController: viewController)
                        .tag(index)
                }
            }
            viewController.metadata = metadata
            viewController.height = height
            viewController.controller = controller
            return viewController
        } else {
            return applicationHandle.pagingViewController(pagingViewController, viewControllerAt: index, metadata: metadata, topHeight: height)
        }
    }

    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {

        if pages[index] == .activity {
            return PagingIndexItem(index: index, title: NSLocalizedString("_activity_", comment: ""))
        } else if pages[index] == .sharing {
            return PagingIndexItem(index: index, title: NSLocalizedString("_sharing_", comment: ""))
        } else {
            return applicationHandle.pagingViewController(pagingViewController, pagingItemAt: index)
        }
    }
}

private struct NCViewControllerRepresentable: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { viewController }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

        // TabView(.page) does not propagate appearance trait changes to represented VCs (as of iOS 18.4), seems a SwiftUI bug...
        uiViewController.view.overrideUserInterfaceStyle = context.environment.colorScheme == .dark ? .dark : .light
    }
}

class NCShareHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var path: MarqueeLabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var creation: UILabel!
    @IBOutlet weak var upload: UILabel!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var details: UIButton!
    @IBOutlet weak var tagListView: TagListView!

    var ocId = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
        path.addGestureRecognizer(longGesture)
    }

    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }
        Task {
            let error = await NCNetworking.shared.setStatusWaitFavorite(metadata)
            if error == .success {
                if let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) {
                    await MainActor.run {
                        self.favorite.setImage(NCUtility().loadImage(named: metadata.favorite ? "star" : "star.fill", colors: [NCBrandColor.shared.yellowFavorite], size: 20), for: .normal)
                    }
                }
            } else {
                await MainActor.run {
                    NCContentPresenter().showError(error: error)
                }
            }
        }
    }

    @IBAction func touchUpInsideDetails(_ sender: UIButton) {
        creation.isHidden = !creation.isHidden
        upload.isHidden = !upload.isHidden
    }

    @objc func longTap(_ sender: UIGestureRecognizer) {
        UIPasteboard.general.string = path.text
        let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_copied_path_")
        NCContentPresenter().showInfo(error: error)
    }
}
