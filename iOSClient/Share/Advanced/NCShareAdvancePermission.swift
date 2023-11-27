//
//  NCShareAdvancePermission.swift
//  Nextcloud
//
//  Created by T-systems on 09/08/21.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
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
import NextcloudKit
import SVGKit
import CloudKit

class NCShareAdvancePermission: XLFormViewController, NCShareAdvanceFotterDelegate, NCShareDetail {
    func dismissShareAdvanceView(shouldSave: Bool) {
        if shouldSave {
            self.oldTableShare?.permissions = self.permission ?? (self.oldTableShare?.permissions ?? 0)
            self.share.permissions = self.permission ?? (self.oldTableShare?.permissions ?? 0)
            if isNewShare {
                let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                guard let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as? NCShareNewUserAddComment else { return }
                viewNewUserComment.metadata = self.metadata
                viewNewUserComment.share = self.share
                viewNewUserComment.networking = self.networking
                self.navigationController?.pushViewController(viewNewUserComment, animated: true)
            } else {
                if let downloadSwitchCell = getDownloadLimitSwitchCell() {
                    let isDownloadLimitOn = downloadSwitchCell.switchControl.isOn
                    if !isDownloadLimitOn {
                        setDownloadLimit(deleteLimit: true, limit: "")
                    } else {
                        let downloadLimitInputCell = getDownloadLimitInputCell()
                        let enteredDownloadLimit = downloadLimitInputCell?.cellTextField.text ?? ""
                        if enteredDownloadLimit.isEmpty {
                            showDownloadLimitError(message: NSLocalizedString("_share_download_limit_alert_empty_", comment: ""))
                            return
                        }
                        if let num = Int(enteredDownloadLimit), num < 1 {
                            showDownloadLimitError(message: NSLocalizedString("_share_download_limit_alert_zero_", comment: ""))
                            return
                        }
                        setDownloadLimit(deleteLimit: false, limit: enteredDownloadLimit)
                    }
                }
                
                networking?.updateShare(option: share)
                navigationController?.popViewController(animated: true)
            }
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    let database = NCManageDatabase.shared

    var oldTableShare: tableShare?

    ///
    /// View model for the share link user interface.
    ///
    var share: (any Shareable)!

    ///
    /// Determining whether the currently represented share is new based on its concrete type.
    ///
    var isNewShare: Bool { share is TransientShare }

    ///
    /// The subject to share.
    ///
    var metadata: tableMetadata!

    ///
    /// The possible download limit associated with this share.
    ///
    /// This can only be created after the share has been actually created due to its requirement of the share token provided by the server.
    ///
    var downloadLimit: DownloadLimitViewModel = .unlimited

    var shareConfig: NCShareConfig!
    var networking: NCShareNetworking?
    let tableViewBottomInset: CGFloat = 80.0
    lazy var shareType: Int = {
        isNewShare ? share.shareType : oldTableShare?.shareType ?? NCShareCommon().SHARE_TYPE_USER
    }()
    static let displayDateFormat = "dd. MMM. yyyy"
    var downloadLimit: DownloadLimit?
    var permission: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareConfig = NCShareConfig(parentMetadata: metadata, share: share)
        self.setNavigationTitle()
        // disbale pull to dimiss
        isModalInPresentation = true
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.permission = oldTableShare?.permissions
        initializeForm()
        changeTheming()
        getDownloadLimit()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard tableView.tableHeaderView == nil, tableView.tableFooterView == nil else { return }
        setupHeaderView()
        setupFooterView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if (UIDevice.current.userInterfaceIdiom == .phone), UIDevice().hasNotch {
            let isLandscape = UIDevice.current.orientation.isLandscape
            let tableViewWidth = isLandscape ? view.bounds.width - 80 : view.bounds.width
            tableView.frame = CGRect(x: isLandscape ? 40 : 0, y: tableView.frame.minY, width: tableViewWidth, height: tableView.bounds.height)
            tableView.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + 60, right: 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        if ((notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tableViewBottomInset, right: 0)
        }
    }

    @objc func changeTheming() {
        tableView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.customer
        tableView.reloadData()
    }
    
    func setupFooterView() {
        guard let footerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionFooter", owner: self, options: nil)?.first as? NCShareAdvancePermissionFooter) else { return }
        footerView.setupUI(delegate: self, account: metadata.account)

        // tableFooterView can't use auto layout directly
        footerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100)
        self.view.addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        footerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        footerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        footerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tableViewBottomInset, right: 0)
        
    }

    func setupHeaderView() {
        guard let headerView = (Bundle.main.loadNibNamed("NCShareHeader", owner: self, options: nil)?.first as? NCShareHeader) else { return }
        headerView.setupUI(with: metadata)
        headerView.ocId = metadata.ocId
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 190)
        self.tableView.tableHeaderView = headerView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }

    func initializeForm() {
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Other Cells")
        
        //Sharing
        section = XLFormSectionDescriptor.formSection(withTitle: "")
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        row = XLFormRowDescriptor(tag: "NCFilePermissionCellSharing", rowType: "kNMCFilePermissionCell", title: "")
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_sharing_", comment: "")
        row.height = 44
        section.addFormRow(row)
        
        //PERMISSION
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCShareHeaderCustomCell"] = NCShareHeaderCustomCell.self
        row = XLFormRowDescriptor(tag: "kNMCShareHeaderCustomCell", rowType: "kNMCShareHeaderCustomCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
        row.height = 26
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_PERMISSIONS_", comment: "")
        section.addFormRow(row)
        
        //read only
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        row = XLFormRowDescriptor(tag: "NCFilePermissionCellRead", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_read_only_", comment: "")
        row.height = 44
        
        if let permission = self.permission, !CCUtility.isAnyPermission(toEdit: permission), permission !=  NCGlobal.shared.permissionCreateShare {
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
        }
        if isNewShare {
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            self.permission = NCGlobal.shared.permissionReadShare
        }
        section.addFormRow(row)
        
        //editing
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellEditing", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_allow_editing_", comment: "")
        row.height = 44
        if let permission = self.permission {
            if CCUtility.isAnyPermission(toEdit: permission), permission != NCGlobal.shared.permissionCreateShare {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            }
        }
        let enabled = NCShareCommon().isEditingEnabled(isDirectory: metadata.directory, fileExtension: metadata.fileExtension, shareType: shareType) || checkIsCollaboraFile()
        row.cellConfig["titleLabel.textColor"] = enabled ? NCBrandColor.shared.label : NCBrandColor.shared.systemGray
        row.disabled = !enabled
        section.addFormRow(row)
        
        if !enabled {
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellEditingMsg", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("share_editing_message", comment: "")
            row.cellConfig["titleLabel.textColor"] = NCBrandColor.shared.gray60
            row.height = 80
            section.addFormRow(row)
        }
        
        //file drop
        if isFileDropOptionVisible() {
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
            row = XLFormRowDescriptor(tag: "NCFilePermissionCellFileDrop", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_file_drop_", comment: "")
            if self.permission == NCGlobal.shared.permissionCreateShare {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            }
            row.height = 44
            section.addFormRow(row)
            
            //sammelbox message
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
            
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellFiledropMessage", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_file_drop_message_", comment: "")
            row.cellConfig["titleLabel.textColor"] = NCBrandColor.shared.gray60
            row.cellConfig["imageCheck.image"] = UIImage()
            row.height = 84
            section.addFormRow(row)
        }
        
        //empty cell
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCXLFormBaseCell"] = NCSeparatorCell.self
        row = XLFormRowDescriptor(tag: "kNMCXLFormBaseCell", rowType: "kNMCXLFormBaseCell", title: NSLocalizedString("", comment: ""))
        row.height = 16
        section.addFormRow(row)
        
        //ADVANCE PERMISSION
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self

        row = XLFormRowDescriptor(tag: "NCFilePermissionCellAdvanceTxt", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_advance_permissions_", comment: "")
        row.height = 52
        section.addFormRow(row)

        if isLinkShare() {
            //link label section header
            
            // Custom Link label
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNCShareTextInputCell"] = NCShareTextInputCell.self
            row = XLFormRowDescriptor(tag: "kNCShareTextInputCellCustomLinkField", rowType: "kNCShareTextInputCell", title: "")
            row.cellConfig["cellTextField.placeholder"] = NSLocalizedString("_custom_link_label", comment: "")
            row.cellConfig["cellTextField.text"] = oldTableShare?.label
            row.cellConfig["cellTextField.textAlignment"] = NSTextAlignment.left.rawValue
            row.cellConfig["cellTextField.font"] = UIFont.systemFont(ofSize: 15.0)
            row.cellConfig["cellTextField.textColor"] = NCBrandColor.shared.label
            row.height = 44
            section.addFormRow(row)
        }

        //can reshare
        if isCanReshareOptionVisible() {
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
            
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellEditingCanShare", rowType: "kNMCFilePermissionEditCell", title: "")
            row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
            row.cellClass = NCFilePermissionEditCell.self
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_can_reshare_", comment: "")
            row.height = 44
            section.addFormRow(row)
        }
        
        //hide download
        if isHideDownloadOptionVisible() {
            
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellHideDownload", rowType: "kNMCFilePermissionEditCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_hide_download_", comment: "")
            row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
            row.cellClass = NCFilePermissionEditCell.self
            row.height = 44
            section.addFormRow(row)
        }

        //password
        if isPasswordOptionsVisible() {
            
            // Set password
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditPasswordCellWithText", rowType: "kNMCFilePermissionEditCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_set_password_", comment: "")
            row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
            row.cellClass = NCFilePermissionEditCell.self
            row.height = 44
            section.addFormRow(row)
            
            // enter password input field
            XLFormViewController.cellClassesForRowDescriptorTypes()["NMCSetPasswordCustomInputField"] = PasswordInputField.self
            row = XLFormRowDescriptor(tag: "SetPasswordInputField", rowType: "NMCSetPasswordCustomInputField", title: NSLocalizedString("_filename_", comment: ""))
            row.cellClass = PasswordInputField.self
            row.cellConfig["fileNameInputTextField.placeholder"] = NSLocalizedString("_password_", comment: "")
            row.cellConfig["fileNameInputTextField.textAlignment"] = NSTextAlignment.left.rawValue
            row.cellConfig["fileNameInputTextField.font"] = UIFont.systemFont(ofSize: 15.0)
            row.cellConfig["fileNameInputTextField.textColor"] = NCBrandColor.shared.label
            row.cellConfig["backgroundColor"] = NCBrandColor.shared.secondarySystemGroupedBackground
            row.height = 44
            let hasPassword = oldTableShare?.password != nil && !oldTableShare!.password.isEmpty
            row.hidden = NSNumber.init(booleanLiteral: !hasPassword)
            section.addFormRow(row)
        }

        //expiration
        
        // expiry date switch
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellExpiration", rowType: "kNMCFilePermissionEditCell", title: NSLocalizedString("_share_expiration_date_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_expiration_date_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
        row.cellClass = NCFilePermissionEditCell.self
        row.height = 44
        section.addFormRow(row)
        
        // set expiry date field
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNCShareTextInputCell"] = NCShareTextInputCell.self
        row = XLFormRowDescriptor(tag: "NCShareTextInputCellExpiry", rowType: "kNCShareTextInputCell", title: "")
        row.cellClass = NCShareTextInputCell.self
        row.cellConfig["cellTextField.placeholder"] = NSLocalizedString("_share_expiration_date_placeholder_", comment: "")
        if !isNewShare {
            if let date = oldTableShare?.expirationDate {
                row.cellConfig["cellTextField.text"] = DateFormatter.shareExpDate.string(from: date as Date)
            }
        }
        row.cellConfig["cellTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["cellTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellTextField.textColor"] = NCBrandColor.shared.label
        if let date = oldTableShare?.expirationDate {
            row.cellConfig["cellTextField.text"] = DateFormatter.shareExpDate.string(from: date as Date)
        }
        row.height = 44
        let hasExpiry = oldTableShare?.expirationDate != nil
        row.hidden = NSNumber.init(booleanLiteral: !hasExpiry)
        section.addFormRow(row)
        
        if isDownloadLimitVisible() {
            // DownloadLimit switch
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellDownloadLimit", rowType: "kNMCFilePermissionEditCell", title: NSLocalizedString("_share_download_limit_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_download_limit_", comment: "")
            row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
            row.cellClass = NCFilePermissionEditCell.self
            row.height = 44
            section.addFormRow(row)
            
            // set Download Limit field
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNCShareTextInputCell"] = NCShareTextInputCell.self
            row = XLFormRowDescriptor(tag: "NCShareTextInputCellDownloadLimit", rowType: "kNCShareTextInputCell", title: "")
            row.cellClass = NCShareTextInputCell.self
            row.cellConfig["cellTextField.placeholder"] = NSLocalizedString("_share_download_limit_placeholder_", comment: "")
            row.cellConfig["cellTextField.textAlignment"] = NSTextAlignment.left.rawValue
            row.cellConfig["cellTextField.font"] = UIFont.systemFont(ofSize: 15.0)
            row.cellConfig["cellTextField.textColor"] = NCBrandColor.shared.label
            row.height = 44
            let downloadLimitSet = downloadLimit?.limit != nil
            row.hidden = NSNumber.init(booleanLiteral: !downloadLimitSet)
            if let value = downloadLimit?.limit {
                row.cellConfig["cellTextField.text"] = "\(value)"
            }
            section.addFormRow(row)
            
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
            row = XLFormRowDescriptor(tag: "kNMCDownloadLimitCell", rowType: "kNMCFilePermissionCell", title: "")
            row.cellClass = NCFilePermissionCell.self
            row.height = 44
            if downloadLimit?.limit != nil {
                row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_remaining_download_", comment: "") + " \(downloadLimit?.count ?? 0)"
            }
            row.cellConfig["titleLabel.textColor"] =  NCBrandColor.shared.systemGray
            row.disabled = true
            row.hidden = NSNumber.init(booleanLiteral: !downloadLimitSet)
            section.addFormRow(row)
        }
        
        form.addFormSection(section)
        self.form = form
    }
    
    func reloadForm() {
        self.form.delegate = nil
        self.tableView.reloadData()
        self.form.delegate = self
    }
    
    func updateDownloadLimitUI() {
        if let value = downloadLimit?.limit {
            if let downloadLimitSwitchField: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellDownloadLimit") {
                if let indexPath = self.form.indexPath(ofFormRow: downloadLimitSwitchField) {
                    let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionEditCell
                    cell?.switchControl.isOn = true
                }
                    
                if let downloadLimitInputField: XLFormRowDescriptor = self.form.formRow(withTag: "NCShareTextInputCellDownloadLimit") {
                    downloadLimitInputField.hidden = false
                    if let indexPath = self.form.indexPath(ofFormRow: downloadLimitInputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? NCShareTextInputCell
                        cell?.cellTextField.text = "\(value)"
                    }
                }
                
                if let downloadLimitInputField: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCDownloadLimitCell") {
                    downloadLimitInputField.hidden = false
                    if let indexPath = self.form.indexPath(ofFormRow: downloadLimitInputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionCell
                        cell?.titleLabel.text = NSLocalizedString("_share_remaining_download_", comment: "") + " \(downloadLimit?.count ?? 0)"
                    }
                }
            }
        }
    }
    
    func getDownloadLimitSwitchCell() -> NCFilePermissionEditCell? {
        if let downloadLimitSwitchField: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellDownloadLimit") {
            if let indexPath = self.form.indexPath(ofFormRow: downloadLimitSwitchField) {
                let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionEditCell
                return cell
            }
        }
        return nil
    }
    
    func getDownloadLimitInputCell() -> NCShareTextInputCell? {
        if let downloadLimitInputField: XLFormRowDescriptor = self.form.formRow(withTag: "NCShareTextInputCellDownloadLimit") {
            if let indexPath = self.form.indexPath(ofFormRow: downloadLimitInputField) {
                let cell = tableView.cellForRow(at: indexPath) as? NCShareTextInputCell
                return cell
            }
        }
        return nil
    }
    
    // MARK: - Row Descriptor Value Changed
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor!) {
        guard let metadata = self.metadata else { return }

        switch formRow.tag {
        case "NCFilePermissionCellRead":

            let value = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: canReshareTheShare(), andIsFolder: metadata.directory)
            self.permission = value
//            self.permissions = "RDNVCK"
            metadata.permissions = "RDNVCK"
            if let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead") {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
                if let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing") {
                    row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
                }
                if let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop") {
                    row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
                }
            }

            self.reloadForm()
            break
        case "kNMCFilePermissionCellEditing":
             let value = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: canReshareTheShare(), andIsFolder: metadata.directory)
            self.permission = value
//            self.permissions = "RGDNV"
            metadata.permissions = "RGDNV"
            if let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead") {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            }
            if let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing") {
                row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            }
            if let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop") {
                row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            }
            self.reloadForm()
            break
        case "NCFilePermissionCellFileDrop":
            self.permission = NCGlobal.shared.permissionCreateShare
//            self.permissions = "RGDNVCK"
            metadata.permissions = "RGDNVCK"
            if let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead") {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            }
            if let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing") {
                row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            }
            if let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop") {
                row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            }
            self.reloadForm()
            break
        default:
            break
        }
    }

    func canReshareTheShare() -> Bool {
        if let permissionValue = self.permission {
            let canReshare = CCUtility.isPermission(toCanShare: permissionValue)
            return canReshare
        } else {
            return false
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let advancePermissionHeaderRow: XLFormRowDescriptor = self.form.formRow(withTag: "NCFilePermissionCellAdvanceTxt") {
            if let advancePermissionHeaderRowIndexPath = form.indexPath(ofFormRow: advancePermissionHeaderRow), indexPath == advancePermissionHeaderRowIndexPath {
                let cell = cell as? NCFilePermissionCell
                cell?.seperatorBelowFull.isHidden = isLinkShare()
            }
        }

        //can Reshare
        if let canReshareRow: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellEditingCanShare") {
            if let canReShareRowIndexPath = form.indexPath(ofFormRow: canReshareRow), indexPath == canReShareRowIndexPath {
                let cell = cell as? NCFilePermissionEditCell
                // Can reshare (file)
                if let permissionValue = self.permission {
                    let canReshare = CCUtility.isPermission(toCanShare: permissionValue)
                    cell?.switchControl.isOn = canReshare
                } else {
                    //new share
                    cell?.switchControl.isOn = false
                }
            }
        }
        //hide download
        if let hideDownloadRow: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellHideDownload"){
            if let hideDownloadRowIndexPath = form.indexPath(ofFormRow: hideDownloadRow), indexPath == hideDownloadRowIndexPath {
                let cell = cell as? NCFilePermissionEditCell
                cell?.switchControl.isOn = oldTableShare?.hideDownload ?? false
                cell?.titleLabel.isEnabled = !(self.permission == NCGlobal.shared.permissionCreateShare)
                cell?.switchControl.isEnabled = !(self.permission == NCGlobal.shared.permissionCreateShare)
                cell?.isUserInteractionEnabled = !(self.permission == NCGlobal.shared.permissionCreateShare)
            }

            // set password
            if let setPassword : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionEditPasswordCellWithText") {
                if let setPasswordIndexPath = self.form.indexPath(ofFormRow: setPassword), indexPath == setPasswordIndexPath {
                    let passwordCell = cell as? NCFilePermissionEditCell
                    if let password = oldTableShare?.password {
                        passwordCell?.switchControl.isOn = !password.isEmpty
                    } else {
                        passwordCell?.switchControl.isOn = false
                    }
                }
            }
        }

        //updateExpiryDateSwitch
        if let expiryRow : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionEditCellExpiration") {
            if let expiryIndexPath = self.form.indexPath(ofFormRow: expiryRow), indexPath == expiryIndexPath {
                let cell = cell as? NCFilePermissionEditCell
                if oldTableShare?.expirationDate != nil {
                    cell?.switchControl.isOn = true
                } else {
                    //new share
                    cell?.switchControl.isOn = false
                }
            }
        }

        //SetDownloadLimitSwitch
        if let limitRow : XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellDownloadLimit") {
            if let expiryIndexPath = self.form.indexPath(ofFormRow: limitRow), indexPath == expiryIndexPath {
                let cell = cell as? NCFilePermissionEditCell
                cell?.switchControl.isOn = downloadLimit?.limit != nil
            }
        }

        //SetDownloadLimitSwitch
        if let downloadlimitFieldRow : XLFormRowDescriptor = self.form.formRow(withTag: "NCShareTextInputCellDownloadLimit") {
            if let downloadlimitIndexPath = self.form.indexPath(ofFormRow: downloadlimitFieldRow), indexPath == downloadlimitIndexPath {
                let cell = cell as? NCShareTextInputCell
                cell?.cellTextField.text = "\(downloadLimit?.limit ?? 0)"
            }
        }

        //SetDownloadLimitSwitch
        if downloadLimit?.count != nil {
            if let downloadlimitFieldRow : XLFormRowDescriptor = self.form.formRow(withTag: "kNMCDownloadLimitCell") {
                if let downloadlimitIndexPath = self.form.indexPath(ofFormRow: downloadlimitFieldRow), indexPath == downloadlimitIndexPath {
                    let cell = cell as? NCFilePermissionCell
                    cell?.titleLabel.text = NSLocalizedString("_share_remaining_download_", comment: "") + " \(downloadLimit?.count ?? 0)"
                    cell?.seperatorBelowFull.isHidden = true
                    cell?.seperatorBelow.isHidden = true
                }
            }
        }
    }

    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)

        switch formRow.tag {

        case "kNMCFilePermissionEditCellEditingCanShare":
            if let value = newValue as? Bool {
                canReshareValueChanged(isOn: value)
            }

        case "kNMCFilePermissionEditCellHideDownload":
            if let value = newValue as? Bool {
                share.hideDownload = value
            }

        case "kNMCFilePermissionEditPasswordCellWithText":
            if let value = newValue as? Bool {
                if let setPasswordInputField : XLFormRowDescriptor  = self.form.formRow(withTag: "SetPasswordInputField") {
                    if let indexPath = self.form.indexPath(ofFormRow: setPasswordInputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? PasswordInputField
                        cell?.fileNameInputTextField.text = ""
                    }
                    share.password = ""
                    setPasswordInputField.hidden = !value
                }
            }

        case "kNCShareTextInputCellCustomLinkField":
            if let label = formRow.value as? String {
                self.form.delegate = nil
                share.label = label
                self.form.delegate = self
            }

        case "SetPasswordInputField":
            if let pwd = formRow.value as? String {
                self.form.delegate = nil
                share.password = pwd
                self.form.delegate = self
            }

        case "kNMCFilePermissionEditCellLinkLabel":
            if let label = formRow.value as? String {
                self.form.delegate = nil
                share.label = label
                self.form.delegate = self
            }

        case "kNMCFilePermissionEditCellExpiration":
            if let value = newValue as? Bool {
                if let inputField : XLFormRowDescriptor = self.form.formRow(withTag: "NCShareTextInputCellExpiry") {
                    inputField.hidden = !value
                }
            }

        case "kNMCFilePermissionEditCellDownloadLimit":
            if let value = newValue as? Bool {
                self.downloadLimit = DownloadLimit()
                self.downloadLimit?.limit = value ? 0 : nil
                if let inputField : XLFormRowDescriptor = self.form.formRow(withTag: "NCShareTextInputCellDownloadLimit") {
                    inputField.hidden = !value
                    if let indexPath = self.form.indexPath(ofFormRow: inputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? NCShareTextInputCell
                        cell?.cellTextField.text = ""
                    }
                }

                if let inputField : XLFormRowDescriptor = self.form.formRow(withTag: "kNMCDownloadLimitCell") {
                    inputField.hidden = !value
                    if let indexPath = self.form.indexPath(ofFormRow: inputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionCell
                        cell?.seperatorBelowFull.isHidden = true
                        cell?.seperatorBelow.isHidden = true
                        cell?.titleLabel.text = ""
                    }
                }
            }

        case "NCShareTextInputCellExpiry":
            if let exp = formRow.value as? Date {
                self.form.delegate = nil
                self.share.expirationDate = exp as NSDate
                self.form.delegate = self
            }

        default:
            break
        }
    }
    //Check file type is collabora
    func checkIsCollaboraFile() -> Bool {
        guard let metadata = metadata else {
            return false
        }
        
        // EDITORS
        let editors = NCUtility().isDirectEditing(account: metadata.account, contentType: metadata.contentType)
        let availableRichDocument = NCUtility().isRichDocument(metadata)
        
        // RichDocument: Collabora
        return (availableRichDocument && editors.count == 0)
    }
    
    func isFileDropOptionVisible() -> Bool {
        return (metadata.directory && (isLinkShare() || isExternalUserShare()))
    }
    
    func isLinkShare() -> Bool {
        return NCShareCommon().isLinkShare(shareType: shareType)
    }
    
    func isExternalUserShare() -> Bool {
        return NCShareCommon().isExternalUserShare(shareType: shareType)
    }
    
    func isInternalUser() -> Bool {
        return NCShareCommon().isInternalUser(shareType: shareType)
    }
    
    func isCanReshareOptionVisible() -> Bool {
        return isInternalUser()
    }
    
    func isHideDownloadOptionVisible() -> Bool {
        return !isInternalUser()
    }
    
    func isPasswordOptionsVisible() -> Bool {
        return !isInternalUser()
    }
    
    func isDownloadLimitVisible() -> Bool {
        return isLinkShare() && !(metadata.directory)
    }
    
    func canReshareValueChanged(isOn: Bool) {
        
        guard let oldTableShare = oldTableShare, let permission = self.permission else {
            self.permission = isOn ? (self.permission ?? 0) + NCGlobal.shared.permissionShareShare : ((self.permission ?? 0) - NCGlobal.shared.permissionShareShare)
            return
        }

        let canEdit = CCUtility.isAnyPermission(toEdit: permission)
        let canCreate = CCUtility.isPermission(toCanCreate: permission)
        let canChange = CCUtility.isPermission(toCanChange: permission)
        let canDelete = CCUtility.isPermission(toCanDelete: permission)

        if metadata.directory {
            self.permission = CCUtility.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: canChange, andCanDelete: canDelete, andCanShare: isOn, andIsFolder: metadata.directory)
        } else {
            if isOn {
                if canEdit {
                    self.permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: isOn, andIsFolder: metadata.directory)
                } else {
                    self.permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: isOn, andIsFolder: metadata.directory)
                }
            } else {
                if canEdit {
                    self.permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: isOn, andIsFolder: metadata.directory)
                } else {
                    self.permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: isOn, andIsFolder: metadata.directory)
                }
            }
        }
    }
    
    func getDownloadLimit() {
        NCActivityIndicator.shared.start(backgroundView: view)
        NMCCommunication.shared.getDownloadLimit(token: oldTableShare?.token ?? "") { [weak self] (downloadLimit: DownloadLimit?, error: String) in
            DispatchQueue.main.async {
                NCActivityIndicator.shared.stop()
                if let downloadLimit = downloadLimit {
                    self?.downloadLimit = downloadLimit
                }
                self?.updateDownloadLimitUI()
            }
        }
    }
    
    func setDownloadLimit(deleteLimit: Bool, limit: String) {
        NMCCommunication.shared.setDownloadLimit(deleteLimit: deleteLimit, limit: limit, token: oldTableShare?.token ?? "") { (success, errorMessage) in
            print(success)
        }
    }
    
    func showDownloadLimitError(message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { action in }))
        self.present(alertController, animated: true)
    }
}

// MARK: - NCShareDownloadLimitTableViewControllerDelegate

extension NCShareAdvancePermission: NCShareDownloadLimitTableViewControllerDelegate {
    func didSetDownloadLimit(_ downloadLimit: DownloadLimitViewModel) {
        self.downloadLimit = downloadLimit
    }
}
