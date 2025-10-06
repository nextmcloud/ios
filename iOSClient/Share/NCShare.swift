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
import ContactsUI

enum ShareSection: Int, CaseIterable {
    case header
    case linkByEmail
    case links
    case emails
}

class NCShare: UIViewController, NCSharePagingContent {

    var textField: UITextField? { self.view.viewWithTag(Tag.searchField) as? UITextField }

    @IBOutlet weak var tableView: UITableView!

    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate

    var controller: NCMainTabBarController?

    public var metadata: tableMetadata!
    public var sharingEnabled = true
    public var height: CGFloat = 0
    let shareCommon = NCShareCommon()
    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()
    let database = NCManageDatabase.shared

    var canReshare: Bool {
        return ((metadata.sharePermissionsCollaborationServices & NKShare.Permission.share.rawValue) != 0)
    }

    @MainActor
    var session: NCSession.Session {
        NCSession.shared.getSession(account: metadata.account)
    }

    var shares: (firstShareLink: tableShare?, share: [tableShare]?) = (nil, nil)

    private var dropDown = DropDown()
    private var avatarButton: UIButton!
    var networking: NCShareNetworking?

    var isCurrentUser: Bool {
        if let currentUser = NCManageDatabase.shared.getActiveTableAccount(), currentUser.userId == metadata?.ownerId {
            return true
        }
        return false
    }
    var shareLinks: [tableShare] = []
    var shareEmails: [tableShare] = []
    var shareOthers: [tableShare] = []
    private var cachedHeader: NCShareAdvancePermissionHeader?
    // Stores the next number per share
//    var nextLinkNumberByShare: [String: Int] = [:]
//
//    // Stores assigned numbers for each link (per share)
//    var linkNumbersByShare: [String: [String: Int]] = [:]

//    var shareLinksCount = 0

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
        tableView.register(NCShareEmailLinkHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: NCShareEmailLinkHeaderView.reuseIdentifier)
        tableView.register(CreateLinkFooterView.self, forHeaderFooterViewReuseIdentifier: CreateLinkFooterView.reuseIdentifier)
        tableView.register(NoSharesFooterView.self, forHeaderFooterViewReuseIdentifier: NoSharesFooterView.reuseIdentifier)
        tableView.register(UINib(nibName: "NCShareAdvancePermissionHeader", bundle: nil),
                           forHeaderFooterViewReuseIdentifier: NCShareAdvancePermissionHeader.reuseIdentifier)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterReloadDataNCShare), object: nil)

        Task {
            self.capabilities = await NKCapabilities.shared.getCapabilities(for: metadata.account)
            if metadata.e2eEncrypted {
                let metadataDirectory = await self.database.getMetadataDirectoryAsync(serverUrl: metadata.serverUrl, account: metadata.account)
                if capabilities.e2EEApiVersion == "1.2" ||
                    (capabilities.e2EEApiVersion.hasPrefix("2.") && metadataDirectory?.e2eEncrypted ?? false) {
                    searchFieldTopConstraint.constant = -50
                    searchField.alpha = 0
                    btnContact.alpha = 0
                }
            } else {
                checkSharedWithYou()
            }

            reloadData()

            networking = NCShareNetworking(metadata: metadata, view: self.view, delegate: self, session: session, controller: controller)
//            networking = NCShareNetworking(metadata: metadata, view: self.view, delegate: self, session: session)
        if sharingEnabled {
            let isVisible = (self.navigationController?.topViewController as? NCSharePaging)?.page == .sharing
            networking?.readShare(showLoadingIndicator: isVisible)
            searchField.searchTextField.font = .systemFont(ofSize: 14)
            searchField.delegate = self
        }
    }

    @objc func exitTapped() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterUpdateIcons)
        self.dismiss(animated: true, completion: nil)
    }
    
    func makeNewLinkShare() {
        guard
            let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
            let navigationController = self.navigationController else { return }
        self.checkEnforcedPassword(shareType: NKShare.ShareType.publicLink.rawValue) { password in
            advancePermission.networking = self.networking
            advancePermission.share = TransientShare.shareLink(metadata: self.metadata, password: password)
            advancePermission.metadata = self.metadata
            advancePermission.controller = self.controller
            navigationController.pushViewController(advancePermission, animated: true)
        }
    }

    // Shared with you by ...
    func checkSharedWithYou() {
        guard !metadata.ownerId.isEmpty, metadata.ownerId != session.userId else { return }

        if !canReshare {
            searchField.isUserInteractionEnabled = false
            searchField.alpha = 0.5
            searchField.placeholder = NSLocalizedString("_share_reshare_disabled_", comment: "")
            btnContact.isEnabled = false
        }

        searchFieldTopConstraint.constant = 45
        sharedWithYouByView.isHidden = false
        sharedWithYouByLabel.text = NSLocalizedString("_shared_with_you_by_", comment: "") + " " + metadata.ownerDisplayName
        sharedWithYouByImage.image = utility.loadUserImage(for: metadata.ownerId, displayName: metadata.ownerDisplayName, urlBase: session.urlBase)
        sharedWithYouByLabel.accessibilityHint = NSLocalizedString("_show_profile_", comment: "")

        avatarButton = UIButton(type: .system)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.backgroundColor = .clear
        sharedWithYouByView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: sharedWithYouByImage.topAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: sharedWithYouByImage.bottomAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: sharedWithYouByImage.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: sharedWithYouByLabel.trailingAnchor)
        ])
        avatarButton.showsMenuAsPrimaryAction = true
        avatarButton.menu = NCContextMenuProfile(userId: metadata.ownerId, session: session, viewController: self).viewMenu()

        let fileName = NCSession.shared.getFileName(urlBase: session.urlBase, user: metadata.ownerId)
        let results = NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName)

        if results.image == nil {
            let etag = self.database.getTableAvatar(fileName: fileName)?.etag
            let fileNameLocalPath = utilityFileSystem.createServerUrl(serverUrl: utilityFileSystem.directoryUserData, fileName: fileName)

            NextcloudKit.shared.downloadAvatar(
                user: metadata.ownerId,
                fileNameLocalPath: fileNameLocalPath,
                sizeImage: NCGlobal.shared.avatarSize,
                avatarSizeRounded: NCGlobal.shared.avatarSizeRounded,
                etagResource: etag,
                account: metadata.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: self.metadata.account,
                                                                                                    path: self.metadata.ownerId,
                                                                                                    name: "downloadAvatar")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                } completion: { _, imageAvatar, _, etag, _, error in
                    if error == .success, let etag = etag, let imageAvatar = imageAvatar {
                        self.database.addAvatar(fileName: fileName, etag: etag)
                        self.sharedWithYouByImage.image = imageAvatar
                        self.reloadData()
                    } else if error.errorCode == NCGlobal.shared.errorNotModified, let imageAvatar = self.database.setAvatarLoaded(fileName: fileName) {
                        self.sharedWithYouByImage.image = imageAvatar
                    }
                }
        }

        reloadData()
    }

    // MARK: - Notification Center

    @objc func openShareProfile() {
        guard let metadata = metadata else { return }
        self.showProfileMenu(userId: metadata.ownerId, session: session)
    }
    
    private func scrollToTopIfNeeded() {
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    @objc func keyboardWillShow(notification: Notification) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if UIScreen.main.bounds.width < 374 || UIDevice.current.orientation.isLandscape {
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    if view.frame.origin.y == 0 {
                        scrollToTopIfNeeded()
                        self.view.frame.origin.y -= keyboardSize.height
                    }
                }
            } else if UIScreen.main.bounds.height < 850 {
                if view.frame.origin.y == 0 {
                    scrollToTopIfNeeded()
                    self.view.frame.origin.y -= 70
                }
            } else {
                if view.frame.origin.y == 0 {
                    scrollToTopIfNeeded()
                    self.view.frame.origin.y -= 40
                }
            }
        }

        if UIDevice.current.userInterfaceIdiom == .pad, UIDevice.current.orientation.isLandscape {
            if view.frame.origin.y == 0 {
                if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
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
    
//    @objc private func handleShareCountsUpdate(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//                  let links = userInfo["links"] as? Int,
//                  let emails = userInfo["emails"] as? Int else { return }
//
//            if let header = tableView.headerView(forSection: ShareSection.header.rawValue) as? NCShareAdvancePermissionHeader {
//                header.setupUI(with: metadata,
//                                       linkCount: links,
//                                       emailCount: emails)
//            } else {
//                let headerSection = IndexSet(integer: ShareSection.header.rawValue)
//                tableView.reloadSections(headerSection, with: .none)
//            }
//    }

    // MARK: -

    @objc func reloadData() {
        guard let metadata = metadata else {
            return
        }
//        shares = (nil, nil) // reset
        shares = self.database.getTableShares(metadata: metadata)
        updateShareArrays()
        tableView.reloadData()
    }
    
    func updateShareArrays() {
        shareLinks.removeAll()
        shareEmails.removeAll()

        guard var allShares = shares.share else { return }

        if let firstLink = shares.firstShareLink {
            // Remove if already exists to avoid duplication
            allShares.removeAll { $0.idShare == firstLink.idShare }
            allShares.insert(firstLink, at: 0)
        }

        shares.share = allShares

        for item in allShares {
            if item.shareType == shareCommon.SHARE_TYPE_LINK {
                shareLinks.append(item)
            } else {
                shareEmails.append(item)
            }
        }
    }

    
//    func updateShareArrays() {
//        shareLinks.removeAll()
//        shareEmails.removeAll()
//
//        var allShares = shares.share ?? []
//
//        if let firstLink = shares.firstShareLink {
//            if let idx = allShares.firstIndex(where: { $0.idShare == firstLink.idShare }) {
//                allShares.remove(at: idx)   // only one removal
//            }
//            allShares.insert(firstLink, at: 0)
//        }
//
//        shares.share = allShares
//
//        for item in allShares {
//            if item.shareType == shareCommon.SHARE_TYPE_LINK {
//                shareLinks.append(item)
//            } else {
//                shareEmails.append(item)
//            }
//        }
//    }




//    func updateShareArrays() {
//        shareLinks.removeAll()
//        shareEmails.removeAll()
//
//        if let shareLink = shares.firstShareLink {
//            shares.share?.insert(shareLink, at: 0)
//        }
//
//        guard let allShares = shares.share else { return }
//
////        // Use current shareId as the scope
////        let shareId = metadata?.ocId ?? "0"
////
////        // Ensure storage exists for this share
////        if nextLinkNumberByShare[shareId] == nil {
////            nextLinkNumberByShare[shareId] = 1
////            linkNumbersByShare[shareId] = [:]
////        }
//
//        for item in allShares {
//            if item.shareType == shareCommon.SHARE_TYPE_LINK {
//                shareLinks.append(item)
//            } else {
//                shareEmails.append(item)
//            }
//        }
//
////        // Sort links by assigned number (per-share)
////        shareLinks.sort { lhs, rhs in
////            let lhsNum = linkNumbersByShare[shareId]?[String(lhs.idShare)] ?? 0
////            let rhsNum = linkNumbersByShare[shareId]?[String(rhs.idShare)] ?? 0
////            return lhsNum < rhsNum
////        }
////
////        // ✅ If this share has no links, reset numbering for it
////        if shareLinks.isEmpty {
////            linkNumbersByShare[shareId] = [:]
////            nextLinkNumberByShare[shareId] = 1
////            saveLinkNumberData()
////        }
//
////        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare,
////                                                    userInfo: ["links": shareLinks.count,
////                                                               "emails": shareEmails.count])
//    }

//    // MARK: - Persistence
//    func saveLinkNumberData() {
//        // Save both maps as UserDefaults property lists
//        UserDefaults.standard.set(linkNumbersByShare, forKey: "linkNumbersByShare")
//        UserDefaults.standard.set(nextLinkNumberByShare, forKey: "nextLinkNumberByShare")
//    }
//
//    func loadLinkNumberData() {
//        if let savedMap = UserDefaults.standard.dictionary(forKey: "linkNumbersByShare") as? [String: [String: Int]] {
//            linkNumbersByShare = savedMap
//        } else {
//            linkNumbersByShare = [:]
//        }
//
//        if let savedNext = UserDefaults.standard.dictionary(forKey: "nextLinkNumberByShare") as? [String: Int] {
//            nextLinkNumberByShare = savedNext
//        } else {
//            nextLinkNumberByShare = [:]
//        }
//    }
//
//    // MARK: - Number Assignment
//
//    // Assign number to a link (or reuse existing)
//    func assignLinkNumber(forShare shareId: String, linkId: String) -> Int {
//        if nextLinkNumberByShare[shareId] == nil {
//            nextLinkNumberByShare[shareId] = 1
//            linkNumbersByShare[shareId] = [:]
//        }
//
//        if let number = linkNumbersByShare[shareId]?[linkId] {
//            return number
//        }
//
//        let nextNum = nextLinkNumberByShare[shareId]!
//        linkNumbersByShare[shareId]?[linkId] = nextNum
//        nextLinkNumberByShare[shareId]! += 1
//        return nextNum
//    }
//
//    func removeLink(forShare shareId: String, linkId: String) {
//        linkNumbersByShare[shareId]?.removeValue(forKey: linkId)
//
//        if linkNumbersByShare[shareId]?.isEmpty ?? true {
//            linkNumbersByShare[shareId] = [:]
//            nextLinkNumberByShare[shareId] = 1
//        }
//    }


    
//    func updateShareArrays() {
//        shareLinks.removeAll()
//        shareEmails.removeAll()
//
//        if let shareLink = shares.firstShareLink {
//            shares.share?.insert(shareLink, at: 0)
//        }
//
//        guard let allShares = shares.share else { return }
//
//        // Use current shareId as the scope
//        let shareId = metadata?.ocId ?? "0"
//
//        // Ensure storage exists for this share
//        if nextLinkNumberByShare[shareId] == nil {
//            nextLinkNumberByShare[shareId] = 1
//            linkNumbersByShare[shareId] = [:]
//        }
//
//        for item in allShares {
//            if item.shareType == shareCommon.SHARE_TYPE_LINK {
//                let linkId = String(item.idShare)
//
//                // Assign a number if missing
//                if linkNumbersByShare[shareId]?[linkId] == nil {
//                    let nextNum = nextLinkNumberByShare[shareId] ?? 1
//                    linkNumbersByShare[shareId]?[linkId] = nextNum
//                    nextLinkNumberByShare[shareId] = nextNum + 1
//                    saveLinkNumberData()
//                }
////                if item.shareType == shareCommon.SHARE_TYPE_LINK { shareLinksCount += 1 }
//
//                shareLinks.append(item)
//            } else {
//                shareEmails.append(item)
//            }
//        }
//
//        // Sort links by assigned number (per-share)
//        shareLinks.sort { lhs, rhs in
//            let lhsNum = linkNumbersByShare[shareId]?[String(lhs.idShare)] ?? 0
//            let rhsNum = linkNumbersByShare[shareId]?[String(rhs.idShare)] ?? 0
//            return lhsNum < rhsNum
//        }
//
//        // ✅ If this share has no links, reset numbering for it
//        if shareLinks.isEmpty {
//            linkNumbersByShare[shareId] = [:]
//            nextLinkNumberByShare[shareId] = 1
//            saveLinkNumberData()
//        }
//
////        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare,
////                                                    userInfo: ["links": shareLinks.count,
////                                                               "emails": shareEmails.count])
//    }
//
//    // MARK: - Persistence
//    func saveLinkNumberData() {
//        // Save both maps as UserDefaults property lists
//        UserDefaults.standard.set(linkNumbersByShare, forKey: "linkNumbersByShare")
//        UserDefaults.standard.set(nextLinkNumberByShare, forKey: "nextLinkNumberByShare")
//    }
//
//    func loadLinkNumberData() {
//        if let savedMap = UserDefaults.standard.dictionary(forKey: "linkNumbersByShare") as? [String: [String: Int]] {
//            linkNumbersByShare = savedMap
//        } else {
//            linkNumbersByShare = [:]
//        }
//
//        if let savedNext = UserDefaults.standard.dictionary(forKey: "nextLinkNumberByShare") as? [String: Int] {
//            nextLinkNumberByShare = savedNext
//        } else {
//            nextLinkNumberByShare = [:]
//        }
//    }
//
//    // MARK: - Number Assignment
//
//    // Assign number to a link (or reuse existing)
//    func assignLinkNumber(forShare shareId: String, linkId: String) -> Int {
//        if nextLinkNumberByShare[shareId] == nil {
//            nextLinkNumberByShare[shareId] = 1
//            linkNumbersByShare[shareId] = [:]
//        }
//
//        if let number = linkNumbersByShare[shareId]?[linkId] {
//            return number
//        }
//
//        let nextNum = nextLinkNumberByShare[shareId]!
//        linkNumbersByShare[shareId]?[linkId] = nextNum
//        nextLinkNumberByShare[shareId]! += 1
//        return nextNum
//    }
//
//    func removeLink(forShare shareId: String, linkId: String) {
//        linkNumbersByShare[shareId]?.removeValue(forKey: linkId)
//
//        if linkNumbersByShare[shareId]?.isEmpty ?? true {
//            linkNumbersByShare[shareId] = [:]
//            nextLinkNumberByShare[shareId] = 1
//        }
//    }

    // MARK: - IBAction

    @IBAction func searchFieldDidEndOnExit(textField: UITextField) {
        guard let searchString = textField.text, !searchString.isEmpty else { return }
        if searchString.contains("@"), !utility.validateEmail(searchString) { return }
        networking?.getSharees(searchString: searchString)
    }
    
    @IBAction func searchFieldDidChange(textField: UITextField) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchSharees), object: nil)
        guard let searchString = textField.text else {return}
        if searchString.count == 0 {
            dropDown.hide()
        } else {
//            networking?.getSharees(searchString: searchString)
            perform(#selector(searchSharees), with: nil, afterDelay: 0.5)
        }
    }
    
//    @objc private func searchSharees() {
//        // https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
//        func isValidEmail(_ email: String) -> Bool {
//
//            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
//            return emailPred.evaluate(with: email)
//        }
//        guard let searchString = textField?.text, !searchString.isEmpty else { return }
//        if searchString.contains("@"), !isValidEmail(searchString) { return }
//        networking?.getSharees(searchString: searchString)
//    }
    
    @IBAction func createLinkClicked(_ sender: Any?) {
        appDelegate?.adjust.trackEvent(TriggerEvent(CreateLink.rawValue))
        TealiumHelper.shared.trackEvent(title: "magentacloud-app.sharing.create", data: ["": ""])
//        self.touchUpInsideButtonMenu(sender)
        self.touchUpInsideButtonMenu(sender as Any)
    }
    
    @IBAction func touchUpInsideButtonMenu(_ sender: Any) {
        
        guard let metadata = metadata else { return }
        let isFilesSharingPublicPasswordEnforced = NCCapabilities.Capabilities().capabilityFileSharingPubPasswdEnforced
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

    private func createShareAndReload(password: String) {
        networking?.createShareLink(password: password)
        
        // Delay to wait for DB update or async API completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.reloadData()
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
        guard capabilities.fileSharingPubPasswdEnforced,
              shareType == NKShare.ShareType.publicLink.rawValue || shareType == NKShare.ShareType.email.rawValue
        else { return completion(nil) }

        self.present(UIAlertController.password(titleKey: "_enforce_password_protection_", completion: completion), animated: true)
    }

    @IBAction func selectContactClicked(_ sender: Any) {
        let cnPicker = CNContactPickerViewController()
        cnPicker.delegate = self
        cnPicker.displayedPropertyKeys = [CNContactEmailAddressesKey]
        cnPicker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        cnPicker.predicateForSelectionOfProperty = NSPredicate(format: "emailAddresses.@count > 0")
        self.present(cnPicker, animated: true)
    }

    func presentQuickStatusActionSheet(for share: tableShare, sender: Any?) {
        guard let metadata = metadata else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let isDirectory = metadata.directory

        // Read Only
        let readOnlyAction = UIAlertAction(title: NSLocalizedString("_share_read_only_", comment: ""), style: .default) { [weak self] _ in
            let permissions = NCSharePermissions.getPermissionValue(canCreate: false, canEdit: false, canDelete: false, canShare: false, isDirectory: isDirectory)
            self?.updateSharePermissions(share: share, permissions: permissions)
        }
        alertController.addAction(readOnlyAction)

        // Editing
        let editingAction = UIAlertAction(title: NSLocalizedString("_share_editing_", comment: ""), style: .default) { [weak self] _ in
            let permissions = NCSharePermissions.getPermissionValue(canCreate: true, canEdit: true, canDelete: true, canShare: true, isDirectory: isDirectory)
            self?.updateSharePermissions(share: share, permissions: permissions)
        }
        alertController.addAction(editingAction)

        // File Drop (only for directories with public link or email share)
        if isDirectory && (share.shareType == NKShare.ShareType.publicLink.rawValue || share.shareType == NKShare.ShareType.email.rawValue) {
            let fileDropAction = UIAlertAction(title: NSLocalizedString("_share_file_drop_", comment: ""), style: .default) { [weak self] _ in
                let permissions = NCSharePermissions.getPermissionValue(canRead: false, canCreate: true, canEdit: false, canDelete: false, canShare: false, isDirectory: isDirectory)
                self?.updateSharePermissions(share: share, permissions: permissions)
            }
            alertController.addAction(fileDropAction)
        }

        // Custom Permissions
        let customAction = UIAlertAction(title: NSLocalizedString("_custom_permissions_", comment: ""), style: .default) { [weak self] _ in
            self?.openAdvancePermission(for: share)
        }
        alertController.addAction(customAction)

        // Cancel
        let cancelAction = UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel)
        alertController.addAction(cancelAction)

        // iPad popover support
        if let popover = alertController.popoverPresentationController,
           let sourceView = sender as? UIView {
            let barItem = UIBarButtonItem(customView: sourceView)
            popover.sourceItem = barItem
        }

        present(alertController, animated: true)
    }

    private func openAdvancePermission(for share: tableShare) {
        guard let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
              !share.isInvalidated,
              let metadata = metadata else { return }

        advancePermission.networking = networking
        advancePermission.share = tableShare(value: share)
        advancePermission.oldTableShare = tableShare(value: share)
        advancePermission.metadata = metadata
        advancePermission.controller = self.controller

        if let downloadLimit = try? NCManageDatabase.shared.getDownloadLimit(byAccount: metadata.account, shareToken: share.token) {
            advancePermission.downloadLimit = .limited(limit: downloadLimit.limit, count: downloadLimit.count)
        }

        navigationController?.pushViewController(advancePermission, animated: true)
    }

    func updateSharePermissions(share: tableShare, permissions: Int) {
        let updatedShare = tableShare(value: share)
        updatedShare.permissions = permissions

        var downloadLimit: DownloadLimitViewModel = .unlimited

        do {
            if let model = try database.getDownloadLimit(byAccount: metadata.account, shareToken: updatedShare.token) {
                downloadLimit = .limited(limit: model.limit, count: model.count)
            }
        } catch {
            nkLog(error: "Failed to get download limit from database!")
            return
        }

        networking?.updateShare(updatedShare, downloadLimit: downloadLimit)
    }
}

    // MARK: - NCShareNetworkingDelegate

extension NCShare: NCShareNetworkingDelegate {
    func readShareCompleted() {
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
//        self.reloadData()
    }

    func shareCompleted() {
//        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
//        self.reloadData()
        // Allow DB async save to finish before reload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.reloadData()
        }
    }

    func unShareCompleted() {
//        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
        // Same buffer for consistency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.reloadData()
        }
    }
//    func unShareCompleted() {
//        DispatchQueue.main.async {
//            self.reloadData()
//        }
//    }

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
            if sharee.shareType == NKShare.ShareType.team.rawValue {
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
        dropDown.customCellConfiguration = { (index: Index, _, cell: DropDownCell) in
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
                let shareOptions = TransientShare(sharee: sharee, metadata: self.metadata, password: password)
                advancePermission.share = shareOptions
                advancePermission.networking = self.networking
                advancePermission.metadata = self.metadata
                advancePermission.controller = self.controller
                navigationController.pushViewController(advancePermission, animated: true)
            }
        }

        dropDown.show()
    }

    func downloadLimitRemoved(by token: String) {
        database.deleteDownloadLimit(byAccount: metadata.account, shareToken: token)
    }

    func downloadLimitSet(to limit: Int, by token: String) {
        database.createDownloadLimit(account: metadata.account, count: 0, limit: limit, token: token)
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
        guard let sectionType = ShareSection(rawValue: indexPath.section) else { return 0 }

        switch sectionType {
        case .header:
            return 210

        case .linkByEmail:
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            if isCurrentUser {
                return 130
            } else {
                return isPad ? (canReshare ? 200 : 220) : 220
            }

        case .links, .emails:
            return 60
        }
    }

}

// MARK: - UITableViewDataSource

extension NCShare: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        ShareSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//<<<<<<< HEAD
//        var numRows = shares.share?.count ?? 0
//        if section == 0 {
//            if metadata.e2eEncrypted, capabilities.e2EEApiVersion == "1.2" {
//                numRows = 1
//            } else {
//                // don't allow link creation if reshare is disabled
//                numRows = shares.firstShareLink != nil || canReshare ? 2 : 1
//            }
//=======
        guard let sectionType = ShareSection(rawValue: section) else { return 0 }

        switch sectionType {
        case .header:
            return 0
        case .linkByEmail:
            return 1
        case .links:
            return shareLinks.count
        case .emails:
            return shareEmails.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = ShareSection(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sectionType {
        case .header:
            return UITableViewCell() // Empty row
        case .linkByEmail:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "NCShareEmailFieldCell", for: indexPath) as? NCShareEmailFieldCell else {
                return UITableViewCell()
            }
            cell.searchField.addTarget(self, action: #selector(searchFieldDidEndOnExit(textField:)), for: .editingDidEndOnExit)
            cell.searchField.addTarget(self, action: #selector(searchFieldDidChange(textField:)), for: .editingChanged)
            cell.btnContact.addTarget(self, action: #selector(selectContactClicked(_:)), for: .touchUpInside)
            cell.setupCell(with: metadata)
            return cell

        case .links:
            let tableShare = shareLinks[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            if indexPath.row == 0 {
                cell.configure(with: tableShare, at: indexPath, isDirectory: metadata.directory, title: "")
            } else {
                let linkNumber = " \(indexPath.row + 1)"
                cell.configure(with: tableShare, at: indexPath, isDirectory: metadata.directory, title: linkNumber)
            }
            return cell

        case .emails:
            let tableShare = shareEmails[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            cell.configure(with: tableShare, at: indexPath, isDirectory: metadata.directory, userId: session.userId)
            return cell
        }
        
        // Setup default share cells
        guard indexPath.section != 0 else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell
            else { return UITableViewCell() }
            cell.delegate = self
            if metadata.e2eEncrypted, capabilities.e2EEApiVersion == "1.2" {
                cell.tableShare = shares.firstShareLink
            } else {
                if indexPath.row == 0 {
                    cell.isInternalLink = true
                } else if shares.firstShareLink?.isInvalidated != true {
                    cell.tableShare = shares.firstShareLink
                }
            }
            cell.isDirectory = metadata.directory
            cell.setupCellUI()

            if cell.tableShare != nil, let tableShare = shares.firstShareLink {
                cell.menuButton.menu = NCContextMenuShare(share: tableShare, isDirectory: metadata.isDirectory, canReshare: canReshare, shareController: self, controller: controller).viewMenu()
                cell.menuButton.showsMenuAsPrimaryAction = true
            }

            shareLinksCount += 1
            return cell
        }

        let orderedShares = shares.share?.sorted(by: { $0.date?.compare($1.date as Date? ?? Date()) == .orderedAscending })
        guard let tableShare = orderedShares?[indexPath.row] else { return UITableViewCell() }

        // LINK, EMAIL
        if tableShare.shareType == NKShare.ShareType.publicLink.rawValue || tableShare.shareType == NKShare.ShareType.email.rawValue {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellLink", for: indexPath) as? NCShareLinkCell {
                cell.indexPath = indexPath
                cell.tableShare = tableShare
                cell.delegate = self
//<<<<<<< HEAD
//                cell.setupCellUI(titleAppendString: String(shareLinksCount))
//                cell.menuButton.menu = NCContextMenuShare(share: tableShare, isDirectory: metadata.isDirectory, canReshare: canReshare, shareController: self, controller: controller).viewMenu()
//                cell.menuButton.showsMenuAsPrimaryAction = true
//                if tableShare.shareType == NKShare.ShareType.publicLink.rawValue { shareLinksCount += 1 }
//                return cell
//            }
//        } else {
//        // USER / GROUP etc.
//            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellUser", for: indexPath) as? NCShareUserCell {
//                cell.index = indexPath
//                cell.tableShare = tableShare
//                cell.isDirectory = metadata.directory
//                cell.delegate = self
//                cell.setupCellUI(userId: session.userId, session: session, metadata: metadata)
//
//                cell.buttonMenu.menu = NCContextMenuShare(share: tableShare, isDirectory: metadata.isDirectory, canReshare: canReshare, shareController: self, controller: controller).viewMenu()
//                cell.buttonMenu.showsMenuAsPrimaryAction = true

                cell.setupCellUI()
                if !tableShare.label.isEmpty {
                    cell.labelTitle.text = String(format: NSLocalizedString("_share_linklabel_", comment: ""), tableShare.label)
                } else {
                    cell.labelTitle.text = directory ? NSLocalizedString("_share_link_folder_", comment: "") : NSLocalizedString("_share_link_file_", comment: "")
                }
//                cell.setupCellUI(userId: session.userId)
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
                    cell.isDirectory = metadata.directory
                    cell.delegate = self
                    cell.setupCellUI(userId: session.userId, session: session, metadata: metadata)
                    //                cell.setupCellUI(userId: appDelegate.userId)
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
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = ShareSection(rawValue: section) else { return nil }

        switch sectionType {
        case .header:
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: NCShareAdvancePermissionHeader.reuseIdentifier) as! NCShareAdvancePermissionHeader
            headerView.ocId = metadata.ocId
            headerView.setupUI(with: metadata, linkCount: shareLinks.count, emailCount: shareEmails.count)
            return headerView

        case .linkByEmail:
            return nil
            
        case .links:
            if isCurrentUser || canReshare {
                let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NCShareEmailLinkHeaderView") as! NCShareEmailLinkHeaderView
                headerView.configure(text: NSLocalizedString("_share_copy_link_", comment: ""))
                return headerView
            }
            return nil

        case .emails:
            if (isCurrentUser || canReshare) && numberOfRows(in: section) > 0 {
                let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NCShareEmailLinkHeaderView") as! NCShareEmailLinkHeaderView
                headerView.configure(text: NSLocalizedString("_share_shared_with_", comment: ""))
                return headerView
            }
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = ShareSection(rawValue: section) else { return 0 }

        switch sectionType {
        case .header:
            return 190
        case .linkByEmail:
            return 0
        case .links:
            return (isCurrentUser || canReshare) ? 44 : 0
        case .emails:
            return ((isCurrentUser || canReshare) && numberOfRows(in: section) > 0) ? 44 : 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard isCurrentUser || canReshare,
              let sectionType = ShareSection(rawValue: section) else {
            return nil
        }

        switch sectionType {
        case .links:
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: CreateLinkFooterView.reuseIdentifier) as! CreateLinkFooterView
            footer.createButtonAction = { [weak self] in
                self?.createLinkClicked(nil)
            }
            return footer
            
        case .emails:
            if numberOfRows(in: section) == 0 {
                return tableView.dequeueReusableHeaderFooterView(withIdentifier: NoSharesFooterView.reuseIdentifier)
            }
            return nil
        case .header, .linkByEmail:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard isCurrentUser || canReshare,
              let sectionType = ShareSection(rawValue: section) else {
            return 0.001
        }

        switch sectionType {
        case .links:
            return 80
        case .emails:
            return numberOfRows(in: section) == 0 ? 100 : 80
        case .header, .linkByEmail:
            return 0.001
        }
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

//    func showEmailList(arrEmail: [String], sender: Any?) {
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        
//        for email in arrEmail {
//            alert.addAction(UIAlertAction(title: email, style: .default) { _ in
//                self.searchField?.text = email
//                self.networking?.getSharees(searchString: email)
//            })
//        }
//    }
    
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

        alert.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel))

        // iPad popover support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.present(alert, animated: true)
//            self.presentMenu(with: actions)
        }
    }
}

// MARK: - UISearchBarDelegate

extension NCShare: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchSharees), object: nil)

        if searchText.isEmpty {
            dropDown.hide()
        } else {
            perform(#selector(searchSharees), with: nil, afterDelay: 0.5)
        }
    }

//<<<<<<< HEAD
//    @objc private func searchSharees(_ sender: Any?) {
//        guard let searchString = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !searchString.isEmpty else { return }
//        if searchString.contains("@"), !isValidEmail(searchString) { return }
    @objc private func searchSharees() {
//        // https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        func isValidEmail(_ email: String) -> Bool {

//            let emailRegEx = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-\\u00a1-\\uffff]+\\.[A-Za-z\\u00a1-\\uffff]{2,64}$"
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
        }
        guard let searchString = textField?.text, !searchString.isEmpty else { return }
        if searchString.contains("@"), !utility.validateEmail(searchString) { return }
        networking?.getSharees(searchString: searchString)
    }

}

extension NCShare {
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "^[\u{0021}-\u{007E}\\p{L}\\p{M}\\p{N}._%+\\-]+@([\\p{L}\\p{M}\\p{N}0-9\\-]+\\.)+[\\p{L}\\p{M}]{2,64}$" // Unicode regex allows for all unicode chars, ex. ß, ü, and more.
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
