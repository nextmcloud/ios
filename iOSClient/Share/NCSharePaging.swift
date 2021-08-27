//
//  NCSharePaging.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
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
import Parchment
import NCCommunication
import SVGKit

class NCSharePaging: UIViewController {
    
    private let pagingViewController = NCShareHeaderViewController()
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var activityEnabled = true
    private var commentsEnabled = true
    private var sharingEnabled = true
    
    @objc var metadata = tableMetadata()
    @objc var indexPage: Int = 2
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = NCBrandColor.shared.backgroundView
        // Verify Comments & Sharing enabled
        let serverVersionMajor = NCManageDatabase.shared.getCapabilitiesServerInt(account: appDelegate.account, elements: NCElementsJSON.shared.capabilitiesVersionMajor)
        let comments = NCManageDatabase.shared.getCapabilitiesServerBool(account: appDelegate.account, elements: NCElementsJSON.shared.capabilitiesFilesComments, exists: false)
        if serverVersionMajor >= NCGlobal.shared.nextcloudVersion20 && comments == false {
            commentsEnabled = false
        }
        let sharing = NCManageDatabase.shared.getCapabilitiesServerBool(account: appDelegate.account, elements: NCElementsJSON.shared.capabilitiesFileSharingApiEnabled, exists: false)
        if sharing == false {
            sharingEnabled = false
        }
        let activity = NCManageDatabase.shared.getCapabilitiesServerArray(account: appDelegate.account, elements: NCElementsJSON.shared.capabilitiesActivity)
        if activity == nil {
            activityEnabled = false
        }
        if indexPage == NCGlobal.shared.indexPageComments && !commentsEnabled {
            indexPage = NCGlobal.shared.indexPageActivity
        }
        if indexPage == NCGlobal.shared.indexPageSharing && !sharingEnabled {
            indexPage = NCGlobal.shared.indexPageActivity
        }
        if indexPage == NCGlobal.shared.indexPageActivity && !activityEnabled {
            if sharingEnabled {
                indexPage = NCGlobal.shared.indexPageSharing
            } else if commentsEnabled {
                indexPage = NCGlobal.shared.indexPageComments
            }
        }
        
//        pagingViewController.activityEnabled = activityEnabled
//        pagingViewController.commentsEnabled = commentsEnabled
        pagingViewController.sharingEnabled = sharingEnabled
       
        pagingViewController.metadata = metadata
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .done, target: self, action: #selector(exitTapped))

        // Pagination
//        pagingViewController.view.frame.size.height = 0
//        pagingViewController.selectedBackgroundColor = .clear
//        pagingViewController.menuBackgroundColor = .clear
//        pagingViewController.backgroundColor = .clear
//        pagingViewController.tabBarItem.ba = .clear
        
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
            pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        pagingViewController.select(index: indexPage)
        let pagingIndexItem = self.pagingViewController(pagingViewController, pagingItemAt: indexPage) as! PagingIndexItem
//        let pagingIndexItem = self.pagingViewController(pagingViewController, pagingItemAt: 0) as! PagingIndexItem
        self.title = pagingIndexItem.title
        pagingViewController.collectionView.isHidden = true
        
        changeTheming()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if appDelegate.disableSharesView {
            self.dismiss(animated: false, completion: nil)
        }
        
//        pagingViewController.menuItemSize = .fixed(width: self.view.bounds.width/3, height: 40)
        pagingViewController.menuItemSize = .fixed(width: 0, height: 10)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource, userInfo: ["ocId":metadata.ocId, "serverUrl":metadata.serverUrl])
    }
    
    @objc func exitTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - NotificationCenter
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.backgroundView
        
//        pagingViewController.backgroundColor = NCBrandColor.shared.backgroundForm
//        pagingViewController.menuBackgroundColor = NCBrandColor.shared.backgroundForm
//        pagingViewController.selectedBackgroundColor = NCBrandColor.shared.backgroundForm
//        pagingViewController.textColor = NCBrandColor.shared.textView
//        pagingViewController.selectedTextColor = NCBrandColor.shared.textView
////        pagingViewController.indicatorColor = NCBrandColor.shared.brandElement
//        pagingViewController.indicatorColor = .clear
        pagingViewController.backgroundColor = NCBrandColor.shared.backgroundView
        pagingViewController.menuBackgroundColor = NCBrandColor.shared.backgroundView
        pagingViewController.selectedBackgroundColor = NCBrandColor.shared.backgroundView
        pagingViewController.textColor = NCBrandColor.shared.backgroundView
        pagingViewController.selectedTextColor = NCBrandColor.shared.backgroundView
//        pagingViewController.indicatorColor = NCBrandColor.shared.brandElement
        pagingViewController.indicatorColor = .clear
        (pagingViewController.view as! NCSharePagingView).setupConstraints()
        pagingViewController.reloadMenu()
    }
}

// MARK: - PagingViewController Delegate

extension NCSharePaging: PagingViewControllerDelegate {
    
    func pagingViewController(_ pagingViewController: PagingViewController, willScrollToItem pagingItem: PagingItem, startingViewController: UIViewController, destinationViewController: UIViewController) {
        
        guard let item = pagingItem as? PagingIndexItem else { return }
         
        if item.index == NCGlobal.shared.indexPageActivity && !activityEnabled {
            pagingViewController.contentInteraction = .none
        } else if item.index == NCGlobal.shared.indexPageComments && !commentsEnabled {
            pagingViewController.contentInteraction = .none
        } else if item.index == NCGlobal.shared.indexPageSharing && !sharingEnabled {
            pagingViewController.contentInteraction = .none
        } else {
            self.title = item.title
        }
    }
}

// MARK: - PagingViewController DataSource

extension NCSharePaging: PagingViewControllerDataSource {
    
    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
    
        let height = pagingViewController.options.menuHeight + NCSharePagingView.HeaderHeight
        let topSafeArea = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0

        switch index {
//        case 0:
//            let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "sharing") as! NCShare
//            viewController.sharingEnabled = sharingEnabled
//            viewController.metadata = metadata
//            viewController.height = height
//            return viewController
        
        
        case NCGlobal.shared.indexPageActivity:
            let viewController = UIStoryboard(name: "NCActivity", bundle: nil).instantiateInitialViewController() as! NCActivity
            viewController.insets = UIEdgeInsets(top: height - topSafeArea, left: 0, bottom: 0, right: 0)
            viewController.didSelectItemEnable = false
            viewController.filterFileId = metadata.fileId
            viewController.objectType = "files"
            return viewController
        case NCGlobal.shared.indexPageComments:
            let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "comments") as! NCShareComments
            viewController.metadata = metadata
            viewController.height = height
            return viewController
        case NCGlobal.shared.indexPageSharing:
            let viewController = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "sharing") as! NCShare
            viewController.sharingEnabled = sharingEnabled
            viewController.metadata = metadata
            viewController.height = height
            return viewController
        default:
            return UIViewController()
        }
    }
    
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        
//        switch index {
//        case NCGlobal.shared.indexPageActivity:
//            return PagingIndexItem(index: index, title: NSLocalizedString("_activity_", comment: ""))
//        case NCGlobal.shared.indexPageComments:
//            return PagingIndexItem(index: index, title: NSLocalizedString("_comments_", comment: ""))
//        case NCGlobal.shared.indexPageSharing:
//            return PagingIndexItem(index: index, title: NSLocalizedString("_sharing_", comment: ""))
//        default:
//            return PagingIndexItem(index: index, title: "")
//        }
        
        switch index {
        case NCGlobal.shared.indexPageActivity:
            return PagingIndexItem(index: index, title: NSLocalizedString("", comment: ""))
        case NCGlobal.shared.indexPageComments:
            return PagingIndexItem(index: index, title: NSLocalizedString("", comment: ""))
        case NCGlobal.shared.indexPageSharing:
            return PagingIndexItem(index: index, title: NSLocalizedString("", comment: ""))
        default:
            return PagingIndexItem(index: index, title: "")
        }
        
    }
   
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return 3
//        return 1
    }
}

// MARK: - Header

class NCShareHeaderViewController: PagingViewController {
    
    public var image: UIImage?
    public var metadata: tableMetadata?
    
    public var activityEnabled = false
    public var commentsEnabled = false
    public var sharingEnabled = true

    override func loadView() {
        view = NCSharePagingView(
            options: options,
            collectionView: collectionView,
            pageView: pageViewController.view,
            metadata: metadata
        )
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if indexPath.item == NCGlobal.shared.indexPageActivity && !activityEnabled {
//            return
//        }
//        if indexPath.item == NCGlobal.shared.indexPageComments && !commentsEnabled {
//            return
//        }
//        if indexPath.item == NCGlobal.shared.indexPageSharing && !sharingEnabled {
//            return
//        }
//        super.collectionView(collectionView, didSelectItemAt: indexPath)
    }
}

class NCSharePagingView: PagingView {
    
//    static let HeaderHeight: CGFloat = 250
    static let HeaderHeight: CGFloat = 320
    var metadata: tableMetadata?
    
    var headerHeightConstraint: NSLayoutConstraint?
    
    public init(options: Parchment.PagingOptions, collectionView: UICollectionView, pageView: UIView, metadata: tableMetadata?) {
        super.init(options: options, collectionView: collectionView, pageView: pageView)
        
        self.metadata = metadata
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {
        
        let headerView = Bundle.main.loadNibNamed("NCShareHeaderView", owner: self, options: nil)?.first as! NCShareHeaderView
        headerView.backgroundColor = NCBrandColor.shared.backgroundView
        headerView.fileName.textColor = NCBrandColor.shared.icon
        headerView.labelSharing.textColor = NCBrandColor.shared.icon
        headerView.labelSharingInfo.textColor = NCBrandColor.shared.icon
        headerView.info.textColor = NCBrandColor.shared.textInfo
        headerView.ocId = metadata!.ocId
        
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
//            headerView.imageView.image = UIImage.init(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag))
//            headerView.fullWidthImageView.image = UIImage.init(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag))
//            headerView.fullWidthImageView.image = getImage(metadata: metadata!)
            headerView.fullWidthImageView.image = getImageMetadata(metadata!)
            headerView.fullWidthImageView.contentMode = .scaleToFill
            headerView.imageView.isHidden = true
        } else {
            if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                headerView.imageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
            } else if metadata!.iconName.count > 0 {
                headerView.imageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                headerView.imageView.image = UIImage.init(named: "file")
            }
        }
        headerView.fileName.text = metadata?.fileNameView
        headerView.fileName.textColor = NCBrandColor.shared.textView
        if metadata!.favorite {
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
        } else {
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
        }
        headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        addSubview(headerView)
        
        pageView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        headerHeightConstraint = headerView.heightAnchor.constraint(
            equalToConstant: NCSharePagingView.HeaderHeight
        )
//        headerHeightConstraint = headerView.heightAnchor.constraint(
//            equalToConstant: metadata!.directory ? 350 : 370
//        )
        
        headerHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: options.menuHeight),
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            pageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pageView.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
    }
    
    private func getImage(metadata: tableMetadata) -> UIImage? {
        
        let ext = CCUtility.getExtension(metadata.fileNameView)
        var image: UIImage?
        
        if CCUtility.fileProviderStorageExists(metadata.ocId, fileNameView: metadata.fileNameView) && metadata.typeFile == NCGlobal.shared.metadataTypeFileImage {
           
            let previewPath = CCUtility.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag)!
            let imagePath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
            
            if ext == "GIF" {
                if !FileManager().fileExists(atPath: previewPath) {
                    NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, typeFile: metadata.typeFile)
                }
                image = UIImage.animatedImage(withAnimatedGIFURL: URL(fileURLWithPath: imagePath))
            } else if ext == "SVG" {
                if let svgImage = SVGKImage(contentsOfFile: imagePath) {
                    let scale = svgImage.size.height / svgImage.size.width
                    svgImage.size = CGSize(width: NCGlobal.shared.sizePreview, height: (NCGlobal.shared.sizePreview * scale))
                    if let image = svgImage.uiImage {
                        if !FileManager().fileExists(atPath: previewPath) {
                            do {
                                try image.pngData()?.write(to: URL(fileURLWithPath: previewPath), options: .atomic)
                            } catch { }
                        }
                        return image
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            } else {
                NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, typeFile: metadata.typeFile)
                image = UIImage.init(contentsOfFile: imagePath)
            }
        }
        
        return image
    }
    
    //MARK: - Image
    
    func getImageMetadata(_ metadata: tableMetadata) -> UIImage? {
        
        if let image = getImage(metadata: metadata) {
            return image
        }
        
        if metadata.typeFile == NCGlobal.shared.metadataTypeFileVideo && !metadata.hasPreview {
            NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, typeFile: metadata.typeFile)
        }
        
        if CCUtility.fileProviderStoragePreviewIconExists(metadata.ocId, etag: metadata.etag) {
            if let imagePreviewPath = CCUtility.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag) {
                return UIImage.init(contentsOfFile: imagePreviewPath)
            }
        }
        
        return nil
    }
    
//    private func getImage(metadata: tableMetadata) -> UIImage? {
//
//        let ext = CCUtility.getExtension(metadata.fileNameView)
//        var image: UIImage?
//
//        if CCUtility.fileProviderStorageExists(metadata.ocId, fileNameView: metadata.fileNameView) && metadata.typeFile == NCGlobal.shared.metadataTypeFileImage {
//
//            let previewPath = CCUtility.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag)!
//            let imagePath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
//
//            if ext == "GIF" {
//                if !FileManager().fileExists(atPath: previewPath) {
//                    NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, typeFile: metadata.typeFile)
//                }
//                image = UIImage.animatedImage(withAnimatedGIFURL: URL(fileURLWithPath: imagePath))
//            } else if ext == "SVG" {
//                if let svgImage = SVGKImage(contentsOfFile: imagePath) {
//                    let scale = svgImage.size.height / svgImage.size.width
//                    svgImage.size = CGSize(width: NCGlobal.shared.sizePreview, height: (NCGlobal.shared.sizePreview * scale))
//                    if let image = svgImage.uiImage {
//                        if !FileManager().fileExists(atPath: previewPath) {
//                            do {
//                                try image.pngData()?.write(to: URL(fileURLWithPath: previewPath), options: .atomic)
//                            } catch { }
//                        }
//                        return image
//                    } else {
//                        return nil
//                    }
//                } else {
//                    return nil
//                }
//            } else {
//                NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, typeFile: metadata.typeFile)
//                image = UIImage.init(contentsOfFile: imagePath)
//            }
//        }
//
//        return image
//    }
}

class NCShareHeaderView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelSharingInfo: UILabel!
    @IBOutlet weak var fullWidthImageView: UIImageView!
    
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ocId = ""
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
            NCNetworking.shared.favoriteMetadata(metadata, urlBase: appDelegate.urlBase) { (errorCode, errorDescription) in
                if errorCode == 0 {
                    if !metadata.favorite {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                    } else {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                    }
                } else {
                    NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                }
            }
        }
    }
}
