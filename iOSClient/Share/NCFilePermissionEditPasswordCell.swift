//
//  NCFilePermissionEditPasswordCell.swift
//  Nextcloud
//
//  Created by T-systems on 18/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCFilePermissionEditPasswordCell: XLFormBaseCell , UITextFieldDelegate {
    
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var seperatorMiddle: UIView!
    @IBOutlet weak var seperatorBottom: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var cellTextField: UITextField!
    @IBOutlet weak var buttonLinkLabel: UIButton!
    let datePicker = UIDatePicker()
    var expirationDateText: String!
    var expirationDate: NSDate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cellTextField.delegate = self
        self.cellTextField.isEnabled = false
        self.selectionStyle = .none
        self.cellTextField.isSecureTextEntry = true
        switchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        self.backgroundColor = NCBrandColor.shared.backgroundView
        self.titleLabel.textColor = NCBrandColor.shared.shareCellTitleColor
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)
    }
    
    @objc func changeTheming() {
        self.backgroundColor = NCBrandColor.shared.backgroundView
        self.titleLabel.textColor = NCBrandColor.shared.icon
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        if value {
            //on
            self.rowDescriptor.value = value
            self.cellTextField.isEnabled = true
            cellTextField.delegate = self
        } else {
            self.rowDescriptor.value = value
            self.cellTextField.isEnabled = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if self.cellTextField == textField {
            if let rowDescriptor = rowDescriptor, let text = self.cellTextField.text {

                if (text + " ").isEmpty == false {
                    rowDescriptor.value = self.cellTextField.text! + string
                } else {
                    rowDescriptor.value = nil
                }
            }
        }
        
        self.formViewController().textField(textField, shouldChangeCharactersIn: range, replacementString: string)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.formViewController()?.textFieldShouldReturn(textField)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.formViewController()?.textFieldShouldClear(textField)
        return true
    }
    
    override class func formDescriptorCellHeight(for rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 30
    }
    
    override func formDescriptorCellDidSelected(withForm controller: XLFormViewController!) {
        self.selectionStyle = .none
    }
}
