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

class NCShare: UIViewController, NCSharePagingContent {

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

    var shareLinksCount = 0
    var isCurrentUser: Bool {
        if let currentUser = NCManageDatabase.shared.getActiveTableAccount(), currentUser.userId == metadata?.ownerId {
            return true
        }
        return false
    }
    var shareLinks: [tableShare] = []
    var shareEmails: [tableShare] = []
    var shareOthers: [tableShare] = []

    enum ShareSection: Int, CaseIterable {
        case header
        case linkByEmail
        case links
        case emails
    }

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
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterDidCreateShareLink), object: nil)
        
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
            advancePermission.share = TransientShare.shareLink(metadata: self.metadata, password: password)
            advancePermission.metadata = self.metadata
            navigationController.pushViewController(advancePermission, animated: true)
        }
    }

    // MARK: - Notification Center

    @objc func openShareProfile() {
        guard let metadata = metadata else { return }
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
        guard let metadata = metadata else {
            return
        }
        shares = self.database.getTableShares(metadata: metadata)
        shareLinksCount = 0
        updateShareArrays()
        tableView.reloadData()
    }

    func updateShareArrays() {
        shareLinks = []
        shareEmails = []
        
        if let shareLink = shares.firstShareLink {
            shares.share?.insert(shareLink, at: 0)
            shareLinksCount += 1
        }
        for item in shares.share ?? [] {
            if item.shareType == shareCommon.SHARE_TYPE_LINK {
                shareLinks.append(item)
            } else {
                shareEmails.append(item)
            }
        }
    }

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
    
    @IBAction func createLinkClicked(_ sender: Any) {
        appDelegate?.adjust.trackEvent(TriggerEvent(CreateLink.rawValue))
        TealiumHelper.shared.trackEvent(title: "magentacloud-app.sharing.create", data: ["": ""])
        self.touchUpInsideButtonMenu(sender)
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
    
//    @IBAction func touchUpInsideButtonMenu(_ sender: Any) {
//        guard let metadata = metadata else {
//            return
//        }
//
//        let isFilesSharingPublicPasswordEnforced = NCCapabilities.Capabilities().capabilityFileSharingPubPasswdEnforced
//        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)
//
//        if isFilesSharingPublicPasswordEnforced && shares.firstShareLink == nil {
//            let alertController = UIAlertController(title: NSLocalizedString("_enforce_password_protection_", comment: ""), message: "", preferredStyle: .alert)
//            alertController.addTextField { $0.isSecureTextEntry = true }
//
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default))
//            
//            let okAction = UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { [weak self] _ in
//                let password = alertController.textFields?.first?.text ?? ""
//                self?.createShareAndReload(password: password)
//            }
//
//            alertController.addAction(okAction)
//            present(alertController, animated: true, completion: nil)
//        } else {
//            createShareAndReload(password: "")
//        }
//    }

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
        guard NCCapabilities.Capabilities().capabilityFileSharingPubPasswdEnforced,
              shareType == shareCommon.SHARE_TYPE_LINK || shareType == shareCommon.SHARE_TYPE_EMAIL
        else { return completion(nil) }

        self.present(UIAlertController.password(titleKey: "_enforce_password_protection_", completion: completion), animated: true)
    }
}

    // MARK: - NCShareNetworkingDelegate

extension NCShare: NCShareNetworkingDelegate {
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
            cell.configure(with: tableShare, at: indexPath, isDirectory: metadata.directory, shareLinksCount: shareLinksCount)
            if tableShare.shareType == shareCommon.SHARE_TYPE_LINK { shareLinksCount += 1 }
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
    }

    func numberOfRows(in section: Int) -> Int {
        return tableView(tableView, numberOfRowsInSection: section)
    }
    
    func viewForHeaderInSection(for section: Int) -> UIView? {
        guard let sectionType = ShareSection(rawValue: section), sectionType == .links || sectionType == .emails else { return nil }

        let headerView = UIView()
        headerView.backgroundColor = .clear

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = NCBrandColor.shared.textColor
        label.text = (sectionType == .emails) ? NSLocalizedString("_share_shared_with_", comment: "") : NSLocalizedString("_share_copy_link_", comment: "")

        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            label.heightAnchor.constraint(equalToConstant: 30),
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
        ])

        return headerView
    }

    func viewForFooterInSection(for section: Int) -> UIView? {
        guard ShareSection(rawValue: section) == .links else { return nil }

        let footerView = UIView()
        footerView.backgroundColor = .clear

        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("_create_new_link_", comment: ""), for: .normal)
        button.setTitleColor(NCBrandColor.shared.shareBlackColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = NCBrandColor.shared.label.cgColor
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(createLinkClicked(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        let separator = UIView()
        separator.backgroundColor = .lightGray
        separator.translatesAutoresizingMaskIntoConstraints = false

        footerView.addSubview(button)
        footerView.addSubview(separator)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 15),
            button.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -15),
            button.heightAnchor.constraint(equalToConstant: 40),
            
            separator.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])

        return footerView
    }

    func footerViewForNoShares() -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = NCBrandColor.shared.textColor
        titleLabel.text = NSLocalizedString("_share_shared_with_", comment: "")

        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = NCBrandColor.shared.textColor
        infoLabel.text = NSLocalizedString("_share_no_shares_text_", comment: "")
        infoLabel.numberOfLines = 0
        infoLabel.lineBreakMode = .byWordWrapping

        footerView.addSubview(titleLabel)
        footerView.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -15),
            titleLabel.heightAnchor.constraint(equalToConstant: 25),

            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            infoLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 15),
            infoLabel.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -15)
        ])

        return footerView
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = ShareSection(rawValue: section) else { return nil }

        switch sectionType {
        case .header:
            // Always return the header view
            guard let headerView = Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as? NCShareAdvancePermissionHeader else {
                return nil
            }
            headerView.ocId = metadata.ocId
            headerView.setupUI(with: metadata)
            return headerView

        case .linkByEmail:
            return nil

        case .links:
            return isCurrentUser || canReshare ? viewForHeaderInSection(for: section) : nil

        case .emails:
            return (isCurrentUser || canReshare) && numberOfRows(in: section) > 0 ? viewForHeaderInSection(for: section) : nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = ShareSection(rawValue: section) else { return 0 }

        switch sectionType {
        case .header:
            return 190  // Adjust based on your nib
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
            return viewForFooterInSection(for: section)
        case .emails:
            return numberOfRows(in: section) == 0 ? footerViewForNoShares() : viewForFooterInSection(for: section)
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
