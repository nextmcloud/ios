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
//    private var calendar: FSCalendar?
    var width: CGFloat = 0
    var height: CGFloat = 0
    var permission: Int = 0
    var filePermissionCount = 0
    var password: String!
    var linkLabel = ""
    var expirationDateText = ""
    var expirationDate: NSDate!
//    @IBOutlet weak var headerImageViewSpaceFavorite: NSLayoutConstraint!
    var permissionIndex = 0
    var permissions = "RDNVCK"
    var shareeEmail: String?
    var dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd/MM/yyyy"
      return formatter
    }()
    let datePicker = UIDatePicker()
    var newUser: Bool?
    var permissionInt = 0
    var rowInFirstSection = 0
    var canReshare = false
    var hideDownload = false
    var passwordProtected = false
    var setExpiration = false
    var headerView: NCShareAdvancePermissionHeader! = nil
    var footerView: NCShareAdvancePermissionFooter! = nil
    var directory: Bool!

//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.initializeForm()
//    }
//    
//    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        self.initializeForm()
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.favorite.translatesAutoresizingMaskIntoConstraints = false
//        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
//            self.headerView.imageView.image = getImageMetadata(metadata!)
//            self.headerView.imageView.contentMode = .scaleToFill
//            self.headerView.folderImageView.isHidden = true
//            self.headerImageViewSpaceFavorite.constant = 5.0
//        } else {
//            if metadata!.directory {
//                let image = UIImage.init(named: "folder")!
//                self.folderImageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
//            } else if metadata!.iconName.count > 0 {
//                self.folderImageView.image = UIImage.init(named: metadata!.iconName)
//            } else {
//                self.folderImageView.image = UIImage.init(named: "file")
//            }
//
//            self.headerImageViewSpaceFavorite.constant = -49.0
//        }
//        self.favorite.setNeedsUpdateConstraints()
//        self.favorite.layoutIfNeeded()
//        self.labelFileName.text = self.metadata?.fileNameView
//        self.labelFileName.textColor = NCBrandColor.shared.textView
//        if metadata!.favorite {
//            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
//        } else {
//            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
//        }
//        self.labelDescription.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        
//        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
//        btnCancel.layer.cornerRadius = 10
//        btnCancel.layer.masksToBounds = true
//        btnCancel.layer.borderWidth = 1
//        btnCancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
//        btnCancel.setTitleColor(UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0), for: .normal)
//        btnCancel.backgroundColor = .white
//
////        btnNext.setTitle(NSLocalizedString("_next_", comment: ""), for: .normal)
//        if newUser! {
//            btnNext.setTitle(NSLocalizedString("_next_", comment: ""), for: .normal)
//        } else {
//            btnNext.setTitle(NSLocalizedString("_apply_changes_", comment: ""), for: .normal)
//        }
//        btnNext.layer.cornerRadius = 10
//        btnNext.layer.masksToBounds = true
//        btnNext.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
//        btnNext.setTitleColor(.white, for: .normal)

        
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.icon
        UserDefaults.standard.setValue(self.linkLabel, forKey: "_share_link_")
        
//        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: dummyViewHeight))
//        self.tableView.contentInset = UIEdgeInsets(top: -dummyViewHeight, left: 0, bottom: 0, right: 0)
        self.metadata?.permissions = self.permissions
        if newUser == true {
            self.title = self.shareeEmail
        } else {
            self.title = self.metadata?.ownerDisplayName
            if let expire = metadata?.trashbinDeletionTime {
                
                if expire.timeIntervalSinceNow.sign == .minus {
                     print("date1 is earlier than date2")
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.formatterBehavior = .behavior10_4
                    dateFormatter.dateStyle = .medium
                    self.expirationDateText = dateFormatter.string(from: expire as Date)
                    
                    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    self.expirationDate = expire
                }
            }
        }
        
        self.navigationController!.navigationBar.tintColor = NCBrandColor.shared.customer
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if newUser == false {
//            case 1:
//                self.permissions = "RGDNV"
//                self.permissionInt = NCGlobal.shared.permissionReadShare
//                break
//            case 2:
//                self.permissions = "RGDNVCK"
//                self.permissionInt = NCGlobal.shared.permissionUpdateShare
//                break
//            default:
//                self.permissions = "RDNVCK"
//                break
            
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
            
            if let expire = metadata?.trashbinDeletionTime {
                
                if expire.timeIntervalSinceNow.sign == .minus {
                     print("date1 is earlier than date2")
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.formatterBehavior = .behavior10_4
                    dateFormatter.dateStyle = .medium
                    self.expirationDateText = dateFormatter.string(from: expire as Date)
                    
                    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    self.expirationDate = expire
                }
            }
        }
        
        self.directory = self.metadata?.directory
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase,  view: self.view, delegate: self)
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        changeTheming()
    }
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.reloadData()
//        setupHeader()
        initializeForm()
//        self.reloadForm()
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {

        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    @objc func keyboardWillHide(_ notification:Notification) {

        if ((notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    func initializeForm() {
        
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Other Cells")
        
//        self.headerView = NCShareAdvancePermissionHeader()
        self.headerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as! NCShareAdvancePermissionHeader)
//        self.headerView.favorite.translatesAutoresizingMaskIntoConstraints = false
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
            self.headerView.fullWidthImageView.image = getImageMetadata(metadata!)
            self.headerView.fullWidthImageView.contentMode = .scaleToFill
            self.headerView.imageView.isHidden = true
        } else {
            if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                self.headerView.imageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
            } else if metadata!.iconName.count > 0 {
                self.headerView.imageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                self.headerView.imageView.image = UIImage.init(named: "file")
            }

//            self.headerImageViewSpaceFavorite.constant = -49.0
        }
        self.headerView.favorite.setNeedsUpdateConstraints()
        self.headerView.favorite.layoutIfNeeded()
        self.headerView.fileName.text = self.metadata?.fileNameView
        self.headerView.fileName.textColor = NCBrandColor.shared.textView
        self.headerView.favorite.addTarget(self, action: #selector(favoriteClicked), for: .touchUpInside)
        if metadata!.favorite {
            self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
        } else {
            self.headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
        }
        self.headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        self.headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 250)
        self.tableView.tableHeaderView = self.headerView
        
        //Sharing
        section = XLFormSectionDescriptor.formSection(withTitle: "")
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        row = XLFormRowDescriptor(tag: "NCFilePermissionCellSharing", rowType: "kNMCFilePermissionCell", title: "")
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_sharing_", comment: "")
        section.addFormRow(row)
        
        //PERMISSION
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCShareHeaderCustomCell"] = NCShareHeaderCustomCell.self
        row = XLFormRowDescriptor(tag: "kNMCShareHeaderCustomCell", rowType: "kNMCShareHeaderCustomCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
//        row.height = 15
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_PERMISSION_", comment: "")
        section.addFormRow(row)
        
        //read only
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        row = XLFormRowDescriptor(tag: "NCFilePermissionCellRead", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_read_only_", comment: "")
        
//        if metadata?.permissions == "RDNVCK" {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
////            row.value = "read"
//        } else {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "")
//        }
        
        if tableShare?.permissions == NCGlobal.shared.permissionCreateShare {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
        } else {
            // Read Only
            if newUser == true {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            } else {
                if CCUtility.isAnyPermission(toEdit: tableShare!.permissions) {
    //                cell.labelQuickStatus.text = NSLocalizedString("_share_editing_", comment: "")
                } else {
                    row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
                }
            }
        }
        
//        row.action.formSelector = #selector(filePermission(_:))
//        row.action.
//        row.
        section.addFormRow(row)
        
        //editing
//        "_share_allow_editing_"         = "Allow editing";
//        "_share_editing_"               = "Editing";

        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
        
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionCellEditing", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_allow_editing_", comment: "")
        
//        if metadata?.permissions == NCGlobal.shared.permissionMaxFileShare || metadata?.permissions == NCGlobal.shared.permissionMaxFolderShare ||  metadata?.permissions == NCGlobal.shared.permissionDefaultFileRemoteShareNoSupportShareOption {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
//        }
            
//        if metadata?.permissions == "RGDNV" {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
////            row.value = "edit"
//        } else {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "")
//        }
        
        if newUser == false {
            if tableShare?.permissions == NCGlobal.shared.permissionCreateShare {

            } else {
                // Read Only
                if CCUtility.isAnyPermission(toEdit: tableShare!.permissions) {
                    row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
                } else {
                    
                }
            }
        }
    
        row.action.formSelector = #selector(filePermission(_:))
        section.addFormRow(row)
        
        //file drop
        //"_share_file_drop_"             = "File drop (upload only)";
        if self.directory {
            XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
            row = XLFormRowDescriptor(tag: "NCFilePermissionCellFileDrop", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
            row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_file_drop_", comment: "")
            section.addFormRow(row)
        }
//        if metadata?.permissions == "RGDNVCK" {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
////            row.value = "fileDrop"
//        } else {
//            row.cellConfig["imageCheck.image"] = UIImage(named: "")
//        }
        if newUser == false {
            if tableShare?.permissions == NCGlobal.shared.permissionCreateShare {
                row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            } else {
                // Read Only
                if CCUtility.isAnyPermission(toEdit: tableShare!.permissions) {
                    
                } else {
                    
                }
            }
        }
        
        //can share
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self

        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellEditingCanShare", rowType: "kNMCFilePermissionEditCell", title: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
        row.cellClass = NCFilePermissionEditCell.self
//        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
//
//        row = XLFormRowDescriptor(tag: "NCFilePermissionCellEditingCanShare", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_can_reshare_", comment: "")
        row.height = 44
        section.addFormRow(row)
        
        //ADVANCE PERMISSION
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self

        row = XLFormRowDescriptor(tag: "NCFilePermissionCellAdvanceTxt", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_advance_permissions_", comment: "")
        section.addFormRow(row)
        
        
//        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionCell"] = NCFilePermissionCell.self
//        row = XLFormRowDescriptor(tag: "NCFilePermissionCellAdvanceText", rowType: "kNMCFilePermissionCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
//        row.cellConfig["titleLabel.text"] = NSLocalizedString("_advance_permissions_", comment: "")
////        row.height = 15
//        section.addFormRow(row)

        //link label
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCShareHeaderCustomCell"] = NCShareHeaderCustomCell.self

        row = XLFormRowDescriptor(tag: "kNMCShareHeaderCustomCell", rowType: "kNMCShareHeaderCustomCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_LINK_LABEL_", comment: "")
//        row.height = 15
        section.addFormRow(row)
//
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellLinkLabel", rowType: "kNMCFilePermissionEditCell", title: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
//        section.footerTitle = "OthersFormViewController.swift"
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_custom_link_label", comment: "")
        row.cellConfig["cellTextField.placeholder"] = NSLocalizedString("_custom_link_label", comment: "")
        row.cellClass = NCFilePermissionEditCell.self
        row.height = 88
        section.addFormRow(row)

        //hide download
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellHideDownload", rowType: "kNMCFilePermissionEditCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_hide_download_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
        row.cellClass = NCFilePermissionEditCell.self
        row.height = 44
        section.addFormRow(row)

        //password
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCShareHeaderCustomCell"] = NCShareHeaderCustomCell.self
        row = XLFormRowDescriptor(tag: "kNMCShareHeaderCustomCellPassword", rowType: "kNMCShareHeaderCustomCell", title: NSLocalizedString("_PERMISSION_", comment: ""))
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_PASSWORD_PROTECTION_", comment: "")
//        row.height = 15
        section.addFormRow(row)


//        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_PASSWORD_PROTECTION_", comment: ""))
//        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
//        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellPassword", rowType: "kNMCFilePermissionEditCell", title: "")
//        row.cellConfig["titleLabel.text"] = NSLocalizedString("_set_password_", comment: "")
//        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
//        row.cellClass = NCFilePermissionEditCell.self
//        row.height = 88
////        row.cellConfig["cellTextField.text"] = "false"
//        section.addFormRow(row)
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditPasswordCell"] = NCFilePermissionEditPasswordCell.self
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditPasswordCellWithText", rowType: "kNMCFilePermissionEditPasswordCell", title: "")
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_set_password_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
        row.cellConfig["cellTextField.placeholder"] = NSLocalizedString("_insert_password_", comment: "")
        row.cellClass = NCFilePermissionEditPasswordCell.self
        row.height = 88
        section.addFormRow(row)

        //expiration
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCShareHeaderCustomCell"] = NCShareHeaderCustomCell.self
        row = XLFormRowDescriptor(tag: "kNMCShareHeaderCustomCellExpiration", rowType: "kNMCShareHeaderCustomCell", title: "")
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_EXPIRATION_DATE_", comment: "")
//        row.height = 15
        section.addFormRow(row)

//        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("", comment: ""))
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFilePermissionEditCell"] = NCFilePermissionEditCell.self
        row = XLFormRowDescriptor(tag: "kNMCFilePermissionEditCellExpiration", rowType: "kNMCFilePermissionEditCell", title: "")
        row.cellConfig["titleLabel.text"] = NSLocalizedString("_share_expiration_date_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.customer
        if newUser == false {
            row.cellConfig["cellTextField.text"] = self.expirationDateText
        }
        row.cellClass = NCFilePermissionEditCell.self
        row.height = 88
        section.addFormRow(row)
        
        self.footerView = (Bundle.main.loadNibNamed("NCShareAdvancePermissionFooter", owner: self, options: nil)?.first as! NCShareAdvancePermissionFooter)
        self.footerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 80)
        self.footerView.buttonCancel.addTarget(self, action: #selector(cancelClicked(_:)), for: .touchUpInside)
        self.footerView.buttonNext.addTarget(self, action: #selector(nextClicked(_:)), for: .touchUpInside)
        self.tableView.tableFooterView = self.footerView
        self.self.footerView.buttonCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        self.footerView.buttonCancel.layer.cornerRadius = 10
        self.footerView.buttonCancel.layer.masksToBounds = true
        self.footerView.buttonCancel.layer.borderWidth = 1
        self.footerView.buttonCancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        self.footerView.buttonCancel.setTitleColor(UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0), for: .normal)
        self.footerView.buttonCancel.backgroundColor = .white

        if newUser! {
            self.footerView.buttonNext.setTitle(NSLocalizedString("_next_", comment: ""), for: .normal)
        } else {
            self.footerView.buttonNext.setTitle(NSLocalizedString("_apply_changes_", comment: ""), for: .normal)
        }
        self.footerView.buttonNext.layer.cornerRadius = 10
        self.footerView.buttonNext.layer.masksToBounds = true
        self.footerView.buttonNext.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        self.footerView.buttonNext.setTitleColor(.white, for: .normal)

        form.addFormSection(section)
        self.form = form
    }
    
    func reloadForm() {
        
        self.form.delegate = nil
        
//        let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "PhotoButtonDestinationFolder")!
//        buttonDestinationFolder.title = self.titleServerUrl
//        
//        let maskFileName : XLFormRowDescriptor = self.form.formRow(withTag: "maskFileName")!
//        let previewFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
//        previewFileName.value = self.previewFileName(valueRename: maskFileName.value as? String)
        
        self.tableView.reloadData()
        self.form.delegate = self
    }
    
    // MARK: - Row Descriptor Value Changed
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor!) {
        guard let metadata = self.metadata else { return }
       
        switch formRow.tag {
        case "NCFilePermissionCellRead":
            self.permissionInt = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata.directory)
            
            self.tableShare?.permissions = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata.directory)
            self.permissions = "RDNVCK"
            metadata.permissions = "RDNVCK"
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead")!
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing")!
            row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop")!
            row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            
            self.reloadForm()
            break
        case "kNMCFilePermissionCellEditing":
            self.permissionInt = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)
            
            self.tableShare?.permissions = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)
            self.permissions = "RGDNV"
            metadata.permissions = "RGDNV"
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead")!
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing")!
            row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop")!
            row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            
            self.reloadForm()
            break
        case "NCFilePermissionCellFileDrop":
            self.permissionInt = NCGlobal.shared.permissionCreateShare
            
            self.tableShare?.permissions = NCGlobal.shared.permissionCreateShare
            self.permissions = "RGDNVCK"
            metadata.permissions = "RGDNVCK"
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellRead")!
            row.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            let row1 : XLFormRowDescriptor  = self.form.formRow(withTag: "kNMCFilePermissionCellEditing")!
            row1.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: .clear, size: 25.0)
            let row2 : XLFormRowDescriptor  = self.form.formRow(withTag: "NCFilePermissionCellFileDrop")!
            row2.cellConfig["imageCheck.image"] = UIImage(named: "success")!.image(color: NCBrandColor.shared.customer, size: 25.0)
            
            self.reloadForm()
            break
        default:
            break
        }
    }
    
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {

        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        
        switch formRow.tag {
        case "kNMCFilePermissionEditCellHideDownload":
            if let value = newValue as? Bool {
                self.hideDownload = value
            }
            break
        case "kNMCFilePermissionEditPasswordCellWithText":
            if let value = newValue as? Bool {
                self.passwordProtected = value
            }
            
            if let pwd = formRow.value as? String {
                self.form.delegate = nil
                self.password = pwd
    //            formRow.value = "self.fileName"
                self.form.delegate = self
            }
            break
        case "kNMCFilePermissionEditCellLinkLabel":
            if let label = formRow.value as? String {
                self.form.delegate = nil
                self.password = label
                self.form.delegate = self
            }
            break
        case "kNMCFilePermissionEditCellExpiration":
            if let exp = formRow.value as? NSDate {
                self.form.delegate = nil
                self.expirationDate = exp
                self.form.delegate = self
            }
            break
        default:
            break
        }
    }
    
    // MARK: - Switch actions
    
    func readOnlyValueChanged(sender: UISwitch) {
        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata.directory)

        if sender.isOn {
            if metadata.directory {
//                switchAllowUploadAndEditing.setOn(false, animated: false)
                if self.metadata!.directory {
//                    switchFileDrop.setOn(false, animated: false)
                }
                metadata.permissions = "RDNVCK"
            }
        } else {
            metadata.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    func allowUploadEditingValueChanged(sender: UISwitch) {
        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)

        if sender.isOn {
//            switchReadOnly.setOn(false, animated: false)
            if metadata.directory {
//                switchFileDrop.setOn(false, animated: false)
            }
            metadata.permissions = "RGDNV"
        } else {
            metadata.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    func fileDropValueChanged(sender: UISwitch) {

        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)

        if sender.isOn {
//            switchReadOnly.setOn(false, animated: false)
//            switchAllowUploadAndEditing.setOn(false, animated: false)
            metadata.permissions = "RGDNVCK"
        } else {
            metadata.permissions = "RGD"
            sender.setOn(true, animated: false)
        }
    }
    
//    @IBAction func canReshareValueChanged(sender: UISwitch) {
    func canReshareValueChanged(sender: UISwitch) {
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }

        let canEdit = CCUtility.isAnyPermission(toEdit: tableShare.permissions)
        let canCreate = CCUtility.isPermission(toCanCreate: tableShare.permissions)
        let canChange = CCUtility.isPermission(toCanChange: tableShare.permissions)
        let canDelete = CCUtility.isPermission(toCanDelete: tableShare.permissions)
        
        var permission: Int = 0
        
        if metadata.directory {
            permission = CCUtility.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: canChange, andCanDelete: canDelete, andCanShare: sender.isOn, andIsFolder: metadata.directory)
        } else {
            if sender.isOn {
                if canEdit {
                    permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                } else {
                    permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                }
            } else {
                if canEdit {
                    permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                } else {
                    permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                }
            }
        }
        canReshare = sender.isOn
    }
    
    func hideDownloadValueChanged(sender: UISwitch) {
        
        hideDownload = sender.isOn
    }
    
    func setPasswordValueChanged(sender: UISwitch) {
        
        self.passwordProtected = sender.isOn
        
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
        self.tableView.endUpdates()
    }
    
    @IBAction func setExpirationValueChanged(sender: UISwitch) {
        self.setExpiration = sender.isOn
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
        self.tableView.endUpdates()
    }
    
    func fieldSetExpirationDate(sender: UITextField) {
//        width = self.view.frame.width
//        height = self.view.frame.height
//        let calendar = NCShareCommon.shared.openCalendar(view: self.view, width: width, height: height)
//        calendar.calendarView.delegate = self
//        self.calendar = calendar.calendarView
//        viewWindowCalendar = calendar.viewWindow
//
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapViewWindowCalendar))
//        tap.delegate = self
//        viewWindowCalendar?.addGestureRecognizer(tap)
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        
        if self.passwordProtected == true {
            if self.password == nil || self.password == "" {
//                let string = pwd.trimmingCharacters(in: .whitespaces)
//                if string.count < 1 {
                    let alert = UIAlertController(title: "", message: NSLocalizedString("_please_enter_password", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .cancel, handler: nil))
    //                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { action in
    //
    //                }))
                    
                    self.present(alert, animated: true)
                    return
//                }
            }
        }
        
        if self.newUser == true {
            if self.linkLabel != "" {
                UserDefaults.standard.setValue(self.linkLabel, forKey: "_share_link_")
            }
            
            let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
            let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as! NCShareNewUserAddComment
            viewNewUserComment.metadata = self.metadata
            viewNewUserComment.sharee = sharee
            viewNewUserComment.password = self.password
            self.navigationController!.pushViewController(viewNewUserComment, animated: true)
        } else {
//            self.networking?.createShare(shareWith: sharee!.shareWith, shareType: sharee!.shareType, metadata: self.metadata!)
            let directory = metadata?.directory
            if directory! {
                switch self.permissions {
                case "RDNVCK":
                    self.permissionInt = NCGlobal.shared.permissionReadShare
                    break
                case "RGDNV":
                    self.permissionInt = NCGlobal.shared.permissionUpdateShare
                    break
                case "RGDNVCK":
                    self.permissionInt = NCGlobal.shared.permissionCreateShare
                    break
                default:
                    break
                }
            } else {
                switch self.permissions {
                case "RDNVCK":
                    self.permissionInt = NCGlobal.shared.permissionReadShare
                    break
                case "RGDNV":
                    self.permissionInt = NCGlobal.shared.permissionMaxFileShare
                    break
                default:
                    break
                }
            }
            
            networking?.updateShare(idShare: self.tableShare!.idShare, password: self.password, permission: self.permissionInt, note: nil, expirationDate: self.expirationDateText, hideDownload: self.hideDownload)
        }
    }
    
//    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
    @objc func favoriteClicked() {
        if let metadata = self.metadata {
            NCNetworking.shared.favoriteMetadata(metadata, urlBase: appDelegate.urlBase) { (errorCode, errorDescription) in
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
    
    
    func setDatePicker(sender: UITextField) {
        //Format Date
        datePicker.datePickerMode = .date

        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker));

        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)

        sender.inputAccessoryView = toolbar
        sender.inputView = datePicker
    }
    
    @objc func doneDatePicker(){
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateStyle = .medium
        self.expirationDateText = dateFormatter.string(from: datePicker.date as Date)
        
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self.expirationDate = datePicker.date as NSDate

        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
        self.tableView.endUpdates()
        self.view.endEditing(true)
    }

    @objc func cancelDatePicker() {
        self.view.endEditing(true)
    }
    
    @objc func filePermission(_ sender: XLFormRowDescriptor) {
        print("")
    }
    
//    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
//        let useFolderPhotoRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderAutoUpload")!
//        self.deselectFormRow(sender)
//        
//        if (useFolderPhotoRow.value! as AnyObject).boolValue == true{
//            return
//        }
//        
//        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
//        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
//        let viewController = navigationController.topViewController as! NCSelect
//        
//        viewController.delegate = self
//        viewController.hideButtonCreateFolder = false
//        viewController.includeDirectoryE2EEncryption = true
//        viewController.includeImages = false
//        viewController.selectFile = false
//        viewController.titleButtonDone = NSLocalizedString("_select_", comment: "")
//        viewController.type = ""
//        
//        navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
//        self.present(navigationController, animated: true, completion: nil)
//    }
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], buttonType: String, overwrite: Bool) {
        
    }
    
    //MARK: - Header View
    
    func setupHeader() {
        
        let headerView = Bundle.main.loadNibNamed("NCShareAdvancePermissionHeader", owner: self, options: nil)?.first as! NCShareAdvancePermissionHeader
        headerView.backgroundColor = NCBrandColor.shared.backgroundForm
        headerView.fileName.textColor = NCBrandColor.shared.icon
//        headerView.labelSharing.textColor = NCBrandColor.shared.icon
//        headerView.labelSharingInfo.textColor = NCBrandColor.shared.icon
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
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
        } else {
            headerView.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
        }
        headerView.info.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
//        addSubview(headerView)
//
//        pageView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        headerView.translatesAutoresizingMaskIntoConstraints = false
//
////        headerHeightConstraint = headerView.heightAnchor.constraint(
////            equalToConstant: NCSharePagingView.HeaderHeight
////        )
//        headerHeightConstraint = headerView.heightAnchor.constraint(
//            equalToConstant: metadata!.directory ? 350 : 370
//        )
//
//        headerHeightConstraint?.isActive = true
//
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            collectionView.heightAnchor.constraint(equalToConstant: options.menuHeight),
//            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
//
//            headerView.topAnchor.constraint(equalTo: topAnchor),
//            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
//
//            pageView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            pageView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            pageView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            pageView.topAnchor.constraint(equalTo: topAnchor, constant: 10)
//        ])
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

}


//class NCShareAdvancePermissionHeader: UIView {
//    
//    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet weak var fileName: UILabel!
//    @IBOutlet weak var info: UILabel!
//    @IBOutlet weak var favorite: UIButton!
//    @IBOutlet weak var fullWidthImageView: UIImageView!
//    
//    
//    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
//    var delegate: NCShareAdvancePermissionHeaderDelegate?
//    var ocId = ""
//
//    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
//        delegate?.favoriteClicked()
////        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
////            NCNetworking.shared.favoriteMetadata(metadata, urlBase: appDelegate.urlBase) { (errorCode, errorDescription) in
////                if errorCode == 0 {
////                    if !metadata.favorite {
////                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
////                    } else {
////                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
////                    }
////                } else {
////                    NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
////                }
////            }
////        }
//    }
//}
//
//protocol NCShareAdvancePermissionHeaderDelegate {
//    func favoriteClicked()
////    func textFieldSelected(_ textField: UITextField)
////    func textFieldTextChanged(_ textField: UITextField)
//}
