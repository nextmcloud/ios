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

import UIKit
import Queuer
import NextcloudKit
import XLForm
import Photos

class NCCreateFormUploadAssets: XLFormViewController, NCSelectDelegate {

    var serverUrl: String = ""
    var titleServerUrl: String?
    var assets: [PHAsset] = []
    var cryptated: Bool = false
    var session: String = ""
    let requestOptions = PHImageRequestOptions()
    var imagePreview: UIImage?
    let targetSizeImagePreview = CGSize(width: 100, height: 100)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var cellBackgoundColor = UIColor.secondarySystemGroupedBackground
    var switchAutoUpload: Bool = false
    var switchUseSubFolders: Bool = false
    var switchMaintainOriginalFileName: Bool = false
    var switchspecifyTypeInFileName: Bool = false
    
    // MARK: - View Life Cycle

    convenience init(serverUrl: String, assets: [PHAsset], cryptated: Bool, session: String) {

        self.init()

        if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId) {
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

        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isSynchronous = true
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        self.title = NSLocalizedString("_upload_photos_videos_", comment: "")

        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        cellBackgoundColor = .secondarySystemGroupedBackground

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))

        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        if assets.count == 1 && assets[0].mediaType == PHAssetMediaType.image {
            PHImageManager.default().requestImage(for: assets[0], targetSize: targetSizeImagePreview, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { image, _ in
                self.imagePreview = image
            })
        }

        initializeForm()
        reloadForm()
    }

    // MARK: XLForm

    func initializeForm() {

        let form: XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var section: XLFormSectionDescriptor
        var row: XLFormRowDescriptor

        // Section: Destination Folder

        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        section.footerTitle = NSLocalizedString("_auto_upload_help_text_", comment: "")
        form.addFormSection(section)

        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFolderCustomCellType"] = FolderPathCustomCell.self
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: "kNMCFolderCustomCellType", title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))
        row.cellConfig["folderImage.image"] =  UIImage(named: "folder")!.image(color: NCBrandColor.shared.brandElement, size: 25)
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        row.cellConfig["photoLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["photoLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["photoLabel.textColor"] = UIColor.label //photos
        if(self.titleServerUrl == "/"){
            row.cellConfig["photoLabel.text"] = NSLocalizedString("_prefix_upload_path_", comment: "")
        }else{
            row.cellConfig["photoLabel.text"] = self.titleServerUrl
        }
        row.cellConfig["textLabel.text"] = ""//topLineView.isHidden
        section.addFormRow(row)

        // User folder Autoupload
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellAutoUpload"] = AutoUploadFolderCustomCell.self
        row = XLFormRowDescriptor(tag: "useFolderAutoUpload", rowType: "NMCCustomSwitchCellAutoUpload", title: self.titleServerUrl)
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_use_folder_auto_upload_", comment: "")
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = UIColor.label
        row.cellConfig["autoUploadSwitchControl.onTintColor"] = NCBrandColor.shared.brand
        row.value = 0
        if (NSLocalizedString("_use_folder_auto_upload_", comment: "").count > 44 ){
            row.height = 65;
        }
        row.cellConfigAtConfigure["autoUploadSwitchControl.on"] = switchAutoUpload
        row.value = switchAutoUpload
        section.addFormRow(row)

        // Use Sub folder
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellsubFolderUpload"] = SubFolderCustomCell.self
        row = XLFormRowDescriptor(tag: "useSubFolder", rowType: "NMCCustomSwitchCellsubFolderUpload", title: self.titleServerUrl)
        row.cellConfig["subFolderLabel.text"] = NSLocalizedString("_autoupload_create_subfolder_", comment: "")
        let tableAccount = NCManageDatabase.shared.getActiveAccount()
        if tableAccount?.autoUploadCreateSubfolder == true || switchAutoUpload == true {
            row.value = 1
            row.cellConfig["subFolderLabel.textColor"] = UIColor.label
            row.value = "enable_switch"
        } else {
            row.value = 0
            row.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.graySoft
            row.value = "disable_switch"
        }
        row.cellConfigAtConfigure["subFolderSwitch.on"] = switchUseSubFolders
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        row.cellConfig["subFolderLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["subFolderSwitch.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        section.addFormRow(row)

        // Section Mode filename

        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: ""))
        form.addFormSection(section)
        
        // Maintain the original fileName

        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellMaintainOriginalFileName"] = OriginalFileNameCustomSwitchCell.self
        row = XLFormRowDescriptor(tag: "maintainOriginalFileName", rowType: "NMCCustomSwitchCellMaintainOriginalFileName", title: NSLocalizedString("_maintain_original_filename_", comment: ""))
        row.cellConfig["originalFileNameTitle.text"] = NSLocalizedString("_maintain_original_filename_", comment: "")
        if(CCUtility.getOriginalFileName(NCGlobal.shared.keyFileNameOriginal)){
            row.cellConfigAtConfigure["originalFileNameSwitch.on"] = 1
        }else {
            row.cellConfigAtConfigure["originalFileNameSwitch.on"] = 0
        }
        row.cellConfigAtConfigure["originalFileNameSwitch.on"] = switchMaintainOriginalFileName
        row.cellConfig["originalFileNameTitle.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["originalFileNameTitle.textColor"] = UIColor.label
        row.cellConfig["originalFileNameSwitch.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        section.addFormRow(row)
        

        // Add File Name Type

        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCCustomSwitchCellTypeInFileName"] = TypeInFileNameCustomSwitchCell.self
        row = XLFormRowDescriptor(tag: "addFileNameType", rowType: "NMCCustomSwitchCellTypeInFileName", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_add_filenametype_", comment: "")
        row.cellConfigAtConfigure["switchControl.on"] = CCUtility.getFileNameType(NCGlobal.shared.keyFileNameType)
        row.hidden = "$\("maintainOriginalFileName") == 1"
        row.hidden = switchMaintainOriginalFileName
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = UIColor.label
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfigAtConfigure["switchControl.on"] = switchspecifyTypeInFileName
        section.addFormRow(row)

        // Section: Rename File Name

        row = XLFormRowDescriptor(tag: "maskFileName", rowType: "NMCCustomInputFieldFileName", title: NSLocalizedString("_filename_", comment: ""))
        row.cellClass = TextTableViewCell.self
        let fileNameMask : String = CCUtility.getFileNameMask(NCGlobal.shared.keyFileNameMask)
        if fileNameMask.count > 0 {
            row.cellConfig["fileNameTextField.text"] = fileNameMask
            row.value = fileNameMask
        }else{
            let asset = assets[0]
            let  placeHolderString =   CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)
            let placeholderWithoutExtension = URL(fileURLWithPath: placeHolderString ?? "").deletingPathExtension().lastPathComponent
            row.cellConfig["fileNameTextField.text"] = placeholderWithoutExtension
            row.value = ""
        }
        row.hidden = "$\("maintainOriginalFileName") == 1"
        row.cellConfig["fileNameTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["fileNameTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["fileNameTextField.textColor"] = UIColor.label
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        section.addFormRow(row)
        
        // Section: Preview File Name

        row = XLFormRowDescriptor(tag: "previewFileName", rowType: XLFormRowDescriptorTypeTextView, title: "")
        row.height = 180
        row.disabled = true
        row.cellConfig["textView.backgroundColor"] = UIColor.systemGroupedBackground
        row.cellConfig["textView.font"] = UIFont.systemFont(ofSize: 14.0)
        row.cellConfig["textView.textColor"] = UIColor.label
        row.cellConfig["backgroundColor"] = UIColor.systemGroupedBackground

        section.addFormRow(row)

        self.form = form
    }

    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {

        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)

        if formRow.tag == "useFolderAutoUpload" {

            if (formRow.value! as AnyObject).boolValue  == true {

                //Hide folder selection option
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
                buttonDestinationFolder.cellConfig["photoLabel.textColor"] = NCBrandColor.shared.graySoft
                
                //enable subfolder selection option
                let subfolderSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
                subfolderSwitchOption.cellConfig["subFolderLabel.textColor"] = UIColor.label
                subfolderSwitchOption.value = "enable_switch"
                buttonDestinationFolder.disabled = true
                switchAutoUpload = true
                self.reloadForm()

            } else {

                //enable folder selection option
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
                buttonDestinationFolder.cellConfig["photoLabel.textColor"] = UIColor.label
                
                //hide subfolder selection option
                let subfolderSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
                subfolderSwitchOption.cellConfig["subFolderLabel.textColor"] = NCBrandColor.shared.graySoft
                subfolderSwitchOption.disabled = true
                subfolderSwitchOption.value = "disable_switch"
                buttonDestinationFolder.disabled = false
                switchAutoUpload = false
                switchUseSubFolders = false
                self.reloadForm()
            }
        } else if formRow.tag == "useSubFolder" {

            if (formRow.value! as AnyObject).boolValue  == true {
                print("switch on subfolder")
                switchUseSubFolders = true
            } else{
                print("switch off subfolder")
                switchUseSubFolders = false
            }
        } else if formRow.tag == "maintainOriginalFileName" {
            CCUtility.setOriginalFileName((formRow.value! as AnyObject).boolValue, key: NCGlobal.shared.keyFileNameOriginal)
            let rowTypeInFile : XLFormRowDescriptor  = self.form.formRow(withTag: "addFileNameType")!
            if (formRow.value! as AnyObject).boolValue  == true {
                switchMaintainOriginalFileName = true
                rowTypeInFile.hidden = switchMaintainOriginalFileName
            } else {
                switchMaintainOriginalFileName = false
                rowTypeInFile.hidden = switchMaintainOriginalFileName
            }
            self.reloadForm()
        } else if formRow.tag == "addFileNameType" {
            CCUtility.setFileNameType((formRow.value! as AnyObject).boolValue, key: NCGlobal.shared.keyFileNameType)
            if (formRow.value! as AnyObject).boolValue  == true {
                switchspecifyTypeInFileName = true
            } else {
                switchspecifyTypeInFileName = false
            }
            self.reloadForm()
        } else if formRow.tag == "maskFileName" {

            let fileName = formRow.value as? String

            self.form.delegate = nil

            if let fileName = fileName {
                formRow.value = CCUtility.removeForbiddenCharactersServer(fileName)
            }

            self.form.delegate = self

            let previewFileName: XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
            previewFileName.value = self.previewFileName(valueRename: formRow.value as? String)

            // reload cell
            if fileName != nil {

                if newValue as! String != formRow.value as! String {

                    self.reloadFormRow(formRow)

                    let error = NKError(errorCode: NCGlobal.shared.errorCharactersForbidden, errorDescription: "_forbidden_characters_")
                    NCContentPresenter.shared.showInfo(error: error)
                }
            } else {
                let asset = assets[0]
                formRow.cellConfig["fileNameTextField.text"] =   CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: true)
            }

            self.reloadFormRow(previewFileName)
        }
    }

    func reloadForm() {

        self.form.delegate = nil

        let buttonDestinationFolder: XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
        buttonDestinationFolder.title = self.titleServerUrl

        let maskFileName: XLFormRowDescriptor = self.form.formRow(withTag: "maskFileName")!
        let previewFileName: XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
        previewFileName.value = self.previewFileName(valueRename: maskFileName.value as? String)
        let fileNameMask : String = CCUtility.getFileNameMask(NCGlobal.shared.keyFileNameMask)
        if fileNameMask.count > 0 {
            maskFileName.cellConfig["fileNameTextField.text"] = fileNameMask
        }else{
            let asset = assets[0]
            let  placeHolderString =   CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)
            let placeholderWithoutExtension = URL(fileURLWithPath: placeHolderString ?? "").deletingPathExtension().lastPathComponent
            maskFileName.cellConfig["fileNameTextField.text"] = placeholderWithoutExtension
        }
        self.tableView.reloadData()
        self.form.delegate = self
    }

    // MARK: - Action

    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], overwrite: Bool, copy: Bool, move: Bool) {

        if serverUrl != nil {

            self.serverUrl = serverUrl!

            if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId) {
                self.titleServerUrl = "/"
            } else {
                if let tableDirectory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", appDelegate.account, self.serverUrl)) {
                    if let metadata = NCManageDatabase.shared.getMetadataFromOcId(tableDirectory.ocId) {
                        titleServerUrl = metadata.fileNameView
                    } else { titleServerUrl = (self.serverUrl as NSString).lastPathComponent }
                } else { titleServerUrl = (self.serverUrl as NSString).lastPathComponent }
            }

            // Update
            let row: XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
            row.cellConfig["photoLabel.text"] = self.titleServerUrl
            self.updateFormRow(row)
        }
    }

    @objc func save() {

        DispatchQueue.global().async {

            let useFolderPhotoRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderAutoUpload")!
            let useSubFolderRow: XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
            var useSubFolder: Bool = false
            var metadatasNOConflict: [tableMetadata] = []
            var metadatasUploadInConflict: [tableMetadata] = []
            let autoUploadPath = NCManageDatabase.shared.getAccountAutoUploadPath(urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId, account: self.appDelegate.account)

            if (useFolderPhotoRow.value! as AnyObject).boolValue == true {
                self.serverUrl = NCManageDatabase.shared.getAccountAutoUploadPath(urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId, account: self.appDelegate.account)
                useSubFolder = (useSubFolderRow.value! as AnyObject).boolValue
            }

            if autoUploadPath == self.serverUrl {
                if !NCNetworking.shared.createFolder(assets: self.assets, selector: NCGlobal.shared.selectorUploadFile, useSubFolder: useSubFolder, account: self.appDelegate.account, urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId, withPush: false) {
                    
                    let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_error_createsubfolders_upload_")
                    NCContentPresenter.shared.showError(error: error)
                    return
                }
            }

            for asset in self.assets {

                var serverUrl = self.serverUrl
                var livePhoto: Bool = false
                let creationDate = asset.creationDate ?? Date()
                let fileName = CCUtility.createFileName(asset.value(forKey: "filename") as? String, fileDate: creationDate, fileType: asset.mediaType, keyFileName: NCGlobal.shared.keyFileNameMask, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)!

                if asset.mediaSubtypes.contains(.photoLive) && CCUtility.getLivePhoto() {
                    livePhoto = true
                }

                if useSubFolder {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy"
                    let yearString = dateFormatter.string(from: creationDate)
                    dateFormatter.dateFormat = "MM"
                    let monthString = dateFormatter.string(from: creationDate)
                    serverUrl = autoUploadPath + "/" + yearString + "/" + monthString
                }

                // Check if is in upload
                let isRecordInSessions = NCManageDatabase.shared.getAdvancedMetadatas(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@ AND session != ''", self.appDelegate.account, serverUrl, fileName), sorted: "fileName", ascending: false)
                if isRecordInSessions.count > 0 { continue }

                let metadataForUpload = NCManageDatabase.shared.createMetadata(account: self.appDelegate.account, user: self.appDelegate.user, userId: self.appDelegate.userId, fileName: fileName, fileNameView: fileName, ocId: NSUUID().uuidString, serverUrl: serverUrl, urlBase: self.appDelegate.urlBase, url: "", contentType: "", isLivePhoto: livePhoto)

                metadataForUpload.assetLocalIdentifier = asset.localIdentifier
                metadataForUpload.session = self.session
                metadataForUpload.sessionSelector = NCGlobal.shared.selectorUploadFile
                metadataForUpload.status = NCGlobal.shared.metadataStatusWaitUpload

                if let result = NCManageDatabase.shared.getMetadataConflict(account: self.appDelegate.account, serverUrl: serverUrl, fileNameView: fileName) {
                    metadataForUpload.fileName = result.fileName
                    metadatasUploadInConflict.append(metadataForUpload)
                } else {
                    metadatasNOConflict.append(metadataForUpload)
                }
            }

            // Verify if file(s) exists
            if metadatasUploadInConflict.count > 0 {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let conflict = UIStoryboard(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict {

                        conflict.serverUrl = self.serverUrl
                        conflict.metadatasNOConflict = metadatasNOConflict
                        conflict.metadatasUploadInConflict = metadatasUploadInConflict
                        conflict.delegate = self.appDelegate

                        self.appDelegate.window?.rootViewController?.present(conflict, animated: true, completion: nil)
                    }
                }

            } else {
                NCNetworkingProcessUpload.shared.createProcessUploads(metadatas: metadatasNOConflict, completion: { _ in })
            }

            DispatchQueue.main.async {self.dismiss(animated: true, completion: nil)  }
        }
    }

    @objc func cancel() {

        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Utility

    func previewFileName(valueRename: String?) -> String {

        var returnString: String = ""
        let asset = assets[0]
        let creationDate = asset.creationDate ?? Date()

        if CCUtility.getOriginalFileName(NCGlobal.shared.keyFileNameOriginal) {

            return (NSLocalizedString("_filename_", comment: "") + ": " + (asset.value(forKey: "filename") as! String))

        } else if let valueRename = valueRename {

            let valueRenameTrimming = valueRename.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            if valueRenameTrimming.count > 0 {

                self.form.delegate = nil
                CCUtility.setFileNameMask(valueRename, key: NCGlobal.shared.keyFileNameMask)
                self.form.delegate = self

                returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: creationDate, fileType: asset.mediaType, keyFileName: NCGlobal.shared.keyFileNameMask, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)

            } else {

                CCUtility.setFileNameMask("", key: NCGlobal.shared.keyFileNameMask)
                returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)
            }

        } else {

            CCUtility.setFileNameMask("", key: NCGlobal.shared.keyFileNameMask)
            returnString = CCUtility.createFileName(asset.value(forKey: "filename") as! String?, fileDate: creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: false)
        }

        return String(format: NSLocalizedString("_preview_filename_", comment: ""), "MM, MMM, DD, YY, YYYY, HH, hh, mm, ss, ampm") + ":" + "\n\n" + returnString
    }

    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {

        self.deselectFormRow(sender)

        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        let viewController = navigationController.topViewController as! NCSelect

        viewController.delegate = self
        viewController.typeOfCommandView = .selectCreateFolder
        viewController.includeDirectoryE2EEncryption = true

        self.present(navigationController, animated: true, completion: nil)
    }
}
