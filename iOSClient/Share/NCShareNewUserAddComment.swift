//
//  NCShareNewUserAddComment.swift
//  Nextcloud
//
//  Created by TSI-mc on 21/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//  Copyright © 2021 TSI-mc. All rights reserved.
//

import UIKit
import NCCommunication
import SVGKit

class NCShareNewUserAddComment: UIViewController, UITextViewDelegate, NCShareNetworkingDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var folderImageView: UIImageView!
    @IBOutlet weak var favorite: UIButton!
    @IBOutlet weak var labelFileName: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    
    @IBOutlet weak var labelNote: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSendShare: UIButton!
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    private var networking: NCShareNetworking?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var permission: Int = 0
    var hideDownload: Bool?
    var password: String!
    @IBOutlet weak var headerImageViewSpaceFavorite: NSLayoutConstraint!
    var creatingShare = false
    var note = ""
    var shareeEmail: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = NCBrandColor.shared.backgroundView
        self.commentTextView.backgroundColor = NCBrandColor.shared.backgroundView
        if FileManager.default.fileExists(atPath: CCUtility.getDirectoryProviderStorageIconOcId(metadata!.ocId, etag: metadata!.etag)) {
            self.imageView.image = getImageMetadata(metadata!)
            self.folderImageView.isHidden = true
//            self.headerImageViewSpaceFavorite.constant = 5.0
        } else {
            if metadata!.directory {
                let image = UIImage.init(named: "folder")!
                self.folderImageView.image = image.image(color: NCBrandColor.shared.customerDefault, size: image.size.width)
            } else if metadata!.iconName.count > 0 {
                self.folderImageView.image = UIImage.init(named: metadata!.iconName)
            } else {
                self.folderImageView.image = UIImage.init(named: "file")
            }
//            self.headerImageViewSpaceFavorite.constant = -49.0
        }
        self.favorite.layoutIfNeeded()
        self.labelFileName.text = self.metadata?.fileNameView
        self.labelFileName.textColor = NCBrandColor.shared.textView
        if metadata!.favorite {
            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
        } else {
            self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
        }
        self.labelDescription.text = CCUtility.transformedSize(metadata!.size) + ", " + CCUtility.dateDiff(metadata!.date as Date)
        
        labelNote.text = NSLocalizedString("_share_note_recipient_", comment: "")
        
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = NCBrandColor.shared.gray26AndGrayf2.cgColor
//        commentTextView.text = "Note"
        commentTextView.textColor = NCBrandColor.shared.shareCellTitleColor
        
        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        btnCancel.layer.cornerRadius = 10
        btnCancel.layer.masksToBounds = true
        btnCancel.layer.borderWidth = 1
        btnCancel.layer.borderColor = NCBrandColor.shared.gray26AndGrayf2.cgColor
        btnCancel.setTitleColor(NCBrandColor.shared.shareCellTitleColor, for: .normal)
        btnCancel.backgroundColor = .white
        
        btnSendShare.setTitle(NSLocalizedString("_send_share_", comment: ""), for: .normal)
        btnSendShare.layer.cornerRadius = 10
        btnSendShare.layer.masksToBounds = true
        btnSendShare.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        btnSendShare.setTitleColor(.white, for: .normal)
        
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.icon
        self.title = self.metadata?.ownerDisplayName
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase, view: self.view, delegate: self)
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        popToShare()
    }
    
    @IBAction func sendShareClicked(_ sender: Any) {
        let message = commentTextView.text.trimmingCharacters(in: .whitespaces)
        if message.count > 0 {
            NCCommunication.shared.putComments(fileId: metadata!.fileId, message: message) { (account, errorCode, errorDescription) in
                if errorCode == 0 {
                    self.commentTextView.text = ""
                } else {
                    NCContentPresenter.shared.messageNotification("_share_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                }
            }
        }
        self.note = message
        self.networking?.createShare(shareWith: sharee!.shareWith, shareType: sharee!.shareType, metadata: self.metadata!)
        self.creatingShare = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Note"
            textView.textColor = UIColor.lightGray
        }
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
    
    //MARK :- Action methods
    
    @IBAction func touchUpInsideFavorite(_ sender: UIButton) {
        if let metadata = self.metadata {
            NCNetworking.shared.favoriteMetadata(metadata, urlBase: appDelegate.urlBase) { (errorCode, errorDescription) in
                if errorCode == 0 {
                    if !metadata.favorite {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.yellowFavorite, size: 24), for: .normal)
                        self.metadata?.favorite = true
                    } else {
                        self.favorite.setImage(NCUtility.shared.loadImage(named: "star.fill", color: NCBrandColor.shared.textInfo, size: 24), for: .normal)
                        self.metadata?.favorite = false
                    }
                } else {
                    NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, errorCode: errorCode)
                }
            }
        }
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
    
    //MARK: - NCShareNetworkingDelegate
    
    func popToShare() {
        let controller = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 3]
        self.navigationController?.popToViewController(controller!, animated: true)
    }
    
    func readShareCompleted() {}
    
    func shareCompleted() {
        if self.creatingShare {
            self.appDelegate.shares = NCManageDatabase.shared.getTableShares(account: self.metadata!.account)
//            if let tableShare = NCManageDatabase.shared.getTableShares(metadata: metadata!) {
//                networking?.updateShare(idShare: tableShare.idShare, password: self.password, permission: tableShare.permissions, note: self.note, expirationDate: nil, hideDownload: self.hideDownload!)
//            }
        }
        popToShare()
    }
    
    func unShareCompleted() {}
    
    func updateShareWithError(idShare: Int) {}
    
    func getSharees(sharees: [NCCommunicationSharee]?) {}
    
}
