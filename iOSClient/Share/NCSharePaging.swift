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
import Parchment
import NextcloudKit
import MarqueeLabel
import TagListView

protocol NCSharePagingContent {
    var textField: UITextField? { get }
}

class NCSharePaging: UIViewController {
    private let pagingViewController = NCShareHeaderViewController()
    private weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
    private var currentVC: NCSharePagingContent?
    private let applicationHandle = NCApplicationHandle()

    var metadata = tableMetadata()
    var pages: [NCBrandOptions.NCInfoPagingTab] = []
    var page: NCBrandOptions.NCInfoPagingTab = .activity

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = NSLocalizedString("_details_", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .done, target: self, action: #selector(exitTapped))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterApplicationDidEnterBackground), object: nil)

        // *** MUST BE THE FIRST ONE ***
        pagingViewController.metadata = metadata
        pagingViewController.backgroundColor = .systemBackground
        pagingViewController.menuBackgroundColor = .systemBackground
        pagingViewController.selectedBackgroundColor = .systemBackground
        pagingViewController.textColor = .label
        pagingViewController.selectedTextColor = .label

        // Pagination
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)

        // Customization
        pagingViewController.indicatorOptions = .visible(
            height: 1,
            zIndex: Int.max,
            spacing: .zero,
            insets: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        )

        // Contrain the paging view to all edges.
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        pagingViewController.dataSource = self
        pagingViewController.delegate = self

        if page.rawValue < pages.count {
            pagingViewController.select(index: page.rawValue)
        } else {
            pagingViewController.select(index: 0)
        }

        (pagingViewController.view as? NCSharePagingView)?.setupConstraints()
        pagingViewController.reloadMenu()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentVC = pagingViewController.pageViewController.selectedViewController as? NCSharePagingContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if NCCapabilities.shared.disableSharesView(account: metadata.account) {
            self.dismiss(animated: false, completion: nil)
        }

        pagingViewController.menuItemSize = .fixed(
            width: self.view.bounds.width / CGFloat(self.pages.count),
            height: 40)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource, userInfo: ["serverUrl": metadata.serverUrl])
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.pagingViewController.menuItemSize = .fixed(
                width: self.view.bounds.width / CGFloat(self.pages.count),
                height: 40)
            self.currentVC?.textField?.resignFirstResponder()
        }
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

    @objc func exitTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func applicationDidEnterBackground(notification: Notification) {
        self.dismiss(animated: false, completion: nil)
    }
}

// MARK: - PagingViewController Delegate

extension NCSharePaging: PagingViewControllerDelegate {

    func pagingViewController(_ pagingViewController: PagingViewController, willScrollToItem pagingItem: PagingItem, startingViewController: UIViewController, destinationViewController: UIViewController) {

        currentVC?.textField?.resignFirstResponder()
        self.currentVC = destinationViewController as? NCSharePagingContent
    }
}

// MARK: - PagingViewController DataSource

extension NCSharePaging: PagingViewControllerDataSource {

    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {

        let height = pagingViewController.options.menuHeight + NCSharePagingView.headerHeight + NCSharePagingView.tagHeaderHeight

        if pages[index] == .activity {
            guard let viewController = UIStoryboard(name: "NCActivity", bundle: nil).instantiateInitialViewController() as? NCActivity else {
                return UIViewController()
            }
            viewController.height = height
            viewController.showComments = true
            viewController.didSelectItemEnable = false
            viewController.metadata = metadata
            viewController.objectType = "files"
            viewController.account = metadata.account
            return viewController
        } else if pages[index] == .sharing {
            guard let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "sharing") as? NCShare else {
                return UIViewController()
            }
            viewController.metadata = metadata
            viewController.height = height
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

    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return self.pages.count
    }
}

// MARK: - Header

class NCShareHeaderViewController: PagingViewController {

    public var image: UIImage?
    public var metadata = tableMetadata()

    public var activityEnabled = true
    public var commentsEnabled = true
    public var sharingEnabled = true

    override func loadView() {
        view = NCSharePagingView(
            options: options,
            collectionView: collectionView,
            pageView: pageViewController.view,
            metadata: metadata
        )
    }
}

class NCSharePagingView: PagingView {

    static let headerHeight: CGFloat = 90
    static var tagHeaderHeight: CGFloat = 0
    var metadata = tableMetadata()
    public var headerHeightConstraint: NSLayoutConstraint?

    // MARK: - View Life Cycle

    public init(options: Parchment.PagingOptions, collectionView: UICollectionView, pageView: UIView, metadata: tableMetadata) {
        super.init(options: options, collectionView: collectionView, pageView: pageView)

        self.metadata = metadata
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class NCShareHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelSharingInfo: UILabel!
    @IBOutlet weak var fullWidthImageView: UIImageView!
    @IBOutlet weak var canShareInfoView: UIView!
    @IBOutlet weak var sharedByLabel: UILabel!
    @IBOutlet weak var resharingAllowedLabel: UILabel!
    @IBOutlet weak var sharedByImageView: UIImageView!
    @IBOutlet weak var constraintTopSharingLabel: NSLayoutConstraint!
    let utility = NCUtility()
    var ocId = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        labelSharing.text = NSLocalizedString("_sharing_", comment: "")
        labelSharingInfo.text = NSLocalizedString("_sharing_message_", comment: "")
        
        if UIScreen.main.bounds.width < 376 {
            constraintTopSharingLabel.constant = 15
        }
    }
    
    func updateCanReshareUI() {
        let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId)
        var isCurrentUser = true
        if let ownerId = metadata?.ownerId, !ownerId.isEmpty {
            isCurrentUser = NCShareCommon().isCurrentUserIsFileOwner(fileOwnerId: ownerId)
        }
        var canReshare: Bool {
            guard let metadata = metadata else { return true }
            return ((metadata.sharePermissionsCollaborationServices & NCPermissions().permissionShareShare) != 0)
        }
        canShareInfoView.isHidden = isCurrentUser
        labelSharingInfo.isHidden = !isCurrentUser
        
        if !isCurrentUser {
            sharedByImageView.image = UIImage(named: "cloudUpload")?.image(color: .systemBlue, size: 26)
            let ownerName = metadata?.ownerDisplayName ?? ""
            sharedByLabel.text = NSLocalizedString("_shared_with_you_by_", comment: "") + " " + ownerName
            let resharingAllowedMessage =  NSLocalizedString("_share_reshare_allowed_", comment: "") + " " + NSLocalizedString("_sharing_message_", comment: "")
            let resharingNotAllowedMessage = NSLocalizedString("_share_reshare_not_allowed_", comment: "")
            resharingAllowedLabel.text = canReshare ? resharingAllowedMessage  : resharingNotAllowedMessage
        }
    }
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) else { return }
        NCNetworking.shared.favoriteMetadata(metadata) { error in
            if error == .success {
                guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) else { return }
                if metadata.favorite {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite], size: 24), for: .normal)
                } else {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.textInfo], size: 24), for: .normal)
                }
            } else {
                NCContentPresenter().showError(error: error)
            }
        }
    }
}
