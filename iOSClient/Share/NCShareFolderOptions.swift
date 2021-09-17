//
//  NCShareFolderOptions.swift
//  Nextcloud
//
//  Created by T-systems on 03/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit
import FSCalendar
import NCCommunication

class NCShareFolderOptions: UIViewController ,UIGestureRecognizerDelegate, NCShareNetworkingDelegate, FSCalendarDelegate, FSCalendarDelegateAppearance, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelFileName: UILabel!
    @IBOutlet weak var labelFileDescription: UILabel!
    @IBOutlet weak var labelSharing: UILabel!
    @IBOutlet weak var labelPermission: UILabel!
    @IBOutlet weak var switchReadOnly: UISwitch!
    @IBOutlet weak var labelReadOnly: UILabel!
    @IBOutlet weak var switchEditing: UISwitch!
    @IBOutlet weak var labelEditing: UILabel!
    @IBOutlet weak var switchFileDrop: UISwitch!
    @IBOutlet weak var labelFileDrop: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelAdvancePermission: UILabel!
    @IBOutlet weak var switchHideDownload: UISwitch!
    @IBOutlet weak var labelHideDownload: UILabel!
    @IBOutlet weak var labelPwdProtection: UILabel!
    @IBOutlet weak var switchPwd: UISwitch!
    @IBOutlet weak var labelSetPwd: UILabel!
    @IBOutlet weak var tfPwd: UITextField!
    @IBOutlet weak var labelExpirationDate: UILabel!
    @IBOutlet weak var switchExpiration: UISwitch!
    @IBOutlet weak var labelSetExpiration: UILabel!
    @IBOutlet weak var tfExpirationDate: UITextField!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var applyChanges: UIButton!
//    @IBOutlet weak var scrollView: UIScrollView!
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    public var tableShare: tableShare?
    
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ocId = ""
    private var networking: NCShareNetworking?
    var viewWindowCalendar: UIView?
    private var calendar: FSCalendar?
    var width: CGFloat = 0
    var height: CGFloat = 0
    var permission: Int = 0
    var hideDownload: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switchPwd.onTintColor = NCBrandColor.shared.brandElement
        switchHideDownload.onTintColor = NCBrandColor.shared.brandElement
        switchEditing.onTintColor = NCBrandColor.shared.brandElement
        switchExpiration.onTintColor = NCBrandColor.shared.brandElement
        switchReadOnly.onTintColor = NCBrandColor.shared.brandElement
        switchFileDrop.onTintColor = NCBrandColor.shared.brandElement
        
        
        labelReadOnly?.text = NSLocalizedString("_share_read_only_", comment: "")
        labelReadOnly?.textColor = NCBrandColor.shared.icon
        labelEditing?.text = NSLocalizedString("_share_allow_upload_", comment: "")
        labelEditing?.textColor = NCBrandColor.shared.icon
        labelFileDrop?.text = NSLocalizedString("_share_file_drop_", comment: "")
        labelFileDrop?.textColor = NCBrandColor.shared.icon
        labelHideDownload?.text = NSLocalizedString("_share_hide_download_", comment: "")
        labelHideDownload?.textColor = NCBrandColor.shared.icon
        labelSetPwd?.text = NSLocalizedString("_share_password_protect_", comment: "")
        labelSetPwd?.textColor = NCBrandColor.shared.icon
        labelSetExpiration?.text = NSLocalizedString("_share_expiration_date_", comment: "")
        labelSetExpiration?.textColor = NCBrandColor.shared.icon

        labelPermission?.text = NSLocalizedString("_PERMISSIONS_", comment: "")
        labelPermission?.textColor = NCBrandColor.shared.commonViewInfoText
        labelAdvancePermission?.text = NSLocalizedString("_ADVANCE_PERMISSION_", comment: "")
        labelAdvancePermission?.textColor = NCBrandColor.shared.commonViewInfoText
        labelPwdProtection?.text = NSLocalizedString("_EXPIRATION_DATE_", comment: "")
        labelPwdProtection?.textColor = NCBrandColor.shared.commonViewInfoText
        labelExpirationDate?.text = NSLocalizedString("_EXPIRATION_DATE_", comment: "")
        labelExpirationDate?.textColor = NCBrandColor.shared.commonViewInfoText
        labelMessage?.text = NSLocalizedString("_file_drop_message_", comment: "")
        labelMessage?.textColor = NCBrandColor.shared.commonViewInfoText

        cancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        cancel.layer.cornerRadius = 10
        cancel.layer.masksToBounds = true
        cancel.layer.borderWidth = 1
        cancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        cancel.setTitleColor(NCBrandColor.shared.icon, for: .normal)
        cancel.backgroundColor = .white

        applyChanges.setTitle(NSLocalizedString("_apply_changes_", comment: ""), for: .normal)
        applyChanges.layer.cornerRadius = 10
        applyChanges.layer.masksToBounds = true
        applyChanges.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        applyChanges.setTitleColor(.white, for: .normal)

        tfPwd.isEnabled = false
        tfExpirationDate.isEnabled = false
//        self.scrollView.isDirectionalLockEnabled = true
//        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.scrollView.frame.height - 50)
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase,  view: self.view, delegate: self)
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.x>0 {
//            scrollView.contentOffset.x = 0
//        }
//    }
        
    // MARK: - Actions
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        if let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
            NCNetworking.shared.favoriteMetadata(metadata, urlBase: appDelegate.urlBase) { (errorCode, errorDescription) in
                if errorCode == 0 {
                    if !metadata.favorite {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                    } else {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                    }
                } else {
                    NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                }
            }
        }
    }
    
    @IBAction func readOnlyValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: false, andIsFolder: metadata.directory)

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            if metadata.directory {
                switchEditing.setOn(false, animated: false)
                if self.metadata!.directory {
                    switchFileDrop.setOn(false, animated: false)
                }
                metadata.permissions = "RDNVCK"
            }
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func allowUploadEditingValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            switchReadOnly.setOn(false, animated: false)
            if metadata.directory {
                switchFileDrop.setOn(false, animated: false)
            }
            metadata.permissions = "RGDNV"
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata.permissions = "RDNVW"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func fileDropValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }

        guard let metadata = self.metadata else { return }
        permission = CCUtility.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: false, andIsFolder: metadata.directory)

//        if sender.isOn && permission != tableShare.permissions {
        if sender.isOn {
            switchReadOnly.setOn(false, animated: false)
            switchEditing.setOn(false, animated: false)
            metadata.permissions = "RGDNVCK"
//            networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        } else {
            metadata.permissions = "RGD"
            sender.setOn(true, animated: false)
        }
    }
    
    @IBAction func canReshareValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }

        let canEdit = CCUtility.isAnyPermission(toEdit: tableShare!.permissions)
        let canCreate = CCUtility.isPermission(toCanCreate: tableShare!.permissions)
        let canChange = CCUtility.isPermission(toCanChange: tableShare!.permissions)
        let canDelete = CCUtility.isPermission(toCanDelete: tableShare!.permissions)
        
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
//            metadata.permissions = "SRGD"
        }
        
//        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: permission, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
    }
    
    @IBAction func hideDownloadValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        
        hideDownload = sender.isOn
//        networking?.updateShare(idShare: tableShare.idShare, password: nil, permission: tableShare.permissions, note: nil, expirationDate: nil, hideDownload: sender.isOn)
    }
    
    @IBAction func setPasswordValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }
        
        if sender.isOn {
            tfPwd.isEnabled = true
            tfPwd.text = ""
            tfPwd.becomeFirstResponder()
        } else {
            tfPwd.isEnabled = false
//            networking?.updateShare(idShare: tableShare.idShare, password: "", permission: tableShare.permissions, note: nil, expirationDate: nil, hideDownload: tableShare.hideDownload)
        }
    }
    
    @IBAction func setExpirationValueChanged(sender: UISwitch) {
//        guard let tableShare = self.tableShare else { return }

        if sender.isOn {
            tfExpirationDate.isEnabled = true
            fieldSetExpirationDate(sender: tfExpirationDate)
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
    
    @IBAction func touchUpInsideCancel(_ sender: Any) {
        
    }
    
    @IBAction func touchUpInsideApplyChanges(_ sender: Any) {
        
    }
    
    // MARK: - Delegate calendar
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            tfExpirationDate.text = dateFormatter.string(from:date)
            tfExpirationDate.endEditing(true)
            
            tfExpirationDate?.removeFromSuperview()
            
//            guard let tableShare = self.tableShare else { return }

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
        
//        reloadData(idShare: tableShare?.idShare ?? 0)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return gestureRecognizer.view == touch.view
    }

    
    // MARK: - Delegate networking
    func readShareCompleted() {
        
    }
    
    func shareCompleted() {
        
    }
    
    func unShareCompleted() {
        
    }
    
    func updateShareWithError(idShare: Int) {
        
    }
    
    func getSharees(sharees: [NCCommunicationSharee]?) {
        
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
