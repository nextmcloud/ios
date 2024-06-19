//
//  AnalyticsHelper.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 10/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

class AnalyticsHelper: AnalyticsService {
    
    static let shared = AnalyticsHelper()

    private var analyticsServices: [AnalyticsService]

    private init() {
        // Initialize the analytics services
        let moEngageAnalytics = MoEngageAnalytics()
        moEngageAnalytics.trackAppId()
        analyticsServices = [moEngageAnalytics]
        
    }

    func trackEvent(eventName: AnalyticEvents, properties: [String: Any]? = nil) {
        DispatchQueue.global(qos: .background).async {
            self.analyticsServices.forEach { $0.trackEvent(eventName: eventName, properties: properties) }
        }
    }
    
    func trackUserData() {
        DispatchQueue.global(qos: .background).async {
            self.analyticsServices.forEach { $0.trackUserData() }
        }
    }

    func trackUsedStorageData(quotaUsed: Int64) {
        DispatchQueue.global(qos: .background).async {
            self.analyticsServices.forEach { $0.trackUsedStorageData(quotaUsed: quotaUsed) }
        }
    }
    
    func trackAutoUpload(isEnable: Bool) {
        DispatchQueue.global(qos: .background).async {
            self.analyticsServices.forEach { $0.trackAutoUpload(isEnable: isEnable) }
        }
    }
    
    func trackAppVersion() {
        DispatchQueue.global(qos: .background).async {
            self.analyticsServices.forEach { $0.trackAppVersion() }
        }
    }
}
