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
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], overwrite: Bool, copy: Bool, move: Bool, session: NCSession.Session) {
        
    }
    

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeigth: NSLayoutConstraint!

    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    var editorId = ""
    var creatorId = ""
    var typeTemplate = ""
    var templateIdentifier = ""
    var serverUrl = ""
    var fileNameFolder = ""
    var fileName = ""
    var fileNameExtension = ""
    var titleForm = ""
    var listOfTemplate: [NKEditorTemplate] = []
    var selectTemplate: NKEditorTemplate?
    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()

    // Layout
    let numItems = 2
    let sectionInsets: CGFloat = 10
    let highLabelName: CGFloat = 20

    var controller: NCMainTabBarController!
    var session: NCSession.Session {
        NCSession.shared.getSession(controller: controller)
    }
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if serverUrl == utilityFileSystem.getHomeServer(session: session) {
            fileNameFolder = "/"
        } else {
            fileNameFolder = utilityFileSystem.getTextServerUrl(session: session, serverUrl: serverUrl)//(serverUrl as NSString).lastPathComponent
        }

        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        view.backgroundColor = .systemGroupedBackground
        collectionView.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .secondarySystemGroupedBackground

        let cancelButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cancel))
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(save))
        cancelButton.tintColor = NCBrandColor.shared.brand
        saveButton.tintColor = NCBrandColor.shared.brand

        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        // title
        self.title = titleForm
        
        fileName = NCUtilityFileSystem().createFileNameDate("Text", ext: getFileExtension())

        initializeForm()
        getTemplate()
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
        row.cellConfig["folderImage.image"] =  UIImage(named: "folder")!.withTintColor(NCBrandColor.shared.customer)
        row.cellConfig["photoLabel.textAlignment"] = NSTextAlignment.left.rawValue
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
        // tableView.reloadData()
        // collectionView.reloadData()
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont.systemFont(ofSize: 13.0)
        header?.textLabel?.textColor = .gray
        header?.tintColor = tableView.backgroundColor
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont.systemFont(ofSize: 13.0)
        header?.textLabel?.textColor = .gray
        header?.tintColor = tableView.backgroundColor
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
        let imagePreview = cell.viewWithTag(100) as? UIImageView
        if !template.preview.isEmpty {
            let fileNameLocalPath = utilityFileSystem.directoryUserData + "/" + template.name + ".png"
            if FileManager.default.fileExists(atPath: fileNameLocalPath) {
                let imageURL = URL(fileURLWithPath: fileNameLocalPath)
                if let image = UIImage(contentsOfFile: imageURL.path) {
                    imagePreview?.image = image
                }
            } else {
                getImageFromTemplate(name: template.name, preview: template.preview, indexPath: indexPath)
            }
        }

        // name
        let name = cell.viewWithTag(200) as? UILabel
        name?.text = template.name
        name?.textColor = .secondarySystemGroupedBackground

        // select
        let imageSelect = cell.viewWithTag(300) as? UIImageView
        if selectTemplate != nil && selectTemplate?.name == template.name {
            cell.backgroundColor = .label
            imageSelect?.image = UIImage(named: "plus100")
            imageSelect?.isHidden = false
        } else {
            cell.backgroundColor = .secondarySystemGroupedBackground
            imageSelect?.isHidden = true
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

        guard let serverUrl = serverUrl else { return }

        self.serverUrl = serverUrl
        if serverUrl == utilityFileSystem.getHomeServer(session: session) {
            fileNameFolder = "/"
        } else {
            fileNameFolder = (serverUrl as NSString).lastPathComponent
        }

        let buttonDestinationFolder: XLFormRowDescriptor = self.form.formRow(withTag: "ButtonDestinationFolder")!
        buttonDestinationFolder.cellConfig["photoLabel.text"] = fileNameFolder

        self.tableView.reloadData()
    }

//    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
//        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
////        if formRow.tag == "fileName" {
////            self.form.delegate = nil
////            if let fileNameNew = formRow.value {
////                self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew as? String)
////            }
////            formRow.value = self.fileName
////            self.form.delegate = self
////        }
//    }

    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {

        self.deselectFormRow(sender)

        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        if let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController,
           let viewController = navigationController.topViewController as? NCSelect {

            viewController.delegate = self
            viewController.typeOfCommandView = .selectCreateFolder

            self.present(navigationController, animated: true, completion: nil)
        }
    }

    @objc func save() {

        Task {
            guard let selectTemplate = self.selectTemplate else { return }
            templateIdentifier = selectTemplate.identifier
            
            let rowFileName: XLFormRowDescriptor = self.form.formRow(withTag: "fileName")!
            var fileName = rowFileName.value as? String
            if fileName?.isEmpty ?? false || fileName == nil {
                fileName = NCUtilityFileSystem().createFileNameDate("Text", ext: getFileExtension())
            } else if fileName?.trimmingCharacters(in: .whitespaces).isEmpty ?? false {
                let alert = UIAlertController(title: "", message: NSLocalizedString("_please_enter_file_name_", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            
            // Ensure fileName is not nil or empty
            guard var fileNameForm: String = fileName, !fileNameForm.isEmpty else { return }
            
            // Trim whitespaces and newlines
            fileNameForm = fileNameForm.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let fileAutoRenamer = FileAutoRenamer()
            fileName = fileAutoRenamer.rename(filename: fileNameForm, isFolderPath: true)

            let result = await NKTypeIdentifiers.shared.getInternalType(fileName: fileNameForm, mimeType: "", directory: false, account: session.account)
            
            if utility.editorsDirectEditing(account: session.account, contentType: result.mimeType).isEmpty {
                fileNameForm = (fileNameForm as NSString).deletingPathExtension + "." + fileNameExtension
            }
            
            // verify if already exists
            if NCManageDatabase.shared.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@", session.account, self.serverUrl, fileNameForm)) != nil {
                NCContentPresenter().showError(error: NKError(errorCode: 0, errorDescription: "_rename_already_exists_"))
                return
                //        }
                //
                //        if NCManageDatabase.shared.getMetadataConflict(account: session.account, serverUrl: serverUrl, fileNameView: String(describing: fileNameForm), nativeFormat: false) != nil {
                //
                //            let metadataForUpload = NCManageDatabase.shared.createMetadata(fileName: String(describing: fileNameForm), fileNameView: String(describing: fileNameForm), ocId: UUID().uuidString, serverUrl: serverUrl, url: "", contentType: "", session: session, sceneIdentifier: self.appDelegate.sceneIdentifier)
                //
                //            guard let conflict = UIStoryboard(name: "NCCreateFormUploadConflict", bundle: nil).instantiateInitialViewController() as? NCCreateFormUploadConflict else { return }
                //
                //            conflict.textLabelDetailNewFile = NSLocalizedString("_now_", comment: "")
                //            conflict.alwaysNewFileNameNumber = true
                //            conflict.serverUrl = serverUrl
                //            conflict.metadatasUploadInConflict = [metadataForUpload]
                //            conflict.delegate = self
                //
                //            self.present(conflict, animated: true, completion: nil)
                
            } else {
                
                let fileNamePath = utilityFileSystem.getFileNamePath(String(describing: fileNameForm), serverUrl: serverUrl, session: session)
                await NCCreateDocument().createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileNameForm), fileNameExtension: self.fileNameExtension, editorId: editorId, creatorId: creatorId, templateId: templateIdentifier, account: session.account)
                
            }
        }
    }

    func dismissCreateFormUploadConflict(metadatas: [tableMetadata]?) {

        if let metadatas, metadatas.count > 0 {
            let fileName = metadatas[0].fileName
            let fileNamePath = utilityFileSystem.getFileNamePath(fileName, serverUrl: serverUrl, session: session)
//            createDocument(fileNamePath: fileNamePath, fileName: fileName)
            Task {
                await NCCreateDocument().createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: editorId, creatorId: creatorId, templateId: templateIdentifier, account: session.account)
            }

        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.cancel()
            }
        }
    }

    func createDocument(fileNamePath: String, fileName: String) {

        self.navigationItem.rightBarButtonItem?.isEnabled = false
        var UUID = NSUUID().uuidString
        UUID = "TEMP" + UUID.replacingOccurrences(of: "-", with: "")

        if self.editorId == NCGlobal.shared.editorText || self.editorId == NCGlobal.shared.editorOnlyoffice {

            Task {
                var options = NKRequestOptions()
                if self.editorId == NCGlobal.shared.editorOnlyoffice {
                    options = NKRequestOptions(customUserAgent: utility.getCustomUserAgentOnlyOffice())
                } else if editorId == NCGlobal.shared.editorText {
                    options = NKRequestOptions(customUserAgent: utility.getCustomUserAgentNCText())
                }
                
                let results = await NextcloudKit.shared.textCreateFileAsync(fileNamePath: fileNamePath, editorId: editorId, creatorId: creatorId, templateId: templateIdentifier, account: session.account, options: options) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: self.session.account,
                                                                                                    path: fileNamePath,
                                                                                                    name: "textCreateFile")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                }
                guard results.error == .success, let url = results.url else {
                    return NCContentPresenter().showError(error: results.error)
                }
                let metadata = await NCManageDatabase.shared.createMetadataAsync(fileName: fileName,
                                                                                 ocId: UUID,
                                                                                 serverUrl: serverUrl,
                                                                                 url: url,
                                                                                 session: session,
                                                                                 sceneIdentifier: controller.sceneIdentifier)
                AnalyticsHelper.shared.trackCreateFile(metadata: metadata)
                if let vc = await NCViewer().getViewerController(metadata: metadata, delegate: controller) {
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }

        if self.editorId == NCGlobal.shared.editorCollabora {
            Task {
                
                let results = await NextcloudKit.shared.createRichdocumentsAsync(path: fileNamePath, templateId: templateIdentifier, account: session.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: self.session.account,
                                                                                                    path: fileNamePath,
                                                                                                    name: "CreateRichdocuments")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                }
                guard results.error == .success, let url = results.url else {
                    return NCContentPresenter().showError(error: results.error)
                }
                
                let metadata = await NCManageDatabase.shared.createMetadataAsync(fileName: fileName,
                                                                                 ocId: UUID,
                                                                                 serverUrl: serverUrl,
                                                                                 url: url,
                                                                                 session: session,
                                                                                 sceneIdentifier: controller.sceneIdentifier)
                
                if let vc = await NCViewer().getViewerController(metadata: metadata, delegate: controller) {
                    controller.navigationController?.pushViewController(vc, animated: true)
                }
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
                options = NKRequestOptions(customUserAgent: utility.getCustomUserAgentOnlyOffice())
            } else if editorId == NCGlobal.shared.editorText {
                options = NKRequestOptions(customUserAgent: utility.getCustomUserAgentNCText())
            }

            NextcloudKit.shared.textGetListOfTemplates(account: session.account, options: options) { account, templates, _, error in

                self.indicator.stopAnimating()

                if error == .success && account == self.session.account, let templates = templates {

                    for template in templates {

                        var temp = NKEditorTemplate()

                        temp.identifier = template.identifier
                        temp.ext = template.ext
                        temp.name = template.name
                        temp.preview = template.preview

                        self.listOfTemplate.append(temp)

                        // default: template empty
                        if temp.preview.isEmpty {
                            self.selectTemplate = temp
                            self.fileNameExtension = template.ext
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    }
                }

                if self.listOfTemplate.isEmpty {

                    var temp = NKEditorTemplate()

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

            NextcloudKit.shared.getTemplatesRichdocuments(typeTemplate: typeTemplate, account: session.account) { account, templates, _, error in

                self.indicator.stopAnimating()

                if error == .success && account == self.session.account {

                    for template in templates! {

                        var temp = NKEditorTemplate()

                        temp.identifier = "\(template.templateId)"
//                        temp.delete = template.delete
                        temp.ext = template.ext
                        temp.name = template.name
                        temp.preview = template.preview
//                        temp.type = template.type

                        self.listOfTemplate.append(temp)

                        // default: template empty
                        if temp.preview.isEmpty {
                            self.selectTemplate = temp
                            self.fileNameExtension = temp.ext
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    }
                }

                if self.listOfTemplate.isEmpty {

                    var temp = NKEditorTemplate()

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

        let fileNameLocalPath = utilityFileSystem.directoryUserData + "/" + name + ".png"

        NextcloudKit.shared.download(serverUrlFileName: preview, fileNameLocalPath: fileNameLocalPath, account: session.account, requestHandler: { _ in

        }, taskHandler: { _ in

        }, progressHandler: { _ in

        }) { account, _, _, _, _, _, error in

            if error == .success && account == self.session.account {
                self.collectionView.reloadItems(at: [indexPath])
            } else if error != .success {
                print("\(error.errorCode)")
            } else {
                print("[ERROR] It has been changed user during networking process, error.")
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
