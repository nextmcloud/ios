// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Iva Horn
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

///
/// View controller for the download limit detail view in share details.
///
class NCShareDownloadLimitViewController: UIViewController, NCShareNavigationTitleSetting {
    public var downloadLimit: DownloadLimitViewModel = .unlimited
    public var metadata: tableMetadata!
    public var onDismiss: (() -> Void)?
    public var share: Shareable!
    public var shareDownloadLimitTableViewControllerDelegate: NCShareDownloadLimitTableViewControllerDelegate?

    @IBOutlet var headerContainerView: UIView!
//    private var headerView: NCShareAdvancePermissionHeader?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitle()

//        NotificationCenter.default.addObserver(self, selector: #selector(handleShareCountsUpdate), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterShareCountsUpdated), object: nil)

        // Set up header view.
//        setupHeaderView()

        guard let headerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as? NCShareAdvancePermissionHeader) else { return }
//        guard let headerView = (Bundle.main.loadNibNamed("NCShareHeader", owner: self, options: nil)?.first as? NCShareHeader) else { return }
        headerContainerView.addSubview(headerView)
        headerView.frame = headerContainerView.frame
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: headerContainerView.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: headerContainerView.rightAnchor).isActive = true

        headerView.setupUI(with: metadata)

        // End editing of inputs when the user taps anywhere else.

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let tableViewController = segue.destination as? NCShareDownloadLimitTableViewController else {
            return
        }

        tableViewController.delegate = shareDownloadLimitTableViewControllerDelegate
        tableViewController.downloadLimit = downloadLimit
        tableViewController.metadata = metadata
        tableViewController.share = share
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
//    // MARK: - Header
//
//    private func setupHeaderView() {
//        guard headerView == nil else { return } // Prevent multiple creations
//        guard let view = Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as? NCShareAdvancePermissionHeader else { return }
//
//        headerView = view
//        headerContainerView.addSubview(view)
//
//        // Auto Layout
//        view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            view.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
//            view.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
//            view.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor)
//        ])
//
//        // Initial setup
//        headerView?.setupUI(with: metadata)
//    }
//
//    @objc private func handleShareCountsUpdate(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let links = userInfo["links"] as? Int,
//              let emails = userInfo["emails"] as? Int else { return }
//
//        // Just update, don’t recreate
//        headerView?.setupUI(with: metadata, linkCount: links, emailCount: emails)
//    }
}
