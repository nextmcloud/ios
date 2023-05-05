//
//  NCCreateFormUploadDocuments.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/11/18.
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
import NextcloudKit
import XLForm

// MARK: -

@objc class NCCreateFormUploadDocuments: XLFormViewController, NCSelectDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NCCreateFormUploadConflictDelegate {

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeigth: NSLayoutConstraint!

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var editorId = ""
    var creatorId = ""
    var typeTemplate = ""
    var templateIdentifier = ""
    var serverUrl = ""
    var fileNameFolder = ""
    var fileName = ""
    var fileNameExtension = ""
    var titleForm = ""
    var listOfTemplate: [NKEditorTemplates] = []
    var selectTemplate: NKEditorTemplates?

    // Layout
    let numItems = 2
    let sectionInsets: CGFloat = 10
    let highLabelName: CGFloat = 20

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId) {
            fileNameFolder = "/"
        } else {
            fileNameFolder = (serverUrl as NSString).lastPathComponent
        }

        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        let cancelButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        cancelButton.tintColor = NCBrandColor.shared.brand
        saveButton.tintColor = NCBrandColor.shared.brand

        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        // title
        self.title = titleForm
        
        fileName = CCUtility.createFileNameDate("Text", extension: getFileExtension())!

        changeTheming()
        
        initializeForm()
        getTemplate()
    }



    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        changeTheming()
    }
    
    // MARK: - Theming
    
    func changeTheming() {
        
        view.backgroundColor = .systemGroupedBackground
        collectionView.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    // MARK: - Tableview (XLForm)

    func initializeForm() {

        let form: XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var section: XLFormSectionDescriptor
        var row: XLFormRowDescriptor

        // Section: Destination Folder

        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: "").uppercased())
        section.footerTitle = "                                                                               "
        form.addFormSection(section)
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["kNMCFolderCustomCellType"] = FolderPathCustomCell.self

        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: "kNMCFolderCustomCellType", title: "")
        row.action.formSelector = #selector(changeDestinationFolder(_:))

        row.cellConfig["folderImage.image"] =  UIImage(named: "folder")
        
        row.cellConfig["photoLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["photoLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["photoLabel.textColor"] = UIColor.label //photos
        if(self.fileNameFolder == "/"){
            row.cellConfig["photoLabel.text"] = NSLocalizedString("_prefix_upload_path_", comment: "")
        }else{
            row.cellConfig["photoLabel.text"] = self.fileNameFolder
        }
        row.cellConfig["textLabel.text"] = ""

        section.addFormRow(row)

        // Section: File Name

        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: "").uppercased())
        form.addFormSection(section)
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["kMyAppCustomCellType"] = NCCreateDocumentCustomTextField.self
        
        row = XLFormRowDescriptor(tag: "fileName", rowType: "kMyAppCustomCellType", title: NSLocalizedString("_filename_", comment: ""))
        row.cellClass = NCCreateDocumentCustomTextField.self

        row.cellConfigAtConfigure["backgroundColor"] =  UIColor.secondarySystemGroupedBackground;
        row.cellConfig["fileNameTextField.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["fileNameTextField.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["fileNameTextField.textColor"] = UIColor.label
        row.cellConfig["fileNameTextField.placeholder"] = self.fileName
        
        section.addFormRow(row)

        self.form = form
        //tableView.reloadData()
        //collectionView.reloadData()
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFont(ofSize: 13.0)
        header.textLabel?.textColor = .gray
        header.tintColor = .systemGroupedBackground
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        footer.textLabel?.font = UIFont.systemFont(ofSize: 13.0)
        footer.textLabel?.textColor = .gray
        footer.tintColor = .systemGroupedBackground
    }

    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listOfTemplate.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let itemWidth: CGFloat = (collectionView.frame.width - (sectionInsets * 4) - CGFloat(numItems)) / CGFloat(numItems)
        let itemHeight: CGFloat = itemWidth + highLabelName

        collectionViewHeigth.constant = itemHeight + sectionInsets

        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

        let template = listOfTemplate[indexPath.row]

        // image
        let imagePreview = cell.viewWithTag(100) as! UIImageView
        if template.preview != "" {
            let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + template.name + ".png"
            if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                let imageURL = URL(fileURLWithPath: fileNameLocalPath)
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    imagePreview.image = image
                }
            } else {
                getImageFromTemplate(name: template.name, preview: template.preview, indexPath: indexPath)
            }
        }

        // name
        let name = cell.viewWithTag(200) as! UILabel
        name.text = template.name
        name.textColor = .secondarySystemGroupedBackground

        // select
        let imageSelect = cell.viewWithTag(300) as! UIImageView
        if selectTemplate != nil && selectTemplate?.name == template.name {
            cell.backgroundColor = .label
            imageSelect.image = UIImage(named: "plus100")
            imageSelect.isHidden = false
        } else {
            cell.backgroundColor = .secondarySystemGroupedBackground
            imageSelect.isHidden = true
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let template = listOfTemplate[indexPath.row]

        selectTemplate = template
        fileNameExtension = template.ext

        collectionView.reloadData()
    }

    // MARK: - Action

    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], overwrite: Bool, copy: Bool, move: Bool) {

        guard let serverUrl = serverUrl else {
            return
        }

        self.serverUrl = serverUrl
        if serverUrl == NCUtilityFileSystem.shared.getHomeServer(urlBase: appDelegate.urlBase, userId: appDelegate.userId) {
            fileNameFolder = "/"
        } else {
            fileNameFolder = (serverUrl as NSString).lastPathComponent
        }

        let buttonDestinationFolder: XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
        buttonDestinationFolder.title = fileNameFolder

        self.tableView.reloadData()
    }
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "fileName" {
            
            self.form.delegate = nil
            
            if let fileNameNew = formRow.value {
                self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew as? String)
            }
            
            formRow.value = self.fileName
            //self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
    }

    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {

        self.deselectFormRow(sender)

        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        let viewController = navigationController.topViewController as! NCSelect

        viewController.delegate = self
        viewController.typeOfCommandView = .selectCreateFolder

        self.present(navigationController, animated: true, completion: nil)
    }

    @objc func save() {
        let fileNameUpload = self.fileName.trimmingCharacters(in: .whitespaces)
        if  fileNameUpload == "" || fileNameUpload.isEmpty {
            let alert = UIAlertController(title: "", message: NSLocalizedString("_please_enter_file_name_", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }

        guard let selectTemplate = self.selectTemplate else {
            return
        }
        templateIdentifier = selectTemplate.identifier

        if fileName == "" {
            return
        } else {

            let result = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: fileName , mimeType: "", directory: false)
            if NCUtility.shared.isDirectEditing(account: appDelegate.account, contentType: result.mimeType).count == 0 {
                fileName = (fileName as NSString).deletingPathExtension + "." + fileNameExtension
            }
            
            if NCManageDatabase.shared.getMetadataConflict(account: appDelegate.account, serverUrl: serverUrl, fileNameView: String(describing: fileName)) != nil {
                
                let metadataForUpload = NCManageDatabase.shared.createMetadata(account: appDelegate.account, user: appDelegate.user, userId: appDelegate.userId, fileName: String(describing: fileName), fileNameView: String(describing: fileName), ocId: "", serverUrl: serverUrl, urlBase: appDelegate.urlBase, url: "", contentType: "", isLivePhoto: false)
                
                guard let conflict = UIStoryboard(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict else { return }

                conflict.textLabelDetailNewFile = NSLocalizedString("_now_", comment: "")
                conflict.alwaysNewFileNameNumber = true
                conflict.serverUrl = serverUrl
                conflict.metadatasUploadInConflict = [metadataForUpload]
                conflict.delegate = self

                self.present(conflict, animated: true, completion: nil)

            } else {

                let fileNamePath = CCUtility.returnFileNamePath(fromFileName: String(describing: fileName), serverUrl: serverUrl, urlBase: appDelegate.urlBase, userId: appDelegate.userId, account: appDelegate.account)!
                createDocument(fileNamePath: fileNamePath, fileName: String(describing: fileName))
            }
        }
    }

    func dismissCreateFormUploadConflict(metadatas: [tableMetadata]?) {

        if metadatas == nil || metadatas?.count == 0 {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.cancel()
            }

        } else {

            let fileName = metadatas![0].fileName
            let fileNamePath = CCUtility.returnFileNamePath(fromFileName: fileName, serverUrl: serverUrl, urlBase: appDelegate.urlBase, userId: appDelegate.userId, account: appDelegate.account)!

            createDocument(fileNamePath: fileNamePath, fileName: fileName)
        }
    }

    func createDocument(fileNamePath: String, fileName: String) {

        self.navigationItem.rightBarButtonItem?.isEnabled = false
        var UUID = NSUUID().uuidString
        UUID = "TEMP" + UUID.replacingOccurrences(of: "-", with: "")

        if self.editorId == NCGlobal.shared.editorText || self.editorId == NCGlobal.shared.editorOnlyoffice {
            
            var options = NKRequestOptions()
            if self.editorId == NCGlobal.shared.editorOnlyoffice {
                options = NKRequestOptions(customUserAgent: NCUtility.shared.getCustomUserAgentOnlyOffice())
            } else if editorId == NCGlobal.shared.editorText {
                options = NKRequestOptions(customUserAgent: NCUtility.shared.getCustomUserAgentNCText())
            }

            NextcloudKit.shared.NCTextCreateFile(fileNamePath: fileNamePath, editorId: editorId, creatorId: creatorId, templateId: templateIdentifier, options: options) { account, url, data, error in
                guard error == .success, account == self.appDelegate.account, let url = url else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    NCContentPresenter.shared.showError(error: error)
                    return
                }

                var results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: fileName, mimeType: "", directory: false)
                //FIXME: iOS 12.0,* don't detect UTI text/markdown, text/x-markdown
                if results.mimeType.isEmpty {
                    results.mimeType = "text/x-markdown"
                }

                self.dismiss(animated: true, completion: {
                    let metadata = NCManageDatabase.shared.createMetadata(account: self.appDelegate.account, user: self.appDelegate.user, userId: self.appDelegate.userId, fileName: fileName, fileNameView: fileName, ocId: UUID, serverUrl: self.serverUrl, urlBase: self.appDelegate.urlBase, url: url, contentType: results.mimeType)
                    if let viewController = self.appDelegate.activeViewController {
                        NCViewer.shared.view(viewController: viewController, metadata: metadata, metadatas: [metadata], imageIcon: nil)
                    }
                })
            }
        }

        if self.editorId == NCGlobal.shared.editorCollabora {

            NextcloudKit.shared.createRichdocuments(path: fileNamePath, templateId: templateIdentifier) { account, url, data, error in
                guard error == .success, account == self.appDelegate.account, let url = url else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    NCContentPresenter.shared.showError(error: error)
                    return
                }

                self.dismiss(animated: true, completion: {
                    let createFileName = (fileName as NSString).deletingPathExtension + "." + self.fileNameExtension
                    let metadata = NCManageDatabase.shared.createMetadata(account: self.appDelegate.account, user: self.appDelegate.user, userId: self.appDelegate.userId, fileName: createFileName, fileNameView: createFileName, ocId: UUID, serverUrl: self.serverUrl, urlBase: self.appDelegate.urlBase, url: url, contentType: "")
                    if let viewController = self.appDelegate.activeViewController {
                        NCViewer.shared.view(viewController: viewController, metadata: metadata, metadatas: [metadata], imageIcon: nil)
                    }
               })
            }
        }
    }

    @objc func cancel() {

        self.dismiss(animated: true, completion: nil)
    }

    // MARK: NC API

    func getTemplate() {

        indicator.color = NCBrandColor.shared.brandElement
        indicator.startAnimating()

        if self.editorId == NCGlobal.shared.editorText || self.editorId == NCGlobal.shared.editorOnlyoffice {

            var options = NKRequestOptions()
            if self.editorId == NCGlobal.shared.editorOnlyoffice {
                options = NKRequestOptions(customUserAgent: NCUtility.shared.getCustomUserAgentOnlyOffice())
            } else if editorId == NCGlobal.shared.editorText {
                options = NKRequestOptions(customUserAgent: NCUtility.shared.getCustomUserAgentNCText())
            }

            NextcloudKit.shared.NCTextGetListOfTemplates(options: options) { account, templates, data, error in

                self.indicator.stopAnimating()

                if error == .success && account == self.appDelegate.account {

                    for template in templates {

                        let temp = NKEditorTemplates()

                        temp.identifier = template.identifier
                        temp.ext = template.ext
                        temp.name = template.name
                        temp.preview = template.preview

                        self.listOfTemplate.append(temp)

                        // default: template empty
                        if temp.preview == "" {
                            self.selectTemplate = temp
                            self.fileNameExtension = template.ext
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    }
                }

                if self.listOfTemplate.count == 0 {

                    let temp = NKEditorTemplates()

                    temp.identifier = ""
                    if self.editorId == NCGlobal.shared.editorText {
                        temp.ext = "md"
                    } else if self.editorId == NCGlobal.shared.editorOnlyoffice && self.typeTemplate == NCGlobal.shared.templateDocument {
                        temp.ext = "docx"
                    } else if self.editorId == NCGlobal.shared.editorOnlyoffice && self.typeTemplate == NCGlobal.shared.templateSpreadsheet {
                        temp.ext = "xlsx"
                    } else if self.editorId == NCGlobal.shared.editorOnlyoffice && self.typeTemplate == NCGlobal.shared.templatePresentation {
                        temp.ext = "pptx"
                    }
                    temp.name = "Empty"
                    temp.preview = ""

                    self.listOfTemplate.append(temp)

                    self.selectTemplate = temp
                    self.fileNameExtension = temp.ext
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }

                self.collectionView.reloadData()
            }

        }

        if self.editorId == NCGlobal.shared.editorCollabora {

            NextcloudKit.shared.getTemplatesRichdocuments(typeTemplate: typeTemplate) { account, templates, data, error in

                self.indicator.stopAnimating()

                if error == .success && account == self.appDelegate.account {

                    for template in templates! {

                        let temp = NKEditorTemplates()

                        temp.identifier = "\(template.templateId)"
                        temp.delete = template.delete
                        temp.ext = template.ext
                        temp.name = template.name
                        temp.preview = template.preview
                        temp.type = template.type

                        self.listOfTemplate.append(temp)

                        // default: template empty
                        if temp.preview == "" {
                            self.selectTemplate = temp
                            self.fileNameExtension = temp.ext
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    }
                }

                if self.listOfTemplate.count == 0 {

                    let temp = NKEditorTemplates()

                    temp.identifier = ""
                    if self.typeTemplate == NCGlobal.shared.templateDocument {
                        temp.ext = "docx"
                    } else if self.typeTemplate == NCGlobal.shared.templateSpreadsheet {
                        temp.ext = "xlsx"
                    } else if self.typeTemplate == NCGlobal.shared.templatePresentation {
                        temp.ext = "pptx"
                    }
                    temp.name = "Empty"
                    temp.preview = ""

                    self.listOfTemplate.append(temp)

                    self.selectTemplate = temp
                    self.fileNameExtension = temp.ext
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }

                self.collectionView.reloadData()
            }
        }
    }

    func getImageFromTemplate(name: String, preview: String, indexPath: IndexPath) {

        let fileNameLocalPath = String(CCUtility.getDirectoryUserData()) + "/" + name + ".png"

        NextcloudKit.shared.download(serverUrlFileName: preview, fileNameLocalPath: fileNameLocalPath, requestHandler: { _ in

        }, taskHandler: { _ in

        }, progressHandler: { _ in

        }) { account, _, _, _, _, _, error in

            if error == .success && account == self.appDelegate.account {
                self.collectionView.reloadItems(at: [indexPath])
            } else if error != .success {
                print("\(error.errorCode)")
            } else {
                print("[LOG] It has been changed user during networking process, error.")
            }
        }
    }
    
    func getFileExtension() -> String {
        switch typeTemplate {
        case NCGlobal.shared.editorText:
            return "md"
        case NCGlobal.shared.templateDocument:
            return "docx"
        case NCGlobal.shared.templateSpreadsheet:
            return "xlsx"
        case NCGlobal.shared.templatePresentation:
            return "pptx"
        default:
            return ""
        }
    }
}
