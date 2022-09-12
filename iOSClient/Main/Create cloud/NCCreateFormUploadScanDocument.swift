//
//  NCCreateFormUploadScanDocument.swift
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
import NCCommunication
import Vision
import VisionKit

@available(iOS 13.0, *)
class NCCreateFormUploadScanDocument: XLFormViewController, NCSelectDelegate, NCCreateFormUploadConflictDelegate {
    
    enum typeQuality {
        case low
        case medium
        case high
    }
    var quality: typeQuality = .medium
    
    var serverUrl = ""
    var titleServerUrl = ""
    var arrayImages: [UIImage] = []
    var fileName = CCUtility.createFileNameDate("scan", extension: "pdf")
    var password: String = ""
    var fileType = "PDF"
    var isPDFWithOCRSwitchOn = false
    var isPDFWithoutOCRSwitchOn = false
    var isSetpasswordEnable = false
    
    var isTextFileSwitchOn = false
    var isPNGFormatSwitchOn = false
    var isJPGFormatSwitchOn = false
    var isOCRActivatedFileConflicts = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    var cellBackgoundColor = NCBrandColor.shared.secondarySystemGroupedBackground
    
    // MARK: - View Life Cycle
    
    convenience init(serverUrl: String, arrayImages: [UIImage]) {
        
        self.init()
        
        if serverUrl == NCUtilityFileSystem.shared.getHomeServer(account: appDelegate.account) {
            titleServerUrl = "/"
        } else {
            titleServerUrl = (serverUrl as NSString).lastPathComponent
        }
        
        self.serverUrl = serverUrl
        self.arrayImages = arrayImages
    }
    
    // MARK: - View Life Cycle
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.title = NSLocalizedString("_save_settings_", comment: "")
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        
        self.navigationItem.rightBarButtonItem = saveButton
        let cancelButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem?.tintColor = NCBrandColor.shared.brand
        self.navigationItem.leftBarButtonItem?.tintColor = NCBrandColor.shared.brand
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        changeTheming()
        
        initializeForm()
        
        let value = CCUtility.getTextRecognitionStatus()
        SetTextRecognition(newValue: value)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        changeTheming()
    }
    
    // MARK: - Theming
    
    @objc func changeTheming() {
        
        view.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        tableView.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        cellBackgoundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        tableView.reloadData()
    }
    
    //MARK: XLForm
    
    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        //FileName custom view Start
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: ""))
        form.addFormSection(section)
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCScamFileNameCustomInputField"] = FileNameInputTextField.self
        row = XLFormRowDescriptor(tag: "fileName", rowType: "NMCScamFileNameCustomInputField", title: NSLocalizedString("_filename_", comment: ""))
        row.cellClass = FileNameInputTextField.self
        row.cellConfig["fileNameInputTextField.placeholder"] = self.fileName
        
        row.cellConfig["fileNameInputTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["fileNameInputTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["fileNameInputTextField.textColor"] = NCBrandColor.shared.label
        
        
        section.addFormRow(row)
        //FileName custom view END
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_location_", comment: ""))
        form.addFormSection(section)
        
        //Scan documnet folder path
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCScanFolderPathCustomCell"] = ScanDocumentPathView.self
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: "NMCScanFolderPathCustomCell", title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))
        row.cellConfig["backgroundColor"] = cellBackgoundColor
        row.cellConfig["folderImage.image"] =  UIImage(named: "folder")?.imageColor(NCBrandColor.shared.customer)
        row.cellConfig["photoLabel.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["photoLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["photoLabel.textColor"] = NCBrandColor.shared.label
        if(self.titleServerUrl == "/"){
            row.cellConfig["photoLabel.text"] = NSLocalizedString("_prefix_upload_path_", comment: "")
        }else{
            row.cellConfig["photoLabel.text"] = self.titleServerUrl
        }
        row.cellConfig["textLabel.text"] = ""
        
        section.addFormRow(row)
        // END of Scan documnet folder path
        
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_with_text_recognition_", comment: ""))
        form.addFormSection(section)
        
        // Save with Text Recognition PDF
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCPdfWithOCRSwitchCell"] = PdfWithOcrSwitchView.self
        row = XLFormRowDescriptor(tag: "PDFWithOCRSwitch", rowType: "NMCPdfWithOCRSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_pdf_with_ocr_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        // END of Save with Text Recognition PDF
        
        //Save with Text Recognition text file
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCTextFileWithOCRSwitchCell"] = TextFileWithOcrSwitchView.self
        row = XLFormRowDescriptor(tag: "TextFileWithOCRSwitch", rowType: "NMCTextFileWithOCRSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_text_file_ocr_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        //END of Save with Text Recognition text file
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_without_text_recognition_", comment: ""))
        form.addFormSection(section)
        
        // PDF without text recongnition
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCPDFWithoutOCRSwitchCell"] = PdfWithoutOcrSwitchView.self
        row = XLFormRowDescriptor(tag: "PDFWithoutOCRSwitch", rowType: "NMCPDFWithoutOCRSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_pdf_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        // END of PDF without text recongnition
        
        // JPG without text recongnition
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCJPGWithoutOCRSwitchCell"] = JPGImageSaveSwitchView.self
        row = XLFormRowDescriptor(tag: "JPGWithoutOCRSwitch", rowType: "NMCJPGWithoutOCRSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_jpg_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        // END JPG without text recongnition
        
        // PNG without text recongnition
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCPNGWithoutOCRSwitchCell"] = PNGImageSaveSwitchView.self
        row = XLFormRowDescriptor(tag: "PNGWithoutOCRSwitch", rowType: "NMCPNGWithoutOCRSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_png_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        // END without text recongnition
        
        // PDF password section
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_pdf_password_", comment: ""))
        form.addFormSection(section)
        // END of PDF password
        
        // Set PDF password switch
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCSetPDFPasswordSwitchCell"] = SetPDFPasswordSwitchView.self
        row = XLFormRowDescriptor(tag: "PDFSetPasswordSwitch", rowType: "NMCSetPDFPasswordSwitchCell", title: self.titleServerUrl)
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_set_password_", comment: "")
        row.cellConfig["switchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label
        
        section.addFormRow(row)
        // END of set PDF password switch
        
        // enter password input field
        XLFormViewController.cellClassesForRowDescriptorTypes()["NMCSetPasswordCustomInputField"] = PasswordInputField.self
        row = XLFormRowDescriptor(tag: "SetPasswordInputField", rowType: "NMCSetPasswordCustomInputField", title: NSLocalizedString("_filename_", comment: ""))
        row.cellClass = PasswordInputField.self
        row.cellConfig["fileNameInputTextField.placeholder"] = NSLocalizedString("_password_", comment: "")
        
        row.cellConfig["fileNameInputTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["fileNameInputTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["fileNameInputTextField.textColor"] = NCBrandColor.shared.label
        row.cellConfig["backgroundColor"] = NCBrandColor.shared.secondarySystemGroupedBackground
        row.hidden = 1
        
        
        section.addFormRow(row)
        
        // Section: Password
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_pdf_password_", comment: ""))
        // form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "password", rowType: XLFormRowDescriptorTypePassword, title: NSLocalizedString("_password_", comment: ""))
        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.label
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["textField.textColor"] = NCBrandColor.shared.label
        
        // Section: Text recognition
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_text_recognition_", comment: ""))
        //form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "textRecognition", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_text_recognition_", comment: ""))
        row.value = 0
        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
        
        row.cellConfig["imageView.image"] = UIImage(named: "textRecognition")!.image(color: NCBrandColor.shared.brandElement, size: 25)
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.label
        
        // Section: File
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_file_creation_", comment: ""))
        
        row = XLFormRowDescriptor(tag: "filetype", rowType: XLFormRowDescriptorTypeSelectorSegmentedControl, title: NSLocalizedString("_file_type_", comment: ""))
        if arrayImages.count == 1 {
            row.selectorOptions = ["PDF","JPG"]
        } else {
            row.selectorOptions = ["PDF"]
        }
        row.value = "PDF"
        row.cellConfig["backgroundColor"] = NCBrandColor.shared.secondarySystemGroupedBackground
        
        row.cellConfig["tintColor"] = NCBrandColor.shared.brandElement
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.label
        
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "textRecognition" {
            
        }
        
        if formRow.tag == "fileName" {
            
            self.form.delegate = nil
            
            let fileNameNew = newValue as? String
            
            if fileNameNew != nil {
                self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew)
            } else {
                self.fileName = ""
            }
            
            formRow.value = self.fileName
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "compressionQuality" {
            
            self.form.delegate = nil
            
            //let row : XLFormRowDescriptor  = self.form.formRow(withTag: "descriptionQuality")!
            let newQuality = newValue as? NSNumber
            let compressionQuality = (newQuality?.doubleValue)!
            
            if compressionQuality >= 0.0 && compressionQuality <= 0.3  {
                formRow.title = NSLocalizedString("_quality_low_", comment: "")
                quality = typeQuality.low
            } else if compressionQuality > 0.3 && compressionQuality <= 0.6 {
                formRow.title = NSLocalizedString("_quality_medium_", comment: "")
                quality = typeQuality.medium
            } else if compressionQuality > 0.6 && compressionQuality <= 1.0 {
                formRow.title = NSLocalizedString("_quality_high_", comment: "")
                quality = typeQuality.high
            }
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "password" {
            let stringPassword = newValue as? String
            if stringPassword != nil {
                password = stringPassword!
            } else {
                password = ""
            }
        }
        
        if formRow.tag == "filetype" {
            fileType = newValue as! String
            
            let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
            let rowPassword : XLFormRowDescriptor  = self.form.formRow(withTag: "password")!
            rowFileName.value = createFileName(rowFileName.value as? String)
            
            self.updateFormRow(rowFileName)
            
            // rowPassword
            if fileType == "JPG" || fileType == "TXT" {
                rowPassword.value = ""
                password = ""
                rowPassword.disabled = true
            } else {
                rowPassword.disabled = false
            }
            
            self.updateFormRow(rowPassword)
        }
        
        if formRow.tag == "PDFSetPasswordSwitch"{
            
            isSetpasswordEnable = (formRow.value! as AnyObject).boolValue
            let setPasswordInputField : XLFormRowDescriptor  = self.form.formRow(withTag: "SetPasswordInputField")!
            if (formRow.value! as AnyObject).boolValue  == true {
                //setPasswordInputField.cellConfigAtConfigure["fileNameInputTextField.isEnabled"] = true
                setPasswordInputField.hidden = 0
                // self.tableView.reloadData()
            }else {
                //setPasswordInputField.cellConfigAtConfigure["fileNameInputTextField.isEnabled"] = false
                setPasswordInputField.hidden = 1
                //self.tableView.reloadData()
            }
        }
        
        if formRow.tag == "PDFWithOCRSwitch"{
            //TODO
            print("In PDF with OCR: value for without OCR \(isPDFWithoutOCRSwitchOn)")
            isPDFWithOCRSwitchOn = (formRow.value! as AnyObject).boolValue
            if (!isPDFWithoutOCRSwitchOn){
                if (formRow.value! as AnyObject).boolValue  == true {
                    let setPasswordSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "PDFSetPasswordSwitch")!
                    setPasswordSwitchOption.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label//isEnabled
                    setPasswordSwitchOption.value = "enable_switch"
                    
                    self.tableView.reloadData()
                }else{
                    let setPasswordSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "PDFSetPasswordSwitch")!
                    setPasswordSwitchOption.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.graySoft
                    setPasswordSwitchOption.disabled = true
                    setPasswordSwitchOption.value = "disable_switch"
                    self.tableView.reloadData()
                    
                }
            }
            
        }
        
        if formRow.tag == "PDFWithoutOCRSwitch"{
            print("In PDF without OCR: value for with OCR \(isPDFWithOCRSwitchOn)")
            
            isPDFWithoutOCRSwitchOn = (formRow.value! as AnyObject).boolValue
            if(!isPDFWithOCRSwitchOn){
                if (formRow.value! as AnyObject).boolValue  == true {
                    let setPasswordSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "PDFSetPasswordSwitch")!
                    setPasswordSwitchOption.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label//isEnabled
                    setPasswordSwitchOption.value = "enable_switch"
                    
                    self.tableView.reloadData()
                }else{
                    let setPasswordSwitchOption : XLFormRowDescriptor  = self.form.formRow(withTag: "PDFSetPasswordSwitch")!
                    setPasswordSwitchOption.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.graySoft
                    setPasswordSwitchOption.disabled = true
                    setPasswordSwitchOption.value = "disable_switch"
                    self.tableView.reloadData()
                    
                }
            }
            
        }
        
        if formRow.tag == "SetPasswordInputField" {
            let stringPassword = newValue as? String
            if stringPassword != nil {
                password = stringPassword!
            } else {
                password = ""
            }
        }
        
        if formRow.tag == "TextFileWithOCRSwitch" {
            isTextFileSwitchOn = (formRow.value! as AnyObject).boolValue
            self.SetTextRecognition(newValue: newValue as! Int)
        }
        if formRow.tag == "JPGWithoutOCRSwitch" {
            isJPGFormatSwitchOn = (formRow.value! as AnyObject).boolValue
        }
        if formRow.tag == "PNGWithoutOCRSwitch" {
            isPNGFormatSwitchOn = (formRow.value! as AnyObject).boolValue
        }
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    func SetTextRecognition(newValue: Int) {
        
        let rowFileName: XLFormRowDescriptor = self.form.formRow(withTag: "fileName")!
        //let rowPassword: XLFormRowDescriptor = self.form.formRow(withTag: "password")!
        //let rowTextRecognition: XLFormRowDescriptor = self.form.formRow(withTag: "textRecognition")!
        
        self.form.delegate = nil
        
        if newValue == 1 {
            //rowFileTape.selectorOptions = ["PDF","TXT"]
            //rowFileTape.value = "PDF"
            fileType = "PDF"
            //rowPassword.disabled = true
            // rowCompressionQuality.disabled = false
        } else {
            if arrayImages.count == 1 {
                //rowFileTape.selectorOptions = ["PDF","JPG"]
            } else {
                //rowFileTape.selectorOptions = ["PDF"]
            }
            //rowFileTape.value = "PDF"
            fileType = "PDF"
            //rowPassword.disabled = false
            //rowCompressionQuality.disabled = false
        }
        
        
        rowFileName.value = createFileName(rowFileName.value as? String)
        self.updateFormRow(rowFileName)
        self.tableView.reloadData()
        
        CCUtility.setTextRecognitionStatus(newValue)
        
        self.form.delegate = self
    }
    
    func createFileName(_ fileName: String?) -> String {
        
        var name: String = ""
        var newFileName: String = ""
        
        if fileName == nil || fileName == "" {
            name = CCUtility.createFileNameDate("scan", extension: "pdf") ?? "scan.pdf"
        } else {
            name = fileName!
        }
        
        let ext = (name as NSString).pathExtension.uppercased()
        
        if (ext == "") {
            newFileName = name + "." + fileType.lowercased()
        } else {
            newFileName = (name as NSString).deletingPathExtension + "." + fileType.lowercased()
        }
        
        return newFileName
    }
    
    // MARK: - Action
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], overwrite: Bool, copy: Bool, move: Bool) {
        
        if serverUrl != nil {
            
            CCUtility.setDirectoryScanDocuments(serverUrl!)
            self.serverUrl = serverUrl!
            
            if serverUrl == NCUtilityFileSystem.shared.getHomeServer(account: appDelegate.account) {
                self.titleServerUrl = "/"
            } else {
                self.titleServerUrl = (serverUrl! as NSString).lastPathComponent
            }
            
            // Update
            let row : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
            row.title = self.titleServerUrl
            row.cellConfig["photoLabel.text"] = self.titleServerUrl
            self.updateFormRow(row)
        }
    }
    
    

    
    func startProcessForSaving(){
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard let name = rowFileName.value else {
            return
        }
        if name as! String == "" {
            return
        }
        
        let ext = (name as! NSString).pathExtension.uppercased()
        var fileNameSave = ""
        
        if (ext == "") {
            fileNameSave = name as! String + "." + fileType.lowercased()
        } else {
            fileNameSave = (name as! NSString).deletingPathExtension + "." + fileType.lowercased()
        }
    
        
        NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: true)
        
        saveImages(fileNameSave: fileNameSave,fileType: "jpg",metadataConflict: nil,completion: { (success) -> Void in
            print("jpg line of code executed")
            if success { // this will be equal to whatever value is set in this method call
                print("true")
                saveImages(fileNameSave: fileNameSave,fileType: "png",metadataConflict: nil,completion: { (success) -> Void in
                    print("png line of code executed")
                    if success {
                        if(isPDFWithOCRSwitchOn){
                            savePDF(ocrSwitchOn: true,completion: {(success) -> Void in
                                if success{
                                    if(isPDFWithoutOCRSwitchOn){
                                        savePDF(ocrSwitchOn: false, completion: {(success) -> Void in
                                            if success{
                                                //Save Text File
                                                if(isTextFileSwitchOn){
                                                    saveTxtFile(completion: {(success) -> Void in
                                                        if success{
                                                            //DELETE Files
                                                            showDeleteAlert()
                                                            NCUtility.shared.stopActivityIndicator()
                                                        }
                                                    })
                                                }else{
                                                    //DELETE files
                                                    showDeleteAlert()
                                                    NCUtility.shared.stopActivityIndicator()
                                                }
                                            }
                                        })
                                    }else{
                                        //Save Text File
                                        if(isTextFileSwitchOn){
                                            saveTxtFile(completion: {(success) -> Void in
                                                if success{
                                                    //DELETE Files
                                                    showDeleteAlert()
                                                    NCUtility.shared.stopActivityIndicator()
                                                }
                                            })
                                        }else{
                                            //DELETE files
                                            showDeleteAlert()
                                            NCUtility.shared.stopActivityIndicator()
                                        }
                                    }
                                }
                            })
                        }else {
                            if(isPDFWithoutOCRSwitchOn){
                                savePDF(ocrSwitchOn: false, completion: {(success) -> Void in
                                    if success{
                                        //Save Text File
                                        if(isTextFileSwitchOn){
                                            saveTxtFile(completion: {(success) -> Void in
                                                if success{
                                                    //DELETE Files
                                                    showDeleteAlert()
                                                    NCUtility.shared.stopActivityIndicator()
                                                }
                                            })
                                        }else{
                                            //DELETE files
                                            showDeleteAlert()
                                            NCUtility.shared.stopActivityIndicator()
                                        }
                                    }
                                })
                            }else{
                                //Save Text File
                                if(isTextFileSwitchOn){
                                    saveTxtFile(completion: {(success) -> Void in
                                        if success{
                                            //DELETE Files
                                            showDeleteAlert()
                                            NCUtility.shared.stopActivityIndicator()
                                        }
                                    })
                                }else{
                                    //DELETE files
                                    showDeleteAlert()
                                    NCUtility.shared.stopActivityIndicator()
                                }
                            }
                        }
                    }
                })
            }
        })
    }
    
    
    @objc func save() {
        
        if(isSetpasswordEnable && password.count <= 0){
            showAlert()
            return
        }
          
        if(!isAtleastOneFiletypeSelected()){
            
            let alertController = UIAlertController(title: "", message: NSLocalizedString("_no_file_type_selection_error_", comment: ""), preferredStyle: .alert)
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.windowLevel = UIWindow.Level.alert
            alertWindow.rootViewController = UIViewController()
            alertWindow.makeKeyAndVisible()
            let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action:UIAlertAction) in
                alertController.dismiss(animated: true, completion: nil)
            }
            
            alertController.addAction(actionOk)
            self.present(alertController, animated: true)
        }else {
            // Request delete all image scanned
            let alertController = UIAlertController(title: "", message: NSLocalizedString("_saved_info_alert_", comment: ""), preferredStyle: .alert)
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.windowLevel = UIWindow.Level.alert
            alertWindow.rootViewController = UIViewController()
            alertWindow.makeKeyAndVisible()
            let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action:UIAlertAction) in
                self.startProcessForSaving()
                alertController.dismiss(animated: true, completion: nil)
            }
            
            alertController.addAction(actionOk)
            self.present(alertController, animated: true)
        }
        
    }
        
    func showAlert(){
        // Request delete all image scanned
        let alertController = UIAlertController(title: "", message: NSLocalizedString("_no_password_warn_", comment: ""), preferredStyle: .alert)
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.windowLevel = UIWindow.Level.alert
        alertWindow.rootViewController = UIViewController()
        alertWindow.makeKeyAndVisible()
        let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action:UIAlertAction) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(actionOk)
        //alertWindow.addSubview(alertController)
        self.present(alertController, animated: true)
        //alertWindow.rootViewController?.present(alertController, animated: true, completion: nil)
        
    }
    
    func showAlertForInfo(){
        // Request delete all image scanned
        let alertController = UIAlertController(title: "", message: NSLocalizedString("_saved_info_alert_", comment: ""), preferredStyle: .alert)
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.windowLevel = UIWindow.Level.alert
        alertWindow.rootViewController = UIViewController()
        alertWindow.makeKeyAndVisible()
        let actionOk = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action:UIAlertAction) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(actionOk)
        //alertWindow.addSubview(alertController)
        self.present(alertController, animated: true)
    }
    func saveTxtFile(completion: (Bool) -> ()){
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard var name = rowFileName.value else {
            return
        }
        if name as! String == "" {
            return
        }
        
        for count in 0..<arrayImages.count {
            
            
            name = name as! String
            
            let ext = (name as! NSString).pathExtension.uppercased()
            var fileNameSave = ""
            
            if (ext == "") {
                if(count != 0){
                    fileNameSave = name as! String + "(\(count)" + ")" + "." + ".txt"
                }else {
                    fileNameSave = name as! String + "." + ".txt"
                }
            } else {
                if(count != 0){
                    fileNameSave = (name as! NSString).deletingPathExtension + "(\(count)" + ")" + "." + "txt"
                }else{
                    fileNameSave = (name as! NSString).deletingPathExtension  + "." + "txt"
                }
            }
            
            
            let metadataForUpload = NCManageDatabase.shared.createMetadata(account: appDelegate.account, user: appDelegate.user, userId: appDelegate.userId, fileName: fileNameSave, fileNameView: fileNameSave, ocId: UUID().uuidString, serverUrl: serverUrl, urlBase: appDelegate.urlBase, url: "", contentType: "", livePhoto: false)
            
            metadataForUpload.session = NCNetworking.shared.sessionIdentifierBackground
            metadataForUpload.sessionSelector = NCGlobal.shared.selectorUploadFile
            metadataForUpload.status = NCGlobal.shared.metadataStatusWaitUpload
            
            if NCManageDatabase.shared.getMetadataConflict(account: appDelegate.account, serverUrl: serverUrl, fileName: fileNameSave) != nil {
                
                guard let conflictViewController = UIStoryboard(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict else { return }
                conflictViewController.textLabelDetailNewFile = NSLocalizedString("_now_", comment: "")
                conflictViewController.serverUrl = serverUrl
                conflictViewController.metadatasUploadInConflict = [metadataForUpload]
                conflictViewController.delegate = self
                
                self.present(conflictViewController, animated: true, completion: nil)
                
            }else {
                NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.dismissAndUpload(metadataForUpload, fileType: "TXT")
                }
            }
        }
        completion(true)
    }
    
    func savePDF(ocrSwitchOn: Bool,completion: (Bool) -> ()){
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard var name = rowFileName.value else {
            return
        }
        if name as! String == "" {
            return
        }
        
        if (ocrSwitchOn){
            name = name as! String
        }
        
        let ext = (name as! NSString).pathExtension.uppercased()
        var fileNameSave = ""
        
        if (ext == "") {
            if (ocrSwitchOn){
                fileNameSave = name as! String + "_OCR" + "." + "pdf"
            }else{
                fileNameSave = name as! String +  "." + "pdf"
            }
        } else {
            if(ocrSwitchOn){
                fileNameSave = (name as! NSString).deletingPathExtension + "_OCR" + "." + fileType.lowercased()
                
            }else{
                fileNameSave = (name as! NSString).deletingPathExtension + "." + fileType.lowercased()
            }
        }
        
        
        let metadataForUpload = NCManageDatabase.shared.createMetadata(account: appDelegate.account, user: appDelegate.user, userId: appDelegate.userId, fileName: fileNameSave, fileNameView: fileNameSave, ocId: UUID().uuidString, serverUrl: serverUrl, urlBase: appDelegate.urlBase, url: "", contentType: "", livePhoto: false)
        
        metadataForUpload.session = NCNetworking.shared.sessionIdentifierBackground
        metadataForUpload.sessionSelector = NCGlobal.shared.selectorUploadFile
        metadataForUpload.status = NCGlobal.shared.metadataStatusWaitUpload
        
        NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isPDFWithOCRSwitchOn = ocrSwitchOn
            self.dismissAndUpload(metadataForUpload, fileType: "PDF")
        }
        
        completion(true)
    }
    
    fileprivate func showDeleteAlert() {
        
        let path = CCUtility.getDirectoryScan()!
        
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: path)
            for filePath in filePaths {
                try FileManager.default.removeItem(atPath: path + "/" + filePath)
            }
        } catch let error as NSError {
            print("Error: \(error.debugDescription)")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveImages(fileNameSave: String, fileType: String, metadataConflict: tableMetadata?, completion: (Bool) -> ()) {
        
        if(!isJPGFormatSwitchOn && fileType == "jpg"){
            completion(true)
            return
        }else if(!isPNGFormatSwitchOn && fileType == "png"){
            completion(true)
            return
        }
        else {
            let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
            guard var name = rowFileName.value else {
                return
            }
            if name as! String == "" {
                return
            }
            
            for count in 0..<arrayImages.count {
                
                name = name as! String
                
                let ext = (name as! NSString).pathExtension.uppercased()
                var fileNameSave = ""
                
                if (ext == "") {
                    if(count != 0){
                        fileNameSave = name as! String + "(\(count)" + ")" + "." + fileType
                    }else {
                        fileNameSave = name as! String + "." + fileType
                    }
                } else {
                    if(count != 0){
                        fileNameSave = (name as! NSString).deletingPathExtension + "(\(count)" + ")" + "." + fileType
                    }else{
                        fileNameSave = (name as! NSString).deletingPathExtension  + "." + fileType
                    }
                }
                
                let metadataForUpload = NCManageDatabase.shared.createMetadata(account: appDelegate.account, user: appDelegate.user, userId: appDelegate.userId, fileName: fileNameSave, fileNameView: fileNameSave, ocId: UUID().uuidString, serverUrl: serverUrl, urlBase: appDelegate.urlBase, url: "", contentType: "", livePhoto: false)
                
                metadataForUpload.session = NCNetworking.shared.sessionIdentifierBackground
                metadataForUpload.sessionSelector = NCGlobal.shared.selectorUploadFile
                metadataForUpload.status = NCGlobal.shared.metadataStatusWaitUpload
                
                if NCManageDatabase.shared.getMetadataConflict(account: appDelegate.account, serverUrl: serverUrl, fileName: fileNameSave) != nil {
                    
                    guard let conflictViewController = UIStoryboard(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict else { return }
                    conflictViewController.textLabelDetailNewFile = NSLocalizedString("_now_", comment: "")
                    conflictViewController.serverUrl = serverUrl
                    conflictViewController.metadatasUploadInConflict = [metadataForUpload]
                    conflictViewController.delegate = self
                    
                    self.present(conflictViewController, animated: true, completion: nil)
                    
                } else {
                    
                    NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.dismissAndUpload(metadataForUpload, fileType: fileType.uppercased())
                    }
                }
                
            }
            completion(true)
        }
    }
    
    func dismissCreateFormUploadConflict(metadatas: [tableMetadata]?) {
        
        if metadatas != nil && metadatas!.count > 0 {
            
            NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // if let metadata = metadatas![0] as? tableMetadata{
                if (metadatas![0].ext == "jpg"){
                    //TODO for jpg
                    self.dismissAndUpload(metadatas![0],fileType: "JPG")
                    NCUtility.shared.stopActivityIndicator()
                    
                }else if(metadatas![0].ext == "png") {
                    //TODO for png
                    self.dismissAndUpload(metadatas![0],fileType: "PNG")
                    NCUtility.shared.stopActivityIndicator()
                    
                    
                }else if(metadatas![0].ext == "pdf"){
                    //TODO for pdf
                    self.isOCRActivatedFileConflicts = metadatas![0].fileName.contains("_OCR")
                    self.dismissAndUpload(metadatas![0],fileType: "PDF")
                    NCUtility.shared.stopActivityIndicator()
                    
                }else if(metadatas![0].ext == "txt"){
                    //TODO for txt
                    self.dismissAndUpload(metadatas![0],fileType: "TXT")
                    NCUtility.shared.stopActivityIndicator()
                    
                }
            }
        }
    }
    
    func dismissAndUpload(_ metadata: tableMetadata, fileType: String?) {
        
        guard let fileNameGenerateExport = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView) else {
            NCUtility.shared.stopActivityIndicator()
            NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
            return
        }
        let fileUrl = URL(fileURLWithPath: fileNameGenerateExport)
        // Text Recognition TXT && self.form.formRow(withTag: "textRecognition")!.value as! Int == 1
        if fileType == "TXT"  {
            var textFile = ""
            for image in self.arrayImages {
                
                let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                
                let request = VNRecognizeTextRequest { (request, error) in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        NCUtility.shared.stopActivityIndicator()
                        return
                    }
                    for observation in observations {
                        guard let textLine = observation.topCandidates(1).first else {
                            continue
                        }
                        
                        textFile += textLine.string
                        textFile += "\n"
                    }
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                try? requestHandler.perform([request])
            }
            
            do {
                try textFile.write(to: fileUrl as URL  , atomically: true, encoding: .utf8)
            } catch {
                NCUtility.shared.stopActivityIndicator()
                NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
                
                return
            }
        }
        
        if fileType == "PDF" {
            
            let pdfData = NSMutableData()
            
            if password.count > 0 {
                let info: [AnyHashable: Any] = [kCGPDFContextUserPassword as String : password, kCGPDFContextOwnerPassword as String : password]
                UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, info)
            } else {
                UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
            }
            var fontColor = UIColor.clear
#if targetEnvironment(simulator)
            fontColor = UIColor.red
#endif
            
            
            for var image in self.arrayImages {
                
                image = changeCompressionImage(image)
                
                let bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                
                //self.form.formRow(withTag: "textRecognition")!.value as! Int == 1
                if isPDFWithOCRSwitchOn {
                    
                    UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                    image.draw(in: bounds)
                    
                    let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                    
                    let request = VNRecognizeTextRequest { (request, error) in
                        guard let observations = request.results as? [VNRecognizedTextObservation] else {
                            NCUtility.shared.stopActivityIndicator()
                            return
                        }
                        for observation in observations {
                            guard let textLine = observation.topCandidates(1).first else {
                                continue
                            }
                            
                            var t: CGAffineTransform = CGAffineTransform.identity
                            t = t.scaledBy(x: image.size.width, y: -image.size.height)
                            t = t.translatedBy(x: 0, y: -1)
                            let rect = observation.boundingBox.applying(t)
                            let text = textLine.string
                            
                            let font = UIFont.systemFont(ofSize: rect.size.height, weight: .regular)
                            let attributes = self.bestFittingFont(for: text, in: rect, fontDescriptor: font.fontDescriptor, fontColor: fontColor)
                            
                            text.draw(with: rect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
                        }
                    }
                    
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    try? requestHandler.perform([request])
                    
                } else {
                    
                    UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                    image.draw(in: bounds)
                }
            }
            
            UIGraphicsEndPDFContext();
            
            do {
                try pdfData.write(to: fileUrl, options: .atomic)
            } catch {
                print("error catched")
            }
        }
        
        if fileType == "JPG" {
            
            //let image = changeCompressionImage(self.arrayImages[0])
            
            for image in self.arrayImages {
                //                let image = changeCompressionImage(self.arrayImages[0])
                guard let data = image.jpegData(compressionQuality: CGFloat(0.5)) else {
                    NCUtility.shared.stopActivityIndicator()
                    NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
                    return
                }
                
                do {
                    try data.write(to: fileUrl, options: .atomic)
                } catch {
                    NCUtility.shared.stopActivityIndicator()
                    NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
                    return
                }
            }
            
            
        }
        
        if fileType == "PNG" {
            
            //let image = changeCompressionImage(self.arrayImages[0])
            
            for image in self.arrayImages {
                //                let image = changeCompressionImage(self.arrayImages[0])
                guard let data = image.jpegData(compressionQuality: CGFloat(0.5)) else {
                    NCUtility.shared.stopActivityIndicator()
                    NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
                    return
                }
                
                do {
                    try data.write(to: NSURL.fileURL(withPath: fileNameGenerateExport), options: .atomic)
                } catch {
                    NCUtility.shared.stopActivityIndicator()
                    NCContentPresenter.shared.messageNotification("_error_", description: "_error_creation_file_", delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.info, errorCode: NCGlobal.shared.errorCreationFile)
                    return
                }
            }
            
            
        }
        
        metadata.size = NCUtilityFileSystem.shared.getFileSize(filePath: fileNameGenerateExport)
        
        NCUtility.shared.stopActivityIndicator()
        
        appDelegate.networkingProcessUpload?.createProcessUploads(metadatas: [metadata])
        
        // Request delete all image scanned
        let alertController = UIAlertController(title: "", message: NSLocalizedString("_delete_all_scanned_images_", comment: ""), preferredStyle: .alert)
        
        let actionYes = UIAlertAction(title: NSLocalizedString("_yes_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
            
            let path = CCUtility.getDirectoryScan()!
            
            do {
                let filePaths = try FileManager.default.contentsOfDirectory(atPath: path)
                for filePath in filePaths {
                    try FileManager.default.removeItem(atPath: path + "/" + filePath)
                }
            } catch let error as NSError {
                print("Error: \(error.debugDescription)")
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
        let actionNo = UIAlertAction(title: NSLocalizedString("_no_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(actionYes)
        alertController.addAction(actionNo)
        self.present(alertController, animated: true, completion:nil)
    }
    
    @objc func cancel() {
        
        
        self.dismiss(animated: true, completion: nil)
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
    
    func changeCompressionImage(_ image: UIImage) -> UIImage {
        
        var compressionQuality: CGFloat = 0.5
        var baseHeight: Float = 595.2    // A4
        var baseWidth: Float = 841.8     // A4
        
        switch quality {
        case .low:
            baseHeight *= 1
            baseWidth *= 1
            compressionQuality = 0.3
        case .medium:
            baseHeight *= 2
            baseWidth *= 2
            compressionQuality = 0.6
        case .high:
            baseHeight *= 4
            baseWidth *= 4
            compressionQuality = 0.9
        }
        
        var newHeight = Float(image.size.height)
        var newWidth = Float(image.size.width)
        var imgRatio: Float = newWidth / newHeight
        let baseRatio: Float = baseWidth / baseHeight
        
        if newHeight > baseHeight || newWidth > baseWidth {
            if imgRatio < baseRatio {
                imgRatio = baseHeight / newHeight
                newWidth = imgRatio * newWidth
                newHeight = baseHeight
            }
            else if imgRatio > baseRatio {
                imgRatio = baseWidth / newWidth
                newHeight = imgRatio * newHeight
                newWidth = baseWidth
            }
            else {
                newHeight = baseHeight
                newWidth = baseWidth
            }
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(newWidth), height: CGFloat(newHeight))
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = img?.jpegData(compressionQuality: CGFloat(compressionQuality))
        UIGraphicsEndImageContext()
        return UIImage(data: imageData!) ?? image
    }
    
    func bestFittingFont(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, fontColor: UIColor) -> [NSAttributedString.Key: Any] {
        
        let constrainingDimension = min(bounds.width, bounds.height)
        let properBounds = CGRect(origin: .zero, size: bounds.size)
        var attributes: [NSAttributedString.Key: Any] = [:]
        
        let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        var bestFontSize: CGFloat = constrainingDimension
        
        // Search font (H)
        for fontSize in stride(from: bestFontSize, through: 0, by: -1) {
            let newFont = UIFont(descriptor: fontDescriptor, size: fontSize)
            attributes[.font] = newFont
            
            let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            
            if properBounds.contains(currentFrame) {
                bestFontSize = fontSize
                break
            }
        }
        
        // Search kern (W)
        let font = UIFont(descriptor: fontDescriptor, size: bestFontSize)
        attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.kern: 0] as [NSAttributedString.Key : Any]
        for kern in stride(from: 0, through: 100, by: 0.1) {
            let attributesTmp = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.kern: kern] as [NSAttributedString.Key : Any]
            let size = text.size(withAttributes: attributesTmp).width
            if size <= bounds.width {
                attributes = attributesTmp
            } else {
                break
            }
        }
        
        return attributes
    }
    
    func isAtleastOneFiletypeSelected() -> Bool{
        if(isPDFWithOCRSwitchOn
           || isPDFWithoutOCRSwitchOn
           || isTextFileSwitchOn
           || isPNGFormatSwitchOn
           || isJPGFormatSwitchOn){
            
            return true
        }else{
            return false
        }
    }
    
}

@available(iOS 13.0, *)
class NCCreateScanDocument : NSObject, VNDocumentCameraViewControllerDelegate {
    
    @objc static let shared: NCCreateScanDocument = {
        let instance = NCCreateScanDocument()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewController: UIViewController?
    
    func openScannerDocument(viewController: UIViewController) {
        
        self.viewController = viewController
        
        guard VNDocumentCameraViewController.isSupported else { return }
        
        let controller = VNDocumentCameraViewController()
        controller.delegate = self
        
        TealiumHelper.shared.trackView(title: "magentacloud-app.plus", data: ["": ""])
        self.viewController?.present(controller, animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for pageNumber in 0..<scan.pageCount {
            let fileName = CCUtility.createFileName("scan.png", fileDate: Date(), fileType: PHAssetMediaType.image, keyFileName: NCGlobal.shared.keyFileNameMask, keyFileNameType: NCGlobal.shared.keyFileNameType, keyFileNameOriginal: NCGlobal.shared.keyFileNameOriginal, forcedNewFileName: true)!
            let fileNamePath = CCUtility.getDirectoryScan() + "/" + fileName
            let image = scan.imageOfPage(at: pageNumber)
            do {
                try image.pngData()?.write(to: NSURL.fileURL(withPath: fileNamePath))
            } catch { }
        }
        
        controller.dismiss(animated: true) {
            if self.viewController is DragDropViewController {
                (self.viewController as! DragDropViewController).loadImage()
            } else {
                self.appDelegate.adjust.trackEvent(TriggerEvent(DocumentScan.rawValue))
                TealiumHelper.shared.trackEvent(title: "magentacloud-app.plus.documentscan", data: ["": ""])
                self.reDirectToSave()
            }
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func reDirectToSave(){
        var itemsSource: [String] = []
        
        //Data Source for collectionViewDestination
        var imagesDestination: [UIImage] = []
        var itemsDestination: [String] = []
        
        do {
            let atPath = CCUtility.getDirectoryScan()!
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: atPath)
            for fileName in directoryContents {
                if fileName.first != "." {
                    itemsSource.append(fileName)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        itemsSource = itemsSource.sorted()
        
        for fileName in itemsSource {
            
            if !itemsDestination.contains(fileName) {
                
                let fileNamePathAt = CCUtility.getDirectoryScan() + "/" + fileName
                
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: fileNamePathAt)) else { return }
                guard let image = UIImage(data: data) else { return }
                
                imagesDestination.append(image)
                itemsDestination.append(fileName)
            }
        }
        
        if imagesDestination.count > 0 {
            
            var images: [UIImage] = []
            var serverUrl = appDelegate.activeServerUrl
            
            for image in imagesDestination {
                images.append(image)
            }
            
//            if let directory = CCUtility.getDirectoryScanDocuments() {
//                serverUrl = directory
//            }
            
            let formViewController = NCCreateFormUploadScanDocument.init(serverUrl: serverUrl, arrayImages: images)
            
            formViewController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            
            let navigationController = UINavigationController(rootViewController: formViewController)
            
            //controller.addChild(formViewController)
            //controller.pushViewController(formViewController, animated: true)
            self.viewController?.present(navigationController, animated: true, completion: nil)
        }
    }
}
