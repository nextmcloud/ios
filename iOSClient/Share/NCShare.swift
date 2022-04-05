//
//  NCShare.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 17/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//  Copyright © 2021 TSI-mc. All rights reserved.
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

import UIKit
import Parchment
import DropDown
import NCCommunication
import SVGKit
class NCShare: UIViewController, UIGestureRecognizerDelegate, NCShareLinkCellDelegate, NCShareUserCellDelegate, NCShareNetworkingDelegate {
    
    //    @IBOutlet weak var viewContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    //    @IBOutlet weak var containerView: UIView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    public var metadata: tableMetadata?
    public var sharingEnabled = true
    public var height: CGFloat = 0
    
    private var shareLinkMenuView: NCShareLinkMenuView?
    private var shareUserMenuView: NCShareUserMenuView?
    private var sharePermissionMenuView: NCPermissionMenuView?
    private var shareMenuViewWindow: UIView?
    private var dropDown = DropDown()
    private var networking: NCShareNetworking?
    private var shareeSelected: NCCommunicationSharee?
    public  var tableShareSelected: tableShare?
    private var quickStatusTableShare: tableShare!
    private var sendEmailSelected: Int!
    private var shareeEmail: String!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        
        //        viewContainerConstraint.constant = height
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.backgroundColor = NCBrandColor.shared.systemBackground
        
        tableView.register(UINib.init(nibName: "NCShareLinkCell", bundle: nil), forCellReuseIdentifier: "cellLink")
        tableView.register(UINib.init(nibName: "NCShareUserCell", bundle: nil), forCellReuseIdentifier: "cellUser")
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataNCShare), object: nil)
        
        reloadData()
        
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase, view: self.view, delegate: self)
        if sharingEnabled {
            networking?.readShare(showLoadingIndicator: true)
        }
        
        // changeTheming
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(shareMenuViewInClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterShareViewIn), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareMenuAdvancePermissionClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterShareAdvancePermission), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareMenuSendEmailClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterShareSendEmail), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shareMenuUnshareClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterShareUnshare), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusReadOnlyClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusReadOnly), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusEditingClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusEditing), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusFileDropClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusFileDrop), object: nil)
        TealiumHelper.shared.trackView(title: "magentacloud-app.sharing", data: ["": ""])
        changeTheming()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willComeForeground), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterApplicationWillEnterForeground), object: nil)
        
        //        let isCurrentUser = NCShareCommon.shared.isCurrentUserIsFileOwner(fileOwnerId: metadata?.ownerId ?? "")
        //        let canReshare = NCShareCommon.shared.canReshare(withPermission: metadata?.permissions ?? "")
        //        if isCurrentUser || canReshare {
        //            containerView.isHidden = false
        //        } else {
        //            containerView.isHidden = true
        //        }
        
        setupHeader()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .done, target: self, action: #selector(exitTapped))
        navigationItem.largeTitleDisplayMode = .never
    }
    
    @objc func exitTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupHeader(){
        tableView.register(NCShareSectionHeaderView.nib, forHeaderFooterViewReuseIdentifier: NCShareSectionHeaderView.identifier)
    }
    
    @objc func willComeForeground(notification: Notification) {
        reloadData()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if UIScreen.main.bounds.width == 375, UIScreen.main.bounds.height == 812 {
                if view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= 100
                }
            } else if (UIScreen.main.bounds.width < 376 || UIDevice.current.orientation.isLandscape) {
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    if view.frame.origin.y == 0 {
                        self.view.frame.origin.y -= keyboardSize.height
                    }
                }
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad, UIDevice.current.orientation.isLandscape {
            if view.frame.origin.y == 0 {
                self.view.frame.origin.y -= 230
            }
        }
        if let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField {
            searchField.layer.borderColor = NCBrandColor.shared.brand.cgColor
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
        if let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField {
            searchField.layer.borderColor = NCBrandColor.shared.label.cgColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.reloadData()
        guard let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField  else { return }
        searchField.text = ""
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.beginUpdates()
        tableView.endUpdates()
        let animationHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { [weak self] (context) in
            // This block will be called several times during rotation,
            // so if you want your tableView change more smooth reload it here too.
            self?.tableView.reloadData()
        }
        
        let completionHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { [weak self] (context) in
            // This block will be called when rotation will be completed
            self?.tableView.reloadData()
        }
        
        coordinator.animate(alongsideTransition: animationHandler, completion: completionHandler)
        
    }
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        tableView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        tableView.reloadData()
        self.view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        UINavigationBar.appearance().tintColor = NCBrandColor.shared.customer
    }
    
    @objc func reloadData() {
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        if shares.firstShareLink == nil {
            // buttonMenu.setImage(UIImage.init(named: "shareAdd")?.image(color: .gray, size: 50), for: .normal)
            // buttonMenu.isHidden = true
            // buttonCopy.isHidden = true
        } else {
            // buttonMenu.setImage(UIImage.init(named: "shareMenu")?.image(color: NCBrandColor.shared.customer, size: 50), for: .normal)
            // buttonMenu.isHidden = true
            // buttonCopy.isHidden = true
            self.tableView.setEmptyMessage(NSLocalizedString("", comment: ""))
        }
        tableView.reloadData()
        tableView.isUserInteractionEnabled = true
    }
    
    
    // MARK: - IBAction
    
    @IBAction func searchFieldDidEndOnExit(textField: UITextField) {
        
        guard let searchString = textField.text else { return }
        
        networking?.getSharees(searchString: searchString)
        self.shareeEmail = searchString
    }
    
    @IBAction func touchUpInsideButtonCopy(_ sender: Any) {
        
        guard let metadata = self.metadata else { return }
        
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)
        tapCopy(with: shares.firstShareLink, sender: sender)
    }
    
    @IBAction func touchUpInsideButtonCopyInernalLink(_ sender: Any) {
        
        guard let metadata = self.metadata else { return }
        
        let serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName
        NCNetworking.shared.readFile(serverUrlFileName: serverUrlFileName, account: metadata.account) { (account, metadata, errorCode, errorDescription) in
            if errorCode == 0 && metadata != nil {
                let internalLink = self.appDelegate.urlBase + "/index.php/f/" + metadata!.fileId
                NCShareCommon.shared.copyLink(link: internalLink, viewController: self, sender: sender)
            } else {
                NCContentPresenter.shared.messageNotification("_share_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
            }
        }
    }
    
    @IBAction func touchUpInsideButtonMenu(_ sender: Any) {
        
        guard let metadata = metadata else { return }
        let isFilesSharingPublicPasswordEnforced = NCManageDatabase.shared.getCapabilitiesServerBool(account: metadata.account, elements: NCElementsJSON.shared.capabilitiesFileSharingPubPasswdEnforced, exists: false)
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)
        
        if isFilesSharingPublicPasswordEnforced && shares.firstShareLink == nil {
            let alertController = UIAlertController(title: NSLocalizedString("_enforce_password_protection_", comment: ""), message: "", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.isSecureTextEntry = true
            }
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default) { (action:UIAlertAction) in })
            let okAction = UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) {[weak self] (action:UIAlertAction) in
                let password = alertController.textFields?.first?.text
                self?.networking?.createShareLink(password: password ?? "")
            }
            
            alertController.addAction(okAction)
            
            present(alertController, animated: true, completion:nil)
        } else if shares.firstShareLink == nil {
            networking?.createShareLink(password: "")
        } else {
            //            tapMenu(with: shares.firstShareLink!, sender: sender, index: <#Int#>)
            networking?.createShareLink(password: "")
        }
        
    }
    
    @objc func tapLinkMenuViewWindow(gesture: UITapGestureRecognizer) {
        shareLinkMenuView?.unLoad()
        shareLinkMenuView = nil
        shareUserMenuView?.unLoad()
        shareUserMenuView = nil
        sharePermissionMenuView?.unLoad()
        sharePermissionMenuView = nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return gestureRecognizer.view == touch.view
    }
    
    func tapCopy(with tableShare: tableShare?, sender: Any) {
        
        if let link = tableShare?.url {
            NCShareCommon.shared.copyLink(link: link, viewController: self, sender: sender)
        }
    }
    
    func switchCanEdit(with tableShare: tableShare?, switch: Bool, sender: UISwitch) {
        
        guard let tableShare = tableShare else { return }
        guard let metadata = self.metadata else { return }
        
        let canShare = CCUtility.isPermission(toCanShare: tableShare.permissions)
        var permission: Int = 0
        
        if sender.isOn {
            permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: canShare, andIsFolder: metadata.directory)
        } else {
            permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: canShare, andIsFolder: metadata.directory)
        }
        
        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, label: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
    }
    
    //    func tapMenu(with tableShare: tableShare?, sender: Any) {
    //    func tapMenu(with tableShare: tableShare?, sender: Any, index: Int) {
    //
    //        guard let tableShare = tableShare else { return }
    //
    //        self.tableShareSelected = tableShare
    //        self.sendEmailSelected = index
    //        if tableShare.shareType == 3 {
    ////            let views = NCShareCommon.shared.openViewMenuShareLink(shareViewController: self, tableShare: tableShare, metadata: metadata!)
    ////            shareLinkMenuView = views.shareLinkMenuView
    ////            shareMenuViewWindow = views.viewWindow
    //            let shareMenu = NCShareMenu()
    //            shareMenu.toggleMenu(viewController: self, sendMail: false)
    //
    //            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
    //            tap.delegate = self
    //            shareMenuViewWindow?.addGestureRecognizer(tap)
    //        } else {
    ////            let views = NCShareCommon.shared.openViewMenuUser(shareViewController: self, tableShare: tableShare, metadata: metadata!)
    ////            shareUserMenuView = views.shareUserMenuView
    ////            shareMenuViewWindow = views.viewWindow
    //            let shareMenu = NCShareMenu()
    //            shareMenu.toggleMenu(viewController: self, sendMail: true)
    //            let views = NCShareCommon.shared.openViewMenuUser(shareViewController: self, tableShare: tableShare, metadata: metadata!)
    //            shareUserMenuView = views.shareUserMenuView
    //            shareMenuViewWindow = views.viewWindow
    //
    //            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
    //            tap.delegate = self
    //            shareMenuViewWindow?.addGestureRecognizer(tap)
    //        }
    //    }
    
    func tapMenu(with tableShare: tableShare?, sender: Any, index: Int) {
        
        guard let tableShare = tableShare else { return }
        guard let metadata = self.metadata else { return }
        
        self.tableShareSelected = tableShare
        self.sendEmailSelected = index
        let isFolder = metadata.directory
        if tableShare.shareType == 3 {
            //            let views = NCShareCommon.shared.openViewMenuShareLink(shareViewController: self, tableShare: tableShare, metadata: metadata!)
            //            shareLinkMenuView = views.shareLinkMenuView
            //            shareMenuViewWindow = views.viewWindow
            //            let shareMenu = NCShareMenu()
            //            shareMenu.toggleMenu(viewController: self)
            //            let views = NCShareCommon.shared.openViewMenuShareLink(shareViewController: self, tableShare: tableShare, metadata: metadata!)
            //            shareLinkMenuView = views.shareLinkMenuView
            //            shareMenuViewWindow = views.viewWindow
            let shareMenu = NCShareMenu()
            let isFolder = metadata.directory
            shareMenu.toggleMenu(viewController: self, sendMail: false, folder: isFolder)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
            tap.delegate = self
            //            shareUserMenuView = views.shareUserMenuView
            //            shareMenuViewWindow = views.viewWindow
            //            let shareMenu = NCShareMenu()
            //            shareMenu.toggleMenu(viewController: self)
            //            shareMenu.toggleMenu(viewController: self, sendMail: true)
            //
            //            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
            //            tap.delegate = self
        } else {
            let shareMenu = NCShareMenu()
            shareMenu.toggleMenu(viewController: self, sendMail: true, folder: isFolder)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
            tap.delegate = self
        }
    }
    
    
    //    func quickStatus(with tableShare: tableShare?, sender: UIButton) {
    //        guard let tableShare = tableShare else { return }
    //
    //        if tableShare.shareType != 3 {
    ////            let views = NCShareCommon.shared.openQuickShare(shareViewController: self, tableShare: tableShare, metadata: metadata!)
    ////            sharePermissionMenuView = views.sharePermissionMenuView
    ////            shareMenuViewWindow = views.viewWindow
    ////
    ////            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
    ////            tap.delegate = self
    ////            shareMenuViewWindow?.addGestureRecognizer(tap)
    //
    //            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
    //            tap.delegate = self
    //            shareMenuViewWindow?.addGestureRecognizer(tap)
    //            self.quickStatusTableShare = tableShare
    //            let quickStatusMenu = NCShareQuickStatusMenu()
    //            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, directoryType: "", status: tableShare.permissions)
    //        }
    //    }
    
    //    func quickStatus(with tableShare: tableShare?, sender: UIButton) {
    //        guard let tableShare = tableShare else { return }
    //
    //        if tableShare.shareType != 3 {
    ////            let views = NCShareCommon.shared.openQuickShare(shareViewController: self, tableShare: tableShare, metadata: metadata!)
    ////            sharePermissionMenuView = views.sharePermissionMenuView
    ////            shareMenuViewWindow = views.viewWindow
    ////
    ////            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
    ////            tap.delegate = self
    ////            shareMenuViewWindow?.addGestureRecognizer(tap)
    //
    //            self.quickStatusTableShare = tableShare
    //            let quickStatusMenu = NCShareQuickStatusMenu()
    //            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, status: tableShare.permissions)
    //
    //        }
    //    }
    
    /// MARK: - NCShareNetworkingDelegate
    
    func readShareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func shareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func unShareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func updateShareWithError(idShare: Int) {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
        self.reloadData()
    }
    
    func getSharees(sharees: [NCCommunicationSharee]?) {
        
        guard let sharees = sharees else { return }
        guard let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField  else { return }
        dropDown = DropDown()
        let appearance = DropDown.appearance()
        appearance.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        appearance.cornerRadius = 10
        appearance.shadowColor = UIColor(white: 0.5, alpha: 1)
        appearance.shadowOpacity = 0.9
        appearance.shadowRadius = 25
        appearance.animationduration = 0.25
        appearance.textColor = .darkGray
        appearance.setupMaskedCorners([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        
        for sharee in sharees {
            var label = sharee.label
            if sharee.shareType == NCShareCommon.shared.SHARE_TYPE_CIRCLE {
                label = label + " (" + sharee.circleInfo + ", " +  sharee.circleOwner + ")"
            }
            dropDown.dataSource.append(label)
        }
        
        dropDown.anchorView = searchField
        dropDown.bottomOffset = CGPoint(x: 0, y: searchField.bounds.height)
        dropDown.width = searchField.bounds.width
        dropDown.direction = .bottom
        
        dropDown.cellNib = UINib(nibName: "NCShareUserDropDownCell", bundle: nil)
        dropDown.customCellConfiguration = {[weak self] (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let cell = cell as? NCShareUserDropDownCell else { return }
            let sharee = sharees[index]
            cell.imageItem.image = NCShareCommon.shared.getImageShareType(shareType: sharee.shareType)
            let status = NCUtility.shared.getUserStatus(userIcon: sharee.userIcon, userStatus: sharee.userStatus, userMessage: sharee.userMessage)
            cell.imageStatus.image = status.onlineStatus
            cell.status.text = status.statusMessage
            if cell.status.text?.count ?? 0 > 0 {
                cell.centerTitle.constant = -5
            } else {
                cell.centerTitle.constant = 0
            }
            
            let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(self?.appDelegate.user, urlBase: self?.appDelegate.urlBase)) + "-" + sharee.label + ".png"
            if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                    cell.imageItem.image = NCUtility.shared.createAvatar(image: image, size: 30)
                }
            } else {
                let fileName = self?.appDelegate.userBaseUrl ?? "" + "-" + sharee.shareWith + ".png"
                if NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName) == nil {
                    let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + fileName
                    let etag = NCManageDatabase.shared.getTableAvatar(fileName: fileName)?.etag
                    
                    NCCommunication.shared.downloadAvatar(user: sharee.shareWith, fileNameLocalPath: fileNameLocalPath, sizeImage: NCGlobal.shared.avatarSize, avatarSizeRounded: NCGlobal.shared.avatarSizeRounded, etag: etag) { _, imageAvatar, _, etag, errorCode, _ in
                        
                        if errorCode == 0, let etag = etag, let imageAvatar = imageAvatar {
                            
                            NCManageDatabase.shared.addAvatar(fileName: fileName, etag: etag)
                            cell.imageItem.image = imageAvatar
                            
                        } else if errorCode == NCGlobal.shared.errorNotModified, let imageAvatar = NCManageDatabase.shared.setAvatarLoaded(fileName: fileName) {
                            
                            cell.imageItem.image = imageAvatar
                        }
                    }
                }
            }
            let image: UIImage? = sharee.shareType == NCShareCommon.shared.SHARE_TYPE_USER ? NCShareCommon.shared.getImageShareType(shareType: sharee.shareType) : nil
            cell.imageShareeType.image = image
        }
        
        dropDown.selectionAction = { [weak self] (index, item) in
            let sharee = sharees[index]
            searchField.layer.borderColor = NCBrandColor.shared.label.cgColor
            searchField.text = ""
            let directory = self?.metadata?.directory ?? false
            let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
            DispatchQueue.main.async() { [self] in
                //                var viewNewUserPermission: NCShareNewUserPermission
                var viewNewUserPermission: NCShareAdvancePermission
                //                if directory! {
                ////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                //                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFolderPermission") as! NCShareNewUserPermission
                //                } else {
                ////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                //                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFilePermission") as! NCShareNewUserPermission
                //                }
                //                if directory! {
                
                viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareAdvancePermission") as! NCShareAdvancePermission
                //                } else {
                ////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                //                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFilePermission") as! NCShareNewUserPermission
                //                }
                
                if let ocId = self?.metadata?.ocId {
                    let metaData = NCManageDatabase.shared.getMetadataFromOcId(ocId)
                    self?.metadata = metaData
                }
                searchField.resignFirstResponder()
                viewNewUserPermission.metadata = self!.metadata
                viewNewUserPermission.sharee = sharee
                viewNewUserPermission.shareeEmail = self?.shareeEmail
                viewNewUserPermission.newUser = true
                self?.navigationController!.pushViewController(viewNewUserPermission, animated: true)
            }
            //            self!.networking?.createShare(shareWith: sharee.shareWith, shareType: sharee.shareType, metadata: self!.metadata!)
        }
        
        dropDown.show()
    }
    
    func getImageMetadata(_ metadata: tableMetadata) -> UIImage? {
        
        if let image = getImage(metadata: metadata) {
            return image
        }
        
        if metadata.classFile == NCCommunicationCommon.typeClassFile.video.rawValue && !metadata.hasPreview {
            NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
        }
        
        if CCUtility.fileProviderStoragePreviewIconExists(metadata.ocId, etag: metadata.etag) {
            if let imagePreviewPath = CCUtility.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag) {
                return UIImage.init(contentsOfFile: imagePreviewPath)
            }
        }
        
        return nil
    }
    private func getImage(metadata: tableMetadata) -> UIImage? {
        
        let ext = CCUtility.getExtension(metadata.fileNameView)
        var image: UIImage?
        
        if CCUtility.fileProviderStorageExists(metadata) && metadata.classFile == NCCommunicationCommon.typeClassFile.image.rawValue {
            
            let previewPath = CCUtility.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag)!
            let imagePath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
            
            if ext == "GIF" {
                if !FileManager().fileExists(atPath: previewPath) {
                    NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
                }
                image = UIImage.animatedImage(withAnimatedGIFURL: URL(fileURLWithPath: imagePath))
            } else if ext == "SVG" {
                if let svgImage = SVGKImage(contentsOfFile: imagePath) {
                    let scale = svgImage.size.height / svgImage.size.width
                    svgImage.size = CGSize(width: NCGlobal.shared.sizePreview, height: (NCGlobal.shared.sizePreview * Int(scale)))
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
                NCUtility.shared.createImageFrom(fileName: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
                image = UIImage.init(contentsOfFile: imagePath)
            }
        }
        
        return image
    }
    
    @IBAction func createLinkClicked(_ sender: Any) {
        appDelegate.adjust.trackEvent(TriggerEvent(CreateLink.rawValue))
        TealiumHelper.shared.trackEvent(title: "magentacloud-app.sharing.create", data: ["": ""])
        self.touchUpInsideButtonMenu(sender)
    }
    
    
    // MARK: -NCShareMenuOptions
    @objc func shareMenuViewInClicked() {
        // image to share
        let image = UIImage(named: "pencil")
        
        let imageToShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    @objc func shareMenuAdvancePermissionClicked() {
        //        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        //        let directory = self.metadata?.directory
        //        let shareFileOptions = storyboard.instantiateViewController(withIdentifier: "NCShareFileOptions") as! NCShareFileOptions
        //        shareFileOptions.metadata = self.metadata
        //        shareFileOptions.tableShare = self.tableShareSelected
        //        shareFileOptions.sharee = self.shareeSelected
        //        guard let navigationController = navigationController else {
        //            print("this vc is not embedded in navigationController")
        //            return
        //        }
        //        navigationController.pushViewController(shareFileOptions, animated: true)
        //NCShareAdvancePermission
        
        let directory = self.metadata?.directory
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        //        var viewNewUserPermission: NCShareNewUserPermission
        //        viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserPermission") as! NCShareNewUserPermission
        var advancePermission: NCShareAdvancePermission
        advancePermission = storyboard.instantiateViewController(withIdentifier: "NCShareAdvancePermission") as! NCShareAdvancePermission
        if let ocId = metadata?.ocId {
            let metaData = NCManageDatabase.shared.getMetadataFromOcId(ocId)
            self.metadata = metaData
        }
        advancePermission.metadata = self.metadata
        advancePermission.sharee = self.shareeSelected
        //        advancePermission.shareeEmail = self.shareeEmail
        advancePermission.newUser = false
        advancePermission.tableShare = self.tableShareSelected
        guard let navigationController = navigationController else {
            print("this vc is not embedded in navigationController")
            return
        }
        if let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField {
            searchField.resignFirstResponder()
        }
        navigationController.pushViewController(advancePermission, animated: true)
    }
    
    @objc func shareMenuSendEmailClicked() {
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as! NCShareNewUserAddComment
        if let ocId = metadata?.ocId {
            let metaData = NCManageDatabase.shared.getMetadataFromOcId(ocId)
            self.metadata = metaData
        }
        viewNewUserComment.metadata = self.metadata
        viewNewUserComment.tableShare = self.tableShareSelected
        viewNewUserComment.isUpdating = true
        if let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField {
            searchField.resignFirstResponder()
        }
        self.navigationController?.pushViewController(viewNewUserComment, animated: true)
    }
    
    @objc func shareMenuUnshareClicked() {
        guard let tableShare = self.tableShareSelected else { return }
        tableView.isUserInteractionEnabled = false
        networking?.unShare(idShare: tableShare.idShare)
    }
    
    // MARK: -StatusChangeNotification
    func quickStatus(with tableShare: tableShare?, sender: UIButton) {
        guard let tableShare = tableShare else { return }
        let directory = self.metadata?.directory ?? false
        let editingAllowed = NCShareCommon.shared.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.ext ?? "", shareType: tableShare.shareType)
        if editingAllowed {
            self.quickStatusTableShare = tableShare
            let quickStatusMenu = NCShareQuickStatusMenu()
            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, tableShare: tableShare)
        } else {
            return
        }
    }
    
    
    func quickStatusLink(with tableShare: tableShare?, sender: UIButton) {
        guard let tableShare = tableShare else { return }
        let directory = metadata?.directory ?? false
        
        if directory {
            self.quickStatusTableShare = tableShare
            let quickStatusMenu = NCShareQuickStatusMenu()
            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, tableShare: tableShare)
        }
    }
    
    @objc func statusReadOnlyClicked() {
        guard self.quickStatusTableShare != nil else { return }
        var canReshare = false
        if let value = self.tableShareSelected?.permissions {
            canReshare = CCUtility.isPermission(toCanShare: value)
        }
        let permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: canReshare, andIsFolder: metadata!.directory)
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, label: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
    
    @objc func statusEditingClicked() {
        guard self.quickStatusTableShare != nil else { return }
        var canReshare = false
        if let value = self.tableShareSelected?.permissions {
            canReshare = CCUtility.isPermission(toCanShare: value)
        }
        let permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: canReshare, andIsFolder: metadata!.directory)
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, label: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
    
    @objc func statusFileDropClicked() {
        guard self.quickStatusTableShare != nil else { return }
        let permission = NCGlobal.shared.permissionCreateShare
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, label: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let searchField = self.view.viewWithTag(Tag.searchField) as? UITextField {
            if searchField.isEditing {
                searchField.resignFirstResponder()
            }
        }
    }
}

extension NCShare: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let searchString = "\(textField.text ?? "")\(string)"
        if searchString.count == 1, string == "" {
            dropDown.hide()
        } else {
            networking?.getSharees(searchString: searchString)
        }
        self.shareeEmail = searchString
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let text = textField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
            networking?.getSharees(searchString: text)
        }
    }
}

// MARK: - UITableViewDelegate

extension NCShare: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? UITableView.automaticDimension : 60
    }
}

// MARK: - UITableViewDataSource

extension NCShare: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let canReshare = NCShareCommon.shared.canReshare(withPermission: metadata?.permissions ?? "")
        var numOfRows = 0
        var shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        if let shareLink = shares.firstShareLink {
            shares.share?.insert(shareLink, at: 0)
        }
        
        self.tableView.setEmptyMessage(NSLocalizedString("", comment: ""))
        if shares.share != nil {
            numOfRows = shares.share!.count
        }
        if numOfRows == 0 {
            for messageView in self.tableView.subviews.filter({$0.tag == 999}){
                messageView.removeFromSuperview()
            }
            if canReshare {
                self.tableView.setEmptyMessage(NSLocalizedString("no_shares_created", comment: ""))
            }
        } else {
            self.tableView.restore()
        }
        return canReshare ? (numOfRows + 1) : numOfRows
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NCShareEmailFieldCell", for: indexPath) as! NCShareEmailFieldCell
            cell.searchField.addTarget(self, action: #selector(searchFieldDidEndOnExit(textField:)), for: .editingDidEndOnExit)
            cell.searchField.delegate = self
            cell.btnCreateLink.addTarget(self, action: #selector(createLinkClicked(_:)), for: .touchUpInside)
            return cell
        }
        
        var shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        if let shareLink = shares.firstShareLink {
            shares.share?.insert(shareLink, at: 0)
        }
        let tableShare = shares.share![indexPath.row - 1]
        let directory = self.metadata?.directory ?? false
        
        // LINK
        if tableShare.shareType == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell {
                cell.tableShare = tableShare
                cell.delegate = self
                cell.contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
                cell.imageItem.image = UIImage(named: "sharebylink")?.image(color: NCBrandColor.shared.label, size: 30)
                if !tableShare.label.isEmpty {
                    cell.labelTitle.text = String(format: NSLocalizedString("_share_linklabel_", comment: ""), tableShare.label)
                } else {
                    cell.labelTitle.text = directory ? NSLocalizedString("_share_link_folder_", comment: "") : NSLocalizedString("_share_link_file_", comment: "")
                }
                
                cell.labelTitle.textColor = NCBrandColor.shared.label
                cell.indexSelected = indexPath.row - 1
                cell.btnQuickStatus.tag = indexPath.row - 1
                
                if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
                    cell.labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
                } else {
                    // Read Only
                    if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
                    } else {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
                    }
                }
                
                if directory {
                    cell.btnQuickStatus.isEnabled = true
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.brand
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.brand)
                } else {
                    cell.btnQuickStatus.isEnabled = false
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.quickStatusTextColor
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.quickStatusTextColor)
                }
                
                return cell
            }
        } else if tableShare.shareType == 4 {
            //external
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell {
                
                cell.contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
                cell.tableShare = tableShare
                cell.delegate = self
                cell.labelTitle.text = tableShare.shareWithDisplayname
                cell.labelTitle.textColor = NCBrandColor.shared.label
                cell.labelCanEdit.text = NSLocalizedString("_share_permission_edit_", comment: "")
                cell.labelCanEdit.textColor = NCBrandColor.shared.iconColor
                cell.isUserInteractionEnabled = true
                cell.switchCanEdit.isHidden = true//false
                cell.labelCanEdit.isHidden = true//false
                cell.buttonMenu.isHidden = false
                cell.imageItem.image = NCShareCommon.shared.getImageShareType(shareType: tableShare.shareType)
                cell.indexSelected = indexPath.row - 1
                cell.btnQuickStatus.tag = indexPath.row - 1
                
                let status = NCUtility.shared.getUserStatus(userIcon: tableShare.userIcon, userStatus: tableShare.userStatus, userMessage: tableShare.userMessage)
                cell.imageStatus.image = status.onlineStatus
                cell.status.text = status.statusMessage
                
                let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + tableShare.shareWith + ".png"
                
                if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                    if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                    }
                }
                
                if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                    cell.switchCanEdit.setOn(true, animated: false)
                } else {
                    cell.switchCanEdit.setOn(false, animated: false)
                }
                
                // If the initiator or the recipient is not the current user, show the list of sharees without any options to edit it.
                if tableShare.uidOwner != self.appDelegate.userId && tableShare.uidFileOwner != self.appDelegate.userId {
                    cell.isUserInteractionEnabled = false
                    cell.switchCanEdit.isHidden = true
                    cell.labelCanEdit.isHidden = true
                    cell.buttonMenu.isHidden = true
                }
                cell.btnQuickStatus.setTitle("", for: .normal)
                cell.btnQuickStatus.contentHorizontalAlignment = .left
                
                cell.btnQuickStatus.isEnabled = true
                cell.labelQuickStatus.textColor = NCBrandColor.shared.brand
                cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.brand)
                
                if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
                    cell.labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
                } else {
                    // Read Only
                    if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
                    } else {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
                    }
                }
                
                let isEditingAllowed = NCShareCommon.shared.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.ext ?? "", shareType: tableShare.shareType)
                if isEditingAllowed {
                    cell.btnQuickStatus.isEnabled = true
                } else {
                    cell.btnQuickStatus.isEnabled = false
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.quickStatusTextColor
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.quickStatusTextColor)
                }
                
                return cell
            }
        } else {
            // USER
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell {
                
                cell.contentView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
                cell.tableShare = tableShare
                cell.delegate = self
                cell.labelTitle.text = tableShare.shareWithDisplayname
                cell.labelTitle.textColor = NCBrandColor.shared.label
                cell.labelCanEdit.text = NSLocalizedString("_share_permission_edit_", comment: "")
                cell.labelCanEdit.textColor = NCBrandColor.shared.iconColor
                cell.isUserInteractionEnabled = true
                cell.switchCanEdit.isHidden = true//false
                cell.labelCanEdit.isHidden = true//false
                cell.buttonMenu.isHidden = false
                cell.imageItem.image = NCShareCommon.shared.getImageShareType(shareType: tableShare.shareType)
                cell.indexSelected = indexPath.row - 1
                cell.btnQuickStatus.tag = indexPath.row - 1
                
                let status = NCUtility.shared.getUserStatus(userIcon: tableShare.userIcon, userStatus: tableShare.userStatus, userMessage: tableShare.userMessage)
                cell.imageStatus.image = status.onlineStatus
                cell.status.text = status.statusMessage
                
                let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + tableShare.shareWith + ".png"
                
                if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                    if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                        
                    }
                }
                
                if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                    cell.switchCanEdit.setOn(true, animated: false)
                } else {
                    cell.switchCanEdit.setOn(false, animated: false)
                }
                
                // If the initiator or the recipient is not the current user, show the list of sharees without any options to edit it.
                if tableShare.uidOwner != self.appDelegate.userId && tableShare.uidFileOwner != self.appDelegate.userId {
                    cell.isUserInteractionEnabled = false
                    cell.switchCanEdit.isHidden = true
                    cell.labelCanEdit.isHidden = true
                    cell.buttonMenu.isHidden = true
                }
                cell.btnQuickStatus.setTitle("", for: .normal)
                cell.btnQuickStatus.contentHorizontalAlignment = .left
                
                cell.labelQuickStatus.textColor = NCBrandColor.shared.brand
                cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.brand)
                cell.btnQuickStatus.isEnabled = true
                
                if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
                    cell.labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
                } else {
                    // Read Only
                    if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
                    } else {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
                    }
                }
                
                let isEditingAllowed = NCShareCommon.shared.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.ext ?? "", shareType: tableShare.shareType)
                if isEditingAllowed {
                    cell.btnQuickStatus.isEnabled = true
                } else {
                    cell.btnQuickStatus.isEnabled = false
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.quickStatusTextColor
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.quickStatusTextColor)
                }
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    //    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return "Share Header"
    //    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = Bundle.main.loadNibNamed("NCShareHeaderView", owner: self, options: nil)?.first as! NCShareHeaderView
        headerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        headerView.fileName.textColor = NCBrandColor.shared.label
        headerView.labelSharing.textColor = NCBrandColor.shared.label
        headerView.labelSharingInfo.textColor = NCBrandColor.shared.label
        headerView.info.textColor = NCBrandColor.shared.systemGray2
        headerView.ocId = metadata!.ocId
        headerView.updateCanReshareUI()
        
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
            //            headerView.imageView.image = UIImage.init(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag))
            //            headerView.fullWidthImageView.image = UIImage.init(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag))
            //            headerView.fullWidthImageView.image = getImage(metadata: metadata!)
            headerView.fullWidthImageView.image = getImageMetadata(metadata!)
            headerView.fullWidthImageView.contentMode = .scaleAspectFill
            headerView.imageView.isHidden = true
        } else {
            if metadata!.directory {
                headerView.imageView.image = UIImage.init(named: "folder")!
                //                let image = UIImage.init(named: "folder")!
                //                headerView.imageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
            } else if metadata!.iconName.count > 0 {
                headerView.imageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                headerView.imageView.image = UIImage.init(named: "file")
            }
        }
        headerView.fileName.text = metadata?.fileNameView
        headerView.fileName.textColor = NCBrandColor.shared.label
        if metadata!.favorite {
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
        } else {
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
        }
        headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        return headerView
        
    }
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 320
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 320
    }
    
}

// MARK: - NCShareUserCell

class NCShareUserCell: UITableViewCell {
    
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelCanEdit: UILabel!
    @IBOutlet weak var switchCanEdit: UISwitch!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var btnQuickStatus: UIButton!
    
    @IBOutlet weak var labelQuickStatus: UILabel!
    @IBOutlet weak var imageDownArrow: UIImageView!
    var indexSelected: Int?
    
    var tableShare: tableShare?
    weak var delegate: NCShareUserCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        switchCanEdit.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanEdit.onTintColor = NCBrandColor.shared.brandElement
        buttonMenu.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 24), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.customer
        imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.customer)
    }
    
    @IBAction func switchCanEditChanged(sender: UISwitch) {
        delegate?.switchCanEdit(with: tableShare, switch: sender.isOn, sender: sender)
    }
    
    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender, index: indexSelected!)
    }
    
    @IBAction func quickStatusClicked(_ sender: UIButton) {
        delegate?.quickStatus(with: tableShare, sender: sender)
    }
}

protocol NCShareUserCellDelegate: AnyObject {
    func switchCanEdit(with tableShare: tableShare?, switch: Bool, sender: UISwitch)
    func tapMenu(with tableShare: tableShare?, sender: Any, index: Int)
    func quickStatus(with tableShare: tableShare?, sender: UIButton)
}

// MARK: - NCShareUserDropDownCell

class NCShareUserDropDownCell: DropDownCell {
    
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var imageStatus: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var imageShareeType: UIImageView!
    @IBOutlet weak var centerTitle: NSLayoutConstraint!
}

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 10, y: 515, width: self.bounds.size.width, height: 20))
        messageLabel.text = message
        messageLabel.textColor = NCBrandColor.shared.textInfo
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 17)
        messageLabel.tag = 999
        messageLabel.sizeToFit()
        self.addSubview(messageLabel)
    }
    
    func restore() {
        self.backgroundView = nil
        self.subviews.forEach({ $0.removeFromSuperview() })
    }
}

enum Tag {
    static let searchField = 999
}

class NCShareEmailFieldCell: UITableViewCell {
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var btnCreateLink: UIButton!
    @IBOutlet weak var labelYourShare: UILabel!
    @IBOutlet weak var labelShareByMail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    func setupCell(){
        self.btnCreateLink.setTitle(NSLocalizedString("_create_link_", comment: ""), for: .normal)
        self.btnCreateLink.layer.cornerRadius = 7
        self.btnCreateLink.layer.masksToBounds = true
        self.btnCreateLink.layer.borderWidth = 1
        self.btnCreateLink.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.btnCreateLink.titleLabel!.adjustsFontSizeToFitWidth = true
        self.btnCreateLink.titleLabel!.minimumScaleFactor = 0.5
        self.btnCreateLink.layer.borderColor = NCBrandColor.shared.label.cgColor
        self.btnCreateLink.setTitleColor(NCBrandColor.shared.label, for: .normal)
        self.btnCreateLink.backgroundColor = .clear
        
        self.labelShareByMail.text = NSLocalizedString("personal_share_by_mail", comment: "")
        self.labelShareByMail.textColor = NCBrandColor.shared.shareByEmailTextColor
        
        labelYourShare.text = NSLocalizedString("_your_shares_", comment: "")
        
        searchField.layer.cornerRadius = 5
        searchField.layer.masksToBounds = true
        searchField.layer.borderWidth = 1
        self.searchField.text = ""
        searchField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("_shareLinksearch_placeholder_", comment: ""),
                                                               attributes: [NSAttributedString.Key.foregroundColor: NCBrandColor.shared.searchFieldPlaceHolder])
        searchField.textColor = NCBrandColor.shared.label
        searchField.layer.borderColor = NCBrandColor.shared.label.cgColor
        searchField.tag = Tag.searchField
        setDoneButton(sender: searchField)
    }
    
    @objc func cancelDatePicker() {
        self.searchField.endEditing(true)
    }
    
    func setDoneButton(sender: UITextField) {
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("_done_", comment: ""), style: .plain, target: self, action: #selector(cancelDatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton, doneButton], animated: false)
        sender.inputAccessoryView = toolbar
    }
}
