//
//  NCShareAdvancePermission.swift
//  Nextcloud
//
//  Created by T-systems on 09/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit
import NCCommunication
import SVGKit

class NCShareAdvancePermission: XLFormViewController, NCSelectDelegate, NCShareNetworkingDelegate, NCShareAdvancePermissionHeaderDelegate {
    fileprivate struct Tags {
        static let SwitchBool = "switchBool"
        static let SwitchCheck = "switchCheck"
        static let StepCounter = "stepCounter"
        static let Slider = "slider"
        static let SegmentedControl = "segmentedControl"
        static let Custom = "custom"
        static let Info = "info"
        static let Button = "button"
        static let Image = "image"
        static let ButtonLeftAligned = "buttonLeftAligned"
        static let ButtonWithSegueId = "buttonWithSegueId"
        static let ButtonWithSegueClass = "buttonWithSegueClass"
        static let ButtonWithNibName = "buttonWithNibName"
        static let ButtonWithStoryboardId = "buttonWithStoryboardId"
    }
    
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    public var tableShare: tableShare?
    private var networking: NCShareNetworking?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewWindowCalendar: UIView?
    var width: CGFloat = 0
    var height: CGFloat = 0
    var filePermissionCount = 0
    var password: String!
    var linkLabel = ""
    var expirationDate: NSDate!
    var permissionIndex = 0
    var permissions = "RDNVCK"
    var shareeEmail: String?
    var dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd/MM/yyyy"
      return formatter
    }()
    let datePicker = UIDatePicker()
    var newUser: Bool = false
    lazy var shareType: Int = {
        if newUser {
            return sharee?.shareType ?? NCShareCommon.shared.SHARE_TYPE_USER
        }
        return tableShare?.shareType ?? NCShareCommon.shared.SHARE_TYPE_USER
    }()
    var permissionInt = NCGlobal.shared.permissionReadShare
    var rowInFirstSection = 0
    var canReshare = false
    var hideDownload = false
    var passwordProtected = false
    var setExpiration = false
    var headerView: NCShareAdvancePermissionHeader! = nil
    var footerView: NCShareAdvancePermissionFooter! = nil
    var directory: Bool = false
    var typeFile: String!
    let tableViewBottomInset: CGFloat = 80.0
    static let displayDateFormat = "dd. MMM. yyyy"
    var downloadLimit: DownloadLimit?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.typeFile = self.metadata?.classFile
        
        self.metadata?.permissions = self.permissions
        if !newUser {
            if let expire = metadata?.trashbinDeletionTime {
                
                if expire.timeIntervalSinceNow.sign == .minus {
                     print("date1 is earlier than date2")
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.formatterBehavior = .behavior10_4
                    dateFormatter.dateStyle = .medium
//                    self.expirationDateText = dateFormatter.string(from: expire as Date)
                    
                    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    self.expirationDate = expire
                }
            }
        }
        setTitle()
        getDownloadLimit()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if newUser == false {
            
            switch metadata?.permissions {
            case "RDNVCK":
                self.permissionIndex = 0
                break
            case "RGDNV":
                self.permissionIndex = 1
                break
            case "RGDNVCK":
                self.permissionIndex = 2
                break
            default:
                break
            }
            
            if let expire = tableShare?.expirationDate {
                
                if expire.timeIntervalSinceNow.sign == .minus {
                     print("date1 is earlier than date2")
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.formatterBehavior = .behavior10_4
                    dateFormatter.dateStyle = .medium
//                    self.expirationDateText = dateFormatter.string(from: expire as Date)
                    
                    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    self.expirationDate = expire
                }
            }
        }

        self.directory = self.metadata?.directory ?? false
        self.linkLabel = tableShare?.label ?? ""
        self.permissionInt = tableShare?.permissions ?? NCGlobal.shared.permissionReadShare
        self.hideDownload = tableShare?.hideDownload ?? false
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase,  view: self.view, delegate: self)
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        initializeForm()
        changeTheming()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
    }
    
    func setTitle() {
        if newUser {
            title = sharee?.shareWith ?? NSLocalizedString("_sharing_", comment: "")
        } else {
            if let shareType = tableShare?.shareType, shareType == NCShareCommon.shared.SHARE_TYPE_USER || shareType == NCShareCommon.shared.SHARE_TYPE_EMAIL {
                title = tableShare?.shareWith ?? NSLocalizedString("_sharing_", comment: "")
            } else {
                title = NSLocalizedString("_sharing_", comment: "")
            }
        }
    }
    
    @objc func changeTheming() {
        tableView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.customer
        self.headerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.headerView.fileName.textColor = NCBrandColor.shared.label
        self.headerView.info.textColor = NCBrandColor.shared.textInfo
        self.footerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        
        self.footerView.buttonCancel.setTitleColor(NCBrandColor.shared.label, for: .normal)
        footerView.buttonCancel.layer.borderColor = NCBrandColor.shared.label.cgColor
        footerView.buttonCancel.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.footerView.buttonNext.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        self.footerView.buttonNext.setTitleColor(.white, for: .normal)
        
        tableView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        footerView.buttonCancel.layer.borderColor = NCBrandColor.shared.label.cgColor
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

    func initializeForm() {
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Other Cells")
        
        self.headerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as! NCShareAdvancePermissionHeader)
        self.headerView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
            self.headerView.fullWidthImageView.image = getImageMetadata(metadata!)
            self.headerView.fullWidthImageView.contentMode = .scaleAspectFill
            self.headerView.imageView.isHidden = true
        } else {
            if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                self.headerView.imageView.image = image
            } else if metadata!.iconName.count > 0 {
                self.headerView.imageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                self.headerView.imageView.image = UIImage.init(named: "file")
            }
        }
        self.headerView.favorite.setNeedsUpdateConstraints()
        self.headerView.favorite.layoutIfNeeded()
        self.headerView.fileName.text = self.metadata?.fileNameView
        self.headerView.fileName.textColor = NCBrandColor.shared.fileFolderName
        self.headerView.favorite.addTarget(self, action: #selector(favoriteClicked), for: .touchUpInside)
        if metadata!.favorite {
            self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
        } else {
            self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
        }
        self.headerView.info.textColor = NCBrandColor.shared.optionItem
        self.headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        self.headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 190)
        self.tableView.tableHeaderView = self.headerView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 190).isActive = true
        headerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
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
        
        if let permission = tableShare?.permissions, !CCUtility.isAnyPermission(toEdit: permission), permission !=  NCGlobal.shared.permissionCreateShare {
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
        }
        if newUser {
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
        }
        section.addFormRow(row)
        
        //editing
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellEditing", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_allow_editing_", comment: "")
        row.height = 44
        if let permission = tableShare?.permissions {
            if CCUtility.isAnyPermission(toEdit: permission), permission != NCGlobal.shared.permissionCreateShare {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            }
        }
        let enabled = NCShareCommon.shared.isEditingEnabled(isDirectory: directory, fileExtension: metadata?.ext ?? "", shareType: shareType)
        row.cellConfig["titleLabel.textColor"] = enabled ? NCBrandColor.shared.label : NCBrandColor.shared.systemGray
        row.disabled = !enabled
        section.addFormRow(row)
        
        if !enabled {
            row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellEditingMsg", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("share_editing_message", comment: "")
            row.cellConfig["titleLabel.textColor"] = NCBrandColor.shared.gray60
            row.height = 60
            section.addFormRow(row)
        }
        
        //file drop
        if isFileDropOptionVisible() {
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
            row = XLFormRowDescriptor(tag: "NCFilePermissionCellFileDrop", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSIONS_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_file_drop_", comment: "")
            if tableShare?.permissions == NCGlobal.shared.permissionCreateShare {
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
            row.cellConfig["cellTextField.text"] = tableShare?.label
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
            let hasPassword = tableShare?.password != nil && !tableShare!.password.isEmpty
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
        if newUser == false {
            if let date = tableShare?.expirationDate {
                row.cellConfig["cellTextField.text"] = getDisplayStyleDate(date: date as Date)
            }
        }
        row.cellConfig["cellTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["cellTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellTextField.textColor"] = NCBrandColor.shared.label
        if let date = expirationDate {
            row.cellConfig["cellTextField.text"] = getDisplayStyleDate(date: date as Date)
        }
        row.height = 44
        let hasExpiry = tableShare?.expirationDate != nil
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
        
        self.footerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionFooter", owner: self, options: nil)?.first as! NCShareAdvancePermissionFooter)
        self.footerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100)
        self.footerView.buttonCancel.addTarget(self, action: #selector(cancelClicked(_:)), for: .touchUpInside)
        self.footerView.buttonNext.addTarget(self, action: #selector(nextClicked(_:)), for: .touchUpInside)
        self.footerView.buttonCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        self.footerView.buttonCancel.layer.cornerRadius = 10
        self.footerView.buttonCancel.layer.masksToBounds = true
        self.footerView.buttonCancel.layer.borderWidth = 1
        footerView.addShadow(location: .top)

        if newUser {
            self.footerView.buttonNext.setTitle(NSLocalizedString("_next_", comment: ""), for: .normal)
        } else {
            self.footerView.buttonNext.setTitle(NSLocalizedString("_apply_changes_", comment: ""), for: .normal)
        }
        self.footerView.buttonNext.layer.cornerRadius = 10
        self.footerView.buttonNext.layer.masksToBounds = true
        
        self.view.addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        footerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        footerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        footerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tableViewBottomInset, right: 0)
        form.addFormSection(section)
        self.form = form
    }
    
    func getDownloadLimit() {
        NCUtility.shared.startActivityIndicator(backgroundView: view, blurEffect: false)
        NMCCommunication.shared.getDownloadLimit(token: tableShare?.token ?? "") { [weak self] (downloadLimit: DownloadLimit?, error: String) in
            DispatchQueue.main.async {
                NCUtility.shared.stopActivityIndicator()
                if let downloadLimit = downloadLimit {
                    self?.downloadLimit = downloadLimit
                }
                self?.updateDownloadLimitUI()
            }
        }
    }
    
    func setDownloadLimit(deleteLimit: Bool, limit: String) {
        NMCCommunication.shared.setDownloadLimit(deleteLimit: deleteLimit, limit: limit, token: tableShare?.token ?? "") { (success, errorMessage) in
            print(success)
        }
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
    
    func reloadForm() {
        self.form.delegate = nil
        self.tableView.reloadData()
        self.form.delegate = self
    }
    
    // MARK: - Row Descriptor Value Changed
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor!) {
        guard let metadata = self.metadata else { return }
       
        switch formRow.tag {
        case "NCFilePermissionCellRead":
            
            let value = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: canReshareTheShare(), andIsFolder: metadata.directory)
            self.permissionInt = value
            self.tableShare?.setPermission(value: value)
            self.permissions = "RDNVCK"
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
            self.permissionInt = value
            self.tableShare?.setPermission(value: value)
            self.permissions = "RGDNV"
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
            self.permissionInt = NCGlobal.shared.permissionCreateShare
            
            self.tableShare?.setPermission(value: NCGlobal.shared.permissionCreateShare)
            self.permissions = "RGDNVCK"
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
        if let permissionValue = tableShare?.permissions {
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
                if let permissionValue = tableShare?.permissions {
                    let canReshare = CCUtility.isPermission(toCanShare: permissionValue)
                    cell?.switchControl.isOn = canReshare
                } else {
                    //new share
                    cell?.switchControl.isOn = canReshare
                }
            }
        }
        //hide download
        if let hideDownloadRow: XLFormRowDescriptor = self.form.formRow(withTag: "kNMCFilePermissionEditCellHideDownload"){
            if let hideDownloadRowIndexPath = form.indexPath(ofFormRow: hideDownloadRow), indexPath == hideDownloadRowIndexPath {
                let cell = cell as? NCFilePermissionEditCell
                cell?.switchControl.isOn = tableShare?.hideDownload ?? false
                cell?.titleLabel.isEnabled = !(permissionInt == NCGlobal.shared.permissionCreateShare)
                cell?.switchControl.isEnabled = !(permissionInt == NCGlobal.shared.permissionCreateShare)
                cell?.isUserInteractionEnabled = !(permissionInt == NCGlobal.shared.permissionCreateShare)
            }
            
            // set password
            if let setPassword : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionEditPasswordCellWithText") {
                if let setPasswordIndexPath = self.form.indexPath(ofFormRow: setPassword), indexPath == setPasswordIndexPath {
                    let passwordCell = cell as? NCFilePermissionEditCell
                    if let password = tableShare?.password {
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
                if tableShare?.expirationDate != nil {
                    cell?.switchControl.isOn = true
                } else {
                    //new share
                    cell?.switchControl.isOn = setExpiration
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
                self.hideDownload = value
            }
            
        case "kNMCFilePermissionEditPasswordCellWithText":
            if let value = newValue as? Bool {
                self.passwordProtected = value
                if let setPasswordInputField : XLFormRowDescriptor  = self.form.formRow(withTag: "SetPasswordInputField") {
                    if let indexPath = self.form.indexPath(ofFormRow: setPasswordInputField) {
                        let cell = tableView.cellForRow(at: indexPath) as? PasswordInputField
                        cell?.fileNameInputTextField.text = ""
                    }
                    password = ""
                    setPasswordInputField.hidden = !value
                }
            }
            
        case "kNCShareTextInputCellCustomLinkField":
            if let label = formRow.value as? String {
                self.form.delegate = nil
                self.linkLabel = label
                self.form.delegate = self
            }
            
        case "SetPasswordInputField":
            if let pwd = formRow.value as? String {
                self.form.delegate = nil
                self.password = pwd
                self.form.delegate = self
            }
            
        case "kNMCFilePermissionEditCellLinkLabel":
            if let label = formRow.value as? String {
                self.form.delegate = nil
                self.linkLabel = label
                self.form.delegate = self
            }
            
        case "kNMCFilePermissionEditCellExpiration":
            if let value = newValue as? Bool {
                self.setExpiration = value
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
                expirationDate = exp as NSDate
                self.form.delegate = self
            }
            
        default:
            break
        }
    }
    
    func getServerStyleDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let expiryDate = dateFormatter.string(from: date)
        return expiryDate
    }
    
    func getDisplayStyleDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = NCShareAdvancePermission.displayDateFormat
        var expiryDate = dateFormatter.string(from: date)
        expiryDate = expiryDate.replacingOccurrences(of: "..", with: ".")
        return expiryDate
    }
    
    func canReshareValueChanged(isOn: Bool) {
        guard let tableShare = self.tableShare else {
            //new share
            canReshare = isOn
            return
        }
        guard let metadata = self.metadata else { return }
        
        let canEdit = CCUtility.isAnyPermission(toEdit: tableShare.permissions)
        let canCreate = CCUtility.isPermission(toCanCreate: tableShare.permissions)
        let canChange = CCUtility.isPermission(toCanChange: tableShare.permissions)
        let canDelete = CCUtility.isPermission(toCanDelete: tableShare.permissions)
        
        var permission: Int = 0
        
        if metadata.directory {
            permission = CCUtility.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: canChange, andCanDelete: canDelete, andCanShare: isOn, andIsFolder: metadata.directory)
        } else {
            if isOn {
                if canEdit {
                    permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: isOn, andIsFolder: metadata.directory)
                } else {
                    permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: isOn, andIsFolder: metadata.directory)
                }
            } else {
                if canEdit {
                    permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: isOn, andIsFolder: metadata.directory)
                } else {
                    permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: isOn, andIsFolder: metadata.directory)
                }
            }
        }
        self.tableShare?.setPermission(value: permission)
        self.permissionInt = permission
        canReshare = isOn
    }
    
    func isFileDropOptionVisible() -> Bool {
        return (directory && (isLinkShare() || isExternalUserShare()))
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
        return isLinkShare() && !(metadata?.directory ?? false)
    }
    
    func isLinkShare() -> Bool {
        return NCShareCommon.shared.isLinkShare(shareType: shareType)
    }
    
    func isExternalUserShare() -> Bool {
        return NCShareCommon.shared.isExternalUserShare(shareType: shareType)
    }
    
    func isInternalUser() -> Bool {
        return NCShareCommon.shared.isInternalUser(shareType: shareType)
    }
    
    func getPasswordFromField() -> String? {
        if let setPasswordInputField : XLFormRowDescriptor = self.form.formRow(withTag: "SetPasswordInputField") {
            var password = ""
            if let indexPath = self.form.indexPath(ofFormRow: setPasswordInputField) {
                let cell = tableView.cellForRow(at: indexPath) as? PasswordInputField
                password = cell?.fileNameInputTextField.text ?? ""
            }
            return password
        }
        return nil
    }
    
    func isPasswordEnabled() -> Bool {
        if let passwordField: XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionEditPasswordCellWithText") {
            if let indexPath = self.form.indexPath(ofFormRow: passwordField) {
                let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionEditCell
                return cell?.switchControl.isOn ?? false
            }
        }
        return false
    }
    
    func getExpiryFromField() -> String? {
        var expiry: String?
        if let expiryInputField : XLFormRowDescriptor  = self.form.formRow(withTag: "NCShareTextInputCellExpiry") {
            if let indexPath = self.form.indexPath(ofFormRow: expiryInputField) {
                let cell = tableView.cellForRow(at: indexPath) as? NCShareTextInputCell
                expiry = cell?.cellTextField.text ?? ""
            }
        }
        return expiry
    }
    
    func isExpiryEnabled() -> Bool {
        if let expiryField: XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionEditCellExpiration") {
            if let indexPath = self.form.indexPath(ofFormRow: expiryField) {
                let cell = tableView.cellForRow(at: indexPath) as? NCFilePermissionEditCell
                return cell?.switchControl.isOn ?? false
            }
        }
        return false
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        let isPasswordEnabled = self.isPasswordEnabled()
        if isPasswordEnabled {
            let password = (getPasswordFromField() ?? "").trimmingCharacters(in: .whitespaces)
                if  password == ""{
                let alert = UIAlertController(title: "", message: NSLocalizedString("_please_enter_password", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
        }
        
        let isExpiryEnabled = self.isExpiryEnabled()
        if isExpiryEnabled {
            let inputDate = getExpiryFromField() ?? ""
            if inputDate.isEmpty {
                let alert = UIAlertController(title: "", message: NSLocalizedString("_please_enter_expiration", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
        }
        let label = linkLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let expirationDate = isExpiryEnabled ? getServerStyleDate(date: self.expirationDate as Date) : ""
        
        if newUser {
            let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
            let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as! NCShareNewUserAddComment
            if canReshare {
                self.permissionInt = self.permissionInt + NCGlobal.shared.permissionShareShare
            }
            viewNewUserComment.metadata = self.metadata
            viewNewUserComment.permission = self.permissionInt
            viewNewUserComment.password = self.password
            viewNewUserComment.label = label
            viewNewUserComment.expirationDate = nil
            viewNewUserComment.hideDownload = self.hideDownload
            
            viewNewUserComment.sharee = sharee
            viewNewUserComment.isUpdating = false
            self.navigationController!.pushViewController(viewNewUserComment, animated: true)
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
            
            let label = linkLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let expirationDate = isExpiryEnabled ? getServerStyleDate(date: self.expirationDate as Date) : ""
            networking?.updateShare(idShare: self.tableShare!.idShare, password: password, permission: self.permissionInt, note: nil, label: label, expirationDate: expirationDate, hideDownload: self.hideDownload)
        }
    }
    
    func showDownloadLimitError(message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { action in }))
        self.present(alertController, animated: true)
    }
    
    @objc func favoriteClicked() {
        if let metadata = self.metadata {
            NCNetworking.shared.favoriteMetadata(metadata) { errorCode, errorDescription in
                if errorCode == 0 {
                    if !metadata.favorite {
                        self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                        self.metadata?.favorite = true
                    } else {
                        self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                        self.metadata?.favorite = false
                    }
                } else {
                    NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                }
            }
        }
    }
    
    // MARK: - Delegate networking
    
    func readShareCompleted() {
        navigationController?.popViewController(animated: true)
    }
    
    func shareCompleted() {
//        unLoad()
    }
    
    func unShareCompleted() {
//        unLoad()
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func updateShareWithError(idShare: Int) {
    }
    
    func getSharees(sharees: [NCCommunicationSharee]?) { }
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], overwrite: Bool, copy: Bool, move: Bool) {
        
    }
    
    //MARK: - Image
    
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

}
