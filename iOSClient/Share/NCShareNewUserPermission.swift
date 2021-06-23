//
//  NCShareNewUserPermission.swift
//  Nextcloud
//
//  Created by T-systems on 20/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit
import FSCalendar
import NCCommunication

class NCShareNewUserPermission: UIViewController, UIGestureRecognizerDelegate, NCShareNetworkingDelegate, FSCalendarDelegate, FSCalendarDelegateAppearance {

    @IBOutlet weak var labelPermission: UILabel!
    @IBOutlet weak var switchReadOnly: UISwitch!
    @IBOutlet weak var labelReadOnly: UILabel!
    @IBOutlet weak var switchAllowUploadAndEditing: UISwitch!
    @IBOutlet weak var labelAllowUploadAndEditing: UILabel!
    @IBOutlet weak var switchFileDrop: UISwitch!
    @IBOutlet weak var labelFileDrop: UILabel!
    @IBOutlet weak var switchCanReshare: UISwitch!
    @IBOutlet weak var labelCanReshare: UILabel!
    @IBOutlet weak var labelAdvancePermission: UILabel!
    @IBOutlet weak var switchHideDownload: UISwitch!
    @IBOutlet weak var labelHideDownload: UILabel!
    @IBOutlet weak var switchPasswordProtect: UISwitch!
    @IBOutlet weak var labelPasswordProtect: UILabel!
    @IBOutlet weak var fieldPasswordProtect: UITextField!
    @IBOutlet weak var switchSetExpirationDate: UISwitch!
    @IBOutlet weak var labelSetExpirationDate: UILabel!
    @IBOutlet weak var fieldSetExpirationDate: UITextField!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    public var tableShare: tableShare?
    private var networking: NCShareNetworking?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewWindowCalendar: UIView?
    private var calendar: FSCalendar?
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switchAllowUploadAndEditing.onTintColor = NCBrandColor.shared.brandElement
        switchReadOnly.onTintColor = NCBrandColor.shared.brandElement
        switchCanReshare.onTintColor = NCBrandColor.shared.brandElement
        switchPasswordProtect.onTintColor = NCBrandColor.shared.brandElement
        switchHideDownload.onTintColor = NCBrandColor.shared.brandElement
        switchSetExpirationDate.onTintColor = NCBrandColor.shared.brandElement
        
        labelCanReshare?.text = NSLocalizedString("_share_can_reshare_", comment: "")
        labelCanReshare?.textColor = NCBrandColor.shared.textView
        labelReadOnly?.text = NSLocalizedString("_share_read_only_", comment: "")
        labelReadOnly?.textColor = NCBrandColor.shared.icon
        labelAllowUploadAndEditing?.text = NSLocalizedString("_share_allow_upload_", comment: "")
        labelAllowUploadAndEditing?.textColor = NCBrandColor.shared.icon
        labelHideDownload?.text = NSLocalizedString("_share_hide_download_", comment: "")
        labelHideDownload?.textColor = NCBrandColor.shared.icon
        labelPasswordProtect?.text = NSLocalizedString("_share_password_protect_", comment: "")
        labelPasswordProtect?.textColor = NCBrandColor.shared.icon
        labelSetExpirationDate?.text = NSLocalizedString("_share_expiration_date_", comment: "")
        labelSetExpirationDate?.textColor = NCBrandColor.shared.icon
        
        labelPermission?.text = NSLocalizedString("_permissions_", comment: "")
        labelPermission?.textColor = NCBrandColor.shared.commonViewInfoText
        labelAdvancePermission?.text = NSLocalizedString("_share_expiration_date_", comment: "")
        labelAdvancePermission?.textColor = NCBrandColor.shared.commonViewInfoText
        
        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        btnCancel.layer.cornerRadius = 10
        btnCancel.layer.masksToBounds = true
        btnCancel.layer.borderWidth = 1
        btnCancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        btnCancel.setTitleColor(NCBrandColor.shared.icon, for: .normal)
        btnCancel.backgroundColor = .white
        
        btnNext.setTitle(NSLocalizedString("_next_", comment: ""), for: .normal)
        btnNext.layer.cornerRadius = 10
        btnNext.layer.masksToBounds = true
        btnNext.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        btnNext.setTitleColor(.white, for: .normal)
        
        fieldPasswordProtect.isEnabled = false
        
        if self.metadata!.directory {
            switchFileDrop.onTintColor = NCBrandColor.shared.brandElement
            labelFileDrop?.text = NSLocalizedString("_share_file_drop_", comment: "")
            labelFileDrop?.textColor = NCBrandColor.shared.icon
        }
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase,  view: self.view, delegate: self)
    }
    
    func reloadData(idShare: Int) {
//        guard let metadata = self.metadata else { return }
//        tableShare = NCManageDatabase.shared.getTableShare(account: metadata.account, idShare: idShare)
//        guard let tableShare = self.tableShare else { return }
//
//        guard let sharee = self.sharee else { return }
//
//        if metadata.directory {
//            // File Drop
//            if tableShare.permissions == NCGlobal.shared.permissionCreateShare {
//                switchReadOnly.setOn(false, animated: false)
//                switchAllowUploadAndEditing.setOn(false, animated: false)
//                switchFileDrop.setOn(true, animated: false)
//            } else {
//                // Read Only
//                if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
//                    switchReadOnly.setOn(false, animated: false)
//                    switchAllowUploadAndEditing.setOn(true, animated: false)
//                } else {
//                    switchReadOnly.setOn(true, animated: false)
//                    switchAllowUploadAndEditing.setOn(false, animated: false)
//                }
//                switchFileDrop.setOn(false, animated: false)
//            }
//        } else {
//            // Allow editing
//            if CCUtility.isAnyPermission(toEdit: tableShare.permissions) {
//                switchAllowUploadAndEditing.setOn(true, animated: false)
//                switchReadOnly.setOn(false, animated: false)
//            } else {
//                switchAllowUploadAndEditing.setOn(false, animated: false)
//                switchReadOnly.setOn(true, animated: false)
//            }
//        }
//
//        // Hide download
//        if tableShare.hideDownload {
//            switchHideDownload.setOn(true, animated: false)
//        } else {
//            switchHideDownload.setOn(false, animated: false)
//        }
//
//        // Password protect
//        if tableShare.shareWith.count > 0 {
//            switchPasswordProtect.setOn(true, animated: false)
//            fieldPasswordProtect.isEnabled = true
//            fieldPasswordProtect.text = tableShare.shareWith
//        } else {
//            switchPasswordProtect.setOn(false, animated: false)
//            fieldPasswordProtect.isEnabled = false
//            fieldPasswordProtect.text = ""
//        }
//
//        // Set expiration date
//        if tableShare.expirationDate != nil {
//            switchSetExpirationDate.setOn(true, animated: false)
//            fieldSetExpirationDate.isEnabled = true
//
//            let dateFormatter = DateFormatter()
//            dateFormatter.formatterBehavior = .behavior10_4
//            dateFormatter.dateStyle = .medium
//            fieldSetExpirationDate.text = dateFormatter.string(from: tableShare.expirationDate! as Date)
//        } else {
//            switchSetExpirationDate.setOn(false, animated: false)
//            fieldSetExpirationDate.isEnabled = false
//            fieldSetExpirationDate.text = ""
//        }
    }
    
    func unLoad() {
        viewWindowCalendar?.removeFromSuperview()
//        viewWindow?.removeFromSuperview()
        
        viewWindowCalendar = nil
//        viewWindow = nil
    }
    
    @IBAction func readOnlyValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
//        guard let metadata = self.metadata else { return }
//        let permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata.directory)

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            if metadata!.directory {
                switchAllowUploadAndEditing.setOn(false, animated: false)
                if self.metadata!.directory {
                    switchFileDrop.setOn(false, animated: false)
                }
                metadata?.permissions = "RDNVCK"
            }
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata?.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func allowUploadEditingValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
//        guard let metadata = self.metadata else { return }
//        let permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            switchReadOnly.setOn(false, animated: false)
            if metadata!.directory {
                switchFileDrop.setOn(false, animated: false)
            }
            metadata?.permissions = "RGDNV"
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata?.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func fileDropValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
//        let permission = NCGlobal.shared.permissionCreateShare

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            switchReadOnly.setOn(false, animated: false)
            switchAllowUploadAndEditing.setOn(false, animated: false)
            metadata?.permissions = "RGDNVCK"
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata?.permissions = "RGD"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func canReshareValueChanged(sender: UISwitch) {
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
            metadata.permissions = "SRGD"
        }
        
//        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
    }
    
    @IBAction func hideDownloadValueChanged(sender: UISwitch) {
        guard let tableShare = self.tableShare else { return }
        
//        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: tableShare.permissions, note: nil, expirationDate: nil, hideDownload: sender.isOn)
    }
    
    @IBAction func setPasswordValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        
        if sender.isOn {
            fieldPasswordProtect.isEnabled = true
            fieldPasswordProtect.text = ""
            fieldPasswordProtect.becomeFirstResponder()
        } else {
            fieldPasswordProtect.isEnabled = false
//            networking?.updateShare(idShare: tableShare.idShare, password: "", permission: tableShare.permissions, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        }
    }
    
    @IBAction func setExpirationValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }

        if sender.isOn {
            fieldSetExpirationDate.isEnabled = true
            fieldSetExpirationDate(sender: fieldSetExpirationDate)
        } else {
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: tableShare.permissions, note: nil, expirationDate: "", hideDownload: tableShare.hideDownload)
        }
    }
    
    @IBAction func fieldSetExpirationDate(sender: UITextField) {
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
    
    @IBAction func nextClicked(_ sender: Any) {
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as! NCShareNewUserAddComment
        viewNewUserComment.metadata = self.metadata
        viewNewUserComment.sharee = sharee
        self.navigationController!.pushViewController(viewNewUserComment, animated: true)
    }
    
    // MARK: - Delegate networking
    
    func readShareCompleted() {
        reloadData(idShare: tableShare?.idShare ?? 0)
    }
    
    func shareCompleted() {
        unLoad()
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func unShareCompleted() {
        unLoad()
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataNCShare)
    }
    
    func updateShareWithError(idShare: Int) {
        reloadData(idShare: idShare)
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
            fieldSetExpirationDate.text = dateFormatter.string(from:date)
            fieldSetExpirationDate.endEditing(true)
            
            viewWindowCalendar?.removeFromSuperview()
            
            guard let tableShare = self.tableShare else { return }

            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let expirationDate = dateFormatter.string(from: date)
            
            metadata?.trashbinDeletionTime = date as NSDate
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: tableShare.permissions, note: nil, expirationDate: expirationDate, hideDownload: tableShare.hideDownload)
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
        
        reloadData(idShare: tableShare?.idShare ?? 0)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return gestureRecognizer.view == touch.view
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
