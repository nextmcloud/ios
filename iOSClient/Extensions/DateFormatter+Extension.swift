// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

extension DateFormatter {
    static let shareExpDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
//        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = NCShareAdvancePermission.displayDateFormat
        return dateFormatter
    }()
}

extension Date {
    static var tomorrow:  Date { return Date().dayAfter }
    static var today: Date {return Date()}
    static var dayAfterYear:  Date { return Date().dateAfterYear }
    var dayAfter: Date {
      return Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }
    var dateAfterYear: Date {
       return Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    }
}
