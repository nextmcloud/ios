//
//  NCCreateFormUploadAssets.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/11/2018.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
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
import Queuer

@objc protocol createFormUploadAssetsDelegate {
    
    func dismissFormUploadAssets()
}

class NCCreateFormUploadAssets: XLFormViewController, NCSelectDelegate {
    
    var serverUrl: String = ""
    var titleServerUrl: String?
    var assets: [PHAsset] = []
    var cryptated: Bool = false
    var session: String = ""
    weak var delegate: createFormUploadAssetsDelegate?
    let requestOptions = PHImageRequestOptions()
    var imagePreview: UIImage?
    let targetSizeImagePreview = CGSize(width:100, height: 100)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @objc convenience init(serverUrl: String, assets: [PHAsset], cryptated: Bool, session: String, delegate: createFormUploadAssetsDelegate?) {
        
        self.init()
        
        if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, account: appDelegate.account) {
            titleServerUrl = "/"
        } else {
            if let tableDirectory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, serverUrl)) {
                if let metadata = NCManageDatabase.shared.getMetadataFromOcId(tableDirectory.ocId) {
                    titleServerUrl = metadata.fileNameView
                } else { titleServerUrl = (serverUrl as NSString).lastPathComponent }
            } else { titleServerUrl = (serverUrl as NSString).lastPathComponent }
        }
        
        self.serverUrl = serverUrl
        self.assets = assets
        self.cryptated = cryptated
        self.session = session
        self.delegate = delegate
        
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isSynchronous = true
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.title = NSLocalizedString("_upload_photos_videos_", comment: "")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        self.navigationController!.navigationBar.tintColor = NCBrandColor.shared.customer
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        if assets.count == 1 && assets[0].mediaType == PHAssetMediaType.image {
            PHImageManager.default().requestImage(for: assets[0], targetSize: targetSizeImagePreview, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, info) in
                self.imagePreview = image
            })
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCBrandGlobal.shared.notificationCenterChangeTheming), object: nil)

        changeTheming()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        self.delegate?.dismissFormUploadAssets()
    }
    
    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.backgroundColor = NCBrandColor.shared.backgroundForm
        tableView.reloadData()
        initializeForm()
        self.reloadForm()
    }
    
    //MARK: XLForm
    
    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        section.footerTitle = NSLocalizedString("_auto_upload_help_text_", comment: "")
        form.addFormSection(section)
        
//        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
//        row.action.formSelector = #selector(changeDestinationFolder(_:))
//        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
////       row.cellConfig["imageView.image"] = UIImage(named: "folder")!.image(color: NCBrandColor.shared.brandElement, size: 25)
//        row.cellConfig["imageView.image"] = UIImage(named: "folder")!.image(color: NCBrandColor.shared.customerDefault, size: 25)
//        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
        
        //custom folder upload
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFolderCustomCellType"] = FolderPathCustomCell.self
        
        
        row = XLFormRowDescriptor(tag: "PhotoButtonDestinationFolder", rowType: "kNMCFolderCustomCellType", title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))
        row.cellConfig["folderImage.image"] =  UIImage(named: "folder")!.image(color: NCBrandColor.shared.brandElement, size: 25)
        
        row.cellConfig["photoLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["photoLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["photoLabel.textColor"] = NCBrandColor.shared.textView //photos
        row.cellConfig["photoLabel.text"] = NSLocalizedString("_prefix_upload_path_", comment: "")
        row.cellConfig["textLabel.text"] = ""//topLineView.isHidden
        
        section.addFormRow(row)
        
         //User folder Autoupload
//        row = XLFormRowDescriptor(tag: "useFolderAutoUpload", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_use_folder_auto_upload_", comment: ""))
//        row.value = 0
//        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
//        //row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        
        
        //custom autouload cell
    
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellAutoUpload"] = AutoUploadFolderCustomCell.self


        row = XLFormRowDescriptor(tag: "useFolderAutoUpload", rowType: "NMCCustomSwitchCellAutoUpload", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_use_folder_auto_upload_", comment: "")
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.textView
        row.cellConfigAtConfigure["autoUploadSwitchControl.on"] = 0 //onTintColor
        row.cellConfig["autoUploadSwitchControl.onTintColor"] = NCBrandColor.shared.brand
        row.value = 0
        if (NSLocalizedString("_use_folder_auto_upload_", comment: "").count > 44 ){
            row.height = 65;
        }
        //end of custom autoupload cell
        
        
        section.addFormRow(row)
        
        // Use Sub folder
//        row = XLFormRowDescriptor(tag: "useSubFolder", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_create_subfolder_", comment: ""))
//        let tableAccount = NCManageDatabase.shared.getAccountActive()
//        if tableAccount?.autoUploadCreateSubfolder == true {
//            row.value = 1
//        } else {
//            row.value = 0
//        }
//        row.hidden = "$\("useFolderAutoUpload") == 0"
//
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
        
//        row = [XLFormRowDescriptor formRowDescriptorWithTag:@"useFolderAutoUpload" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"_lock_protection_no_screen_", nil)];
        
        
        //custom subfolder row
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellsubFolderUpload"] = SubFolderCustomCell.self


        row = XLFormRowDescriptor(tag: "useSubFolder", rowType: "NMCCustomSwitchCellsubFolderUpload", title: self.titleServerUrl)
        row.cellConfig["subFolderLabel.text"] = NSLocalizedString("_autoupload_create_subfolder_", comment: "")
        let tableAccount = NCManageDatabase.shared.getAccountActive()
        if tableAccount?.autoUploadCreateSubfolder == true {
            row.cellConfigAtConfigure["subFolderSwitch.on"] = 1
            row.value = 1
            row.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.textView
        } else {
            row.cellConfigAtConfigure["subFolderSwitch.on"] = 0
            row.value = 0
            row.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.graySoft
        }
        //row.hidden = "$\("useFolderAutoUpload") == 0"
        row.cellConfig["subFolderLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["subFolderSwitch.onTintColor"] = NCBrandColor.shared.brand
        //end of custom subfolder row
        section.addFormRow(row)

        // Section Mode filename
        
//        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_mode_filename_", comment: ""))
//        form.addFormSection(section)
        
        // Maintain the original fileName
        
      
        
        // Add File Name Type
        
        
        
        // Section: Rename File Name
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: ""))
        form.addFormSection(section)
        
        // Maintain the original fileName
        
//        row = XLFormRowDescriptor(tag: "maintainOriginalFileName", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_maintain_original_filename_", comment: ""))
//        row.value = CCUtility.getOriginalFileName(NCBrandGlobal.shared.keyFileNameOriginal)
//        //row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
        
        //######## custom row maintain original filename
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellMaintainOriginalFileName"] = OriginalFileNameCustomSwitchCell.self


        row = XLFormRowDescriptor(tag: "maintainOriginalFileName", rowType: "NMCCustomSwitchCellMaintainOriginalFileName", title: NSLocalizedString("_maintain_original_filename_", comment: ""))
        row.cellConfig["originalFileNameTitle.text"] = NSLocalizedString("_maintain_original_filename_", comment: "")
        
        if(CCUtility.getOriginalFileName(NCBrandGlobal.shared.keyFileNameOriginal)){
            
            row.cellConfigAtConfigure["originalFileNameSwitch.on"] = 1
        }else {
            row.cellConfigAtConfigure["originalFileNameSwitch.on"] = 0
        }
//        row.cellConfig["originalFileNameSwitch.on"] = CCUtility.getOriginalFileName(NCBrandGlobal.shared.keyFileNameOriginal)
        row.cellConfig["originalFileNameTitle.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["originalFileNameTitle.textColor"] = NCBrandColor.shared.textView
        row.cellConfig["originalFileNameSwitch.onTintColor"] = NCBrandColor.shared.brand

        //#######end of custom row maintain original filename
        
        section.addFormRow(row)
        
        //Add File Name Type
//
//        row = XLFormRowDescriptor(tag: "addFileNameType", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_add_filenametype_", comment: ""))
//        row.value = CCUtility.getFileNameType(NCBrandGlobal.shared.keyFileNameType)
//        row.hidden = "$\("maintainOriginalFileName") == 1"
//        //row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
        
        //###### custom row Add File Name Type
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellTypeInFileName"] = TypeInFileNameCustomSwitchCell.self


        row = XLFormRowDescriptor(tag: "addFileNameType", rowType: "NMCCustomSwitchCellTypeInFileName", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_add_filenametype_", comment: "")
        row.cellConfigAtConfigure["switchControl.on"] = CCUtility.getFileNameType(NCBrandGlobal.shared.keyFileNameType)
        row.hidden = "$\("maintainOriginalFileName") == 1"
       // row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm

        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.textView
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand

        //#######end of custom row Add File Name Type
        
        section.addFormRow(row)
        
//        row = XLFormRowDescriptor(tag: "maskFileName", rowType: XLFormRowDescriptorTypeAccount, title: (NSLocalizedString("_filename_", comment: "")))
//        let fileNameMask : String = CCUtility.getFileNameMask(NCBrandGlobal.shared.keyFileNameMask)
//        if fileNameMask.count > 0 {
//            row.value = fileNameMask
//        }
//        row.hidden = "$\("maintainOriginalFileName") == 1"
//        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.textView
//
//        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
//        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textField.textColor"] = NCBrandColor.shared.textView
        
        //custom row mask file name
        row = XLFormRowDescriptor(tag: "maskFileName", rowType: "NMCCustomInputFieldFileName", title: NSLocalizedString("_filename_", comment: ""))
        row.cellClass = TextTableViewCell.self
        let fileNameMask : String = CCUtility.getFileNameMask(NCBrandGlobal.shared.keyFileNameMask)

        if fileNameMask.count > 0 {
            //row.value = fileNameMask
            row.cellConfig["fileNameTextField.text"] = fileNameMask
        }else{
            let asset = assets[0]
            let  placeHolderString =   CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)
            row.cellConfig["fileNameTextField.placeholder"] = placeHolderString
        }
        row.hidden = "$\("maintainOriginalFileName") == 1"
       // row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm

        //row.cellConfig["labelFileName.font"] = UIFont.systemFont(ofSize: 15.0)
        //row.cellConfig["labelFileName.textColor"] = NCBrandColor.shared.textView

        row.cellConfig["fileNameTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["fileNameTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["fileNameTextField.textColor"] = NCBrandColor.shared.textView

        //end of custom row mask file name

        section.addFormRow(row)
        
        // Section: Preview File Name
        
        row = XLFormRowDescriptor(tag: "previewFileName", rowType: XLFormRowDescriptorTypeTextView, title: "")
        row.height = 180
        row.disabled = true
        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm

        row.cellConfig["textView.backgroundColor"] = NCBrandColor.shared.backgroundForm
        row.cellConfig["textView.font"] = UIFont.systemFont(ofSize: 14.0)
        row.cellConfig["textView.textColor"] = NCBrandColor.shared.textView

        section.addFormRow(row)
        
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "useFolderAutoUpload" {
            
            if (formRow.value! as AnyObject).boolValue  == true {
                
                //Hide folder selection option
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "PhotoButtonDestinationFolder")!
                buttonDestinationFolder.cellConfig["photoLabel.textColor"] = NCBrandColor.shared.graySoft
                
                //enable subfolder selection option
                let subfolderSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
                subfolderSwitchOption.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.textView//isEnabled
                subfolderSwitchOption.value = "enable_switch"
                self.reloadForm()

            } else{
                
                //enable folder selection option
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "PhotoButtonDestinationFolder")!
                buttonDestinationFolder.cellConfig["photoLabel.textColor"] = NCBrandColor.shared.textView
                
                //hide subfolder selection option
                let subfolderSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
                subfolderSwitchOption.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.graySoft
                subfolderSwitchOption.disabled = true
                subfolderSwitchOption.value = "disable_switch"
                self.reloadForm()

            }
        }
        else if formRow.tag == "useSubFolder" {
            
            if (formRow.value! as AnyObject).boolValue  == true {
                print("switch on subfolder")
                
            } else{
                print("switch off subfolder")

            }
        }
        else if formRow.tag == "maintainOriginalFileName" {
            CCUtility.setOriginalFileName((formRow.value! as AnyObject).boolValue, key: NCBrandGlobal.shared.keyFileNameOriginal)
            self.reloadForm()
        }
        else if formRow.tag == "addFileNameType" {
            CCUtility.setFileNameType((formRow.value! as AnyObject).boolValue, key: NCBrandGlobal.shared.keyFileNameType)
            self.reloadForm()
        }
        else if formRow.tag == "maskFileName" {
            
            let fileName = formRow.value as? String
            
            self.form.delegate = nil
            
            if let fileName = fileName {
                formRow.value = CCUtility.removeForbiddenCharactersServer(fileName)
            }
            
            self.form.delegate = self
            
            let previewFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
            previewFileName.value = self.previewFileName(valueRename: formRow.value as? String)
            
            // reload cell
            if fileName != nil {
                
                if newValue as! String != formRow.value as! String {
                    
                    self.reloadFormRow(formRow)
                    
                    NCContentPresenter.shared.messageNotification("_info_", description: "_forbidden_characters_", delay: NCBrandGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCBrandGlobal.shared.ErrorCharactersForbidden, forced: true)
                }
            }else{
                let asset = assets[0]
                formRow.cellConfig["fileNameTextField.placeholder"] =   CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)
            }
            
            self.reloadFormRow(previewFileName)
        }
    }
    
    func reloadForm() {
        
        self.form.delegate = nil
        
        let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "PhotoButtonDestinationFolder")!
        buttonDestinationFolder.title = self.titleServerUrl
        
        let maskFileName : XLFormRowDescriptor = self.form.formRow(withTag: "maskFileName")!
        let previewFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
        previewFileName.value = self.previewFileName(valueRename: maskFileName.value as? String)
        
        self.tableView.reloadData()
        self.form.delegate = self
    }
    
    // MARK: - Action
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], buttonType: String, overwrite: Bool) {
        
        if serverUrl != nil {
            
            self.serverUrl = serverUrl!
            
            if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, account: appDelegate.account) {
                self.titleServerUrl = "/"
            } else {
                if let tableDirectory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account
                    , self.serverUrl)) {
                    if let metadata = NCManageDatabase.shared.getMetadataFromOcId(tableDirectory.ocId) {
                        titleServerUrl = metadata.fileNameView
                    } else { titleServerUrl = (self.serverUrl as NSString).lastPathComponent }
                } else { titleServerUrl = (self.serverUrl as NSString).lastPathComponent }                
            }
            
            // Update
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "PhotoButtonDestinationFolder")!
            row.cellConfig["photoLabel.text"] = self.titleServerUrl
            self.updateFormRow(row)
        }
    }
    
    /*
    @objc func save() {
        
        self.dismiss(animated: true, completion: {
            
            let useFolderPhotoRow : XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderAutoUpload")!
            let useSubFolderRow : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
            var useSubFolder : Bool = false
            
            if (useFolderPhotoRow.value! as AnyObject).boolValue == true {
                
                self.serverUrl = NCManageDatabase.shared.getAccountAutoUploadPath(urlBase: self.appDelegate.urlBase, account: self.appDelegate.account)
                useSubFolder = (useSubFolderRow.value! as AnyObject).boolValue
            }
            
            self.appDelegate.activeMain.uploadFileAsset(self.assets, serverUrl: self.serverUrl, useSubFolder: useSubFolder, session: self.session)
        })
    }
    */
    
    @objc func save() {
         
        DispatchQueue.global().async {
        
            let useFolderPhotoRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderAutoUpload")!
            let useSubFolderRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
            var useSubFolder: Bool = false
            var metadatasMOV: [tableMetadata] = []
            var metadatasNOConflict: [tableMetadata] = []
            var metadatasUploadInConflict: [tableMetadata] = []

            if (useFolderPhotoRow.value! as AnyObject).boolValue == true {
                self.serverUrl = NCManageDatabase.shared.getAccountAutoUploadPath(urlBase: self.appDelegate.urlBase, account: self.appDelegate.account)
                useSubFolder = (useSubFolderRow.value! as AnyObject).boolValue
            }
            
            let autoUploadPath = NCManageDatabase.shared.getAccountAutoUploadPath(urlBase: self.appDelegate.urlBase, account: self.appDelegate.account)
            if autoUploadPath == self.serverUrl {
                if !NCNetworking.shared.createFolder(assets: self.assets, selector: NCBrandGlobal.shared.selectorUploadFile, useSubFolder: useSubFolder, account: self.appDelegate.account, urlBase: self.appDelegate.urlBase) {
                    NCContentPresenter.shared.messageNotification("_error_", description: "_error_createsubfolders_upload_", delay: NCBrandGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: NCBrandGlobal.shared.ErrorInternalError, forced: true)
                    return
                }
            }

            for asset in self.assets {
                    
                var serverUrl = self.serverUrl
                var livePhoto: Bool = false
                let fileName = CCUtility.createFileName(asset.value(forKey: "filename") as? String, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: NCBrandGlobal.shared.keyFileNameMask, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)!
                let assetDate = asset.creationDate ?? Date()
                let dateFormatter = DateFormatter()
                
                // Detect LivePhoto Upload
                if asset.mediaSubtypes.contains(.photoLive) && CCUtility.getLivePhoto() {
                    livePhoto = true
                } 
                
                // Create serverUrl if use sub folder
                if useSubFolder {
                    
                    dateFormatter.dateFormat = "yyyy"
                    let yearString = dateFormatter.string(from: assetDate)
                   
                    dateFormatter.dateFormat = "MM"
                    let monthString = dateFormatter.string(from: assetDate)
                    
                    serverUrl = autoUploadPath + "/" + yearString + "/" + monthString
                }
                
                // Check if is in upload
                let isRecordInSessions = NCManageDatabase.shared.getAdvancedMetadatas(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@ AND session != ''", self.appDelegate.account, serverUrl, fileName), sorted: "fileName", ascending: false)
                if isRecordInSessions.count > 0 {
                    continue
                }
                
                let metadataForUpload = NCManageDatabase.shared.createMetadata(account: self.appDelegate.account, fileName: fileName, fileNameView: fileName, ocId: NSUUID().uuidString, serverUrl: serverUrl, urlBase: self.appDelegate.urlBase, url: "", contentType: "", livePhoto: livePhoto, chunk: false)
                
                metadataForUpload.assetLocalIdentifier = asset.localIdentifier
                metadataForUpload.session = self.session
                metadataForUpload.sessionSelector = NCBrandGlobal.shared.selectorUploadFile
                metadataForUpload.size = NCUtilityFileSystem.shared.getFileSize(asset: asset)
                metadataForUpload.status = NCBrandGlobal.shared.metadataStatusWaitUpload
                
                if livePhoto {
                    
                    let fileNameMove = (fileName as NSString).deletingPathExtension + ".mov"
                    let ocId = NSUUID().uuidString
                    let filePath = CCUtility.getDirectoryProviderStorageOcId(ocId, fileNameView: fileNameMove)!
                    
                    let semaphore = Semaphore()
                    CCUtility.extractLivePhotoAsset(asset, filePath: filePath) { (url) in
                        if let url = url {
                            let fileSize = NCUtilityFileSystem.shared.getFileSize(filePath: url.path)
                            let metadataMOVForUpload = NCManageDatabase.shared.createMetadata(account: self.appDelegate.account, fileName: fileNameMove,fileNameView: fileName, ocId:ocId, serverUrl: serverUrl, urlBase: self.appDelegate.urlBase, url: "", contentType: "", livePhoto: livePhoto, chunk: false)

                            metadataForUpload.livePhoto = true
                            metadataMOVForUpload.livePhoto = true
                            
                            metadataMOVForUpload.session = self.session
                            metadataMOVForUpload.sessionSelector = NCBrandGlobal.shared.selectorUploadFile
                            metadataMOVForUpload.size = fileSize
                            metadataMOVForUpload.status = NCBrandGlobal.shared.metadataStatusWaitUpload
                            metadataMOVForUpload.typeFile = NCBrandGlobal.shared.metadataTypeFileVideo

                            metadatasMOV.append(metadataMOVForUpload)
                        }
                        semaphore.continue()
                    }
                    semaphore.wait()
                }
                
                if NCManageDatabase.shared.getMetadataConflict(account: self.appDelegate.account, serverUrl: serverUrl, fileName: fileName) != nil {
                    metadatasUploadInConflict.append(metadataForUpload)
                } else {
                    metadatasNOConflict.append(metadataForUpload)
                }
            }
            
            // Verify if file(s) exists
            if metadatasUploadInConflict.count > 0 {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let conflict = UIStoryboard.init(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict {
                        
                        conflict.serverUrl = self.serverUrl
                        conflict.metadatasNOConflict = metadatasNOConflict
                        conflict.metadatasMOV = metadatasMOV
                        conflict.metadatasUploadInConflict = metadatasUploadInConflict
                    
                        self.appDelegate.window?.rootViewController?.present(conflict, animated: true, completion: nil)
                    }
                }
                
            } else {
                
                self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: metadatasNOConflict)
                self.appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: metadatasMOV)  
            }
        
            DispatchQueue.main.async {self.dismiss(animated: true, completion: nil)  }
        }
    }
    
    @objc func cancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility
    
    func previewFileName(valueRename : String?) -> String {
        
        var returnString: String = ""
        let asset = assets[0]
        
        if (CCUtility.getOriginalFileName(NCBrandGlobal.shared.keyFileNameOriginal)) {
            
            return (NSLocalizedString("_filename_", comment: "") + ": " + (asset.value(forKey: "filename") as! String))
            
        } else if let valueRename = valueRename {
            
            let valueRenameTrimming = valueRename.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if valueRenameTrimming.count > 0 {
                
                self.form.delegate = nil
                CCUtility.setFileNameMask(valueRename, key: NCBrandGlobal.shared.keyFileNameMask)
                self.form.delegate = self
                
                returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: NCBrandGlobal.shared.keyFileNameMask, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)
                
            } else {
                
                CCUtility.setFileNameMask("", key: NCBrandGlobal.shared.keyFileNameMask)
                returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)
            }
            
        } else {
            
            CCUtility.setFileNameMask("", key: NCBrandGlobal.shared.keyFileNameMask)
            returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCBrandGlobal.shared.keyFileNameType, keyFileNameOriginal: NCBrandGlobal.shared.keyFileNameOriginal)
        }
        
        return String(format: NSLocalizedString("_preview_filename_", comment: ""), "MM, MMM, DD, YY, YYYY, HH, hh, mm, ss, ampm") + ":" + "\n\n" + returnString
    }
    
    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
        let useFolderPhotoRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderAutoUpload")!
        self.deselectFormRow(sender)
        
        if (useFolderPhotoRow.value! as AnyObject).boolValue == true{
            return
        }
        
        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        let viewController = navigationController.topViewController as! NCSelect
        
        viewController.delegate = self
        viewController.hideButtonCreateFolder = false
        viewController.includeDirectoryE2EEncryption = true
        viewController.includeImages = false
        viewController.selectFile = false
        viewController.titleButtonDone = NSLocalizedString("_select_", comment: "")
        viewController.type = ""
        
        navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(navigationController, animated: true, completion: nil)
    }
}
