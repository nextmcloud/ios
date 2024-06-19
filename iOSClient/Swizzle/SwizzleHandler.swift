//
//  SwizzleHandler.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 14/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

protocol SwizzleDelegate {
    static func swizzleMethod(anyClass: AnyClass?, originalSelector: Selector, swizzledSelector: Selector)
}

extension SwizzleDelegate {
    static func swizzleMethod(anyClass: AnyClass?, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(anyClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(anyClass, swizzledSelector) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}


class SwizzleHandler {
    func setup() {
        SceneDelegate.setup()
    }
}
