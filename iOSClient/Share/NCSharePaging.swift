// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit
import NextcloudKitUI
import TagListView
import SwiftUI

protocol NCSharePagingContent {
    var textField: UITextField? { get }
}

class NCSharePaging: UIViewController {
    private weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
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

        let manageTagsAction = UIAction(title: NSLocalizedString("_edit_tags_", comment: ""), image: UIImage(systemName: "tag")) { [weak self] _ in
            self?.editTagsTapped(nil)
        }

        let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: nil, action: nil)
        moreButton.menu = UIMenu(children: [manageTagsAction])

        var rightBarButtonItems = [moreButton]

        // The unified share (+) button only applies to servers with the new sharing API.
        let capabilities = NCNetworking.shared.capabilities[metadata.account] ?? NKCapabilities.Capabilities()

        if capabilities.unifiedSharingEnabled {
            let addShareButton = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .plain, target: self, action: #selector(addShareTapped(_:)))
            addShareButton.accessibilityLabel = NSLocalizedString("_share_", comment: "")
            rightBarButtonItems.insert(addShareButton, at: 0)
        }

        navigationItem.rightBarButtonItems = rightBarButtonItems

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

        pageVCs = pages.map { makeViewController(for: $0) }
        tabModel.selection = pages.firstIndex(of: initialPage) ?? 0

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

    private func setupHeader() {
        guard let headerView = Bundle.main.loadNibNamed("NCShareHeader", owner: self, options: nil)?.first as? NCShareHeader else { return }
        self.headerView = headerView
        headerView.backgroundColor = .systemGroupedBackground
        headerView.setupUI(with: metadata)

        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupContent() {
        let content = NCSharePagingContentView(
            model: tabModel,
            tint: Color(NCBrandColor.shared.getElement(account: metadata.account)),
            titles: pages.map(titleForTab(_:)),
            pageVCs: pageVCs,
            onSelectionChange: { [weak self] _ in
                self?.view.endEditing(true)
            }
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

    private func titleForTab(_ tab: NCBrandOptions.NCInfoPagingTab) -> String {
        switch tab {
        case .activity: return NSLocalizedString("_activity_", comment: "")
        case .sharing: return NSLocalizedString("_sharing_", comment: "")
        case .details: return NSLocalizedString("_details_", comment: "")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarAppearance()

        let capabilities = NCNetworking.shared.capabilities[metadata.account] ?? NKCapabilities.Capabilities()

        if !capabilities.fileSharingApiEnabled && !capabilities.filesComments && capabilities.activity.isEmpty {
            self.dismiss(animated: false, completion: nil)
        }

        pagingViewController.menuItemSize = .fixed(
            width: self.view.bounds.width / CGFloat(self.pages.count),
            height: 40)
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

    @objc func exitTapped(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func addShareTapped(_ sender: UIBarButtonItem) {
        page = .sharing
        shareCreateTrigger.isPresenting = true
    }

    @objc func editTagsTapped(_ sender: Any?) {
        guard let header = headerView else { return }

        header.presentTagEditor(from: self) { [weak self] tags in
            guard let self else { return }
            self.metadata.tags.removeAll()
            self.metadata.tags.append(objectsIn: tags, account: self.metadata.account)
        }
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
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onChange(of: model.selection) { _, newValue in
            onSelectionChange(newValue)
        }
    }
}

private struct NCViewControllerRepresentable: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { viewController }

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
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
        path.addGestureRecognizer(longGesture)
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
            return ((metadata.sharePermissionsCollaborationServices & NCGlobal.shared.permissionShareShare) != 0)
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
        NCNetworking.shared.setStatusWaitFavorite(metadata) { error in
            if error == .success {
                guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) else { return }
                if metadata.favorite {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                } else {
                    self.favorite.setImage(self.utility.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                }
            } else {
                NCContentPresenter().showError(error: error)
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
