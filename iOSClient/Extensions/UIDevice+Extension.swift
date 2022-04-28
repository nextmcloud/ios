//
//  UIDevice+Extension.swift
//  Nextcloud
//
//  Created by A200020526 on 27/04/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import Foundation

extension UIDevice {

    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
           return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0
        }
        return false
   }
}
