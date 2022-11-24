//
//  NCRenameFile.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 26/02/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
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
import UIKit
import NextcloudKit

public protocol NCRenameFileDelegate: AnyObject {
    func rename(fileName: String, fileNameNew: String)
}

// optional func
public extension NCRenameFileDelegate {
    func rename(fileName: String, fileNameNew: String) {}
}

class NCRenameFile: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separatorHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var previewFile: UIImageView!
    @IBOutlet weak var fileNameWithoutExt: UITextField!
    @IBOutlet weak var point: UILabel!
    @IBOutlet weak var ext: UITextField!
    @IBOutlet weak var fileNameWithoutExtTrailingContraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var renameButton: UIButton!
    @IBOutlet weak var seperator: UIView!
    weak var delegate: NCRenameFileDelegate?

    let width: CGFloat = 300
    let height: CGFloat = 350
    var metadata: tableMetadata?
    var fileName: String?
    var imagePreview: UIImage?
    var disableChangeExt: Bool = false
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let metadata = self.metadata {

            if metadata.directory {
                titleLabel.text = NSLocalizedString("_rename_folder_", comment: "")
            } else {
                titleLabel.text = NSLocalizedString("_rename_file_", comment: "")
            }
            separatorHeightContraint.constant = 0.3
            
            fileNameWithoutExt.text = (metadata.fileNameView as NSString).deletingPathExtension
            fileNameWithoutExt.delegate = self
            fileNameWithoutExt.layer.borderColor = NCBrandColor.shared.iconColor.cgColor
            fileNameWithoutExt.becomeFirstResponder()

            ext.text = metadata.fileExtension
            ext.delegate = self
            if disableChangeExt {
                ext.isEnabled = false
                ext.textColor = .lightGray
            }
            
            previewFile.image = imagePreview
            previewFile.layer.cornerRadius = 10
            previewFile.layer.masksToBounds = true

            if metadata.directory {

                if imagePreview == nil {
                    previewFile.image = NCBrandColor.cacheImages.folder
                }

                ext.isHidden = true
                point.isHidden = true
                fileNameWithoutExtTrailingContraint.constant = 20

            } else {

                if imagePreview == nil {
                    previewFile.image = NCBrandColor.cacheImages.file
                }
//                if let icon = UIImage(contentsOfFile: CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, etag: metadata.etag)) {
//                    previewFile.image = icon
//                }
                
                fileNameWithoutExtTrailingContraint.constant = 90
            }
        } else if let fileName = self.fileName {

            titleLabel.text = NSLocalizedString("_rename_file_", comment: "")

            fileNameWithoutExt.text = (fileName as NSString).deletingPathExtension
            fileNameWithoutExt.delegate = self
            fileNameWithoutExt.becomeFirstResponder()
            fileNameWithoutExtTrailingContraint.constant = 90

            ext.text = (fileName as NSString).pathExtension
            ext.delegate = self

            if imagePreview == nil {
                previewFile.image = NCBrandColor.cacheImages.file
            } else {
                previewFile.image = imagePreview
            }
            previewFile.layer.cornerRadius = 10
            previewFile.layer.masksToBounds = true
        }
        
        cancelButton.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        cancelButton.setTitleColor(NCBrandColor.shared.iconColor, for: .normal)
        cancelButton.layer.cornerRadius = 5
        cancelButton.layer.masksToBounds = true
//        cancelButton.layer.backgroundColor =  NCBrandColor.shared.graySoft.withAlphaComponent(0.2).cgColor
        cancelButton.layer.borderWidth = 0.3
        cancelButton.layer.borderColor = NCBrandColor.shared.iconColor.cgColor
        
        renameButton.setTitle(NSLocalizedString("_rename_", comment: ""), for: .normal)
        renameButton.setTitleColor(NCBrandColor.shared.brandText, for: .normal)
        renameButton.layer.cornerRadius = 5
        renameButton.layer.masksToBounds = true
        renameButton.layer.backgroundColor = NCBrandColor.shared.brand.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
        
        changeTheming()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if metadata == nil && fileName == nil {
            dismiss(animated: true)
        }

        fileNameWithoutExt.selectAll(nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        renameMedia(textField)
        return true
    }
    
    // MARK: - NotificationCenter

    @objc func changeTheming() {
        view.backgroundColor = NCBrandColor.shared.nmcGray80TabBar
        seperator.backgroundColor = NCBrandColor.shared.seperatorRename
        fileNameWithoutExt.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        ext.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
    }

    // MARK: - Action

    @IBAction func cancel(_ sender: Any) {

        dismiss(animated: true)
    }

    @IBAction func renameMedia(_ sender: Any) {

        var fileNameWithoutExtNew = ""
        var extNew = ""
        var fileNameNew = ""

        if let metadata = self.metadata {
            
            let extCurrent = (metadata.fileNameView as NSString).pathExtension

            if fileNameWithoutExt.text == nil || fileNameWithoutExt.text?.count == 0 {
                self.fileNameWithoutExt.text = (metadata.fileNameView as NSString).deletingPathExtension
                return
            } else {
                fileNameWithoutExtNew = fileNameWithoutExt.text!
            }
            
            if metadata.directory {

                fileNameNew = fileNameWithoutExtNew
                renameMetadata(metadata, fileNameNew: fileNameNew)

            } else {

                if ext.text == nil || ext.text?.count == 0 {
                    self.ext.text = metadata.fileExtension
                    return
                } else {
                    extNew = ext.text!
                }

                if extNew != extCurrent {

                    let message = String(format: NSLocalizedString("_rename_ext_message_", comment: ""), extCurrent, extNew)
                    let alertController = UIAlertController(title: NSLocalizedString("_rename_ext_title_", comment: ""), message: message, preferredStyle: .alert)

                    var title = String(format: NSLocalizedString("_use_", comment: ""), extNew)
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: { _ in

                        fileNameNew = fileNameWithoutExtNew + "." + extNew
                        self.renameMetadata(metadata, fileNameNew: fileNameNew)
                    }))
                    
                    title = String(format: NSLocalizedString("_keep_", comment: ""), extCurrent)
                    alertController.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                        self.ext.text = metadata.fileExtension
                    }))

                    self.present(alertController, animated: true)

                } else {

                    fileNameNew = fileNameWithoutExtNew + "." + extNew
                    renameMetadata(metadata, fileNameNew: fileNameNew)
                }
            }

        } else if let fileName = self.fileName {

            if fileNameWithoutExt.text == nil || fileNameWithoutExt.text?.count == 0 {
                fileNameWithoutExt.text = (fileName as NSString).deletingPathExtension
                return
            } else if ext.text == nil || ext.text?.count == 0 {
                ext.text = (fileName as NSString).pathExtension
                return
            }

            fileNameNew = (fileNameWithoutExt.text ?? "") + "." + (ext.text ?? "")
            self.dismiss(animated: true) {
                self.delegate?.rename(fileName: fileName, fileNameNew: fileNameNew)
            }
        }
    }

    // MARK: - Networking

    func renameMetadata(_ metadata: tableMetadata, fileNameNew: String) {

        NCActivityIndicator.shared.start()

        NCNetworking.shared.renameMetadata(metadata, fileNameNew: fileNameNew, viewController: self) { error in

            NCActivityIndicator.shared.stop()

            if error == .success {

                self.dismiss(animated: true)

            } else {

                NCContentPresenter.shared.showError(error: error)
            }
        }
    }
}
