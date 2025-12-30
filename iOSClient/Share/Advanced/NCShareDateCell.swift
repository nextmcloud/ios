// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

///
/// Table view cell to manage the expiration date on a share in its details.
///
class NCShareDateCell: UITableViewCell {
    let picker = UIDatePicker()
    let textField = UITextField()
    var shareType: Int
    var onReload: (() -> Void)?
    let shareCommon = NCShareCommon()

    init(share: Shareable) {
        self.shareType = share.shareType
        super.init(style: .value1, reuseIdentifier: "shareExpDate")

        picker.datePickerMode = .date
        picker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        picker.preferredDatePickerStyle = .wheels
        // Get the app's language (first language in the preferred languages array)
        let appLanguage = Locale.preferredLanguages.first?.prefix(2) ?? "en"

        // Set the locale of the picker to the app's language
        picker.locale = Locale(identifier: "\(appLanguage)_\(appLanguage.uppercased())")

        // Handle date changes
//        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)

        picker.action(for: .valueChanged) { datePicker in
            guard let datePicker = datePicker as? UIDatePicker else { return }
            self.detailTextLabel?.text = DateFormatter.formattedExpiryDate(datePicker.date)//DateFormatter.formattedShareExpDate(from: datePicker.date)
        }
        accessoryView = textField

        let toolbar = UIToolbar.toolbar {
            self.resignFirstResponder()
            share.expirationDate = nil
            self.onReload?()
        } onDone: {
            self.resignFirstResponder()
            share.expirationDate = self.picker.date as NSDate
            self.onReload?()
        }

        textField.isAccessibilityElement = false
        textField.accessibilityElementsHidden = true
        textField.inputAccessoryView = toolbar.wrappedSafeAreaContainer
        textField.inputView = picker

        if let expDate = share.expirationDate {
            print(DateFormatter.formattedExpiryDate(expDate as Date))
            detailTextLabel?.text = DateFormatter.formattedExpiryDate(expDate as Date) //DateFormatter.formattedShareExpDate(from: expDate as Date)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func checkMaximumDate(account: String) {
        let defaultExpDays = defaultExpirationDays(account: account)
        if defaultExpDays > 0 && isExpireDateEnforced(account: account) {
            let enforcedInSecs = TimeInterval(defaultExpDays * 24 * 60 * 60)
            self.picker.maximumDate = Date().advanced(by: enforcedInSecs)
        }
    }

    private func isExpireDateEnforced(account: String) -> Bool {
        switch self.shareType {
        case NKShare.ShareType.publicLink.rawValue,
            NKShare.ShareType.email.rawValue,
            NKShare.ShareType.guest.rawValue:
            return capabilities.fileSharingPubExpireDateEnforced
        case NKShare.ShareType.user.rawValue,
            NKShare.ShareType.group.rawValue,
            NKShare.ShareType.team.rawValue,
            NKShare.ShareType.talkConversation.rawValue:
            return capabilities.fileSharingInternalExpireDateEnforced
        case NKShare.ShareType.federatedCloud.rawValue,
            NKShare.ShareType.federatedGroup.rawValue:
            return capabilities.fileSharingRemoteExpireDateEnforced
        default:
            return false
        }
    }

    private func defaultExpirationDays(account: String) -> Int {
        switch self.shareType {
        case NKShare.ShareType.publicLink.rawValue,
            NKShare.ShareType.email.rawValue,
            NKShare.ShareType.guest.rawValue:
            return capabilities.fileSharingPubExpireDateDays
        case NKShare.ShareType.user.rawValue,
            NKShare.ShareType.group.rawValue,
            NKShare.ShareType.team.rawValue,
            NKShare.ShareType.talkConversation.rawValue:
            return capabilities.fileSharingInternalExpireDateDays
        case NKShare.ShareType.federatedCloud.rawValue,
            NKShare.ShareType.federatedGroup.rawValue:
            return capabilities.fileSharingRemoteExpireDateDays
        default:
            return 0
        }
    }
}
