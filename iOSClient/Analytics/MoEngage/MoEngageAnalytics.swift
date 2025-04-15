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
        guard let user = NCManageDatabase.shared.getActiveTableAccount() else { return }
        
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
        if isEnable {
            MoEngageSDKAnalytics.sharedInstance.setUserAttribute(isEnable, withAttributeName: AnalyticEvents.USER_PROPERTIES_AUTO_UPLOAD.rawValue)
        }
    }
    
    // Method to track the app version
    func trackAppVersion(oldVersion: String?) {
        // Get the app version and set it as a user attribute
        let version = NCUtility().getVersionApp() as String
        
        // Check if a build version key is present in UserDefaults
        if let oldVersion {
            if version != oldVersion {
                MoEngageSDKAnalytics.sharedInstance.appStatus(.update)
                if let oldAppVersion = Int(oldVersion.dropLast().replacingOccurrences(of: ".", with: "")) {
                    if oldAppVersion < NCGlobal.shared.moEngageAppVersion {
                        trackUserData()
                    }
                }
            }
        } else {
            MoEngageSDKAnalytics.sharedInstance.appStatus(.install)
        }
        
        MoEngageSDKAnalytics.sharedInstance.setUserAttribute(version, withAttributeName: AnalyticEvents.USER_PROPERTIES_APP_VERSION.rawValue)
    }
    
    //Method to track user logout
    func trackLogout() {
        MoEngageSDKAnalytics.sharedInstance.resetUser()
    }
    
    //Method to track create file
    func trackCreateFile(metadata: tableMetadata) {
        let properties = MoEngageProperties()
        properties.addAttribute(getFileType(contentType: metadata.contentType), withName: AnalyticPropertyAttributes.PROPERTIES__FILE_TYPE.rawValue)
        properties.addAttribute(String(getFileSizeInMB(bytes: Int(metadata.size))), withName: AnalyticPropertyAttributes.PROPERTIES__FILE_SIZE.rawValue)
        properties.addAttribute(getDate(date: metadata.creationDate as Date), withName: AnalyticPropertyAttributes.PROPERTIES__CREATION_DATE.rawValue)
        MoEngageSDKAnalytics.sharedInstance.trackEvent(AnalyticEvents.EVENT__CREATE_FILE.rawValue, withProperties: properties)
    }
    
    //Method to track upload file
    func trackEventWithMetadata(eventName: AnalyticEvents, metadata: tableMetadata) {
        let properties = MoEngageProperties()
        properties.addAttribute(getFileType(contentType: metadata.contentType), withName: AnalyticPropertyAttributes.PROPERTIES__FILE_TYPE.rawValue)
        properties.addAttribute(String(getFileSizeInMB(bytes: Int(metadata.size))), withName: AnalyticPropertyAttributes.PROPERTIES__FILE_SIZE.rawValue)
        properties.addAttribute(getDate(date: metadata.creationDate as Date), withName: AnalyticPropertyAttributes.PROPERTIES__CREATION_DATE.rawValue)
        properties.addAttribute(getDate(date: metadata.uploadDate as Date), withName: AnalyticPropertyAttributes.PROPERTIES__UPLOAD_DATE.rawValue)
        MoEngageSDKAnalytics.sharedInstance.trackEvent(eventName.rawValue, withProperties: properties)
    }
    
    //Method to track create folder
    func trackCreateFolder(isEncrypted: Bool, creationDate: Date) {
        let properties = MoEngageProperties()
        properties.addAttribute(isEncrypted ? FolderType.FOLDER_ENCRYPTED.rawValue : FolderType.FOLDER_NORMAL.rawValue , withName: AnalyticPropertyAttributes.PROPERTIES__FILE_TYPE.rawValue)
        properties.addAttribute(getDate(date: creationDate), withName: AnalyticPropertyAttributes.PROPERTIES__CREATION_DATE.rawValue)
        MoEngageSDKAnalytics.sharedInstance.trackEvent(AnalyticEvents.EVENT__CREATE_FOLDER.rawValue, withProperties: properties)
    }
    
    //Method to track create voice memo
    func trackCreateVoiceMemo(size: Int64, date: Date) {
        let properties = MoEngageProperties()
        properties.addAttribute(FileType.AUDIO.rawValue, withName: AnalyticPropertyAttributes.PROPERTIES__FILE_TYPE.rawValue)
        properties.addAttribute(String(getFileSizeInMB(bytes: Int(size))), withName: AnalyticPropertyAttributes.PROPERTIES__FILE_SIZE.rawValue)
        properties.addAttribute(getDate(date: date), withName: AnalyticPropertyAttributes.PROPERTIES__CREATION_DATE.rawValue)
        MoEngageSDKAnalytics.sharedInstance.trackEvent(AnalyticEvents.EVENT__CREATE_VOICE_MEMO.rawValue, withProperties: properties)
    }
    
    
}

// Functions
extension MoEngageAnalytics {
    private func getFileType(contentType: String) -> String? {
        switch contentType {
        case "image/png":
            return FileType.FOTO.rawValue
        case "audio/x-m4a", "audio/mp4":
            return FileType.AUDIO.rawValue
        case "video/mp4":
            return FileType.VIDEO.rawValue
        case "application/pdf":
            return FileType.PDF.rawValue
        case "text/x-markdown","text/plain":
            return FileType.TEXT.rawValue
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            return FileType.DOCX.rawValue
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","text/csv":
            return FileType.XLSX.rawValue
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            return FileType.PPT.rawValue
        default:
            return FileType.OTHER.rawValue
        }
    }
    
    private func getDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    private func getFileSizeInMB(bytes: Int) -> Float {
        return round((Float(bytes) / Float(Size.MEGABYTE)) * 10) / 10
    }

}

//    SCAN("scan"),


