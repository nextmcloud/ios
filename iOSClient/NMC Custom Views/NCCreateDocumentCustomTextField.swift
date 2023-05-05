//
//  NCCreateDocumentCustomTextField.swift
//  Nextcloud
//
//  Created by A200073704 on 04/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

class NCCreateDocumentCustomTextField: XLFormBaseCell,UITextFieldDelegate {

    @IBOutlet weak var fileNameTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        fileNameTextField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if fileNameTextField == textField {
            if let rowDescriptor = rowDescriptor, let text = self.fileNameTextField.text {

                if (text + " ").isEmpty == false {
                    rowDescriptor.value = self.fileNameTextField.text! + string
                } else {
                    rowDescriptor.value = nil
                }
            }
        }

         self.formViewController().textField(textField, shouldChangeCharactersIn: range, replacementString: string)
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.formViewController()?.textFieldShouldReturn(fileNameTextField)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.formViewController()?.textFieldShouldClear(fileNameTextField)
        return true
    }
    
    override class func formDescriptorCellHeight(for rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 45
    }
}
