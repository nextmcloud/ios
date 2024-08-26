//
//  NCShare.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 17/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
//  Copyright © 2022 Henrik Storch. All rights reserved.
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
import DropDown
import NextcloudKit
import MarqueeLabel
import ContactsUI

class NCShare: UIViewController, NCShareNetworkingDelegate, NCSharePagingContent {

    var textField: UITextField? { self.view.viewWithTag(Tag.searchField) as? UITextField }

    @IBOutlet weak var tableView: UITableView!

    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate

    public var metadata: tableMetadata!
    public var sharingEnabled = true
    public var height: CGFloat = 0
    let shareCommon = NCShareCommon()
    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()
    let database = NCManageDatabase.shared

    var canReshare: Bool {
        guard let metadata = metadata else { return true }
        return ((metadata.sharePermissionsCollaborationServices & NCPermissions().permissionShareShare) != 0)
    }

    var session: NCSession.Session {
        NCSession.shared.getSession(account: metadata.account)
    }

    var shares: (firstShareLink: tableShare?, share: [tableShare]?) = (nil, nil)

    private var dropDown = DropDown()
    var networking: NCShareNetworking?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .secondarySystemGroupedBackground

        tableView.register(UINib(nibName: "NCShareLinkCell", bundle: nil), forCellReuseIdentifier: "cellLink")
        tableView.register(UINib(nibName: "NCShareUserCell", bundle: nil), forCellReuseIdentifier: "cellUser")
        tableView.register(UINib(nibName: "NCShareEmailFieldCell", bundle: nil), forCellReuseIdentifier: "NCShareEmailFieldCell")

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataNCShare), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        guard let metadata = metadata else { return }
        
        reloadData()

        networking = NCShareNetworking(metadata: metadata, view: self.view, delegate: self, session: session)
        if sharingEnabled {
            let isVisible = (self.navigationController?.topViewController as? NCSharePaging)?.page == .sharing
            networking?.readShare(showLoadingIndicator: isVisible)
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: .done, target: self, action: #selector(exitTapped))
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }

    @objc func exitTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func makeNewLinkShare() {
        guard
            let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
            let navigationController = self.navigationController else { return }
        self.checkEnforcedPassword(shareType: shareCommon.SHARE_TYPE_LINK) { password in
            advancePermission.networking = self.networking
            advancePermission.share = NCTableShareOptions.shareLink(metadata: self.metadata, password: password)
            advancePermission.metadata = self.metadata
            navigationController.pushViewController(advancePermission, animated: true)
        }
    }

    // MARK: - Notification Center

    @objc func openShareProfile() {
        self.showProfileMenu(userId: metadata.ownerId, session: session)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if UIDevice.current.userInterfaceIdiom == .phone {
           if (UIScreen.main.bounds.width < 374 || UIDevice.current.orientation.isLandscape) {
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    if view.frame.origin.y == 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        self.view.frame.origin.y -= keyboardSize.height
                    }
                }
            } else if UIScreen.main.bounds.height < 850 {
                if view.frame.origin.y == 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    self.view.frame.origin.y -= 70
                }
            } else {
                if view.frame.origin.y == 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    self.view.frame.origin.y -= 40
                }
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad, UIDevice.current.orientation.isLandscape {
            if view.frame.origin.y == 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                self.view.frame.origin.y -= 230
            }
        }
        textField?.layer.borderColor = NCBrandColor.shared.brand.cgColor
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
        textField?.layer.borderColor = NCBrandColor.shared.label.cgColor
    }

    @objc func appWillEnterForeground(notification: Notification) {
        reloadData()
    }
    // MARK: -

    @objc func reloadData() {
        shares = self.database.getTableShares(metadata: metadata)
        tableView.reloadData()
    }

    // MARK: - IBAction

    @IBAction func searchFieldDidEndOnExit(textField: UITextField) {
        guard let searchString = textField.text, !searchString.isEmpty else { return }
        if searchString.contains("@"), !utility.isValidEmail(searchString) { return }
        networking?.getSharees(searchString: searchString)
    }
    
    @IBAction func searchFieldDidChange(textField: UITextField) {
        guard let searchString = textField.text else {return}
        if searchString.count == 0 {
            dropDown.hide()
        } else {
            networking?.getSharees(searchString: searchString)
        }
    }
    
    @IBAction func createLinkClicked(_ sender: Any) {
        appDelegate?.adjust.trackEvent(TriggerEvent(CreateLink.rawValue))
        TealiumHelper.shared.trackEvent(title: "magentacloud-app.sharing.create", data: ["": ""])
        self.touchUpInsideButtonMenu(sender)
    }
    
    @IBAction func touchUpInsideButtonMenu(_ sender: Any) {
        
        guard let metadata = metadata else { return }
        let isFilesSharingPublicPasswordEnforced = NCGlobal.shared.capabilityFileSharingPubPasswdEnforced
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
            networking?.createShareLink(password: "")
        }
        
    }
    
    @IBAction func selectContactClicked(_ sender: Any) {
        let cnPicker = CNContactPickerViewController()
        cnPicker.delegate = self
        cnPicker.displayedPropertyKeys = [CNContactEmailAddressesKey]
        cnPicker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        cnPicker.predicateForSelectionOfProperty = NSPredicate(format: "emailAddresses.@count > 0")
        
        self.present(cnPicker, animated: true)
    }
    
    func checkEnforcedPassword(shareType: Int, completion: @escaping (String?) -> Void) {
        guard NCCapabilities.shared.getCapabilities(account: session.account).capabilityFileSharingPubPasswdEnforced,
              shareType == shareCommon.SHARE_TYPE_LINK || shareType == shareCommon.SHARE_TYPE_EMAIL
        else { return completion(nil) }

        self.present(UIAlertController.password(titleKey: "_enforce_password_protection_", completion: completion), animated: true)
    }

    // MARK: - NCShareNetworkingDelegate

    func readShareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }

    func shareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
        self.reloadData()
    }

    func unShareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
        self.reloadData()
    }

    func updateShareWithError(idShare: Int) {
        self.reloadData()
    }

    func getSharees(sharees: [NKSharee]?) {
        guard let sharees else { return }

        dropDown = DropDown()
        let appearance = DropDown.appearance()

        appearance.backgroundColor = .secondarySystemGroupedBackground
        appearance.cornerRadius = 10
        appearance.shadowColor = UIColor(white: 0.5, alpha: 1)
        appearance.shadowOpacity = 0.9
        appearance.shadowRadius = 25
        appearance.animationduration = 0.25
        appearance.textColor = .darkGray
        appearance.setupMaskedCorners([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])

        for sharee in sharees {
            var label = sharee.label
            if sharee.shareType == shareCommon.SHARE_TYPE_CIRCLE {
                label += " (\(sharee.circleInfo), \(sharee.circleOwner))"
            }
            dropDown.dataSource.append(label)
        }

        dropDown.anchorView = textField
        dropDown.bottomOffset = CGPoint(x: 0, y: textField?.bounds.height ?? 0)
        dropDown.width = textField?.bounds.width ?? 0
        if (UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.orientation.isLandscape), UIScreen.main.bounds.width < 1111  {
            dropDown.topOffset = CGPoint(x: 0, y: -(textField?.bounds.height ?? 0))
            dropDown.direction = .top
        } else {
            dropDown.bottomOffset = CGPoint(x: 0, y: (textField?.bounds.height ?? 0) - 80)
            dropDown.direction = .any
        }

        dropDown.cellNib = UINib(nibName: "NCSearchUserDropDownCell", bundle: nil)
        dropDown.customCellConfiguration = { (index: Index, _, cell: DropDownCell) -> Void in
            guard let cell = cell as? NCSearchUserDropDownCell else { return }
            let sharee = sharees[index]
            cell.setupCell(sharee: sharee, session: self.session)
        }

        dropDown.selectionAction = { index, _ in
            self.textField?.text = ""
            self.textField?.resignFirstResponder()
            let sharee = sharees[index]
            guard
                let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
                let navigationController = self.navigationController else { return }
            self.checkEnforcedPassword(shareType: sharee.shareType) { password in
                let shareOptions = NCTableShareOptions(sharee: sharee, metadata: self.metadata, password: password)
                advancePermission.share = shareOptions
                advancePermission.networking = self.networking
                advancePermission.metadata = self.metadata
                navigationController.pushViewController(advancePermission, animated: true)
            }
        }

        dropDown.show()
    }
    
    func checkIsCollaboraFile() -> Bool {
        guard let metadata = metadata else {
            return false
        }
        
        // EDITORS
        let editors = utility.editorsDirectEditing(account: metadata.account, contentType: metadata.contentType)
        let availableRichDocument = utility.isTypeFileRichDocument(metadata)
        
        // RichDocument: Collabora
        return (availableRichDocument && editors.count == 0)
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
        var numOfRows = 0
        if let metadataobj = metadata {
            shares = NCManageDatabase.shared.getTableShares(metadata: metadataobj)
        }
        if let shareLink = shares.firstShareLink {
            shares.share?.insert(shareLink, at: 0)
        }
        
        if shares.share != nil {
            numOfRows = shares.share!.count
        }
        return canReshare ? (numOfRows + 1) : numOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NCShareEmailFieldCell", for: indexPath) as? NCShareEmailFieldCell  else { return UITableViewCell() }
            cell.searchField.addTarget(self, action: #selector(searchFieldDidEndOnExit(textField:)), for: .editingDidEndOnExit)
            cell.searchField.addTarget(self, action: #selector(searchFieldDidChange(textField:)), for: .editingChanged)
            cell.btnCreateLink.addTarget(self, action: #selector(createLinkClicked(_:)), for: .touchUpInside)
            cell.btnContact.addTarget(self, action: #selector(selectContactClicked(_:)), for: .touchUpInside)
            cell.labelNoShare.isHidden = (shares.share?.count ?? 0) > 0
            cell.heightLabelNoShare.constant = (shares.share?.count ?? 0) > 0 ? 0 : 25
            return cell
        }
        
        let directory = self.metadata?.directory ?? false
        guard let appDelegate = appDelegate, let tableShare = shares.share?[indexPath.row - 1] else { return UITableViewCell() }

        // LINK
        if tableShare.shareType == shareCommon.SHARE_TYPE_LINK {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell
            else { return UITableViewCell() }
            cell.tableShare = tableShare
            cell.delegate = self
            cell.setupCellUI()
            if !tableShare.label.isEmpty {
                cell.labelTitle.text = String(format: NSLocalizedString("_share_linklabel_", comment: ""), tableShare.label)
            } else {
                cell.labelTitle.text = directory ? NSLocalizedString("_share_link_folder_", comment: "") : NSLocalizedString("_share_link_file_", comment: "")
            }
            let isEditingAllowed = shareCommon.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.fileExtension ?? "", shareType: tableShare.shareType)
            if isEditingAllowed || directory || checkIsCollaboraFile() {
                cell.btnQuickStatus.isEnabled = true
                cell.labelQuickStatus.textColor = NCBrandColor.shared.brand
                cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.brand)
            } else {
                cell.btnQuickStatus.isEnabled = false
                cell.labelQuickStatus.textColor = NCBrandColor.shared.optionItem
                cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.optionItem)
            }
            
            return cell
        } else {
        // USER / GROUP etc.
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell {
                cell.tableShare = tableShare
                cell.delegate = self
                cell.setupCellUI(userId: appDelegate.userId)
                let isEditingAllowed = shareCommon.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.fileExtension ?? "", shareType: tableShare.shareType)
                if isEditingAllowed || checkIsCollaboraFile() {
                    cell.btnQuickStatus.isEnabled = true
                } else {
                    cell.btnQuickStatus.isEnabled = false
                    cell.labelQuickStatus.textColor = NCBrandColor.shared.optionItem
                    cell.imageDownArrow.image = UIImage(named: "downArrow")?.imageColor(NCBrandColor.shared.optionItem)
                }
                return cell
            }
        }

        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = Bundle.main.loadNibNamed("NCShareHeaderView", owner: self, options: nil)?.first as? NCShareHeaderView else {
            return UIView()
        }
        headerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        headerView.fileName.textColor = NCBrandColor.shared.label
        headerView.labelSharing.textColor = NCBrandColor.shared.label
        headerView.labelSharingInfo.textColor = NCBrandColor.shared.label
        headerView.info.textColor = NCBrandColor.shared.systemGray2
        headerView.ocId = metadata!.ocId
        headerView.updateCanReshareUI()
        
        
        if FileManager.default.fileExists(atPath: utilityFileSystem.getDirectoryProviderStorageIconOcId(metadata?.ocId ?? "", etag: metadata?.etag ?? "")) {
            headerView.fullWidthImageView.image = UIImage(contentsOfFile: utilityFileSystem.getDirectoryProviderStorageIconOcId(metadata?.ocId ?? "", etag: metadata?.etag ?? ""))
            headerView.fullWidthImageView.contentMode = .scaleAspectFill
            headerView.imageView.isHidden = true
        } else {
            if metadata?.directory ?? false {
                let image = (metadata?.e2eEncrypted ?? false) ? UIImage(named: "folderEncrypted") : UIImage(named: "folder_nmcloud")
                headerView.imageView.image = image
            } else if !(metadata?.iconName.isEmpty ?? false) {
                headerView.imageView.image = metadata!.fileExtension == "odg" ? UIImage(named: "file-diagram") : UIImage.init(named: metadata!.iconName)
            } else {
                headerView.imageView.image = UIImage(named: "file")
            }
        }
    
        headerView.fileName.text = metadata?.fileNameView
        headerView.fileName.textColor = NCBrandColor.shared.label
        if metadata!.favorite {
            headerView.favorite.setImage(utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite], size: 24), for: .normal)
        } else {
            headerView.favorite.setImage(utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.textInfo], size: 24), for: .normal)
        }
        headerView.info.text = utilityFileSystem.transformedSize(metadata!.size) + ", " + utility.dateDiff(metadata!.date as Date)
        return headerView
        
    }
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return metadata?.ownerId != appDelegate?.userId ? canReshare ? 400 : 350 : 320
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return metadata?.ownerId != appDelegate?.userId ? canReshare ? UITableView.automaticDimension : 350 : 320
    }
}

//MARK: CNContactPickerDelegate
extension NCShare: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        if  contact.emailAddresses.count > 1 {
            showEmailList(arrEmail: contact.emailAddresses.map({$0.value as String}))
        } else if let email = contact.emailAddresses.first?.value as? String {
            textField?.text = email
            networking?.getSharees(searchString: email)
        }
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.keyboardWillHide(notification: Notification(name: Notification.Name("dismiss")))
    }
    
    func showEmailList(arrEmail: [String]) {
        var actions = [NCMenuAction]()
        for email in arrEmail {
            actions.append(
                NCMenuAction(
                    title: email,
                    icon: utility.loadImage(named: "email").imageColor(NCBrandColor.shared.brandElement),
                    selected: false,
                    on: false,
                    action: { _ in
                        self.textField?.text = email
                        self.networking?.getSharees(searchString: email)
                    }
                )
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.presentMenu(with: actions)
        }
    }
}

