//
//  MoEngageAnalytics.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 10/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation
import MoEngageSDK

class MoEngageAnalytics {
    
    // Initializer for the MoEngageAnalytics class
    init() {
        // Create a configuration object for MoEngage SDK with the given App ID and Data Center
        let sdkConfig = MoEngageSDKConfig(appId: "7KWWUKA6OKXGP8Q6DMCXLDX5", dataCenter: MoEngageDataCenter.data_center_02)
        
        // Disable periodic flushing of analytics data
        sdkConfig.analyticsDisablePeriodicFlush = true
        
        // Initialize the MoEngage SDK
        // Use different initialization methods for Debug and Production environments
#if DEBUG
        MoEngage.sharedInstance.initializeDefaultTestInstance(sdkConfig)
#else
        MoEngage.sharedInstance.initializeDefaultLiveInstance(sdkConfig)
#endif
    }
    
    // Method to track the App ID
    func trackAppId() {
        MoEngageSDKAnalytics.sharedInstance.trackLocale(forAppID: "312838242")
    }
}

// AnalyticsService protocol
extension MoEngageAnalytics: AnalyticsService {
    // Method to track a specific event with optional properties
    func trackEvent(eventName: AnalyticEvents, properties: [String: Any]?) {
        let eventProperties = MoEngageProperties(withAttributes: properties)
        MoEngageSDKAnalytics.sharedInstance.trackEvent(eventName.moEngageEvent, withProperties: eventProperties)
    }
    
    // Method to track user data
    func trackUserData() {
        // Get the active user account from the database
        guard let user = NCManageDatabase.shared.getActiveAccount() else { return }
        
        // Set user attributes in the MoEngage SDK
        MoEngageSDKAnalytics.sharedInstance.setUniqueID(user.userId)
        MoEngageSDKAnalytics.sharedInstance.setName(user.displayName)
        MoEngageSDKAnalytics.sharedInstance.setEmailID(user.email)
        
        // Convert the user's total storage quota to a readable format and set it as a user attribute
        let storageCapacity = NCUtilityFileSystem().transformedSize(user.quotaTotal)
        MoEngageSDKAnalytics.sharedInstance.setUserAttribute(storageCapacity, withAttributeName: AnalyticEvents.USER_PROPERTIES_STORAGE_CAPACITY.rawValue)
        
        // Track whether auto-upload is enabled for the user
        trackAutoUpload(isEnable: user.autoUpload)
    }
    
    // Method to track the used storage data
    func trackUsedStorageData(quotaUsed: Int64) {
        MoEngageSDKAnalytics.sharedInstance.setUserAttribute(quotaUsed, withAttributeName: AnalyticEvents.USER_PROPERTIES_STORAGE_USED.rawValue)
    }
    
    // Method to track the auto-upload setting
    func trackAutoUpload(isEnable: Bool) {
        MoEngageSDKAnalytics.sharedInstance.setUserAttribute(isEnable, withAttributeName: AnalyticEvents.USER_PROPERTIES_AUTO_UPLOAD.rawValue)
    }
    
    // Method to track the app version
    func trackAppVersion() {
        // Get the app version and set it as a user attribute
        let version = NCUtility().getVersionApp() as String
        
        // Check if a build version key is present in UserDefaults
        if let oldVersion = UserDefaults.standard.value(forKey: NCSettingsBundleHelper.SettingsBundleKeys.BuildVersionKey) as? String {
            if version != oldVersion {
                MoEngageSDKAnalytics.sharedInstance.appStatus(.update)
            }
        } else {
            MoEngageSDKAnalytics.sharedInstance.appStatus(.install)
        }
        
        MoEngageSDKAnalytics.sharedInstance.setUserAttribute(version, withAttributeName: AnalyticEvents.USER_PROPERTIES_APP_VERSION.rawValue)
    }
}
