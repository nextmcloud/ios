//
//  NCShareNewUserAddComment.swift
//  Nextcloud
//
//  Created by T-systems on 21/06/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit
import NCCommunication

class NCShareNewUserAddComment: UIViewController, UITextViewDelegate, NCShareNetworkingDelegate {
    
    @IBOutlet weak var labelNote: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSendShare: UIButton!
    public var metadata: tableMetadata?
    public var sharee: NCCommunicationSharee?
    private var networking: NCShareNetworking?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelNote.text = NSLocalizedString("_share_note_recipient_", comment: "")
        
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
//        commentTextView.text = "Note"
        commentTextView.textColor = .lightGray
        
        btnCancel.setTitle(NSLocalizedString("_cancel_", comment: ""), for: .normal)
        btnCancel.layer.cornerRadius = 10
        btnCancel.layer.masksToBounds = true
        btnCancel.layer.borderWidth = 1
        btnCancel.layer.borderColor = NCBrandColor.shared.customerDarkGrey.cgColor
        btnCancel.setTitleColor(NCBrandColor.shared.icon, for: .normal)
        btnCancel.backgroundColor = .white
        
        btnSendShare.setTitle(NSLocalizedString("_send_share_", comment: ""), for: .normal)
        btnSendShare.layer.cornerRadius = 10
        btnSendShare.layer.masksToBounds = true
        btnSendShare.setBackgroundColor(NCBrandColor.shared.customer, for: .normal)
        btnSendShare.setTitleColor(.white, for: .normal)
        
        networking = NCShareNetworking.init(metadata: metadata!, urlBase: appDelegate.urlBase, view: self.view, delegate: self)
        // Do any additional setup after loading the view.
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
        
        self.networking?.createShare(shareWith: sharee!.shareWith, shareType: sharee!.shareType, metadata: self.metadata!)
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
    
    func popToShare() {
        let controller = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 3]
        self.navigationController?.popToViewController(controller!, animated: true)
    }
    
    func readShareCompleted() {}
    
    func shareCompleted() {
        popToShare()
    }
    
    func unShareCompleted() {}
    
    func updateShareWithError(idShare: Int) {}
    
    func getSharees(sharees: [NCCommunicationSharee]?) {}
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
