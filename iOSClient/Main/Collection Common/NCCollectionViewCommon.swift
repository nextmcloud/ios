// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import SwiftUI
import RealmSwift
import NextcloudKit
import EasyTipView

class NCCollectionViewCommon: UIViewController, UIGestureRecognizerDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, NCListCellDelegate, NCGridCellDelegate, NCPhotoCellDelegate, NCSectionHeaderMenuDelegate, NCSectionFooterDelegate, NCSectionFirstHeaderEmptyDataDelegate, NCAccountSettingsModelDelegate, UIAdaptivePresentationControllerDelegate, UIContextMenuInteractionDelegate, NCEmptyDataSetDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    let database = NCManageDatabase.shared
    let global = NCGlobal.shared
    let utility = NCUtility()
    let utilityFileSystem = NCUtilityFileSystem()
    let imageCache = NCImageCache.shared
    var dataSource = NCCollectionViewDataSource()
    let networking = NCNetworking.shared
    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    var pinchGesture: UIPinchGestureRecognizer = UIPinchGestureRecognizer()

    var autoUploadFileName = ""
    var autoUploadDirectory = ""
    let refreshControl = UIRefreshControl()
    var searchController: UISearchController?
    var backgroundImageView = UIImageView()
    var serverUrl: String = ""
    var isEditMode = false
    var isDirectoryE2EE = false
    var fileSelect: [String] = []
    var metadataFolder: tableMetadata?
    var richWorkspaceText: String?
    var sectionFirstHeader: NCSectionFirstHeader?
    var sectionFirstHeaderEmptyData: NCSectionFirstHeaderEmptyData?
    var isSearchingMode: Bool = false
    var networkSearchInProgress: Bool = false
    var layoutForView: NCDBLayoutForView?
    var searchDataSourceTask: URLSessionTask?
    var providers: [NKSearchProvider]?
    var searchResults: [NKSearchResult]?
    var listLayout = NCListLayout()
    var gridLayout = NCGridLayout()
    var mediaLayout = NCMediaLayout()
    var layoutType = NCGlobal.shared.layoutList
    var literalSearch: String?
    var tabBarSelect: NCCollectionViewCommonSelectTabBar?
    var attributesZoomIn: UIMenuElement.Attributes = []
    var attributesZoomOut: UIMenuElement.Attributes = []
    var tipViewAccounts: EasyTipView?

    // DECLARE
    var layoutKey = ""
    var titleCurrentFolder = ""
    var titlePreviusFolder: String?
    var enableSearchBar: Bool = false
    let maxImageGrid: CGFloat = 7
    var headerMenu: NCSectionHeaderMenu?
    var headerMenuTransferView = false
    var headerMenuButtonsView: Bool = true
    var headerRichWorkspaceDisable: Bool = false
    
    var groupByField = "name"

    var emptyImageName: String?
    var emptyImageColors: [UIColor]?
    var emptyImage: UIImage?
    var emptyTitle: String = ""

    var emptyDescription: String = ""
    var emptyDataPortaitOffset: CGFloat = 0
    var emptyDataLandscapeOffset: CGFloat = -20

    var lastScale: CGFloat = 1.0
    var currentScale: CGFloat = 1.0
    var maxColumns: Int {
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let column = Int(screenWidth / 44)

        return column
    }
    var transitionColumns = false
    var numberOfColumns: Int = 0
    var lastNumberOfColumns: Int = 0

    var isTransitioning: Bool = false
    var selectableDataSource: [RealmSwiftObject] { dataSource.getMetadataSourceForAllSections() }
    var pushed: Bool = false
    var emptyDataSet: NCEmptyDataSet?
    
    let heightHeaderRecommendations: CGFloat = 160
    let heightHeaderSection: CGFloat = 30

    @MainActor
    var session: NCSession.Session {
        NCSession.shared.getSession(controller: tabBarController)
    }

    var isLayoutPhoto: Bool {
        layoutForView?.layout == global.layoutPhotoRatio || layoutForView?.layout == global.layoutPhotoSquare
    }

    var isLayoutGrid: Bool {
        layoutForView?.layout == global.layoutGrid
    }

    var isLayoutList: Bool {
        layoutForView?.layout == global.layoutList
    }

    var showDescription: Bool {
        !headerRichWorkspaceDisable && NCPreferences().showDescription
    }

    var isRecommendationActived: Bool {
        let capabilities = NCNetworking.shared.capabilities[session.account] ?? NKCapabilities.Capabilities()
        return self.serverUrl == self.utilityFileSystem.getHomeServer(session: self.session) && capabilities.recommendations
    }

    var infoLabelsSeparator: String {
        layoutForView?.layout == global.layoutList ? " - " : ""
    }

    @MainActor
    var controller: NCMainTabBarController? {
        self.tabBarController as? NCMainTabBarController
    }

    var mainNavigationController: NCMainNavigationController? {
        self.navigationController as? NCMainNavigationController
    }

    var sceneIdentifier: String {
        (self.tabBarController as? NCMainTabBarController)?.sceneIdentifier ?? ""
    }

    var isNumberOfItemsInAllSectionsNull: Bool {
        var totalItems = 0
        for section in 0..<self.collectionView.numberOfSections {
            totalItems += self.collectionView.numberOfItems(inSection: section)
        }
        return totalItems == 0
    }

    var numberOfItemsInAllSections: Int {
        var totalItems = 0
        for section in 0..<self.collectionView.numberOfSections {
            totalItems += self.collectionView.numberOfItems(inSection: section)
        }
        return totalItems
    }

    var isPinchGestureActive: Bool {
        return pinchGesture.state == .began || pinchGesture.state == .changed
    }

    func isRecommendationActived() async -> Bool {
        let capabilities = await NKCapabilities.shared.getCapabilities(for: session.account)
        return self.serverUrl == self.utilityFileSystem.getHomeServer(session: self.session) && capabilities.recommendations
    }

    internal let debouncer = NCDebouncer(delay: 1)

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.presentationController?.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.accessibilityIdentifier = "NCCollectionViewCommon"

        view.backgroundColor = .systemBackground
        collectionView.backgroundColor = .systemBackground
        refreshControl.tintColor = .gray
        
        listLayout = NCListLayout()
        gridLayout = NCGridLayout()
        
        if enableSearchBar {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            searchController?.searchBar.autocapitalizationType = .none
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_back_", comment: ""), style: .plain, target: nil, action: nil)
        }

        // Cell
        collectionView.register(UINib(nibName: "NCListCell", bundle: nil), forCellWithReuseIdentifier: "listCell")
        collectionView.register(UINib(nibName: "NCGridCell", bundle: nil), forCellWithReuseIdentifier: "gridCell")
        collectionView.register(UINib(nibName: "NCPhotoCell", bundle: nil), forCellWithReuseIdentifier: "photoCell")
        collectionView.register(UINib(nibName: "NCTransferCell", bundle: nil), forCellWithReuseIdentifier: "transferCell")

        // Header
        collectionView.register(UINib(nibName: "NCSectionHeaderMenu", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeaderMenu")
        collectionView.register(UINib(nibName: "NCSectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")

        // Footer
        collectionView.register(UINib(nibName: "NCSectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "sectionFooter")
        collectionView.register(UINib(nibName: "NCSectionFooter", bundle: nil), forSupplementaryViewOfKind: mediaSectionFooter, withReuseIdentifier: "sectionFooter")

        collectionView.refreshControl = refreshControl
        refreshControl.action(for: .valueChanged) { _ in
            Task { @MainActor in
                // Perform async server forced
                await self.getServerData(forced: true)

                // Stop the refresh control after data is loaded
                self.refreshControl.endRefreshing()

                // Wait 1.5 seconds before resetting the button alpha
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                self.mainNavigationController?.resetPlusButtonAlpha()
            }
        }
        
        // Empty
        emptyDataSet = NCEmptyDataSet(view: collectionView, offset: getHeaderHeight(), delegate: self)

        let longPressedGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressCollecationView(_:)))
        longPressedGesture.minimumPressDuration = 0.5
        longPressedGesture.delegate = self
        longPressedGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressedGesture)

        collectionView.prefetchDataSource = self
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        collectionView.addGestureRecognizer(pinchGesture)

        let dropInteraction = UIDropInteraction(delegate: self)
        self.navigationController?.navigationItem.leftBarButtonItems?.first?.customView?.addInteraction(dropInteraction)
        
        if(!UserDefaults.standard.bool(forKey: "isInitialPrivacySettingsShowed") || isApplicationUpdated()){
            redirectToPrivacyViewController()
            
            //set current app version
            let appVersion = Bundle.main.infoDictionary?["CFBundleInfoDictionaryVersion"] as? String
            UserDefaults.standard.set(appVersion, forKey: "CurrentAppVersion")
        }

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (view: NCCollectionViewCommon, _) in
            guard let self else { return }

            self.sectionFirstHeader?.setRichWorkspaceColor(style: view.traitCollection.userInterfaceStyle)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.global.notificationCenterChangeTheming), object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.collectionView.reloadData()
        }

        DispatchQueue.main.async {
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if titlePreviusFolder != nil {
            navigationController?.navigationBar.topItem?.title = titlePreviusFolder
        }
        navigationItem.title = titleCurrentFolder
        navigationController?.setNavigationBarAppearance()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        appDelegate.activeViewController = self

        if tabBarSelect == nil {
            tabBarSelect = NCCollectionViewCommonSelectTabBar(controller: self.controller, viewController: self, delegate: self)
        }

        isEditMode = false

        /// Magentacloud branding changes hide user account button on left navigation bar
//        setNavigationLeftItems()
        setNavigationRightItems()

        layoutForView = database.getLayoutForView(account: session.account, key: layoutKey, serverUrl: serverUrl)
        gridLayout.column = CGFloat(layoutForView?.columnGrid ?? 3)
        if isLayoutList {
            collectionView?.collectionViewLayout = listLayout
            self.layoutType = global.layoutList
        } else if isLayoutGrid {
            collectionView?.collectionViewLayout = gridLayout
            self.layoutType = global.layoutGrid
        } else if layoutForView?.layout == global.layoutPhotoRatio {
            collectionView?.collectionViewLayout = mediaLayout
            self.layoutType = global.layoutPhotoRatio
        } else if layoutForView?.layout == global.layoutPhotoSquare {
            collectionView?.collectionViewLayout = mediaLayout
            self.layoutType = global.layoutPhotoSquare
        }

        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            await NCNetworking.shared.transferDispatcher.addDelegate(self)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeRichWorkspaceWebView), name: NSNotification.Name(rawValue: global.notificationCenterCloseRichWorkspaceWebView), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeStatusFolderE2EE(_:)), name: NSNotification.Name(rawValue: global.notificationCenterChangeStatusFolderE2EE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeLayout(_:)), name: NSNotification.Name(rawValue: global.notificationCenterChangeLayout), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(deleteFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterDeleteFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(copyMoveFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterCopyMoveFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renameFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterRenameFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(createFolder(_:)), name: NSNotification.Name(rawValue: global.notificationCenterCreateFolder), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterFavoriteFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(downloadStartFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterDownloadStartFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadedFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterDownloadedFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCancelFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterDownloadCancelFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadStartFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterUploadStartFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadedFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterUploadedFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadedLivePhoto(_:)), name: NSNotification.Name(rawValue: global.notificationCenterUploadedLivePhoto), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadCancelFile(_:)), name: NSNotification.Name(rawValue: global.notificationCenterUploadCancelFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateShare(_:)), name: NSNotification.Name(rawValue: global.notificationCenterUpdateShare), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(triggerProgressTask(_:)), name: NSNotification.Name(rawValue: global.notificationCenterProgressTask), object: nil)

        // FIXME: iPAD PDF landscape mode iOS 16
        DispatchQueue.main.async {
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.networking.cancelUnifiedSearchFiles()
        dismissTip()
        pushed = false
        toggleSelect(isOn: false)
        // Cancel Queue & Retrieves Properties
        self.networking.downloadThumbnailQueue.cancelAll()
        self.networking.unifiedSearchQueue.cancelAll()
        searchDataSourceTask?.cancel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        Task {
            await NCNetworking.shared.transferDispatcher.removeDelegate(self)
        }

        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterCloseRichWorkspaceWebView), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterChangeStatusFolderE2EE), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterChangeLayout), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterDeleteFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterCopyMoveFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterCopyFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterMoveFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterRenameFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterCreateFolder), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterFavoriteFile), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterDownloadStartFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterDownloadedFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterDownloadCancelFile), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterUploadStartFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterUploadedFile), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterUploadedLivePhoto), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterUploadCancelFile), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: global.notificationCenterUpdateShare), object: nil)

        removeImageCache(metadatas: self.dataSource.getMetadatas())
    }
    
    func isApplicationUpdated() -> Bool {
        let appVersion = Bundle.main.infoDictionary?["CFBundleInfoDictionaryVersion"] as? String ?? ""
        let currentVersion = UserDefaults.standard.string(forKey: "CurrentAppVersion")
        return currentVersion != appVersion
    }

    func redirectToPrivacyViewController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "NCSettings", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "privacySettingsNavigation") as! UINavigationController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }

    func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
        let viewController = presentationController.presentedViewController

        if viewController is NCViewerRichWorkspaceWebView {
            closeRichWorkspaceWebView()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                self.collectionView?.collectionViewLayout.invalidateLayout()
            }
            animator.startAnimation()
        })

        self.dismissTip()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - Transfer Delegate

    func transferProgressDidUpdate(progress: Float, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String) { }

    func transferChange(status: String, metadatasError: [tableMetadata: NKError]) {
        switch status {
        // DELETE
        case self.global.networkingStatusDelete:
            let errorForThisServer = metadatasError.first { entry in
                let (key, value) = entry
                return key.serverUrl == self.serverUrl && value != .success
            }?.value

            let needLoadDataSource = metadatasError.contains { entry in
                let (key, value) = entry
                return key.serverUrl == self.serverUrl && value == .success
            }

            if let error = errorForThisServer {
                NCContentPresenter().showError(error: error)
            }

            if self.isSearchingMode {
                self.networkSearch()
            } else if needLoadDataSource {
                Task {
                    await self.reloadDataSource()
                }
            } else {
                Task.detached {
                    if await self.isRecommendationActived() {
                        await self.networking.createRecommendations(session: self.session, serverUrl: self.serverUrl, collectionView: self.collectionView)
                    }
                }
            }
        default:
            break
        }
    }

    func transferChange(status: String, metadata: tableMetadata, error: NKError) {
        guard session.account == metadata.account else { return }

        if error != .success {
            NCContentPresenter().showError(error: error)
        }

        DispatchQueue.main.async {
            switch status {
            // UPLOADED, UPLOADED LIVEPHOTO
            case self.global.networkingStatusUploaded, self.global.networkingStatusUploadedLivePhoto:
                self.debouncer.call {
                    if self.isSearchingMode {
                        self.networkSearch()
                    } else if self.serverUrl == metadata.serverUrl {
                        Task {
                            await self.reloadDataSource()
                        }
                    }
                }
            // DOWNLOAD
            case self.global.networkingStatusDownloading:
                Task {
                    if metadata.serverUrl == self.serverUrl {
                        await self.reloadDataSource()
                    }
                }
            case self.global.networkingStatusDownloaded:
                Task {
                    if metadata.serverUrl == self.serverUrl {
                        await self.reloadDataSource()
                    }
                }
            case self.global.networkingStatusDownloadCancel:
                Task {
                    if metadata.serverUrl == self.serverUrl {
                        await self.reloadDataSource()
                    }
                }
            // CREATE FOLDER
            case self.global.networkingStatusCreateFolder:
                if metadata.serverUrl == self.serverUrl, metadata.sessionSelector != self.global.selectorUploadAutoUpload {
                    self.pushMetadata(metadata)
                }
            // RENAME
            case self.global.networkingStatusRename:
                self.debouncer.call {
                    if self.isSearchingMode {
                        self.networkSearch()
                    } else if self.serverUrl == metadata.serverUrl {
                        Task {
                            await self.reloadDataSource()
                        }
                    }
                }
            // FAVORITE
            case self.global.networkingStatusFavorite:
                self.debouncer.call {
                    if self.isSearchingMode {
                        self.networkSearch()
                    } else if self is NCFavorite {
                        Task {
                            await self.reloadDataSource()
                        }
                    } else if self.serverUrl == metadata.serverUrl {
                        Task {
                            await self.reloadDataSource()
                        }
                    }
                }
            default:
                break
            }
        }
    }

    func transferReloadData(serverUrl: String?, status: Int?) {
        self.debouncer.call {
            if self.isSearchingMode {
                guard status != self.global.metadataStatusWaitDelete,
                      status != self.global.metadataStatusWaitRename,
                      status != self.global.metadataStatusWaitMove,
                      status != self.global.metadataStatusWaitCopy,
                      status != self.global.metadataStatusWaitFavorite else {
                    return
                }
                self.networkSearch()
            } else if ( self.serverUrl == serverUrl) || serverUrl == nil {
                Task {
                    await self.reloadDataSource()
                }
            }
        }
    }

    func transferRequestData(serverUrl: String?) {
        self.debouncer.call {
            if self.isSearchingMode {
                self.networkSearch()
            } else if ( self.serverUrl == serverUrl) || serverUrl == nil {
                Task {
                    await self.getServerData()
                }
            }
        }
    }

    func transferCopy(metadata: tableMetadata, destination: String, error: NKError) {
        if error != .success {
            NCContentPresenter().showError(error: error)
        }

        if isSearchingMode {
            return networkSearch()
        }

        if metadata.serverUrl == self.serverUrl || destination == self.serverUrl {
            Task {
                await self.reloadDataSource()
            }
        }
    }

    func transferMove(metadata: tableMetadata, destination: String, error: NKError) {
        if error != .success {
            NCContentPresenter().showError(error: error)
        }

        if isSearchingMode {
            return networkSearch()
        }

        if metadata.serverUrl == self.serverUrl || destination == self.serverUrl {
            Task {
                await self.reloadDataSource()
            }
        }
    }

    // MARK: - NotificationCenter

    @objc func applicationWillResignActive(_ notification: NSNotification) {
        mainNavigationController?.resetPlusButtonAlpha()
    }

    @objc func closeRichWorkspaceWebView() {
        Task {
            await self.reloadDataSource()
        }
    }

    // MARK: - Layout

    func changeLayout(layoutForView: NCDBLayoutForView) {
        let homeServer = utilityFileSystem.getHomeServer(urlBase: session.urlBase, userId: session.userId)
        let numFoldersLayoutsForView = self.database.getLayoutsForView(keyStore: layoutForView.keyStore)?.count ?? 1

        func changeLayout(withSubFolders: Bool) {
            if self.layoutForView?.layout == layoutForView.layout {
                self.layoutForView = self.database.setLayoutForView(layoutForView: layoutForView, withSubFolders: withSubFolders)
                Task {
                    await self.reloadDataSource()
                }
                return
            }

            self.layoutForView = self.database.setLayoutForView(layoutForView: layoutForView, withSubFolders: withSubFolders)
            layoutForView.layout = layoutForView.layout
            self.layoutType = layoutForView.layout

            collectionView.reloadData()

            switch layoutForView.layout {
            case global.layoutList:
                self.collectionView.setCollectionViewLayout(self.listLayout, animated: true)
            case global.layoutGrid:
                self.collectionView.setCollectionViewLayout(self.gridLayout, animated: true)
            case global.layoutPhotoSquare, global.layoutPhotoRatio:
                self.collectionView.setCollectionViewLayout(self.mediaLayout, animated: true)
            default:
                break
            }

            self.collectionView.collectionViewLayout.invalidateLayout()

            Task {
                await (self.navigationController as? NCMainNavigationController)?.updateRightMenu()
            }
        }

        if serverUrl == homeServer || numFoldersLayoutsForView == 1 {
            changeLayout(withSubFolders: false)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("_propagate_layout_", comment: ""), message: nil, preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .default, handler: { _ in
                changeLayout(withSubFolders: true)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_no_", comment: ""), style: .default, handler: { _ in
                changeLayout(withSubFolders: false)
            }))

            self.present(alertController, animated: true)
        }
        self.collectionView.collectionViewLayout.invalidateLayout()

//        (self.navigationController as? NCMainNavigationController)?.setNavigationRightItems()
    }

    @objc func reloadDataSource(_ notification: NSNotification) {
        if let userInfo = notification.userInfo as? NSDictionary {
            if let serverUrl = userInfo["serverUrl"] as? String {
                if serverUrl != self.serverUrl {
                    return
                }
            }

            if let clearDataSource = userInfo["clearDataSource"] as? Bool, clearDataSource {
                self.dataSource.removeAll()
            }
        }

        reloadDataSource()
    }

    @objc func getServerData(_ notification: NSNotification) {
        if let userInfo = notification.userInfo as NSDictionary?,
           let serverUrl = userInfo["serverUrl"] as? String {
            if serverUrl != self.serverUrl {
                return
            }
        }

        getServerData()
    }

    @objc func reloadHeader(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let account = userInfo["account"] as? String,
              account == session.account
        else { return }

        self.collectionView.reloadData()
    }

    @objc func changeStatusFolderE2EE(_ notification: NSNotification) {
        reloadDataSource()
    }

    @objc func closeRichWorkspaceWebView() {
        reloadDataSource()
    }

    @objc func deleteFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let error = userInfo["error"] as? NKError else { return }

        if error == .success {
            if isSearchingMode {
                return networkSearch()
            }

            if isRecommendationActived {
                Task.detached {
                    await NCNetworking.shared.createRecommendations(session: self.session)
                }
            }
        } else {
            NCContentPresenter().showError(error: error)
        }

        reloadDataSource()
    }

    @objc func copyMoveFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String,
              account == session.account else { return }

        if isSearchingMode {
            return networkSearch()
        }

        if isRecommendationActived {
            Task.detached {
                await NCNetworking.shared.createRecommendations(session: self.session)
            }
        }

        if serverUrl == self.serverUrl {
            reloadDataSource()
        }
    }

    @objc func renameFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let account = userInfo["account"] as? String,
              let serverUrl = userInfo["serverUrl"] as? String,
              let error = userInfo["error"] as? NKError,
              account == session.account
        else { return }

        if error == .success {
            if isSearchingMode {
                return networkSearch()
            }

            if isRecommendationActived {
                Task.detached {
                    await NCNetworking.shared.createRecommendations(session: self.session)
                }
            }
        }

        if serverUrl == self.serverUrl {
            if error != .success {
                NCContentPresenter().showError(error: error)
            }
            reloadDataSource()
        } else {
            collectionView.reloadData()
        }
    }

    @objc func createFolder(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let ocId = userInfo["ocId"] as? String,
              let account = userInfo["account"] as? String,
              account == session.account,
              let withPush = userInfo["withPush"] as? Bool,
              let metadata = database.getMetadataFromOcId(ocId)
        else { return }

        if isSearchingMode {
            return networkSearch()
        }

        if metadata.serverUrl + "/" + metadata.fileName == self.serverUrl {
            reloadDataSource()
        } else if withPush, metadata.serverUrl == self.serverUrl {
            reloadDataSource()
            if let sceneIdentifier = userInfo["sceneIdentifier"] as? String {
                if sceneIdentifier == controller?.sceneIdentifier {
                    pushMetadata(metadata)
                }
            } else {
                pushMetadata(metadata)
            }
        }
    }

    @objc func favoriteFile(_ notification: NSNotification) {
        if isSearchingMode {
            return networkSearch()
        }

        if self is NCFavorite {
            return reloadDataSource()
        }

        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              serverUrl == self.serverUrl
        else { return }

        reloadDataSource()
    }

    @objc func downloadStartFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func downloadedFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func downloadCancelFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func uploadStartFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let ocId = userInfo["ocId"] as? String,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String,
              !isSearchingMode,
              let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId)
        else { return }

        // Header view trasfer
        if metadata.isTransferInForeground {
            NCNetworking.shared.transferInForegorund = NCNetworking.TransferInForegorund(ocId: ocId, progress: 0)
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
        
        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func uploadedFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func uploadedLivePhoto(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func uploadCancelFile(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let serverUrl = userInfo["serverUrl"] as? String,
              let account = userInfo["account"] as? String
        else { return }

        if account == self.session.account, serverUrl == self.serverUrl {
            reloadDataSource()
        } else {
            collectionView?.reloadData()
        }
    }

    @objc func updateShare(_ notification: NSNotification) {
        if isSearchingMode {
            networkSearch()
        } else {
            self.dataSource.removeAll()
            getServerData()
        }
    }

    @objc func triggerProgressTask(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let progressNumber = userInfo["progress"] as? NSNumber,
              let totalBytes = userInfo["totalBytes"] as? Int64,
              let totalBytesExpected = userInfo["totalBytesExpected"] as? Int64,
              let ocId = userInfo["ocId"] as? String,
              let ocIdTransfer = userInfo["ocIdTransfer"] as? String,
              let session = userInfo["session"] as? String
        else { return }

        let chunk: Int = userInfo["chunk"] as? Int ?? 0
        let e2eEncrypted: Bool = userInfo["e2eEncrypted"] as? Bool ?? false

        let transfer = NCTransferProgress.shared.append(NCTransferProgress.Transfer(ocId: ocId, ocIdTransfer: ocIdTransfer, session: session, chunk: chunk, e2eEncrypted: e2eEncrypted, progressNumber: progressNumber, totalBytes: totalBytes, totalBytesExpected: totalBytesExpected))

        // HEADER
//        if self.headerMenuTransferView, transfer.session.contains("upload") {
//            self.sectionFirstHeader?.setViewTransfer(isHidden: false, progress: transfer.progressNumber.floatValue)
//            self.sectionFirstHeaderEmptyData?.setViewTransfer(isHidden: false, progress: transfer.progressNumber.floatValue)
//        }
        
        DispatchQueue.main.async {
            if self.headerMenuTransferView && (chunk > 0 || e2eEncrypted) {
                if NCNetworking.shared.transferInForegorund?.ocId == ocId {
                    NCNetworking.shared.transferInForegorund?.progress = progressNumber.floatValue
                } else {
                    NCNetworking.shared.transferInForegorund = NCNetworking.TransferInForegorund(ocId: ocId, progress: progressNumber.floatValue)
                    self.collectionView.reloadData()
                }
                self.headerMenu?.progressTransfer.progress = transfer.progressNumber.floatValue
            } else {
                guard let indexPath = self.dataSource.getIndexPathMetadata(ocId: ocId).indexPath,
                      let cell = self.collectionView?.cellForItem(at: indexPath),
                      let cell = cell as? NCCellProtocol else { return }
                if progressNumber.floatValue == 1 && !(cell is NCTransferCell) {
                    cell.fileProgressView?.isHidden = true
                    cell.fileProgressView?.progress = .zero
                    cell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCImageCache.images.buttonMore)
                    if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                        cell.writeInfoDateSize(date: metadata.date, size: metadata.size)
                    } else {
                        cell.fileInfoLabel?.text = ""
                        cell.fileSubinfoLabel?.text = ""
                    }
                } else {
                    cell.fileProgressView?.isHidden = false
                    cell.fileProgressView?.progress = progressNumber.floatValue
                    cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCImageCache.images.buttonStop)
                    let status = userInfo["status"] as? Int ?? NCGlobal.shared.metadataStatusNormal
                    if status == NCGlobal.shared.metadataStatusDownloading {
                        cell.fileInfoLabel?.text = self.utilityFileSystem.transformedSize(totalBytesExpected)
                        cell.fileSubinfoLabel?.text = self.infoLabelsSeparator + "↓ " + self.utilityFileSystem.transformedSize(totalBytes)
                    } else if status == NCGlobal.shared.metadataStatusUploading {
                        if totalBytes > 0 {
                            cell.fileInfoLabel?.text = self.utilityFileSystem.transformedSize(totalBytesExpected)
                            cell.fileSubinfoLabel?.text = self.infoLabelsSeparator + "↑ " + self.utilityFileSystem.transformedSize(totalBytes)
                        } else {
                            cell.fileInfoLabel?.text = self.utilityFileSystem.transformedSize(totalBytesExpected)
                            cell.fileSubinfoLabel?.text = self.infoLabelsSeparator + "↑ …"
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Layout

    func setNavigationLeftItems() {
        navigationItem.title = titleCurrentFolder
    }
    
    func getNavigationTitle() -> String {
        let tblAccount = self.database.getTableAccount(predicate: NSPredicate(format: "account == %@", session.account))
        if let tblAccount,
           !tblAccount.alias.isEmpty {
            return tblAccount.alias
        }
        return NCBrandOptions.shared.brand
    }

    func accountSettingsDidDismiss(tblAccount: tableAccount?, controller: NCMainTabBarController?) { }

    @MainActor
    func showLoadingTitle() {
        // Don't show spinner on iPad root folder
        if UIDevice.current.userInterfaceIdiom == .pad,
           (self.serverUrl == self.utilityFileSystem.getHomeServer(session: self.session)) || self.serverUrl.isEmpty {
            return
        }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        self.navigationItem.titleView = container
    }

    @MainActor
    func restoreDefaultTitle() {
        self.navigationItem.titleView = nil
        self.navigationItem.title = self.titleCurrentFolder
    }

    // MARK: - Empty

    func emptyDataSetView(_ view: NCEmptyView) {

        self.emptyDataSet?.setOffset(getHeaderHeight())
        if isSearchingMode {
            view.emptyImage.image = UIImage(named: "search")?.image(color: .gray, size: UIScreen.main.bounds.width)
            if self.dataSourceTask?.state == .running {
                view.emptyTitle.text = NSLocalizedString("_search_in_progress_", comment: "")
            } else {
                view.emptyTitle.text = NSLocalizedString("_search_no_record_found_", comment: "")
            }
            view.emptyDescription.text = NSLocalizedString("_search_instruction_", comment: "")
        } else if self.dataSourceTask?.state == .running {
            view.emptyImage.image = UIImage(named: "networkInProgress")?.image(color: .gray, size: UIScreen.main.bounds.width)
            view.emptyTitle.text = NSLocalizedString("_request_in_progress_", comment: "")
            view.emptyDescription.text = ""
        } else {
            if serverUrl.isEmpty {
                view.emptyImage.image = emptyImage
                view.emptyTitle.text = NSLocalizedString(emptyTitle, comment: "")
                view.emptyDescription.text = NSLocalizedString(emptyDescription, comment: "")
            } else {
                view.emptyImage.image = UIImage(named: "folder_nmcloud")
                view.emptyTitle.text = NSLocalizedString("_files_no_files_", comment: "")
                view.emptyDescription.text = NSLocalizedString("_no_file_pull_down_", comment: "")
            }
        }
    }
    
    // MARK: - SEARCH

    func searchController(enabled: Bool) {
        guard enableSearchBar else { return }
        searchController?.searchBar.isUserInteractionEnabled = enabled
        if enabled {
            searchController?.searchBar.alpha = 1
        } else {
            searchController?.searchBar.alpha = 0.3

        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        self.literalSearch = searchController.searchBar.text
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchingMode = true
        self.providers?.removeAll()
        self.dataSource.removeAll()
        Task {
            await self.reloadDataSource()
        }
        // TIP
        dismissTip()
        //
        mainNavigationController?.hiddenPlusButton(true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if isSearchingMode && self.literalSearch?.count ?? 0 >= 2 {
            networkSearch()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.networking.cancelUnifiedSearchFiles()

        self.isSearchingMode = false
        self.literalSearch = ""
        self.providers?.removeAll()
        self.dataSource.removeAll()
        Task {
            await self.reloadDataSource()
        }
        //
        mainNavigationController?.hiddenPlusButton(false)
    }

    // MARK: - TAP EVENT

    func tapMoreListItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, image: UIImage?, sender: Any) {
        tapMoreGridItem(with: ocId, ocIdTransfer: ocIdTransfer, namedButtonMore: namedButtonMore, image: image, sender: sender)
    }

    func tapMorePhotoItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, image: UIImage?, sender: Any) {
        tapMoreGridItem(with: ocId, ocIdTransfer: ocIdTransfer, namedButtonMore: namedButtonMore, image: image, sender: sender)
    }

    func tapShareListItem(with ocId: String, ocIdTransfer: String, sender: Any) {
        if isEditMode { return }
        guard let metadata = self.database.getMetadataFromOcId(ocId) else { return }
        NCDownloadAction.shared.openShare(viewController: self, metadata: metadata, page: .sharing)
        TealiumHelper.shared.trackEvent(title: "magentacloud-app.filebrowser.sharing", data: ["": ""])
        appDelegate.adjust.trackEvent(TriggerEvent(Sharing.rawValue))
        NCActionCenter.shared.openShare(viewController: self, metadata: metadata, page: .sharing)
    }

    func tapMoreGridItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, image: UIImage?, sender: Any) {
        if isEditMode { return }
        guard let metadata = self.database.getMetadataFromOcId(ocId) else { return }
//        toggleMenu(metadata: metadata, image: image)
        if namedButtonMore == NCGlobal.shared.buttonMoreMore || namedButtonMore == NCGlobal.shared.buttonMoreLock {
            toggleMenu(metadata: metadata, image: image)
        } else if namedButtonMore == NCGlobal.shared.buttonMoreStop {
            Task {
                await cancelSession(metadata: metadata)
            }
        }
    }

    func tapRichWorkspace(_ sender: Any) {
        if let navigationController = UIStoryboard(name: "NCViewerRichWorkspace", bundle: nil).instantiateInitialViewController() as? UINavigationController {
            if let viewerRichWorkspace = navigationController.topViewController as? NCViewerRichWorkspace {
                viewerRichWorkspace.richWorkspaceText = richWorkspaceText ?? ""
                viewerRichWorkspace.serverUrl = serverUrl
                viewerRichWorkspace.delegate = self

                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }

    func tapRecommendationsButtonMenu(with metadata: tableMetadata, image: UIImage?, sender: Any?) {
        toggleMenu(metadata: metadata, image: image, sender: sender)
    }

    func tapButtonSection(_ sender: Any, metadataForSection: NCMetadataForSection?) {
        unifiedSearchMore(metadataForSection: metadataForSection)
    }

    func tapRecommendations(with metadata: tableMetadata) {
        didSelectMetadata(metadata, withOcIds: false)
    }

    func tapButtonSwitch(_ sender: Any) {
        guard !isTransitioning else { return }
        isTransitioning = true

        guard let layoutForView = NCManageDatabase.shared.getLayoutForView(account: session.account, key: layoutKey, serverUrl: serverUrl) else { return }

        if layoutForView.layout == NCGlobal.shared.layoutGrid {
            layoutForView.layout = NCGlobal.shared.layoutList
        } else {
            layoutForView.layout = NCGlobal.shared.layoutGrid
        }
        self.layoutForView = NCManageDatabase.shared.setLayoutForView(layoutForView: layoutForView)
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.setCollectionViewLayout(layoutForView.layout == NCGlobal.shared.layoutList ? self.listLayout : self.gridLayout, animated: true) {_ in self.isTransitioning = false }
    }

    func tapButtonOrder(_ sender: Any) {
        
//        if let titleButtonHeader = NCKeychain().getTitleButtonHeader(account: session.account), !titleButtonHeader.isEmpty {
//            layoutForView?.titleButtonHeader = titleButtonHeader
//        }
//        NCManageDatabase.shared.setLayoutForView(layoutForView: layoutForView!)
        
        let sortMenu = NCSortMenu()
        sortMenu.toggleMenu(viewController: self, account: session.account, key: layoutKey, sortButton: sender as? UIButton, serverUrl: serverUrl)
    }

    func longPressPhotoItem(with ocId: String, ocIdTransfer: String, gestureRecognizer: UILongPressGestureRecognizer) { }
    
    func longPressListItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) { }
    
    func tapShareListItem(with objectId: String, indexPath: IndexPath, sender: Any) { }

    func longPressMoreListItem(with ocId: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) { }
    
    func longPressGridItem(with ocId: String, ocIdTransfer: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) { }
        
    func longPressMoreGridItem(with ocId: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) { }
    
    func tapButtonTransfer(_ sender: Any) { }
    
    func tapMorePhotoItem(with ocId: String, ocIdTransfer: String, image: UIImage?, sender: Any) { }
    
    @objc func longPressCollecationView(_ gestureRecognizer: UILongPressGestureRecognizer) {
        openMenuItems(with: nil, gestureRecognizer: gestureRecognizer)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return nil
        }, actionProvider: { _ in
            return nil
        })
    }

    func openMenuItems(with objectId: String?, gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }

        var listMenuItems: [UIMenuItem] = []
        let touchPoint = gestureRecognizer.location(in: collectionView)

        becomeFirstResponder()

        if !serverUrl.isEmpty {
            listMenuItems.append(UIMenuItem(title: NSLocalizedString("_paste_file_", comment: ""), action: #selector(pasteFilesMenu(_:))))
        }

        if !listMenuItems.isEmpty {
            UIMenuController.shared.menuItems = listMenuItems
            UIMenuController.shared.showMenu(from: collectionView, rect: CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0))
        }
    }

    // MARK: - Menu Item

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if #selector(pasteFilesMenu(_:)) == action {
            if !UIPasteboard.general.items.isEmpty, !(metadataFolder?.e2eEncrypted ?? false) {
                return true
            }
        } else if #selector(copyMenuFile(_:)) == action {
            return true
        } else if #selector(moveMenuFile(_:)) == action {
            return true
        }

        return false
    }

    @objc func pasteFilesMenu(_ sender: Any?) {
        Task {
            await NCDownloadAction.shared.pastePasteboard(serverUrl: serverUrl, account: session.account, controller: self.controller)
        }
    }

    // MARK: - DataSource

    @objc func reloadDataSource() async {
        
        // get auto upload folder
        autoUploadFileName = NCManageDatabase.shared.getAccountAutoUploadFileName()
        autoUploadDirectory = NCManageDatabase.shared.getAccountAutoUploadDirectory(urlBase: session.urlBase, userId: session.userId, account: session.account)

        // get layout for view
        layoutForView = NCManageDatabase.shared.getLayoutForView(account: session.account, key: layoutKey, serverUrl: serverUrl)
        // set GroupField for Grid
        if !isSearchingMode && layoutForView?.layout == NCGlobal.shared.layoutGrid {
            groupByField = "classFile"
        } else {
            groupByField = "name"
        }

        if isSearchingMode {
            isDirectoryEncrypted = false
        } else {
            isDirectoryEncrypted = NCUtilityFileSystem().isDirectoryE2EE(session: session, serverUrl: serverUrl)
            if isRecommendationActived {
                Task.detached {
                    await self.networking.createRecommendations(session: self.session, serverUrl: self.serverUrl, collectionView: self.collectionView)
                }
            }
        }

        UIView.transition(with: self.collectionView,
                          duration: 0.20,
                          options: .transitionCrossDissolve,
                          animations: { self.collectionView.reloadData() },
                          completion: nil)

            (self.navigationController as? NCMainNavigationController)?.updateRightMenu()
            self.refreshControl.endRefreshing()
            self.collectionView.reloadData()
            self.setNavigationRightItems()
        }
    }

    func getServerData(forced: Bool = false) async { }

    @objc func networkSearch() {
        guard !networkSearchInProgress else {
            return
        }
        guard !session.account.isEmpty,
              let literalSearch = literalSearch,
              !literalSearch.isEmpty else {
            return
        }
        let capabilities = NCNetworking.shared.capabilities[session.account] ?? NKCapabilities.Capabilities()

        self.networkSearchInProgress = true
        self.dataSource.removeAll()
        Task {
            await self.reloadDataSource()
        }

        if capabilities.serverVersionMajor >= global.nextcloudVersion20 {
            self.networking.unifiedSearchFiles(literal: literalSearch, account: session.account) { task in
                self.searchDataSourceTask = task
                Task {
                    await self.reloadDataSource()
                }
            } providers: { account, searchProviders in
                self.providers = searchProviders
                self.searchResults = []
                self.dataSource = NCCollectionViewDataSource(metadatas: [],
                                                             layoutForView: self.layoutForView,
                                                             providers: self.providers,
                                                             searchResults: self.searchResults,
                                                             account: account)
            } update: { _, _, searchResult, metadatas in
                guard let metadatas, !metadatas.isEmpty, self.isSearchingMode, let searchResult else { return }
                self.networking.unifiedSearchQueue.addOperation(NCCollectionViewUnifiedSearch(collectionViewCommon: self, metadatas: metadatas, searchResult: searchResult))
            } completion: { _, _ in
                Task {
                    await self.reloadDataSource()
                }
                self.networkSearchInProgress = false
            }
        } else {
            self.networking.searchFiles(literal: literalSearch, account: session.account) { task in
                self.searchDataSourceTask = task
                Task {
                    await self.reloadDataSource()
                }
            } completion: { metadatasSearch, error in
                Task {
                    guard let metadatasSearch,
                            error == .success,
                            self.isSearchingMode
                    else {
                        self.networkSearchInProgress = false
                        await self.reloadDataSource()
                        return
                    }
                    let ocId = metadatasSearch.map { $0.ocId }
                    let metadatas = await self.database.getMetadatasAsync(predicate: NSPredicate(format: "ocId IN %@", ocId),
                                                                          withLayout: self.layoutForView,
                                                                          withAccount: self.session.account)

                    self.dataSource = NCCollectionViewDataSource(metadatas: metadatas,
                                                                 layoutForView: self.layoutForView,
                                                                 providers: self.providers,
                                                                 searchResults: self.searchResults,
                                                                 account: self.session.account)
                    self.networkSearchInProgress = false
                    await self.reloadDataSource()
                }
            }
        }
    }

    func unifiedSearchMore(metadataForSection: NCMetadataForSection?) {
        guard let metadataForSection = metadataForSection, let lastSearchResult = metadataForSection.lastSearchResult, let cursor = lastSearchResult.cursor, let term = literalSearch else { return }

        metadataForSection.unifiedSearchInProgress = true
        self.collectionView?.reloadData()

        self.networking.unifiedSearchFilesProvider(id: lastSearchResult.id, term: term, limit: 5, cursor: cursor, account: session.account) { task in
            self.searchDataSourceTask = task
            Task {
                await self.reloadDataSource()
            }
        } completion: { _, searchResult, metadatas, error in
            if error != .success {
                NCContentPresenter().showError(error: error)
            }

            metadataForSection.unifiedSearchInProgress = false
            guard let searchResult = searchResult, let metadatas = metadatas else { return }
            self.dataSource.appendMetadatasToSection(metadatas, metadataForSection: metadataForSection, lastSearchResult: searchResult)

            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    // MARK: - Push metadata

    func pushMetadata(_ metadata: tableMetadata) {
        guard let navigationCollectionViewCommon = self.controller?.navigationCollectionViewCommon else {
            return
        }
        let serverUrlPush = utilityFileSystem.createServerUrl(serverUrl: metadata.serverUrl, fileName: metadata.fileName)

        // Set Last Opening Date
        Task {
            await database.setDirectoryLastOpeningDateAsync(ocId: metadata.ocId)
        }

        if let viewController = navigationCollectionViewCommon.first(where: { $0.navigationController == self.navigationController && $0.serverUrl == serverUrlPush})?.viewController, viewController.isViewLoaded {
            navigationController?.pushViewController(viewController, animated: true)
        } else {
            if let viewController: NCFiles = UIStoryboard(name: "NCFiles", bundle: nil).instantiateInitialViewController() as? NCFiles {
                viewController.serverUrl = serverUrlPush
                viewController.titlePreviusFolder = navigationItem.title
                viewController.titleCurrentFolder = metadata.fileNameView

                navigationCollectionViewCommon.append(NavigationCollectionViewCommon(serverUrl: serverUrlPush, navigationController: self.navigationController, viewController: viewController))

                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

    func pushViewController(viewController: UIViewController) {
        if pushed { return }

        pushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Header size

//    func getHeaderHeight(section: Int) -> (heightHeaderRichWorkspace: CGFloat,
//                                           heightHeaderRecommendations: CGFloat,
//                                           heightHeaderSection: CGFloat) {
//        var heightHeaderRichWorkspace: CGFloat = 0
//        var heightHeaderRecommendations: CGFloat = 0
//        var heightHeaderSection: CGFloat = 0
//
//        if showDescription,
//           !isSearchingMode,
//           let richWorkspaceText = self.richWorkspaceText,
//           !richWorkspaceText.trimmingCharacters(in: .whitespaces).isEmpty {
//            heightHeaderRichWorkspace = UIScreen.main.bounds.size.height / 6
//        }
//
//        if isRecommendationActived,
//           !isSearchingMode,
//           NCKeychain().showRecommendedFiles,
//           !self.database.getRecommendedFiles(account: self.session.account).isEmpty {
//            heightHeaderRecommendations = self.heightHeaderRecommendations
//            heightHeaderSection = self.heightHeaderSection
//        }
//
//        if isSearchingMode || layoutForView?.groupBy != "none" || self.dataSource.numberOfSections() > 1 {
//            if section == 0 {
//                return (heightHeaderRichWorkspace, heightHeaderRecommendations, self.heightHeaderSection)
//            } else {
//                return (0, 0, self.heightHeaderSection)
//            }
//        } else {
//            return (heightHeaderRichWorkspace, heightHeaderRecommendations, heightHeaderSection)
//        }
//    }
    
    func isHeaderMenuTransferViewEnabled() -> [tableMetadata]? {
        if headerMenuTransferView,
           NCNetworking.shared.isOnline,
           let results = database.getResultsMetadatas(predicate: NSPredicate(format: "status IN %@", [global.metadataStatusWaitUpload, global.metadataStatusUploading])),
           !results.isEmpty {
            return Array(results)
        }
        return nil
    }

    func sizeForHeaderInSection(section: Int) -> CGSize {
        var height: CGFloat = 0
        let isLandscape = view.bounds.width > view.bounds.height
        let isIphone = UIDevice.current.userInterfaceIdiom == .phone

        if self.dataSource.isEmpty() {
            height = utility.getHeightHeaderEmptyData(view: view, portraitOffset: emptyDataPortaitOffset, landscapeOffset: emptyDataLandscapeOffset, isHeaderMenuTransferViewEnabled: isHeaderMenuTransferViewEnabled() != nil)
        } else if isEditMode || (isLandscape && isIphone) {
            return CGSize.zero
        } else {
            let (heightHeaderRichWorkspace, heightHeaderRecommendations, heightHeaderSection) = getHeaderHeight(section: section)
            height = heightHeaderRichWorkspace + heightHeaderRecommendations + heightHeaderSection
        }

        return CGSize(width: collectionView.frame.width, height: height)
    }

    // MARK: - Footer size

    func sizeForFooterInSection(section: Int) -> CGSize {
        guard let controller else {
            return CGSize.zero
        }
        let sections = dataSource.numberOfSections()
        let bottomAreaInsets: CGFloat = controller.tabBar.safeAreaInsets.bottom == 0 ? 34 : 0
        let height = controller.tabBar.frame.height + bottomAreaInsets

        if isEditMode {
            return CGSize(width: collectionView.frame.width, height: 90 + height)
        }

        if isSearchingMode {
            return CGSize(width: collectionView.frame.width, height: 50)
        }

        if section == sections - 1 {
            return CGSize(width: collectionView.frame.width, height: height)
        } else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
}
