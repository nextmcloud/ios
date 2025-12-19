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

//    static func formattedExpiryDate(_ date: Date) -> String {
//        // Get the app language
//        let appLanguage = Locale.preferredLanguages.first?.prefix(2) ?? "en"
//        let locale = Locale(identifier: "\(appLanguage)_\(appLanguage.uppercased())")
//
//        // Extract components
//        let calendar = Calendar.current
//        let day = calendar.component(.day, from: date)
//
//        // Get month name abbreviation in the correct locale
//        let monthFormatter = DateFormatter()
//        monthFormatter.locale = locale
//        monthFormatter.dateFormat = "MMM" // abbreviated month
//        var month = monthFormatter.string(from: date)
//
//        // Capitalize first letter (German months are lowercase normally)
//        month = month.prefix(1).uppercased() + month.dropFirst()
//
//        // Remove trailing period if present (common in German abbreviations)
//        month = month.replacingOccurrences(of: ".", with: "")
//
//        // Get year
//        let year = calendar.component(.year, from: date)
//
//        return String(format: "%02d.%@.%d", day, month, year)
//    }
    
    /// Formats a given Date object into the specific string format "dd. MMM. yyyy"
    /// required for the expiry date display (e.g., "01. Dez. 2026").
    static func formattedExpiryDate(_ date: Date) -> String {
        
        // 1. Determine the correct locale to use based on the app's preferences
        let appLanguageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        // Use a standard locale identifier for consistency across devices
        let localeIdentifier = (appLanguageCode == "de" || appLanguageCode == "en") ? appLanguageCode : "en"
        let locale = Locale(identifier: String(localeIdentifier))
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        
        // 2. Get the month abbreviation using the correct locale
        let monthFormatter = DateFormatter()
        monthFormatter.locale = locale
        monthFormatter.dateFormat = "MMM" // e.g., "Dez." (German locale adds a period) or "Dec" (English locale adds no period)
        var month = monthFormatter.string(from: date)
        
        // 3. CRITICAL FIXES:
        // A. Remove any trailing period the locale might have added
        month = month.replacingOccurrences(of: ".", with: "")
        
        // B. Capitalize the first letter (German defaults to lowercase 'dez')
        month = month.prefix(1).uppercased() + month.dropFirst()
        
        // 4. Use the String(format:) with correct spacing to guarantee the output structure
        // This line guarantees a SINGLE period after the day and a SINGLE period after the month abbreviation.
        let formattedDateString = String(format: "%02d. %@. %d", day, month, year)
        
        return formattedDateString
    }

}
