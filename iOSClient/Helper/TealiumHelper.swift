//
//  TealiumHelper.swift
//  Nextcloud
//
//  Created by TSI-mc on 17/07/2019.
//  Copyright © 2021 TSI-mc. All rights reserved.
//
//  Author TSI-mc
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import TealiumSwift
import Foundation

class TealiumHelper: NSObject {
    static let shared = TealiumHelper()
    let config = TealiumConfig(account: "telekom",
                               profile: "magentacloud-app",
                               environment: "dev")
    var tealium: Tealium?

    @objc override init() {
        
        config.batchingEnabled = true
        config.logLevel = .debug
        
        config.collectors = [Collectors.Lifecycle,
                             Collectors.Location,
                             Collectors.VisitorService]
        
        config.dispatchers = [Dispatchers.TagManagement,
                              Dispatchers.RemoteCommands]
        
        tealium = Tealium(config: config, enableCompletion: {value in
            print(value)
        }
        )
    }
    
    func start() {
        _ = TealiumHelper.shared
    }
    
    @objc func trackView(title: String, data: [String: Any]?) {
        let tealView = TealiumView(title, dataLayer: data)
        TealiumHelper.shared.tealium?.track(tealView)
    }
    
    @objc func trackEvent(title: String, data: [String: Any]?) {
        let tealEvent = TealiumEvent(title, dataLayer: data)
        TealiumHelper.shared.tealium?.track(tealEvent)
    }
}
