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

import Foundation
import Parchment
import DropDown
import NCCommunication

class NCShare: UIViewController, UIGestureRecognizerDelegate, NCShareLinkCellDelegate, NCShareUserCellDelegate, NCShareNetworkingDelegate {
   
    @IBOutlet weak var viewContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var sharedWithYouByView: UIView!
    @IBOutlet weak var sharedWithYouByImage: UIImageView!
    @IBOutlet weak var sharedWithYouByLabel: UILabel!
    @IBOutlet weak var searchFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var shareLinkImage: UIImageView!
    @IBOutlet weak var shareLinkLabel: UILabel!
    @IBOutlet weak var shareInternalLinkImage: UIImageView!
    @IBOutlet weak var shareInternalLinkLabel: UILabel!
    @IBOutlet weak var shareInternalLinkDescription: UILabel!
    @IBOutlet weak var buttonInternalCopy: UIButton!
    @IBOutlet weak var buttonCopy: UIButton!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnCreateLink: UIButton!
    
    
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
    public var tableShareSelected: tableShare?
    private var quickStatusTableShare: tableShare!
    private var sendEmailSelected: Int!
    private var shareeEmail: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewContainerConstraint.constant = height
        searchFieldTopConstraint.constant = 10
                
        searchField.placeholder = NSLocalizedString("_shareLinksearch_placeholder_", comment: "")
        
        self.btnCreateLink.setTitle(NSLocalizedString("_create_link_", comment: ""), for: .normal)
        self.btnCreateLink.layer.cornerRadius = 5
        self.btnCreateLink.layer.masksToBounds = true
        self.btnCreateLink.layer.borderWidth = 1
        self.btnCreateLink.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        self.btnCreateLink.setTitleColor(NCBrandColor.shared.icon, for: .normal)
        self.btnCreateLink.backgroundColor = NCBrandColor.shared.backgroundView
//        shareLinkImage.image = NCShareCommon.shared.createLinkAvatar(imageName: "sharebylink", colorCircle: NCBrandColor.shared.brandElement)
        shareLinkImage.image = UIImage(named: "sharebylink")?.image(color: NCBrandColor.shared.icon, size: 30)
        shareLinkImage.image = NCShareCommon.shared.createLinkAvatar(imageName: "sharebylink", colorCircle: NCBrandColor.shared.brandElement)
        shareLinkLabel.text = NSLocalizedString("_share_link_", comment: "")
        buttonCopy.setImage(UIImage.init(named: "shareCopy")?.image(color: .gray, size: 50), for: .normal)

        shareInternalLinkImage.image = NCShareCommon.shared.createLinkAvatar(imageName: "shareInternalLink", colorCircle: .gray)
        shareInternalLinkLabel.text = NSLocalizedString("_share_internal_link_", comment: "")
        shareInternalLinkDescription.text = NSLocalizedString("_share_internal_link_des_", comment: "")
        buttonInternalCopy.setImage(UIImage.init(named: "shareCopy")?.image(color: .gray, size: 50), for: .normal)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false

        tableView.register(UINib.init(nibName: "NCShareLinkCell", bundle: nil), forCellReuseIdentifier: "cellLink")
        tableView.register(UINib.init(nibName: "NCShareUserCell", bundle: nil), forCellReuseIdentifier: "cellUser")
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataNCShare), object: nil)
        
        // Shared with you by ...
        if metadata!.ownerId != self.appDelegate.userId {
            
            searchFieldTopConstraint.constant = 65
            sharedWithYouByView.isHidden = false
            sharedWithYouByLabel.text = NSLocalizedString("_shared_with_you_by_", comment: "") + " " + metadata!.ownerDisplayName
            sharedWithYouByImage.image = UIImage(named: "avatar")

            let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + metadata!.ownerId + ".png"
            if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                    sharedWithYouByImage.image = NCUtility.shared.createAvatar(image: image, size: 40)
                }
            } else {
                NCCommunication.shared.downloadAvatar(userID: metadata!.ownerId, fileNameLocalPath: fileNameLocalPath, size: NCGlobal.shared.avatarSize) { (account, data, errorCode, errorMessage) in
                    if errorCode == 0 && account == self.appDelegate.account && UIImage(data: data!) != nil {
                        if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                            self.sharedWithYouByImage.image = NCUtility.shared.createAvatar(image: image, size: 40)
                        }
                    } 
                }
            }
        } 
        
        reloadData()
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase, view: self.view, delegate: self)
        if sharingEnabled {
            networking?.readShare()
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

        NotificationCenter.default.addObserver(self, selector: #selector(statusReadOnlyClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusReadOnly), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusEditingClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusEditing), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusFileDropClicked), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterStatusFileDrop), object: nil)
        
        changeTheming()
    }
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.reloadData()
        shareLinkLabel.textColor = NCBrandColor.shared.textView
    }
        
    @objc func reloadData() {
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        if shares.firstShareLink == nil {
//            buttonMenu.setImage(UIImage.init(named: "shareAdd")?.image(color: .gray, size: 50), for: .normal)
            buttonCopy.isHidden = true
        } else {
            buttonMenu.setImage(UIImage.init(named: "shareMenu")?.image(color: .gray, size: 50), for: .normal)
            buttonCopy.isHidden = false
        }
        tableView.reloadData()
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

        guard let metadata = self.metadata else { return }
        let isFilesSharingPublicPasswordEnforced = NCManageDatabase.shared.getCapabilitiesServerBool(account: metadata.account, elements: NCElementsJSON.shared.capabilitiesFileSharingPubPasswdEnforced, exists: false)
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)

        if isFilesSharingPublicPasswordEnforced && shares.firstShareLink == nil {
            let alertController = UIAlertController(title: NSLocalizedString("_enforce_password_protection_", comment: ""), message: "", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.isSecureTextEntry = true
            }
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default) { (action:UIAlertAction) in })
            let okAction = UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { (action:UIAlertAction) in
                let password = alertController.textFields?.first?.text
                self.networking?.createShareLink(password: password ?? "")
            }
            
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion:nil)
        } else if shares.firstShareLink == nil {
//            networking?.createShareLink(password: "")
        } else {
            tapMenu(with: shares.firstShareLink!, sender: sender, index: 0)
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
        
        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
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
        
        self.tableShareSelected = tableShare
        self.sendEmailSelected = index
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
            shareMenu.toggleMenu(viewController: self, sendMail: false)
            
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
            shareMenu.toggleMenu(viewController: self, sendMail: true)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkMenuViewWindow))
            tap.delegate = self
        }
    }

    
//    func quickStatus(with tableShare: tableShare?, sender: Any) {
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
    
//    func quickStatus(with tableShare: tableShare?, sender: Any) {
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
    
    func unShareCompleted() { }
    
    func updateShareWithError(idShare: Int) {
        self.reloadData()
    }
    
    func getSharees(sharees: [NCCommunicationSharee]?) {
        
        guard let sharees = sharees else { return }

        dropDown = DropDown()
        let appearance = DropDown.appearance()
        
        appearance.backgroundColor = NCBrandColor.shared.backgroundForm
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
        dropDown.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
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

            let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(self.appDelegate.user, urlBase: self.appDelegate.urlBase)) + "-" + sharee.label + ".png"
            if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                    cell.imageItem.image = NCUtility.shared.createAvatar(image: image, size: 30)
                }
            } else {
                NCCommunication.shared.downloadAvatar(userID: sharee.shareWith, fileNameLocalPath: fileNameLocalPath, size: NCGlobal.shared.avatarSize) { (account, data, errorCode, errorMessage) in
                    if errorCode == 0 && account == self.appDelegate.account && UIImage(data: data!) != nil {
                        if let image = UIImage(contentsOfFile: fileNameLocalPath) {
                            DispatchQueue.main.async {
                                cell.imageItem.image = NCUtility.shared.createAvatar(image: image, size: 30)
                            }
                        }
                    }
                }
            }

            cell.imageShareeType.image = NCShareCommon.shared.getImageShareType(shareType: sharee.shareType)
        }
        
        dropDown.selectionAction = { [weak self] (index, item) in
            let sharee = sharees[index]
            let directory = self!.metadata?.directory
            let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
            DispatchQueue.main.async() { [self] in
                var viewNewUserPermission: NCShareNewUserPermission
//                if directory! {
////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
//                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFolderPermission") as! NCShareNewUserPermission
//                } else {
////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
//                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFilePermission") as! NCShareNewUserPermission
//                }
//                if directory! {
//                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserPermission") as! NCShareNewUserPermission
//                } else {
////                    let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
//                    viewNewUserPermission = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserFilePermission") as! NCShareNewUserPermission
//                }
                
                viewNewUserPermission.metadata = self!.metadata
                viewNewUserPermission.sharee = sharee
                viewNewUserPermission.shareeEmail = self?.shareeEmail
                self?.navigationController!.pushViewController(viewNewUserPermission, animated: true)
            }
//            self!.networking?.createShare(shareWith: sharee.shareWith, shareType: sharee.shareType, metadata: self!.metadata!)
        }
        
        dropDown.show()
    }
    
    @IBAction func createLinkClicked(_ sender: Any) {
        buttonMenu.isHidden = false
        networking?.createShareLink(password: "")
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
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        let directory = self.metadata?.directory
//        if directory! {
//            let shareFolderOptions = storyboard.instantiateViewController(withIdentifier: "NCShareFolderOptions") as! NCShareFolderOptions
//            shareFolderOptions.metadata = self.metadata
//            shareFolderOptions.tableShare = self.tableShareSelected
//    //        shareFolderOptions.sharee = sharee
//            self.navigationController!.pushViewController(shareFolderOptions, animated: true)
//        } else {
            let shareFileOptions = storyboard.instantiateViewController(withIdentifier: "NCShareFileOptions") as! NCShareFileOptions
            shareFileOptions.metadata = self.metadata
            shareFileOptions.tableShare = self.tableShareSelected
            shareFileOptions.sharee = self.shareeSelected
            guard let navigationController = navigationController else {
                print("this vc is not embedded in navigationController")
                return
            }
            navigationController.pushViewController(shareFileOptions, animated: true)
//        }
    }
    
    @objc func shareMenuSendEmailClicked() {
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        let sendEmail = storyboard.instantiateViewController(withIdentifier: "NCShareSendEmail") as! NCShareSendEmail
        sendEmail.metadata = self.metadata
        sendEmail.tableShare = self.tableShareSelected
//        viewNewUserComment.password = self.password
//        self.navigationController!.pushViewController(viewNewUserComment, animated: true)
        guard let navigationController = navigationController else {
            print("this vc is not embedded in navigationController")
            return
        }
        navigationController.pushViewController(sendEmail, animated: true)
    }
    
    @objc func shareMenuUnshareClicked() {
        guard let tableShare = self.tableShareSelected else { return }
        networking?.unShare(idShare: tableShare.idShare)
    }
    
    // MARK: -StatusChangeNotification
    func quickStatus(with tableShare: tableShare?, sender: Any) {
        guard let tableShare = tableShare else { return }
        
        self.quickStatusTableShare = tableShare
        let quickStatusMenu = NCShareQuickStatusMenu()
        //            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, status: tableShare.permissions)
        quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, directoryType: metadata!.typeFile, status: tableShare.permissions)
    }

    
    func quickStatusLink(with tableShare: tableShare?, sender: Any) {
        guard let tableShare = tableShare else { return }
        
        self.quickStatusTableShare = tableShare
        if metadata?.typeFile == "document" {
            self.quickStatusTableShare = tableShare
            let quickStatusMenu = NCShareQuickStatusMenu()
            quickStatusMenu.toggleMenu(viewController: self, directory: metadata!.directory, directoryType: metadata!.typeFile, status: tableShare.permissions)
        }
    }
    
    @objc func statusReadOnlyClicked() {
        let permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata!.directory)
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
    
    @objc func statusEditingClicked() {
        let permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata!.directory)
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
    
    @objc func statusFileDropClicked() {
        let permission = NCGlobal.shared.permissionCreateShare
        
        networking?.updateShare(idShare: self.quickStatusTableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: self.quickStatusTableShare.hideDownload)
    }
}

// MARK: - UITableViewDelegate

extension NCShare: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITableViewDataSource

extension NCShare: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numOfRows = 0
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        
        if shares.share != nil {
            numOfRows = shares.share!.count
        }
        if numOfRows == 0 {
            self.tableView.setEmptyMessage(NSLocalizedString("no_shares_created", comment: ""))
        } else {
            self.tableView.restore()
        }

        return numOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata!)
        let tableShare = shares.share![indexPath.row]
        
        // LINK
        if tableShare.shareType == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell {
                cell.tableShare = tableShare
                cell.delegate = self
//                let linkText = UserDefaults.standard.value(forKey: "_share_link_") as! String
                if let linkText = UserDefaults.standard.value(forKey: "_share_link_") as? String {
                    cell.labelTitle.text = linkText
                } else {
                    cell.labelTitle.text = NSLocalizedString("_share_link_", comment: "")
                }
                cell.labelTitle.textColor = NCBrandColor.shared.textView
                cell.indexSelected = indexPath.row
                cell.buttonMenu.isEnabled = false
                cell.buttonMenu.isHidden = true
                
                if self.metadata?.typeFile != "document" {
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.graySoft
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.graySoft)
                } else {
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.brand
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.brand)
                }
                
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
                return cell
            }
        } else {
        // USER
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell {
                
                cell.tableShare = tableShare
                cell.delegate = self
                cell.labelTitle.text = tableShare.shareWithDisplayname
                cell.labelTitle.textColor = NCBrandColor.shared.textView
                cell.labelCanEdit.text = NSLocalizedString("_share_permission_edit_", comment: "")
                cell.labelCanEdit.textColor = NCBrandColor.shared.textView
                cell.isUserInteractionEnabled = true
                cell.switchCanEdit.isHidden = true//false
                cell.labelCanEdit.isHidden = true//false
                cell.buttonMenu.isHidden = false
                cell.imageItem.image = NCShareCommon.shared.getImageShareType(shareType: tableShare.shareType)
                cell.indexSelected = indexPath.row
                
                let status = NCUtility.shared.getUserStatus(userIcon: tableShare.userIcon, userStatus: tableShare.userStatus, userMessage: tableShare.userMessage)
                cell.imageStatus.image = status.onlineStatus
                cell.status.text = status.statusMessage
                
                let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + String(CCUtility.getStringUser(appDelegate.user, urlBase: appDelegate.urlBase)) + "-" + tableShare.shareWith + ".png"
                if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                    if let image = UIImage(contentsOfFile: fileNameLocalPath) {
//                        cell.imageItem.image = NCUtility.shared.createAvatar(image: image, size: 40)
                        cell.imageItem.image = UIImage(named: "user")?.image(color: NCBrandColor.shared.icon, size: 30)
                    }
                } else {
                    NCCommunication.shared.downloadAvatar(userID: tableShare.shareWith, fileNameLocalPath: fileNameLocalPath, size: NCGlobal.shared.avatarSize) { (account, data, errorCode, errorMessage) in
                        if errorCode == 0 && account == self.appDelegate.account && UIImage(data: data!) != nil {
                            if let image = UIImage(contentsOfFile: fileNameLocalPath) {
//                                cell.imageItem.image = NCUtility.shared.createAvatar(image: image, size: 40)
                                cell.imageItem.image = UIImage(named: "user")?.image(color: NCBrandColor.shared.icon, size: 30)
                            }
                        }
                    }
                }
                
                if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                    cell.switchCanEdit.setOn(true, animated: false)
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_editing_", comment: ""), for: .normal)
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
                
                if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_file_drop_", comment: ""), for: .normal)
                    cell.labelQuickStatus.text = NSLocalizedString("_share_file_drop_", comment: "")
                } else {
                    // Read Only
                    if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
                    } else {
                        cell.labelQuickStatus.text = NSLocalizedString("_share_read_only_", comment: "")
                    }
                }
                
//                if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_file_drop_", comment: ""), for: .normal)
//                }
//                else if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_editing_", comment: ""), for: .normal)
//                } else {
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_read_only_", comment: ""), for: .normal)
//                }
//                if CCUtility.isPermission(toRead: tableShare.permissions) {
//                    cell.btnQuickStatus.setTitle(NSLocalizedString("_share_read_only_", comment: ""), for: .normal)
//                }
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
}

// MARK: - NCShareLinkCell

class NCShareLinkCell: UITableViewCell {
    
    @IBOutlet weak var imageItem: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonCopy: UIButton!
    @IBOutlet weak var buttonMenu: UIButton!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var btnQuickStatus: UIButton!
    @IBOutlet weak var imageDownArrow: UIImageView!
    @IBOutlet weak var labelQuickStatus: UILabel!
    
    private let iconShare: CGFloat = 200
    var indexSelected: Int?
    
    var tableShare: tableShare?
    var delegate: NCShareLinkCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        imageItem.image = NCShareCommon.shared.createLinkAvatar(imageName: "sharebylink", colorCircle: NCBrandColor.shared.brandElement)
        imageItem.image = UIImage(named: "sharebylink")?.image(color: NCBrandColor.shared.icon, size: 30)
        buttonCopy.setImage(UIImage.init(named: "shareCopy")!.image(color: NCBrandColor.shared.customer, size: 50), for: .normal)
//        buttonMenu.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 50), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.customer
//        imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.customer)
    }
    
    @IBAction func touchUpInsideCopy(_ sender: Any) {
        delegate?.tapCopy(with: tableShare, sender: sender)
    }
    
    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender, index: indexSelected!)
    }
    
    @IBAction func quickStatusClicked(_ sender: Any) {
        delegate?.quickStatusLink(with: tableShare, sender: sender)
    }
}

protocol NCShareLinkCellDelegate {
    func tapCopy(with tableShare: tableShare?, sender: Any)
    func tapMenu(with tableShare: tableShare?, sender: Any, index: Int)
    func quickStatusLink(with tableShare: tableShare?, sender: Any)
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
    var delegate: NCShareUserCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        switchCanEdit.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanEdit.onTintColor = NCBrandColor.shared.brandElement
//        buttonMenu.setImage(UIImage.init(named: "shareMenu")!.image(color: NCBrandColor.shared.customer, size: 50), for: .normal)
        labelQuickStatus.textColor = NCBrandColor.shared.customer
        imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.customer)
    }
    
    @IBAction func switchCanEditChanged(sender: UISwitch) {
        delegate?.switchCanEdit(with: tableShare, switch: sender.isOn, sender: sender)
    }
    
    @IBAction func touchUpInsideMenu(_ sender: Any) {
        delegate?.tapMenu(with: tableShare, sender: sender, index: indexSelected!)
    }
    
    @IBAction func quickStatusClicked(_ sender: Any) {
        delegate?.quickStatus(with: tableShare, sender: sender)
    }
}

protocol NCShareUserCellDelegate {
    func switchCanEdit(with tableShare: tableShare?, switch: Bool, sender: UISwitch)
    func tapMenu(with tableShare: tableShare?, sender: Any, index: Int)
    func quickStatus(with tableShare: tableShare?, sender: Any)
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
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
