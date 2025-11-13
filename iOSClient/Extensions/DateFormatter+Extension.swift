//
//  DateFormatter+Extension.swift
//  Nextcloud
//
//  Created by Henrik Storch on 18.03.22.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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

extension DateFormatter {
    static let shareExpDate: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()

    static func formattedShareExpDate(from date: Date) -> String {
        // Get the app language
        let appLanguage = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        let locale = Locale(identifier: "\(appLanguage)_\(appLanguage.uppercased())")

        // Extract components
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        // Get month name abbreviation in the correct locale
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.dateFormat = "MMM" // abbreviated month
        var month = monthFormatter.string(from: date)

        // Capitalize first letter (German months are lowercase normally)
        month = month.prefix(1).uppercased() + month.dropFirst()

        // Remove trailing period if present (common in German abbreviations)
        month = month.replacingOccurrences(of: ".", with: "")

        // Get year
        let year = calendar.component(.year, from: date)

        return String(format: "%02d.%@.%d", day, month, year)
    }
}
