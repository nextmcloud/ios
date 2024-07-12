//
//  NCShares+Swizzle.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 02/07/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

extension NCShares: SwizzleDelegate {
    @objc func swizzle_viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AnalyticsHelper.shared.trackEvent(eventName: .SCREEN_EVENT__SHARED)
    }
    
    static func setup() {
        swizzleMethod(anyClass: self, originalSelector: #selector(viewWillAppear(_:)), swizzledSelector: #selector(swizzle_viewWillAppear(_:)))
    }
}
