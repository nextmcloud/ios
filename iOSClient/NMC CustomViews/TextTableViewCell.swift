//
//  TextTableViewCell.swift
//  Nextcloud
//
//  Created by Ashu on 23/04/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class TextTableViewCell: XLFormBaseCell,UITextFieldDelegate {

    @IBOutlet weak var labelFileName: UILabel!
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
    
}
