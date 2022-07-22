//
//  NCShareFileOptions.swift
//  Nextcloud
//
//  Created by T-systems on 04/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit
import FSCalendar
import NCCommunication
import SVGKit

class NCShareFileOptions: UIViewController , UIGestureRecognizerDelegate, NCShareNetworkingDelegate, FSCalendarDelegate, FSCalendarDelegateAppearance, CellPermissionEditDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelFileName: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var applyChanges: UIButton!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelPermissions: UILabel!
    
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    public var tableShare: tableShare?
    private var networking: NCShareNetworking?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewWindowCalendar: UIView?
    private var calendar: FSCalendar?
    var width: CGFloat = 0
    var height: CGFloat = 0
    var permission: Int = 0
    var hideDownload = false
    var filePermissionCount = 0
    var password: String!
    var linkLabel = ""
    var expirationDateText: String!
    var expirationDate: Date!
    @IBOutlet weak var headerImageViewSpaceFavorite: NSLayoutConstraint!
    var permissionIndex = 0
    var permissions = "RDNVCK"
    var permissionsInt: Int?
    var passwordProtected = false
    var setExpiration = false
    var shareeEmail: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        self.favorite.translatesAutoresizingMaskIntoConstraints = false
        self.permissionsInt = tableShare?.permissions
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
            self.imageView.image = getImageMetadata(metadata!)
            self.imageView.contentMode = .scaleToFill
            self.folderImageView.isHidden = true
        } else {
            if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                self.folderImageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
            } else if metadata!.iconName.count > 0 {
                self.folderImageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                self.folderImageView.image = UIImage.init(named: "file")
            }
        }
        self.favorite.setNeedsUpdateConstraints()
        self.favorite.layoutIfNeeded()
        self.labelFileName.text = self.metadata?.fileNameView
        self.labelFileName.textColor = NCBrandColor.shared.textView
        if metadata!.favorite {
            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
        } else {
            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
        }
        self.labelDescription.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        
        cancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        cancel.layer.cornerRadius = 10
        cancel.layer.masksToBounds = true
        cancel.layer.borderWidth = 1
        cancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        cancel.setTitleColor(UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0), for: .normal)
        cancel.backgroundColor = .white
        
        applyChanges.setTitle(NSLocalizedString("_apply_changes_", comment: ""), for: .normal)
        applyChanges.layer.cornerRadius = 10
        applyChanges.layer.masksToBounds = true
        applyChanges.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        applyChanges.setTitleColor(.white, for: .normal)
        
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.icon
        self.title = self.metadata?.ownerDisplayName
        UserDefaults.standard.setValue(self.linkLabel, forKey: "_share_link_")
        
        let dummyViewHeight = CGFloat(40)
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: dummyViewHeight))
        self.tableView.contentInset = UIEdgeInsets(top: -dummyViewHeight, left: 0, bottom: 0, right: 0)
        self.metadata?.permissions = self.permissions
        
//        buttonCalender.setImage(UIImage(named: "calender")?.image(color: NCBrandColor.shared.customer, size: 25), for: .normal)
//        buttonCalender.addTarget(self, action: #selector(fieldSetExpirationDate(sender:)), for: .touchUpInside)
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase,  view: self.view, delegate: self)
    }
    
    func unLoad() {
        viewWindowCalendar?.removeFromSuperview()
        //        viewWindow?.removeFromSuperview()
        
        viewWindowCalendar = nil
        //        viewWindow = nil
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
        if sender.isOn {
            
        }
    }
    
    func hideDownloadValueChanged(sender: UISwitch) {
        
        hideDownload = sender.isOn
    }
    
    func setPasswordValueChanged(sender: UISwitch) {
        
        if sender.isOn {
            self.passwordProtected = true
        } else {
            self.passwordProtected = false
        }
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
        self.tableView.endUpdates()
    }
    
    @IBAction func setExpirationValueChanged(sender: UISwitch) {
        if sender.isOn {
            self.setExpiration = true
        } else {
            self.setExpiration = false
        }
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
        self.tableView.endUpdates()
    }
    
    @objc func fieldSetExpirationDate(sender: UITextField) {
        width = self.view.frame.width
        height = self.view.frame.height
        let calendar = NCShareCommon.shared.openCalendar(view: self.view, width: width, height: height)
        calendar.calendarView.delegate = self
        self.calendar = calendar.calendarView
        viewWindowCalendar = calendar.viewWindow
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapViewWindowCalendar))
        tap.delegate = self
        viewWindowCalendar?.addGestureRecognizer(tap)
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func applyChangesClicked(_ sender: Any) {
        if self.linkLabel != "" {
            UserDefaults.standard.setValue(self.linkLabel, forKey: "_share_link_")
        }
        
        if self.passwordProtected {
            let pass = self.password.trimmingCharacters(in: .whitespaces)
            if pass == "" {
                let alertController = UIAlertController(title: "", message: NSLocalizedString("_prompt_insert_password", comment: ""), preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .cancel, handler: nil)
                
                let okAction = UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { action in
                    return
                })
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        let share = NCTableShareOptions(sharee: sharee!, metadata: metadata!, password: self.password)
        share.idShare = tableShare!.idShare
        share.password = self.password
        share.permissions = self.permissionsInt!
        share.expirationDate = self.expirationDate as NSDate
        share.hideDownload = self.hideDownload
//        self.networking?.updateShare(idShare: tableShare!.idShare, password: self.password, permission: self.permissionsInt!, note: nil, label: nil, expirationDate: self.expirationDateText, hideDownload: self.hideDownload)
        self.networking?.updateShare(option: share)
    }
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        if let metadata = self.metadata {
            NCNetworking.shared.favoriteMetadata(metadata) { errorCode, errorDescription in
                if errorCode == 0 {
                    if !metadata.favorite {
                        //                            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                        self.metadata?.favorite = true
                    } else {
                        //                            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
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
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
        self.navigationController?.popViewController(animated: true)
    }
    
    func shareCompleted() {
        unLoad()
    }
    
    func unShareCompleted() {
        unLoad()
    }
    
    func updateShareWithError(idShare: Int) {
    }
    
    func getSharees(sharees: [NCCommunicationSharee]?) { }
    
    // MARK: - Delegate calendar
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            
            self.expirationDateText = dateFormatter.string(from:date)
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
            self.tableView.endUpdates()
            
            viewWindowCalendar?.removeFromSuperview()
            
            guard let tableShare = self.tableShare else { return }
            
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let expirationDate = dateFormatter.string(from: date)
            
            metadata?.trashbinDeletionTime = date as NSDate
        }
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return date > Date()
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if date > Date() {
            return UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1)
        } else {
            return UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
        }
    }
    
    // MARK: - Tap viewWindowCalendar
    @objc func tapViewWindowCalendar(gesture: UITapGestureRecognizer) {
        calendar?.removeFromSuperview()
        viewWindowCalendar?.removeFromSuperview()
        
        calendar = nil
        viewWindowCalendar = nil
        
        //        reloadData(idShare: tableShare?.idShare ?? 0)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return gestureRecognizer.view == touch.view
    }
    
    // MARK: - CellPermissionEditDelegate
    func switchChanged(_ sender: UISwitch) {
        let value = sender.tag
        switch value {
        case 1:
            canReshareValueChanged(sender: sender)
            break
        case 2:
            hideDownloadValueChanged(sender: sender)
            break
        case 3:
            setPasswordValueChanged(sender: sender)
            self.passwordProtected = sender.isOn
            break
        case 4:
            setExpirationValueChanged(sender: sender)
            self.setExpiration = sender.isOn
            break
        default:
            break
        }
    }
    
    func textFieldSelected(_ textField: UITextField) {
        print("")
        let value = textField.tag
        
        switch value {
        case 1:
            break
        case 3:
            break
        case 4:
            fieldSetExpirationDate(sender: textField)
            break
        default:
            break
        }
    }
    
    func textFieldTextChanged(_ textField: UITextField) {
        let value = textField.tag
        let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        switch value {
        case 1:
            self.linkLabel = text ?? ""
            break
        case 3:
            self.password = text
            break
        case 4:
            //            fieldSetExpirationDate(sender: textField)
            textField.text = ""
            break
        default:
            break
        }
    }
    
    //MARK: - Image
    
    func getImageMetadata(_ metadata: tableMetadata) -> UIImage? {
        
        if let image = getImage(metadata: metadata) {
            return image
        }
        
        if metadata.classFile == NCCommunicationCommon.typeClassFile.video.rawValue && !metadata.hasPreview {
            NCUtility.shared.createImageFrom(fileNameView: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
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
                    NCUtility.shared.createImageFrom(fileNameView: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
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
                NCUtility.shared.createImageFrom(fileNameView: metadata.fileNameView, ocId: metadata.ocId, etag: metadata.etag, classFile: metadata.classFile)
                image = UIImage.init(contentsOfFile: imagePath)
            }
        }
        
        return image
    }
}



//MARK :- TableViewMethods

extension NCShareFileOptions: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        var height: CGFloat = 44
        
        switch section {
        case 0:
            if indexPath.row == 2 {
                height = 80
            }
            return height
        case 3, 4:
            height = 84
            break
        default:
            break
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            for i in 0...filePermissionCount - 2 {
                if i == indexPath.row {
                    let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! CellPermissionEmail
                    let checkImage = UIImageView(image: UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0))
                    cell.accessoryView = checkImage
                    self.permissionIndex = indexPath.row
                } else {
                    let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! CellPermissionEmail
                    cell.accessoryView = nil
                }
            }
            switch indexPath.row {
            case 1:
                self.permissions = "RGDNV"
                self.permissionsInt = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata!.directory)
                break
            case 2:
                self.permissions = "RGDNVCK"
                self.permissionsInt = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata!.directory)
                break
            default:
                self.permissions = "RDNVCK"
                self.permissionsInt = NCGlobal.shared.permissionCreateShare
                break
            }
        }
    }
}

extension NCShareFileOptions: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let directory = self.metadata?.directory
            if directory! {
                filePermissionCount = 4
                return filePermissionCount
            } else {
                filePermissionCount = 3
                return filePermissionCount
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let directory = self.metadata?.directory
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEmail", for: indexPath) as? CellPermissionEmail {
                    cell.seperator.isHidden = false
                    cell.title.text = NSLocalizedString("_share_read_only_", comment: "")
                    if self.permissionIndex == 0 {
                        let checkImage = UIImageView(image: UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0))
                        cell.accessoryView = checkImage
                    }
                    return cell
                }
            //                    break
            case 1:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEmail", for: indexPath) as? CellPermissionEmail {
                    if self.permissionIndex == 1 {
                        let checkImage = UIImageView(image: UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0))
                        cell.accessoryView = checkImage
                    }
                    if directory! {
                        cell.title.text = NSLocalizedString("_share_allow_upload_", comment: "")
                        return cell
                    } else {
                        cell.title.text = NSLocalizedString("_share_editing_", comment: "")
                        return cell
                    }
                }
                break
            case 2:
                if directory! {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEmail", for: indexPath) as? CellPermissionEmail {
                        cell.title.text = NSLocalizedString("_share_file_drop_", comment: "")
                        if self.permissionIndex == 2 {
                            let checkImage = UIImageView(image: UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0))
                            cell.accessoryView = checkImage
                            
                            cell.titleInfo.text = NSLocalizedString("_file_drop_message_", comment: "")
                        }
                        return cell
                    }
                } else {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                        cell.delegate = self
                        cell.seperator.isHidden = false
                        cell.seperatorBottom.isHidden = true
                        cell.title.text = NSLocalizedString("_share_can_reshare_", comment: "")
//                        cell.switchCell.tag = 1``
//``                        return cell
                    }
                }
                break
            case 3:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                    cell.delegate = self
                    cell.seperator.isHidden = false
                    cell.seperatorBottom.isHidden = true
                    cell.title.text = NSLocalizedString("_share_can_reshare_", comment: "")
                    cell.switchCell.tag = 1
                    return cell
                }
                break
            default:
                break
            }
            break
        case 1:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                cell.delegate = self
                cell.title.text = NSLocalizedString("_LINK_LABEL_", comment: "")
                cell.title.textColor = NCBrandColor.shared.textInfo
                cell.switchCell.isHidden = true
                cell.seperator.isHidden = false
                cell.seperatorBottom.isHidden = true
                cell.textField.placeholder = NSLocalizedString("_custom_link_label", comment: "")
                cell.textField.tag = 1
                let button = UIButton()
                button.sizeThatFits(CGSize(width: 100, height: cell.textField.layer.frame.height))
                //                button.addTarget(self, action: #selector(startTimer), for: .touchUpInside)
                cell.textField.rightView = button
                cell.textField.rightViewMode = .unlessEditing
                return cell
            }
            break
        case 2:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                cell.delegate = self
                cell.title.text = NSLocalizedString("_share_hide_download_", comment: "")
                cell.seperator.isHidden = false
                cell.seperatorBottom.isHidden = true
                cell.switchCell.tag = 2
                if let hide = tableShare?.hideDownload {
                    cell.switchCell.isEnabled = hide
                } else {
                    cell.switchCell.isEnabled = false
                }
                return cell
            }
            break
        case 3:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                cell.delegate = self
                cell.title.text = NSLocalizedString("_share_password_protect_", comment: "")
                cell.seperator.isHidden = false
                cell.seperatorBottom.isHidden = true
                cell.switchCell.tag = 3
                cell.textField.isSecureTextEntry = true
                cell.textField.tag = cell.switchCell.tag
                cell.textField.placeholder = NSLocalizedString("_insert_password_", comment: "")
                if self.passwordProtected {
                    cell.switchCell.isOn = true
                    cell.textField.isEnabled = cell.switchCell.isOn
                    cell.textField.text = ""
                } else {
                    cell.switchCell.isOn = false
                    cell.textField.isEnabled = cell.switchCell.isOn
                }
                return cell
            }
            break
        case 4:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "cellPermissionEditEmail", for: indexPath) as? CellPermissionEditEmail {
                cell.delegate = self
                cell.title.text = NSLocalizedString("_share_expiration_date_", comment: "")
                cell.seperator.isHidden = false
                cell.seperatorBottom.isHidden = true
                cell.switchCell.tag = 4
                cell.textField.tag = cell.switchCell.tag
//                buttonCalender.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
//                buttonCalender.frame = CGRect(x: CGFloat(cell.textField.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
                
                if self.setExpiration {
                    cell.textField.isEnabled = true
                    cell.textField.text = ""
//                    cell.textField.addSubview(buttonCalender)
                } else {
                    cell.textField.isEnabled = false
//                    buttonCalender.removeFromSuperview()
                }
                if let expire = self.expirationDateText {
                    cell.textField.text = expire
                    cell.textField.endEditing(true)
                }
                return cell
            }
            break
        default:
            break
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            let directory = metadata?.directory
            if directory! {
                return 230
            } else {
                return 257
            }
        }
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var view: UIView!
        if section == 0 {
            let leftMargin = 15
            let imageView = UIImageView()
            if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
                view = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 257))
                imageView.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 150)
                imageView.image = getImageMetadata(metadata!)
                imageView.contentMode = .scaleToFill
            } else {
                view = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 100))
                imageView.frame = CGRect(x: leftMargin, y: 0, width: 120, height: 120)
                if metadata!.directory {
                    let image = UIImage.init(named: "folder")!
                    imageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
                } else if metadata!.iconName.count > 0 {
                    imageView.image = UIImage.init(named: metadata!.iconName)
                } else {
                    imageView.image = UIImage.init(named: "file")
                }
            }
            let favoriteSize = 24
            let favoriteB = UIButton(frame: CGRect(x: leftMargin, y: Int(imageView.frame.size.height) + 5, width: favoriteSize, height: favoriteSize))
            favoriteB.setImage(UIImage(named: "favorite"), for: .normal)
            if metadata!.favorite {
                favoriteB.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 20), for: .normal)
            } else {
                favoriteB.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 20), for: .normal)
            }
            let fileName = UILabel(frame: CGRect(x: leftMargin + favoriteSize + 10 , y: Int(favoriteB.frame.origin.y), width: 200, height: 18))
            fileName.text = self.metadata?.fileNameView
            fileName.textColor = NCBrandColor.shared.textView
            
            let fileDesc = UILabel(frame: CGRect(x: leftMargin + favoriteSize + 10 , y: Int(fileName.frame.origin.y + fileName.frame.size.height) + 4, width: 200, height: 18))
            fileDesc.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
            fileDesc.font = UIFont.systemFont(ofSize: 12)
            fileDesc.textColor = NCBrandColor.shared.textInfo
            
            let labelSharing = UILabel(frame: CGRect(x: leftMargin, y: Int(favoriteB.frame.origin.y + favoriteB.frame.size.height) + 35, width: 200, height: 18))
            labelSharing.text = NSLocalizedString("_sharing_", comment: "")
            labelSharing.textColor = NCBrandColor.shared.textView
            
            let labelPermissions = UILabel(frame: CGRect(x: leftMargin, y: Int(labelSharing.frame.origin.y + labelSharing.frame.size.height) + 5, width: 200, height: 18))
            labelPermissions.textColor = NCBrandColor.shared.textInfo
            labelPermissions.text = NSLocalizedString("_PERMISSIONS_", comment: "")
            labelPermissions.font = UIFont.systemFont(ofSize: 12)
            
            view.addSubview(imageView)
            view.addSubview(favoriteB)
            view.addSubview(fileName)
            view.addSubview(fileDesc)
            view.addSubview(labelSharing)
            view.addSubview(labelPermissions)
            return view
        }
        
        view = UIView(frame: CGRect(x: 0, y: 3, width: self.tableView.frame.width, height: 20))
        let headerSectionLabel = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width, height: 15))
        headerSectionLabel.textColor = NCBrandColor.shared.textInfo
        
        switch section {
        case 1:
            headerSectionLabel.text = NSLocalizedString("_advance_permissions_", comment: "")
            headerSectionLabel.textColor = .black
            break
        case 2:
            headerSectionLabel.text = NSLocalizedString("_HIDE_DOWNLOAD_", comment: "")
            break
        case 3:
            headerSectionLabel.text = NSLocalizedString("_PASSWORD_PROTECTION_", comment: "")
            break
        case 4:
            headerSectionLabel.text = NSLocalizedString("_EXPIRATION_DATE_", comment: "")
            break
        default:
            break
        }
        view.addSubview(headerSectionLabel)
        return view
    }
}


class CellPermissionEditEmail: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var switchCell: UISwitch!
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var seperatorBottom: UIView!
    
    var delegate: CellPermissionEditDelegate?
    
    override func awakeFromNib() {
        
    }
    
    @IBAction func switchClicked(_ sender: Any) {
        let swit = sender as! UISwitch
        delegate?.switchChanged(swit)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldSelected(textField)
    }
    
    //    func textFieldDidEndEditing(_ textField: UITextField) {
    //        delegate?.textFieldTextChanged(textField)
    //    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        delegate?.textFieldTextChanged(textField)
        return true
    }
}

class CellPermissionEmail: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var titleInfo: UILabel!
    
    
    override func awakeFromNib() {
        self.title.text = "title"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //        if self.accessoryView == nil {
        self.accessoryView = nil
        //        }
    }
}

protocol CellPermissionEditDelegate {
    func switchChanged(_ sender: UISwitch)
    func textFieldSelected(_ textField: UITextField)
    func textFieldTextChanged(_ textField: UITextField)
}
