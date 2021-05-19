//
//  NCCollectionViewCommon.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/09/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
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
import NCCommunication

class NCCollectionViewCommon: UIViewController, UIGestureRecognizerDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, NCListCellDelegate, NCGridCellDelegate, NCSectionHeaderMenuDelegate, UIAdaptivePresentationControllerDelegate, NCEmptyDataSetDelegate, UIContextMenuInteractionDelegate  {
    
    @IBOutlet weak var collectionView: UICollectionView!

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    internal let refreshControl = UIRefreshControl()
    internal var searchController: UISearchController?
    internal var emptyDataSet: NCEmptyDataSet?
    
    internal var serverUrl: String = ""
    internal var isEncryptedFolder = false
    internal var isEditMode = false
    internal var selectOcId: [String] = []
    internal var metadatasSource: [tableMetadata] = []
    internal var metadataFolder: tableMetadata?
    internal var metadataTouch: tableMetadata?
    internal var dataSource = NCDataSource()
    internal var richWorkspaceText: String?
        
    internal var layout = ""
    internal var sort: String = ""
    internal var ascending: Bool = true
    internal var directoryOnTop: Bool = true
    internal var groupBy = ""
    internal var titleButton = ""
    internal var itemForLine = 0

    private var autoUploadFileName = ""
    private var autoUploadDirectory = ""
        
    internal var listLayout: NCListLayout!
    internal var gridLayout: NCGridLayout!
            
    private let headerHeight: CGFloat = 50
    private var headerRichWorkspaceHeight: CGFloat = 0
    private let footerHeight: CGFloat = 100
    
    private var timerInputSearch: Timer?
    internal var literalSearch: String?
    internal var isSearching: Bool = false
    
    internal var isReloadDataSourceNetworkInProgress: Bool = false
    
    var selectedIndexPath: IndexPath!
   
    
    // DECLARE
    internal var layoutKey = ""
    internal var titleCurrentFolder = ""
    internal var enableSearchBar: Bool = false
    internal var emptyImage: UIImage?
    internal var emptyTitle: String = ""
    internal var emptyDescription: String = ""
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.presentationController?.delegate = self
        
        if enableSearchBar {
            searchController = UISearchController(searchResultsController: nil)
            searchController?.searchResultsUpdater = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        // Cell
        collectionView.register(UINib.init(nibName: "NCListCell", bundle: nil), forCellWithReuseIdentifier: "listCell")
        collectionView.register(UINib.init(nibName: "NCGridCell", bundle: nil), forCellWithReuseIdentifier: "gridCell")
        collectionView.register(UINib.init(nibName: "NCTransferCell", bundle: nil), forCellWithReuseIdentifier: "transferCell")

        // Header
        collectionView.register(UINib.init(nibName: "NCSectionHeaderMenu", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeaderMenu")
        
        // Footer
        collectionView.register(UINib.init(nibName: "NCSectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "sectionFooter")
        
        collectionView.alwaysBounceVertical = true

        listLayout = NCListLayout()
        gridLayout = NCGridLayout()
        
        // Refresh Control
        collectionView.addSubview(refreshControl)
        refreshControl.tintColor = .gray
        refreshControl.addTarget(self, action: #selector(reloadDataSourceNetworkRefreshControl), for: .valueChanged)
        
        // Empty
        emptyDataSet = NCEmptyDataSet.init(view: collectionView, offset: 0, delegate: self)
        
        // Long Press on CollectionView
        let longPressedGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressCollecationView(_:)))
        longPressedGesture.minimumPressDuration = 0.5
        longPressedGesture.delegate = self
        longPressedGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressedGesture)
        
        // Notification
        
        NotificationCenter.default.addObserver(self, selector: #selector(initializeMain), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterInitializeMain), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataSource(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataSource), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataSourceNetworkForced(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataSourceNetworkForced), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeStatusFolderE2EE(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeStatusFolderE2EE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeRichWorkspaceWebView), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterCloseRichWorkspaceWebView), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(deleteFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDeleteFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterMoveFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(copyFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterCopyFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(renameFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterRenameFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(createFolder(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterCreateFolder), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(favoriteFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterFavoriteFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(downloadStartFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDownloadStartFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadedFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDownloadedFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCancelFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDownloadCancelFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadStartFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterUploadStartFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadedFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterUploadedFile), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadCancelFile(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterUploadCancelFile), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(triggerProgressTask(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterProgressTask), object:nil)

        changeTheming()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        appDelegate.activeViewController = self

        if serverUrl == "" {
            appDelegate.activeServerUrl = NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, account: appDelegate.account)
        } else {
            appDelegate.activeServerUrl = serverUrl
        }
        
        (layout, sort, ascending, groupBy, directoryOnTop, titleButton, itemForLine) = NCUtility.shared.getLayoutForView(key: layoutKey, serverUrl: serverUrl)
        gridLayout.itemForLine = CGFloat(itemForLine)
        
        if layout == NCGlobal.shared.layoutList {
            collectionView?.collectionViewLayout = listLayout
        } else {
            collectionView?.collectionViewLayout = gridLayout
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.setNavigationBarHidden(false, animated: true)
        setNavigationItem()
        
        reloadDataSource()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadDataSourceNetwork()
    }
        
    func presentationControllerDidDismiss( _ presentationController: UIPresentationController) {
        let viewController = presentationController.presentedViewController
        if viewController is NCViewerRichWorkspaceWebView {
            closeRichWorkspaceWebView()
        } else if viewController is UINavigationController {
            if (viewController as! UINavigationController).topViewController is NCFileViewInFolder {
                appDelegate.activeFileViewInFolder = nil
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setNavigationItem() {
        
        if isEditMode {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "navigationMore"), style: .plain, target: self, action:#selector(tapSelectMenu(sender:)))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .plain, target: self, action: #selector(tapSelect(sender:)))
            navigationItem.title = NSLocalizedString("_selected_", comment: "") + " : \(selectOcId.count)" + " / \(dataSource.metadatas.count)"
            
        } else {
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_select_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(tapSelect(sender:)))
            navigationItem.leftBarButtonItem = nil
            navigationItem.title = titleCurrentFolder
            
            // PROFILE BUTTON
            
            if layoutKey == NCGlobal.shared.layoutViewFiles {
            
                var image = NCUtility.shared.loadImage(named: "person.crop.circle")
                let fileNamePath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + appDelegate.user + ".png"
                if let userImage = UIImage(contentsOfFile: fileNamePath) {
                    image = userImage
                }
                
                image = NCUtility.shared.createAvatar(image: image, size: 30)
                
                let button = UIButton(type: .custom)
                button.setImage(image, for: .normal)
                
                if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, account: appDelegate.account) {
                 
                    let account = NCManageDatabase.shared.getAccountActive()
                    var title = "  "
                    if account?.alias == "" {
                        title = title + (account?.user ?? "")
                    } else {
                        title = title + (account?.alias ?? "")
                    }
                    
                    button.setTitle(title, for: .normal)
                    button.setTitleColor(.systemBlue, for: .normal)
                }
                
                button.semanticContentAttribute = .forceLeftToRight
                button.sizeToFit()
                button.addTarget(self, action: #selector(profileButtonTapped(sender:)), for: .touchUpInside)
                       
                navigationItem.setLeftBarButton(UIBarButtonItem(customView: button), animated: true)
                navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - NotificationCenter

    @objc func initializeMain() {
        
        if appDelegate.account == "" { return }
        
        if searchController?.isActive ?? false {
            searchController?.isActive = false
        }
        
        // set active serverUrl
        if self.view?.window != nil {
            if serverUrl == "" {
                appDelegate.activeServerUrl = NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, account: appDelegate.account)
            } else {
                appDelegate.activeServerUrl = serverUrl
            }
        }
        
        if self is NCFiles || self is NCFavorite || self is NCOffline {
            self.navigationController?.popToRootViewController(animated: false)
        }
        
        appDelegate.listFilesVC.removeAll()
        appDelegate.listFavoriteVC.removeAll()
        appDelegate.listOfflineVC.removeAll()
        selectOcId.removeAll()
        
        setNavigationItem()
    
        reloadDataSource()
    }
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.backgroundView
        collectionView.backgroundColor = NCBrandColor.shared.backgroundView
        collectionView.reloadData()
    }
    
    @objc func reloadDataSource(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        reloadDataSource()
    }
    
    @objc func reloadDataSourceNetworkForced(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        if let userInfo = notification.userInfo as NSDictionary? {
            if let serverUrl = userInfo["serverUrl"] as? String {
                if serverUrl == self.serverUrl {
                    reloadDataSourceNetwork(forced: true)
                }
            }
        } else {
            reloadDataSourceNetwork(forced: true)
        }
    }
    
    @objc func changeStatusFolderE2EE(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        reloadDataSource()
    }
    
    @objc func closeRichWorkspaceWebView() {
        if self.view?.window == nil { return }
        
        reloadDataSourceNetwork()
    }
    
    @objc func deleteFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let fileNameView = userInfo["fileNameView"] as? String, let onlyLocal = userInfo["onlyLocal"] as? Bool {
                if onlyLocal {
                    reloadDataSource()
                } else if fileNameView.lowercased() == NCGlobal.shared.fileNameRichWorkspace.lowercased() {
                    reloadDataSourceNetwork(forced: true)
                } else {
                    if let row = dataSource.deleteMetadata(ocId: ocId) {
                        let indexPath = IndexPath(row: row, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.deleteItems(at: [indexPath])
                        }, completion: { (_) in
                            self.collectionView?.reloadData()
                        })
                    }
                }
            }
        }
    }
   
    @objc func moveFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let serverUrlFrom = userInfo["serverUrlFrom"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                
                // DEL
                if serverUrlFrom == serverUrl && metadata.account == appDelegate.account {
                    if let row = dataSource.deleteMetadata(ocId: ocId) {
                        let indexPath = IndexPath(row: row, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.deleteItems(at: [indexPath])
                        }, completion: { (_) in
                            self.collectionView?.reloadData()
                        })
                    }
                    // ADD
                } else if metadata.serverUrl == serverUrl && metadata.account == appDelegate.account {
                    if let row = dataSource.addMetadata(metadata) {
                        let indexPath = IndexPath(row: row, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.insertItems(at: [indexPath])
                        }, completion: { (_) in
                            self.collectionView?.reloadData()
                        })
                    }
                }
            }
        }
    }
    
    @objc func copyFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let serverUrlTo = userInfo["serverUrlTo"] as? String {
                
                if serverUrlTo == self.serverUrl {
                    reloadDataSource()
                }
            }
        }
    }
    
    @objc func renameFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        reloadDataSource()
    }
    
    @objc func createFolder(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                
                if metadata.serverUrl == serverUrl && metadata.account == appDelegate.account {
                    if let row = dataSource.addMetadata(metadata) {
                        let indexPath = IndexPath(row: row, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.insertItems(at: [indexPath])
                        }, completion: { (_) in
                            self.collectionView?.reloadData()
                        })
                    }
                }
            }
        } else {
            reloadDataSourceNetwork()
        }
    }
    
    @objc func favoriteFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                
                if dataSource.getIndexMetadata(ocId: metadata.ocId) != nil {
                    reloadDataSource()
                }
            }
        }
    }
    
    @objc func downloadStartFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                if let row = dataSource.reloadMetadata(ocId: metadata.ocId) {
                    let indexPath = IndexPath(row: row, section: 0)
                    if indexPath.section < collectionView.numberOfSections && indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) {
                        collectionView?.reloadItems(at: [indexPath])
                    }
                }
            }
        }
    }
    
    @objc func downloadedFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let _ = userInfo["errorCode"] as? Int, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                if let row = dataSource.reloadMetadata(ocId: metadata.ocId) {
                    let indexPath = IndexPath(row: row, section: 0)
                    if indexPath.section < collectionView.numberOfSections && indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) {
                        collectionView?.reloadItems(at: [indexPath])
                    }
                }
            }
        }
    }
        
    @objc func downloadCancelFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                if let row = dataSource.reloadMetadata(ocId: metadata.ocId) {
                    let indexPath = IndexPath(row: row, section: 0)
                    if indexPath.section < collectionView.numberOfSections && indexPath.row < collectionView.numberOfItems(inSection: indexPath.section) {
                        collectionView?.reloadItems(at: [indexPath])
                    }
                }
            }
        }
    }
    
    @objc func uploadStartFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                if metadata.serverUrl == serverUrl && metadata.account == appDelegate.account {
                    dataSource.addMetadata(metadata)
                    self.collectionView?.reloadData()
                }
            }
        }
    }
        
    @objc func uploadedFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
        if let ocId = userInfo["ocId"] as? String, let ocIdTemp = userInfo["ocIdTemp"] as? String, let _ = userInfo["errorCode"] as? Int, let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                if metadata.serverUrl == serverUrl && metadata.account == appDelegate.account {
                    dataSource.reloadMetadata(ocId: metadata.ocId, ocIdTemp: ocIdTemp)
                    collectionView?.reloadData()
                }
            }
        }
    }
    
    @objc func uploadCancelFile(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String, let serverUrl = userInfo["serverUrl"] as? String, let account = userInfo["account"] as? String {
                
                if serverUrl == self.serverUrl && account == appDelegate.account {
                    if let row = dataSource.deleteMetadata(ocId: ocId) {
                        let indexPath = IndexPath(row: row, section: 0)
                        collectionView?.performBatchUpdates({
                            collectionView?.deleteItems(at: [indexPath])
                        }, completion: { (_) in
                            self.collectionView?.reloadData()
                        })
                    } else {
                        self.reloadDataSource()
                    }
                }
            }
        }
    }
        
    @objc func triggerProgressTask(_ notification: NSNotification) {
        if self.view?.window == nil { return }
        
        if let userInfo = notification.userInfo as NSDictionary? {
            if let ocId = userInfo["ocId"] as? String {
                
                let _ = userInfo["account"] as? String ?? ""
                let _ = userInfo["serverUrl"] as? String ?? ""
                let progressNumber = userInfo["progress"] as? NSNumber ?? 0
                let progress = progressNumber.floatValue
                let status = userInfo["status"] as? Int ?? NCGlobal.shared.metadataStatusNormal
                let totalBytes = userInfo["totalBytes"] as? Int64 ?? 0
                let totalBytesExpected = userInfo["totalBytesExpected"] as? Int64 ?? 0
                        
                let progressType = NCGlobal.progressType(progress: progress, totalBytes: totalBytes, totalBytesExpected: totalBytesExpected)
                appDelegate.listProgress[ocId] = progressType
                                
                if let index = dataSource.getIndexMetadata(ocId: ocId) {
                    if let cell = collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) {
                        if cell is NCListCell {
                            let cell = cell as! NCListCell
                            if progress > 0 {
                                cell.progressView?.isHidden = false
                                cell.progressView?.progress = progress
                                cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCBrandColor.cacheImages.buttonStop)
                                if status == NCGlobal.shared.metadataStatusInDownload {
                                    cell.labelInfo.text = CCUtility.transformedSize(totalBytesExpected) + " - ↓ " + CCUtility.transformedSize(totalBytes)
                                } else if status == NCGlobal.shared.metadataStatusInUpload {
                                    cell.labelInfo.text = CCUtility.transformedSize(totalBytesExpected) + " - ↑ " + CCUtility.transformedSize(totalBytes)
                                }
                            }
                        } else if cell is NCTransferCell {
                            let cell = cell as! NCTransferCell
                            if progress > 0 {
                                cell.progressView?.isHidden = false
                                cell.progressView?.progress = progress
                                cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCBrandColor.cacheImages.buttonStop)
                                if status == NCGlobal.shared.metadataStatusInDownload {
                                    cell.labelInfo.text = CCUtility.transformedSize(totalBytesExpected) + " - ↓ " + CCUtility.transformedSize(totalBytes)
                                } else if status == NCGlobal.shared.metadataStatusInUpload {
                                    cell.labelInfo.text = CCUtility.transformedSize(totalBytesExpected) + " - ↑ " + CCUtility.transformedSize(totalBytes)
                                }
                            }
                        } else if cell is NCGridCell {
                            let cell = cell as! NCGridCell
                            if progress > 0 {
                                cell.progressView.isHidden = false
                                cell.progressView.progress = progress
                                cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCBrandColor.cacheImages.buttonStop)
                            }
                        }
                    }
                }
            }
        }
    }
        
    // MARK: - Empty
    
    func emptyDataSetView(_ view: NCEmptyView) {
                
        if searchController?.isActive ?? false {
            view.emptyImage.image = UIImage.init(named: "search")?.image(color: .gray, size: UIScreen.main.bounds.width)
            if isReloadDataSourceNetworkInProgress {
                view.emptyTitle.text = NSLocalizedString("_search_in_progress_", comment: "")
            } else {
                view.emptyTitle.text = NSLocalizedString("_search_no_record_found_", comment: "")
            }
            view.emptyDescription.text = NSLocalizedString("_search_instruction_", comment: "")
        } else if isReloadDataSourceNetworkInProgress {
            view.emptyImage.image = UIImage.init(named: "networkInProgress")?.image(color: .gray, size: UIScreen.main.bounds.width)
            view.emptyTitle.text = NSLocalizedString("_request_in_progress_", comment: "")
            view.emptyDescription.text = ""
        } else {
            if serverUrl == "" {
                view.emptyImage.image = emptyImage
                view.emptyTitle.text = NSLocalizedString(emptyTitle, comment: "")
                view.emptyDescription.text = NSLocalizedString(emptyDescription, comment: "")
            } else {
                view.emptyImage.image = UIImage.init(named: "folder")?.image(color: NCBrandColor.shared.brandElement, size: UIScreen.main.bounds.width)
                view.emptyTitle.text = NSLocalizedString("_files_no_files_", comment: "")
                view.emptyDescription.text = NSLocalizedString("_no_file_pull_down_", comment: "")
            }
        }
    }
    
    // MARK: - SEARCH
    
    func updateSearchResults(for searchController: UISearchController) {

        timerInputSearch?.invalidate()
        timerInputSearch = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(reloadDataSourceNetwork), userInfo: nil, repeats: false)
        literalSearch = searchController.searchBar.text
        collectionView?.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        isSearching = true
        metadatasSource.removeAll()
        reloadDataSource()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        isSearching = false
        literalSearch = ""
        reloadDataSource()
    }
    
    // MARK: - TAP EVENT
    
    @objc func tapSelect(sender: Any) {
        
        isEditMode = !isEditMode
        
        selectOcId.removeAll()
        setNavigationItem()
        
        self.collectionView.reloadData()
    }
    
    @objc func profileButtonTapped(sender: Any) {
        
        let accounts = NCManageDatabase.shared.getAllAccountOrderAlias()
        if accounts.count > 0 {
            
            if let vcAccountRequest = UIStoryboard(name: "NCAccountRequest", bundle: nil).instantiateInitialViewController() as? NCAccountRequest {
               
                vcAccountRequest.accounts = accounts
                vcAccountRequest.enableTimerProgress = false
                vcAccountRequest.enableAddAccount = true
                vcAccountRequest.viewController = self
                vcAccountRequest.dismissDidEnterBackground = true

                let screenHeighMax = UIScreen.main.bounds.height - (UIScreen.main.bounds.height/5)
                let numberCell = accounts.count + 1
                let height = min(CGFloat(numberCell * Int(vcAccountRequest.heightCell) + 65), screenHeighMax)
                
                let popup = NCPopupViewController(contentController: vcAccountRequest, popupWidth: 300, popupHeight: height)
                
                UIApplication.shared.keyWindow?.rootViewController?.present(popup, animated: true)
            }
        }
    }
    
    func tapSwitchHeader(sender: Any) {
        
        if collectionView.collectionViewLayout == gridLayout {
            // list layout
            UIView.animate(withDuration: 0.0, animations: {
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(self.listLayout, animated: false, completion: { (_) in
                    self.collectionView.reloadData()
                })
            })
            layout = NCGlobal.shared.layoutList
            NCUtility.shared.setLayoutForView(key: layoutKey, serverUrl: serverUrl, layout: layout)
        } else {
            // grid layout
            UIView.animate(withDuration: 0.0, animations: {
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(self.gridLayout, animated: false, completion: { (_) in
                    self.collectionView.reloadData()
                })
            })
            layout = NCGlobal.shared.layoutGrid
            NCUtility.shared.setLayoutForView(key: layoutKey, serverUrl: serverUrl, layout: layout)
        }
    }
    
    func tapOrderHeader(sender: Any) {
        
        let sortMenu = NCSortMenu()
        sortMenu.toggleMenu(viewController: self, key: layoutKey, sortButton: sender as? UIButton, serverUrl: serverUrl)
    }
    
    @objc func tapSelectMenu(sender: Any) {
        
        guard let tabBarController = self.tabBarController else { return }
        toggleMenuSelect(viewController: tabBarController, selectOcId: selectOcId)
    }
    
    func tapMoreHeader(sender: Any) { }
    
    func tapMoreListItem(with objectId: String, namedButtonMore: String, image: UIImage?, sender: Any) {
        
        tapMoreGridItem(with: objectId, namedButtonMore: namedButtonMore, image: image, sender: sender)
    }
    
    func tapShareListItem(with objectId: String, sender: Any) {
        
        if isEditMode { return }
        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(objectId) else { return }
        
        NCFunctionCenter.shared.openShare(ViewController: self, metadata: metadata, indexPage: 2)
    }
        
    func tapMoreGridItem(with objectId: String, namedButtonMore: String, image: UIImage?, sender: Any) {
        
        if isEditMode { return }

        guard let metadata = NCManageDatabase.shared.getMetadataFromOcId(objectId) else { return }

        if namedButtonMore == NCGlobal.shared.buttonMoreMore {
            toggleMenu(viewController: self, metadata: metadata, image: image)
        } else if namedButtonMore == NCGlobal.shared.buttonMoreStop {
            NCNetworking.shared.cancelTransferMetadata(metadata) { }
        }
    }
    
    func tapRichWorkspace(sender: Any) {
        
        if let navigationController = UIStoryboard(name: "NCViewerRichWorkspace", bundle: nil).instantiateInitialViewController() as? UINavigationController {
            if let viewerRichWorkspace = navigationController.topViewController as? NCViewerRichWorkspace {
                viewerRichWorkspace.richWorkspaceText = richWorkspaceText ?? ""
                viewerRichWorkspace.serverUrl = serverUrl
                
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func longPressListItem(with objectId: String, gestureRecognizer: UILongPressGestureRecognizer) {
    }
    
    func longPressGridItem(with objectId: String, gestureRecognizer: UILongPressGestureRecognizer) {
    }
    
    func longPressMoreListItem(with objectId: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) {
    }
    
    func longPressMoreGridItem(with objectId: String, namedButtonMore: String, gestureRecognizer: UILongPressGestureRecognizer) {
    }
    
    @objc func longPressCollecationView(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        openMenuItems(with: nil, gestureRecognizer: gestureRecognizer)
        /*
        if #available(iOS 13.0, *) {
            
            let interaction = UIContextMenuInteraction(delegate: self)
            self.view.addInteraction(interaction)
        }
        */
    }
    
    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            
            return nil
            
        }, actionProvider: { suggestedActions in
            
            //let share = UIAction(title: "Share Pupper", image: UIImage(systemName: "square.and.arrow.up")) { action in
            //}
            //return UIMenu(title: "Main Menu", children: [share])
            return nil
        })
    }
    
    func openMenuItems(with objectId: String?, gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state != .began { return }
        if serverUrl == "" { return }
        
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(objectId) {
            metadataTouch = metadata
        } else {
            metadataTouch = nil
        }
        
        var listMenuItems: [UIMenuItem] = []
        let touchPoint = gestureRecognizer.location(in: collectionView)
        
        becomeFirstResponder()
                
        listMenuItems.append(UIMenuItem.init(title: NSLocalizedString("_paste_file_", comment: ""), action: #selector(pasteFilesMenu)))
        
        if listMenuItems.count > 0 {
            UIMenuController.shared.menuItems = listMenuItems
            UIMenuController.shared.setTargetRect(CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0), in: collectionView)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    // MARK: - Menu Item
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if (#selector(pasteFilesMenu) == action) {
            if UIPasteboard.general.items.count > 0 {
                return true
            }
        }
        
        return false
    }
    
    @objc func pasteFilesMenu() {
        NCFunctionCenter.shared.pastePasteboard(serverUrl: serverUrl)
    }
    
    // MARK: - DataSource + NC Endpoint
    
    @objc func reloadDataSource() {
        
        if appDelegate.account == "" { return }
        
        // Get richWorkspace Text
        let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, serverUrl))
        richWorkspaceText = directory?.richWorkspace
        
        // E2EE
        isEncryptedFolder = CCUtility.isFolderEncrypted(serverUrl, e2eEncrypted: metadataFolder?.e2eEncrypted ?? false, account: appDelegate.account, urlBase: appDelegate.urlBase)

        // get auto upload folder
        autoUploadFileName = NCManageDatabase.shared.getAccountAutoUploadFileName()
        autoUploadDirectory = NCManageDatabase.shared.getAccountAutoUploadDirectory(urlBase: appDelegate.urlBase, account: appDelegate.account)
        
        // get layout for view
        (layout, sort, ascending, groupBy, directoryOnTop, titleButton, itemForLine) = NCUtility.shared.getLayoutForView(key: layoutKey, serverUrl: serverUrl)
    }
    @objc func reloadDataSourceNetwork(forced: Bool = false) { }
    @objc func reloadDataSourceNetworkRefreshControl() {
        reloadDataSourceNetwork(forced: true)
    }
    @objc func networkSearch() {
        
        if appDelegate.account == "" { return }
        
        if literalSearch?.count ?? 0 > 1 {
        
            isReloadDataSourceNetworkInProgress = true
            collectionView?.reloadData()
            
            NCNetworking.shared.searchFiles(urlBase: appDelegate.urlBase, user: appDelegate.user, literal: literalSearch!) { (account, metadatas, errorCode, errorDescription) in
                if self.searchController?.isActive ?? false && errorCode == 0 {
                    self.metadatasSource = metadatas!
                }
                
                self.refreshControl.endRefreshing()
                self.isReloadDataSourceNetworkInProgress = false
                self.reloadDataSource()
            }
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func networkReadFolder(forced: Bool, completion: @escaping(_ metadatas: [tableMetadata]?, _ metadatasUpdate: [tableMetadata]?, _ errorCode: Int, _ errorDescription: String)->()) {
        
        NCNetworking.shared.readFile(serverUrlFileName: serverUrl, account: appDelegate.account) { (account, metadata, errorCode, errorDescription) in
            
            if errorCode == 0 {
                
                let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", self.appDelegate.account, self.serverUrl))
                
                if forced || directory?.etag != metadata?.etag || directory?.e2eEncrypted ?? false {
                    
                    NCNetworking.shared.readFolder(serverUrl: self.serverUrl, account: self.appDelegate.account) { (account, metadataFolder, metadatas, metadatasUpdate, metadatasLocalUpdate, errorCode, errorDescription) in
                        
                        if errorCode == 0 {
                            self.metadataFolder = metadataFolder
                            
                            // E2EE
                            if let metadataFolder = metadataFolder {
                                if metadataFolder.e2eEncrypted && CCUtility.isEnd(toEndEnabled: self.appDelegate.account) {
                                    
                                    NCCommunication.shared.getE2EEMetadata(fileId: metadataFolder.ocId, e2eToken: nil) { (account, e2eMetadata, errorCode, errorDescription) in
                                        if errorCode == 0 && e2eMetadata != nil {
                                            
                                            if !NCEndToEndMetadata.shared.decoderMetadata(e2eMetadata!, privateKey: CCUtility.getEndToEndPrivateKey(account), serverUrl: self.serverUrl, account: account, urlBase: self.appDelegate.urlBase) {
                                                
                                                NCContentPresenter.shared.messageNotification("_error_e2ee_", description: "_e2e_error_decode_metadata_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: NCGlobal.shared.ErrorDecodeMetadata, forced: true)
                                            } else {
                                                self.reloadDataSource()
                                            }
                                            
                                        } else if errorCode != NCGlobal.shared.ErrorResourceNotFound {
                                            
                                            NCContentPresenter.shared.messageNotification("_error_e2ee_", description: "_e2e_error_decode_metadata_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: NCGlobal.shared.ErrorDecodeMetadata, forced: true)
                                        }
                                        
                                        completion(metadatas, metadatasUpdate, errorCode, errorDescription)
                                    }
                                } else {
                                    completion(metadatas, metadatasUpdate, errorCode, errorDescription)
                                }
                            } else {
                                completion(metadatas, metadatasUpdate, errorCode, errorDescription)
                            }
                        } else {
                            completion(nil, nil, errorCode, errorDescription)
                        }
                    }
                } else {
                    completion(nil, nil, 0, "")
                }
            } else {
               completion(nil, nil, errorCode, errorDescription)
            }
        }
    }
}

// MARK: - Collection View

extension NCCollectionViewCommon: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else { return }
        metadataTouch = metadata
        selectedIndexPath = indexPath
        
        if isEditMode {
            if let index = selectOcId.firstIndex(of: metadata.ocId) {
                selectOcId.remove(at: index)
            } else {
                selectOcId.append(metadata.ocId)
            }
            collectionView.reloadItems(at: [indexPath])
            self.navigationItem.title = NSLocalizedString("_selected_", comment: "") + " : \(selectOcId.count)" + " / \(dataSource.metadatas.count)"
            return
        }
        
        if metadata.e2eEncrypted && !CCUtility.isEnd(toEndEnabled: appDelegate.account) {
            NCContentPresenter.shared.messageNotification("_info_", description: "_e2e_goto_settings_for_enable_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.ErrorE2EENotEnabled, forced: true)
            return
        }
        
        if metadata.directory {
            
            guard let serverUrlPush = CCUtility.stringAppendServerUrl(metadataTouch!.serverUrl, addFileName: metadataTouch!.fileName) else { return }
            
            // FILES
            if layoutKey == NCGlobal.shared.layoutViewFiles {
                
                if let viewController = appDelegate.listFilesVC[serverUrlPush] {
                    
                    if viewController.isViewLoaded {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                    
                } else {
                    
                    let vcFiles:NCFiles = UIStoryboard(name: "NCFiles", bundle: nil).instantiateInitialViewController() as! NCFiles
                    
                    vcFiles.isRoot = false
                    vcFiles.serverUrl = serverUrlPush
                    vcFiles.titleCurrentFolder = metadataTouch!.fileNameView
                    
                    appDelegate.listFilesVC[serverUrlPush] = vcFiles
                                        
                    self.navigationController?.pushViewController(vcFiles, animated: true)
                }
            }
            
            // FAVORITE
            if layoutKey == NCGlobal.shared.layoutViewFavorite {
            
                if let viewController = appDelegate.listFavoriteVC[serverUrlPush] {
                    
                    if viewController.isViewLoaded {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }

                } else {
                                        
                    let vcFavorite:NCFavorite = UIStoryboard(name: "NCFavorite", bundle: nil).instantiateInitialViewController() as! NCFavorite
                
                    vcFavorite.serverUrl = serverUrlPush
                    vcFavorite.titleCurrentFolder = metadataTouch!.fileNameView
                
                    appDelegate.listFavoriteVC[serverUrlPush] = vcFavorite
                    
                    self.navigationController?.pushViewController(vcFavorite, animated: true)
                }
            }
            
            // OFFLINE
            if layoutKey == NCGlobal.shared.layoutViewOffline {
                
                if let viewController = appDelegate.listOfflineVC[serverUrlPush] {
                    
                    if viewController.isViewLoaded {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                    
                } else {
                    
                    let vcOffline:NCOffline = UIStoryboard(name: "NCOffline", bundle: nil).instantiateInitialViewController() as! NCOffline
                    
                    vcOffline.serverUrl = serverUrlPush
                    vcOffline.titleCurrentFolder = metadataTouch!.fileNameView
                    
                    appDelegate.listOfflineVC[serverUrlPush] = vcOffline
                    
                    self.navigationController?.pushViewController(vcOffline, animated: true)
                }
            }
            
            // RECENT ( for push use Files ... he he he )
            if layoutKey == NCGlobal.shared.layoutViewRecent {
                
                if let viewController = appDelegate.listFilesVC[serverUrlPush] {
                    
                    if viewController.isViewLoaded {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                    
                } else {
                    
                    let vcFiles:NCFiles = UIStoryboard(name: "NCFiles", bundle: nil).instantiateInitialViewController() as! NCFiles
                    
                    vcFiles.isRoot = false
                    vcFiles.serverUrl = serverUrlPush
                    vcFiles.titleCurrentFolder = metadataTouch!.fileNameView
                    
                    appDelegate.listFilesVC[serverUrlPush] = vcFiles
                    
                    self.navigationController?.pushViewController(vcFiles, animated: true)
                }
            }
            
            //VIEW IN FOLDER
            if layoutKey == NCGlobal.shared.layoutViewViewInFolder {
                
                let vcFileViewInFolder:NCFileViewInFolder = UIStoryboard(name: "NCFileViewInFolder", bundle: nil).instantiateInitialViewController() as! NCFileViewInFolder
                
                vcFileViewInFolder.serverUrl = serverUrlPush
                vcFileViewInFolder.titleCurrentFolder = metadataTouch!.fileNameView
                                
                self.navigationController?.pushViewController(vcFileViewInFolder, animated: true)
            }
            
            // SHARES ( for push use Files ... he he he )
            if layoutKey == NCGlobal.shared.layoutViewShares {
                
                if let viewController = appDelegate.listFilesVC[serverUrlPush] {
                    
                    if viewController.isViewLoaded {
                        self.navigationController?.pushViewController(viewController, animated: true)
                    }
                    
                } else {
                    
                    let vcFiles:NCFiles = UIStoryboard(name: "NCFiles", bundle: nil).instantiateInitialViewController() as! NCFiles
                    
                    vcFiles.isRoot = false
                    vcFiles.serverUrl = serverUrlPush
                    vcFiles.titleCurrentFolder = metadataTouch!.fileNameView
                    
                    appDelegate.listFilesVC[serverUrlPush] = vcFiles
                    
                    self.navigationController?.pushViewController(vcFiles, animated: true)
                }
            }
            
        } else {
            
            guard let metadataTouch = metadataTouch else { return }
            
            if metadata.typeFile == NCGlobal.shared.metadataTypeFileImage || metadata.typeFile == NCGlobal.shared.metadataTypeFileVideo || metadata.typeFile == NCGlobal.shared.metadataTypeFileAudio {
                var metadatas: [tableMetadata] = []
                for metadata in dataSource.metadatas {
                    if metadata.typeFile == NCGlobal.shared.metadataTypeFileImage || metadata.typeFile == NCGlobal.shared.metadataTypeFileVideo || metadata.typeFile == NCGlobal.shared.metadataTypeFileAudio {
                        metadatas.append(metadata)
                    }
                }
                NCViewer.shared.view(viewController: self, metadata: metadataTouch, metadatas: metadatas)
                return
            }
            
            if CCUtility.fileProviderStorageExists(metadataTouch.ocId, fileNameView: metadataTouch.fileNameView) {
                NCViewer.shared.view(viewController: self, metadata: metadataTouch, metadatas: [metadataTouch])
            } else if NCCommunication.shared.isNetworkReachable() {
                NCNetworking.shared.download(metadata: metadataTouch, activityIndicator: false, selector: NCGlobal.shared.selectorLoadFileView) { (_) in }
            } else {
                NCContentPresenter.shared.messageNotification("_info_", description: "_go_online_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.ErrorOffline, forced: true)
            }
        }
    }
    
    func collectionViewSelectAll() {
        selectOcId.removeAll()
        for metadata in metadatasSource {
            selectOcId.append(metadata.ocId)
        }
        collectionView.reloadData()
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else { return nil }
        metadataTouch = metadata
        let identifier = indexPath as NSCopying

        return UIContextMenuConfiguration(identifier: identifier, previewProvider: {
            
            return NCViewerProviderContextMenu(metadata: metadata)
            
        }, actionProvider: { suggestedActions in
            
            return NCFunctionCenter.shared.contextMenuConfiguration(metadata: metadata, viewController: self, enableDeleteLocal: true, enableViewInFolder: false)
        })
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {

            if let indexPath = configuration.identifier as? IndexPath {
                self.collectionView(collectionView, didSelectItemAt: indexPath)
            }
        }
    }
}

extension NCCollectionViewCommon: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else { return }
        NCOperationQueue.shared.downloadThumbnail(metadata: metadata, urlBase: appDelegate.urlBase, view: collectionView, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else { return }        
        NCOperationQueue.shared.cancelDownloadThumbnail(metadata: metadata)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
                        
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderMenu", for: indexPath) as! NCSectionHeaderMenu
            
            if collectionView.collectionViewLayout == gridLayout {
                header.buttonSwitch.setImage(UIImage.init(named: "switchList")!.image(color: NCBrandColor.shared.icon, size: 50), for: .normal)
            } else {
                header.buttonSwitch.setImage(UIImage.init(named: "switchGrid")!.image(color: NCBrandColor.shared.icon, size: 50), for: .normal)
            }
            
            header.delegate = self
            header.setStatusButton(count: dataSource.metadatas.count)
            header.setTitleSorted(datasourceTitleButton: titleButton)
            header.viewRichWorkspaceHeightConstraint.constant = headerRichWorkspaceHeight
            header.setRichWorkspaceText(richWorkspaceText: richWorkspaceText)

            return header
            
        } else {
            
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath) as! NCSectionFooter
            
            let info = dataSource.getFilesInformation()
            footer.setTitleLabel(directories: info.directories, files: info.files, size: info.size )
            
            return footer
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberItems = dataSource.numberOfItems()
        emptyDataSet?.numberOfItemsInSection(numberItems, section: section)
        return numberItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else {
            if layout == NCGlobal.shared.layoutList {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! NCListCell
            } else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! NCGridCell
            }
        }
        
        var tableShare: tableShare?
        var isShare = false
        var isMounted = false
                
        if metadataFolder != nil {
            isShare = metadata.permissions.contains(NCGlobal.shared.permissionShared) && !metadataFolder!.permissions.contains(NCGlobal.shared.permissionShared)
            isMounted = metadata.permissions.contains(NCGlobal.shared.permissionMounted) && !metadataFolder!.permissions.contains(NCGlobal.shared.permissionMounted)
        }
        
        if dataSource.metadataShare[metadata.ocId] != nil {
            tableShare = dataSource.metadataShare[metadata.ocId]
        }
        
        //
        // LAYOUT LIST
        //
        if layout == NCGlobal.shared.layoutList {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! NCListCell
            cell.delegate = self
            
            cell.objectId = metadata.ocId
            cell.indexPath = indexPath
            cell.labelTitle.text = metadata.fileNameView
            cell.labelTitle.textColor = NCBrandColor.shared.textView
            cell.separator.backgroundColor = NCBrandColor.shared.separator
            
            cell.imageSelect.image = nil
            cell.imageStatus.image = nil
            cell.imageLocal.image = nil
            cell.imageFavorite.image = nil
            cell.imageShared.image = nil
            cell.imageMore.image = nil
            
            cell.imageItem.image = nil
            cell.imageItem.backgroundColor = nil
            
            cell.progressView.progress = 0.0
            
            if metadata.directory {
                
                if metadata.e2eEncrypted {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderEncrypted
                } else if isShare {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderSharedWithMe
                } else if (tableShare != nil && tableShare?.shareType != 3) {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderSharedWithMe
                } else if (tableShare != nil && tableShare?.shareType == 3) {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderPublic
                } else if metadata.mountType == "group" {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderGroup
                } else if isMounted {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderExternal
                } else if metadata.fileName == autoUploadFileName && metadata.serverUrl == autoUploadDirectory {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderAutomaticUpload
                } else {
                    cell.imageItem.image = NCBrandColor.cacheImages.folder
                }
                
                cell.labelInfo.text = CCUtility.dateDiff(metadata.date as Date)
                
                let lockServerUrl = CCUtility.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName)!
                let tableDirectory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, lockServerUrl))
                
                // Local image: offline
                if tableDirectory != nil && tableDirectory!.offline {
                    cell.imageLocal.image = NCBrandColor.cacheImages.offlineFlag
                }
                
            } else {
                
                if FileManager().fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag)) {
                    cell.imageItem.image =  UIImage(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag))
                } else {
                    if metadata.hasPreview {
                        cell.imageItem.backgroundColor = .lightGray
                    } else {
                        if metadata.iconName.count > 0 {
                            cell.imageItem.image = UIImage.init(named: metadata.iconName)
                        } else {
                            cell.imageItem.image = NCBrandColor.cacheImages.file
                        }
                    }
                }
                
                cell.labelInfo.text = CCUtility.dateDiff(metadata.date as Date) + " · " + CCUtility.transformedSize(metadata.size)
                                
                // image local
                if dataSource.metadataOffLine.contains(metadata.ocId) {
                    cell.imageLocal.image = NCBrandColor.cacheImages.offlineFlag
                } else if CCUtility.fileProviderStorageExists(metadata.ocId, fileNameView: metadata.fileNameView) {
                    cell.imageLocal.image = NCBrandColor.cacheImages.local
                }
            }
            
            // image Favorite
            if metadata.favorite {
                cell.imageFavorite.image = NCBrandColor.cacheImages.favorite
            }
            
            // Share image
            if (isShare) {
                cell.imageShared.image = NCBrandColor.cacheImages.shared
            } else if (tableShare != nil && tableShare?.shareType == 3) {
                cell.imageShared.image = NCBrandColor.cacheImages.shareByLink
            } else if (tableShare != nil && tableShare?.shareType != 3) {
                cell.imageShared.image = NCBrandColor.cacheImages.shared
            } else {
                cell.imageShared.image = NCBrandColor.cacheImages.canShare
            }
            if metadata.ownerId.count > 0 && metadata.ownerId != appDelegate.userId {
                cell.imageShared.image = UIImage(named: "avatar")
                let fileNameUser = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + metadata.ownerId + ".png"
                if FileManager.default.fileExists(atPath: fileNameUser) {
                    if let image = UIImage(contentsOfFile: fileNameUser) {
                        cell.imageShared.image = NCUtility.shared.createAvatar(image: image, size: 30)
                    }
                } else {
                    NCCommunication.shared.downloadAvatar(userId: metadata.ownerId, fileNameLocalPath: fileNameUser, size: NCGlobal.shared.avatarSize) { (account, data, errorCode, errorMessage) in
                        if errorCode == 0 && account == self.appDelegate.account {
                            if let image = UIImage(contentsOfFile: fileNameUser) {
                                cell.imageShared.image = NCUtility.shared.createAvatar(image: image, size: 30)
                            }
                        }
                    }
                }
            }
            
            // Transfer
            var progress: Float = 0.0
            var totalBytes: Int64 = 0
            if let progressType = appDelegate.listProgress[metadata.ocId] {
                progress = progressType.progress
                totalBytes = progressType.totalBytes
            }
            if metadata.status == NCGlobal.shared.metadataStatusInDownload || metadata.status == NCGlobal.shared.metadataStatusDownloading ||  metadata.status >= NCGlobal.shared.metadataStatusTypeUpload {
                cell.progressView.isHidden = false
                cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCBrandColor.cacheImages.buttonStop)
            } else {
                cell.progressView.isHidden = true
                cell.progressView.progress = progress
                cell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCBrandColor.cacheImages.buttonMore)
            }
            // Write status on Label Info
            switch metadata.status {
            case NCGlobal.shared.metadataStatusWaitDownload:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - " + NSLocalizedString("_status_wait_download_", comment: "")
                break
            case NCGlobal.shared.metadataStatusInDownload:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - " + NSLocalizedString("_status_in_download_", comment: "")
                break
            case NCGlobal.shared.metadataStatusDownloading:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - ↓ " + CCUtility.transformedSize(totalBytes)
                break
            case NCGlobal.shared.metadataStatusWaitUpload:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - " + NSLocalizedString("_status_wait_upload_", comment: "")
                break
            case NCGlobal.shared.metadataStatusInUpload:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - " + NSLocalizedString("_status_in_upload_", comment: "")
                break
            case NCGlobal.shared.metadataStatusUploading:
                cell.labelInfo.text = CCUtility.transformedSize(metadata.size) + " - ↑ " + CCUtility.transformedSize(totalBytes)
                break
            default:
                break
            }
            
            // Live Photo
            if metadata.livePhoto {
                cell.imageStatus.image = NCBrandColor.cacheImages.livePhoto
            }
            
            // E2EE
            if metadata.e2eEncrypted || isEncryptedFolder {
                cell.hideButtonShare(true)
            } else {
                cell.hideButtonShare(false)
            }
            
            // Remove last separator
            if collectionView.numberOfItems(inSection: indexPath.section) == indexPath.row + 1 {
                cell.separator.isHidden = true
            } else {
                cell.separator.isHidden = false
            }
            
            // Edit mode
            if isEditMode {
                cell.selectMode(true)
                if selectOcId.contains(metadata.ocId) {
                    cell.selected(true)
                } else {
                    cell.selected(false)
                }
            } else {
                cell.selectMode(false)
            }
            
            // Disable Share Button
            if appDelegate.disableSharesView {
                cell.hideButtonShare(true)
            }
            
            return cell
        }
        
        //
        // LAYOUT GRID
        //
        if layout == NCGlobal.shared.layoutGrid {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! NCGridCell
            cell.delegate = self
            
            cell.objectId = metadata.ocId
            cell.indexPath = indexPath
            cell.labelTitle.text = metadata.fileNameView
            cell.labelTitle.textColor = NCBrandColor.shared.textView
            
            cell.imageSelect.image = nil
            cell.imageStatus.image = nil
            cell.imageLocal.image = nil
            cell.imageFavorite.image = nil
            
            cell.imageItem.image = nil
            cell.imageItem.backgroundColor = nil
            
            cell.progressView.progress = 0.0

            if metadata.directory {
                
                if metadata.e2eEncrypted {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderEncrypted
                } else if isShare {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderSharedWithMe
                } else if (tableShare != nil && tableShare!.shareType != 3) {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderSharedWithMe
                } else if (tableShare != nil && tableShare!.shareType == 3) {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderPublic
                } else if metadata.mountType == "group" {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderGroup
                } else if isMounted {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderExternal
                } else if metadata.fileName == autoUploadFileName && metadata.serverUrl == autoUploadDirectory {
                    cell.imageItem.image = NCBrandColor.cacheImages.folderAutomaticUpload
                } else {
                    cell.imageItem.image = NCBrandColor.cacheImages.folder
                }
    
                let lockServerUrl = CCUtility.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName)!
                let tableDirectory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, lockServerUrl))
                                
                // Local image: offline
                if tableDirectory != nil && tableDirectory!.offline {
                    cell.imageLocal.image = NCBrandColor.cacheImages.offlineFlag
                }
                
            } else {
                
                if FileManager().fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag)) {
                    cell.imageItem.image =  UIImage(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag))
                } else {
                    if metadata.hasPreview {
                        cell.imageItem.backgroundColor = .lightGray
                    } else {
                        if metadata.iconName.count > 0 {
                            cell.imageItem.image = UIImage.init(named: metadata.iconName)
                        } else {
                            cell.imageItem.image = NCBrandColor.cacheImages.file
                        }
                    }
                }
                
                // image Local
                if dataSource.metadataOffLine.contains(metadata.ocId) {
                    cell.imageLocal.image = NCBrandColor.cacheImages.offlineFlag
                } else if CCUtility.fileProviderStorageExists(metadata.ocId, fileNameView: metadata.fileNameView) {
                    cell.imageLocal.image = NCBrandColor.cacheImages.local
                }
            }
            
            // image Favorite
            if metadata.favorite {
                cell.imageFavorite.image = NCBrandColor.cacheImages.favorite
            }
            
            // Transfer
            if metadata.status == NCGlobal.shared.metadataStatusInDownload || metadata.status == NCGlobal.shared.metadataStatusDownloading ||  metadata.status >= NCGlobal.shared.metadataStatusTypeUpload {
                cell.progressView.isHidden = false
                cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCBrandColor.cacheImages.buttonStop)
            } else {
                cell.progressView.isHidden = true
                cell.progressView.progress = 0.0
                cell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCBrandColor.cacheImages.buttonMore)
            }
            
            // Live Photo
            if metadata.livePhoto {
                cell.imageStatus.image = NCBrandColor.cacheImages.livePhoto
            }
            
            // Edit mode
            if isEditMode {
                cell.selectMode(true)
                if selectOcId.contains(metadata.ocId) {
                    cell.selected(true)
                } else {
                    cell.selected(false)
                }
            } else {
                cell.selectMode(false)
            }
            
            return cell
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! NCGridCell
    }
}

extension NCCollectionViewCommon: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        headerRichWorkspaceHeight = 0
        
        if let richWorkspaceText = richWorkspaceText {
            let trimmed = richWorkspaceText.trimmingCharacters(in: .whitespaces)
            if trimmed.count > 0 && !isSearching {
                headerRichWorkspaceHeight = UIScreen.main.bounds.size.height / 4
            }
        } 
        
        return CGSize(width: collectionView.frame.width, height: headerHeight + headerRichWorkspaceHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: footerHeight)
    }
}
