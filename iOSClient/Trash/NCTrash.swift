//
//  NCTrash.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 02/10/2018.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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

import UIKit
import NextcloudKit
import RealmSwift

class NCTrash: UIViewController, NCTrashListCellDelegate, NCTrashGridCellDelegate, NCSectionHeaderMenuDelegate {
class NCTrash: UIViewController, NCTrashListCellDelegate, NCTrashGridCellDelegate, NCSectionHeaderMenuDelegate, NCEmptyDataSetDelegate {
    @IBOutlet weak var collectionView: UICollectionView!

    var filePath = ""
    var titleCurrentFolder = NSLocalizedString("_trash_view_", comment: "")
    var blinkFileId: String?
    var dataSourceTask: URLSessionTask?
    let utilityFileSystem = NCUtilityFileSystem()
    let database = NCManageDatabase.shared
    let utility = NCUtility()
    var isEditMode = false
    var fileSelect: [String] = []
    var tabBarSelect: NCTrashSelectTabBar!
    var datasource: [tableTrash] = []
    var layoutForView: NCDBLayoutForView?
    var listLayout: NCListLayout!
    var gridLayout: NCGridLayout!
    var layoutKey = NCGlobal.shared.layoutViewTrash
    var layoutType = NCGlobal.shared.layoutList
    let refreshControl = UIRefreshControl()
    var filename: String?
    var session: NCSession.Session {
        NCSession.shared.getSession(controller: tabBarController)
    }
    
    var serverUrl = ""
    var selectableDataSource: [RealmSwiftObject] { datasource }
    private let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    var emptyDataSet: NCEmptyDataSet?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarSelect = NCTrashSelectTabBar(tabBarController: tabBarController, delegate: self)
        serverUrl = utilityFileSystem.getHomeServer(session: session)

        view.backgroundColor = .systemBackground
        self.navigationController?.navigationBar.prefersLargeTitles = true

        collectionView.register(UINib(nibName: "NCTrashListCell", bundle: nil), forCellWithReuseIdentifier: "listCell")
        collectionView.register(UINib(nibName: "NCTrashGridCell", bundle: nil), forCellWithReuseIdentifier: "gridCell")

        collectionView.register(UINib(nibName: "NCSectionFirstHeaderEmptyData", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionFirstHeaderEmptyData")
        collectionView.register(UINib(nibName: "NCSectionHeaderMenu", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeaderMenu")
        collectionView.register(UINib(nibName: "NCSectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "sectionFooter")

        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .systemBackground

        listLayout = NCListLayout()
        gridLayout = NCGridLayout()

        // Add Refresh Control
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = .gray
        refreshControl.addTarget(self, action: #selector(loadListingTrash), for: .valueChanged)

        // Empty
        emptyDataSet = NCEmptyDataSet(view: collectionView, offset: NCGlobal.shared.heightButtonsView, delegate: self)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataSource), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataSource), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeLayout(_:)), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeLayout), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        appDelegate.activeViewController = self

        navigationController?.setNavigationBarAppearance()
        navigationItem.title = titleCurrentFolder

        layoutForView = self.database.getLayoutForView(account: session.account, key: NCGlobal.shared.layoutViewTrash, serverUrl: "")
        gridLayout.column = CGFloat(layoutForView?.columnGrid ?? 3)

        if layoutForView?.layout == NCGlobal.shared.layoutList {
            collectionView.collectionViewLayout = listLayout
        } else {
            collectionView.collectionViewLayout = gridLayout
        }

        isEditMode = false
        setNavigationRightItems()

        reloadDataSource()
        loadListingTrash()
        
        AnalyticsHelper.shared.trackEvent(eventName: .SCREEN_EVENT__DELETED_FILES)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Cancel Queue & Retrieves Properties
        NCNetworking.shared.downloadThumbnailTrashQueue.cancelAll()
        dataSourceTask?.cancel()
        isEditMode = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let frame = tabBarController?.tabBar.frame {
            tabBarSelect.hostingController?.view.frame = frame
        }
    }

    // MARK: - Layout
    
    @objc func changeLayout(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as NSDictionary?,
              let account = userInfo["account"] as? String,
              let serverUrl = userInfo["serverUrl"] as? String,
              let layoutForView = userInfo["layoutForView"] as? NCDBLayoutForView,
              account == session.account,
              serverUrl == self.serverUrl
        else { return }

        self.layoutForView = self.database.setLayoutForView(layoutForView: layoutForView)
        layoutForView.layout = layoutForView.layout
        self.layoutType = layoutForView.layout
//        self.reloadDataSource()
        collectionView.reloadData()

        switch layoutForView.layout {
        case NCGlobal.shared.layoutList:
            self.collectionView.setCollectionViewLayout(self.listLayout, animated: true)
        case NCGlobal.shared.layoutGrid:
            self.collectionView.setCollectionViewLayout(self.gridLayout, animated: true)
        default:
            break
        }

        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Empty

    func emptyDataSetView(_ view: NCEmptyView) {
        view.emptyImage.image = UIImage(named: "trash")?.image(color: .gray, size: UIScreen.main.bounds.width)
        view.emptyTitle.text = NSLocalizedString("_trash_no_trash_", comment: "")
        view.emptyDescription.text = NSLocalizedString("_trash_no_trash_description_", comment: "")
    }

    // MARK: TAP EVENT

    func tapRestoreListItem(with ocId: String, image: UIImage?, sender: Any) {
        if !isEditMode {
            restoreItem(with: ocId)
        } else if let button = sender as? UIView {
            let buttonPosition = button.convert(CGPoint.zero, to: collectionView)
            let indexPath = collectionView.indexPathForItem(at: buttonPosition)
            collectionView(self.collectionView, didSelectItemAt: indexPath!)
        } // else: undefined sender
    }

    func tapMoreListItem(with objectId: String, image: UIImage?, sender: Any) {
        if !isEditMode {
            toggleMenuMore(with: objectId, image: image, isGridCell: false)
        } else if let button = sender as? UIView {
            let buttonPosition = button.convert(CGPoint.zero, to: collectionView)
            let indexPath = collectionView.indexPathForItem(at: buttonPosition)
            collectionView(self.collectionView, didSelectItemAt: indexPath!)
        } // else: undefined sender
    }

    func tapMoreGridItem(with objectId: String, image: UIImage?, sender: Any) {
        if !isEditMode {
            toggleMenuMore(with: objectId, image: image, isGridCell: true)
        } else if let button = sender as? UIView {
            let buttonPosition = button.convert(CGPoint.zero, to: collectionView)
            let indexPath = collectionView.indexPathForItem(at: buttonPosition)
            collectionView(self.collectionView, didSelectItemAt: indexPath!)
        }
    }

    func tapButtonSwitch(_ sender: Any) {
        if layoutForView?.layout == NCGlobal.shared.layoutGrid {
            onListSelected()
        } else {
            onGridSelected()
        }
    }
    
    func tapButtonOrder(_ sender: Any) {

        let sortMenu = NCSortMenu()
        sortMenu.toggleMenu(viewController: self, account: appDelegate.account, key: layoutKey, sortButton: sender as? UIButton, serverUrl: serverUrl)
        sortMenu.toggleMenu(viewController: self, account: session.account, key: layoutKey, sortButton: sender as? UIButton, serverUrl: serverUrl)
    }

    func longPressGridItem(with objectId: String, gestureRecognizer: UILongPressGestureRecognizer) { }

    func longPressMoreGridItem(with objectId: String, gestureRecognizer: UILongPressGestureRecognizer) { }

    // MARK: - DataSource

    @objc func reloadDataSource(withQueryDB: Bool = true) {
        datasource.removeAll()
        guard var trashItems = NCManageDatabase.shared.getTrash(filePath: getFilePath(), sort: layoutForView?.sort, ascending: layoutForView?.ascending, account: session.account) else {
            return
        }
        if layoutForView?.directoryOnTop ?? true {
            trashItems = trashItems.sorted {
                return $0.directory && !$1.directory
            }
        }
        datasource = trashItems
        collectionView.reloadData()
        setNavigationRightItems()

        guard let blinkFileId = blinkFileId else { return }
        for itemIx in 0..<datasource.count where datasource[itemIx].fileId.contains(blinkFileId) {
            let indexPath = IndexPath(item: itemIx, section: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                } completion: { _ in
                    guard let cell = self.collectionView.cellForItem(at: indexPath) else { return }
                    cell.backgroundColor = .darkGray
                    UIView.animate(withDuration: 2) {
                        cell.backgroundColor = .clear
                        self.blinkFileId = nil
                    }
                }
            }
        }
    }

    func getFilePath() -> String {
        if filePath.isEmpty {
            guard let userId = (session.userId as NSString).addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlFragmentAllowed) else { return "" }
            let filePath = session.urlBase + "/remote.php/dav/trashbin/" + userId + "/trash"
            return filePath + "/"
        } else {
            return filePath + "/"
        }
    }
}
