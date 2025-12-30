//
//  NCShareTextInputCell.swift
//  Nextcloud
//
//  Created by T-systems on 20/09/21.
//  Copyright © 2021 Kunal. All rights reserved.
//

import UIKit
import XLForm

class NCShareTextInputCell: XLFormBaseCell, UITextFieldDelegate {
    
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var seperatorBottom: UIView!
    @IBOutlet weak var cellTextField: UITextField!
    @IBOutlet weak var calendarImageView: UIImageView!

    let datePicker = UIDatePicker()
    var expirationDateText: String!
    var expirationDate: NSDate!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.cellTextField.delegate = self
        self.cellTextField.isEnabled = true
        calendarImageView.image = UIImage(named: "calender")//?.imageColor(NCBrandColor.shared.brandElement)
        calendarImageView.image = UIImage(named: "calender")?.imageColor(NCBrandColor.shared.brandElement)
        self.selectionStyle = .none
        self.backgroundColor = NCBrandColor.shared.secondarySystemGroupedBackground
        self.cellTextField.attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [NSAttributedString.Key.foregroundColor: NCBrandColor.shared.fileFolderName]
        )
        self.cellTextField.textColor = NCBrandColor.shared.singleTitleColorButton
    }

    override func configure() {
        super.configure()
    }

    override func update() {
        super.update()

        calendarImageView.isHidden = rowDescriptor.tag != "NCShareTextInputCellExpiry"

        if rowDescriptor.tag == "NCShareTextInputCellExpiry" {
            seperator.isHidden = true
            setDatePicker(sender: self.cellTextField)
        } else if rowDescriptor.tag == "NCShareTextInputCellDownloadLimit" {
            seperator.isHidden = true
            cellTextField.keyboardType = .numberPad
            setDownloadLimitDoneButton(sender: self.cellTextField)
        }
    }

    // MARK: - TextField Delegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if self.cellTextField == textField, let text = self.cellTextField.text {
            rowDescriptor.value = (text + string).isEmpty ? nil : text + string
        }
        self.formViewController().textField(textField, shouldChangeCharactersIn: range, replacementString: string)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        rowDescriptor.value = cellTextField.text
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

    // MARK: - Date Picker

    func setDatePicker(sender: UITextField) {
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()//.tomorrow
        datePicker.minimumDate = Date.tomorrow
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.sizeToFit()
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: NSLocalizedString("_done_", comment: ""), style: .plain, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let clearButton = UIBarButtonItem(title: NSLocalizedString("_clear_", comment: ""), style: .plain, target: self, action: #selector(clearDatePicker))

        toolbar.setItems([clearButton, spaceButton, doneButton], animated: false)
        sender.inputAccessoryView = toolbar
        sender.inputView = datePicker
    }

    @objc func doneDatePicker() {
//        let expiryDateString = DateFormatter.formattedShareExpDate(from: datePicker.date)
        let expiryDateString = DateFormatter.formattedExpiryDate(datePicker.date)

//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = NCShareAdvancePermission.displayDateFormat
//        var expiryDate = dateFormatter.string(from: datePicker.date)
//        expiryDate = expiryDate.replacingOccurrences(of: "..", with: ".")
//        self.expirationDateText = expiryDate
//        self.expirationDate = datePicker.date as NSDate

        let expiryDateString = DateFormatter.shareExpDate.string(from: datePicker.date)
        self.expirationDateText = expiryDateString
        self.expirationDate = datePicker.date as NSDate

        self.cellTextField.text = self.expirationDateText
        self.rowDescriptor.value = self.expirationDate
        self.cellTextField.endEditing(true)
    }

    @objc func clearDatePicker() {
        self.expirationDate = nil
        self.cellTextField.text = ""
        self.rowDescriptor.value = nil
        self.cellTextField.endEditing(true)
    }

    // MARK: - Download Limit

    func setDownloadLimitDoneButton(sender: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: NSLocalizedString("_done_", comment: ""), style: .plain, target: self, action: #selector(doneDownloadLimit))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton, doneButton], animated: false)

        sender.inputAccessoryView = toolbar
    }

    @objc func doneDownloadLimit() {
        if let text = cellTextField.text, let limit = Int(text) {
            rowDescriptor.value = limit
        } else {
            rowDescriptor.value = 0
        }
        cellTextField.endEditing(true)
    }
}

class NCSeparatorCell: XLFormBaseCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func update() {
        super.update()
        selectionStyle = .none
    }
}
