//
//  AnalyticsService.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 10/06/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

import Foundation

protocol AnalyticsService {
    func trackEvent(eventName: AnalyticEvents, properties: [String: Any]?)
    func trackUserData()
    func trackUsedStorageData(quotaUsed: Int64)
    func trackAutoUpload(isEnable: Bool)
    func trackAppVersion()
}


enum AnalyticEvents: String {
    case USER_PROPERTIES_STORAGE_CAPACITY = "storage_capacity" // in GB
    case USER_PROPERTIES_STORAGE_USED = "storage_used" // % of storage used
    case USER_PROPERTIES_AUTO_UPLOAD = "auto_upload_on"
    case USER_PROPERTIES_APP_VERSION = "app_version"
    case EVENT__ACTION_BUTTON = "action_button_clicked" // when user clicks on fab + button
    case EVENT__UPLOAD_FILE = "upload_file" // when user uploads any file (not applicable for folder) from other apps
    case EVENT__CREATE_FILE = "create_file" // when user creates any file in app
    case EVENT__CREATE_FOLDER = "create_folder"
    case EVENT__ADD_FAVORITE = "add_favorite"
    case EVENT__SHARE_FILE = "share_file" // when user share any file using link
    case EVENT__OFFLINE_AVAILABLE = "offline_available"
    case EVENT__PIN_TO_HOME_SCREEN = "pin_to_homescreen"
    case EVENT__ONLINE_OFFICE_USED = "online_office_used" // when user opens any office files
    
    // screen view events when user open specific screen
    case SCREEN_EVENT__FAVOURITES = "favorites"
    case SCREEN_EVENT__MEDIA = "medien"
    case SCREEN_EVENT__OFFLINE_FILES = "offline_files"
    case SCREEN_EVENT__SHARED = "shared"
    case SCREEN_EVENT__DELETED_FILES = "deleted_files"
    case SCREEN_EVENT__NOTIFICATIONS = "notifications"

    var moEngageEvent: String {
        switch self {
        default:
            return self.rawValue
        }
    }
    
    var teliumEvent: String {
        return self.rawValue
    }
    
    var adjustEvent: String {
        return self.rawValue
    }
}

enum AnalyticPropertyAttributes: String {
    // properties attributes key
    case PROPERTIES__FILE_TYPE = "file_type"
    case PROPERTIES__FOLDER_TYPE = "folder_type"
    case PROPERTIES__FILE_SIZE = "file_size" // in MB
    case PROPERTIES__CREATION_DATE = "creation_date" // yyyy-MM-dd
    case PROPERTIES__UPLOAD_DATE = "upload_date" // // yyyy-MM-dd
}
