//
//  AppUpdater.swift
//  Nextcloud
//
//  Created by Amrut Waghmare on 09/10/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

struct AppUpdaterKey {
    static let lastUpdateCheckDate : String = "lastUpdateCheckDate"
}

class AppUpdater {
    func checkForUpdate() {
        checkUpdate{ (version, isForceupdate) in
            DispatchQueue.main.async {
                if let version = version, let isForceupdate = isForceupdate {
                    if (isForceupdate) {
                        self.showUpdateAlert(version: version, isForceUpdate: isForceupdate)
                    } else {
                        if self.checkLastUpdate() {
                            self.showUpdateAlert(version: version, isForceUpdate: isForceupdate)
                        }
                    }
                }
            }
        }
    }
    
    func showUpdateAlert(version: String, isForceUpdate: Bool){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let viewControlller = appDelegate.window?.rootViewController else { return }
        let descriptionMsg = String(format: NSLocalizedString("update_description", comment: ""), version)
        let alert = UIAlertController(title: NSLocalizedString("update_available", comment: ""), message: descriptionMsg, preferredStyle: .alert)
        let updateAction = UIAlertAction(title: NSLocalizedString("update", comment: ""), style: .default, handler: { action in
            guard let url = URL(string: NCBrandOptions.shared.appStoreUrl) else { return }
            UIApplication.shared.open(url)
        })
        alert.addAction(updateAction)
        if !isForceUpdate {
            alert.addAction(UIAlertAction(title: NSLocalizedString("not_now", comment: ""), style: .default, handler: { action in
                self.saveAppUpdateCheckDate()
            }))
        }
        alert.preferredAction = updateAction
        viewControlller.present(alert, animated: true, completion: {})
    }
    
    func checkLastUpdate() -> Bool {
        if let lastUpdateCheckDate = UserDefaults.standard.object(forKey: AppUpdaterKey.lastUpdateCheckDate) as? Date {
            return daysBetweenDate(from: lastUpdateCheckDate) > 7
        } else {
            return true
        }
    }
    
    func checkUpdate(completion: @escaping (String?, Bool?) -> Void)  {
        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.fetch(withExpirationDuration: 1) { (status, error) in
            if status == .success {
                remoteConfig.activate { value, error in
                    // Remote config values fetched successfully
                    let iOSVersion = remoteConfig["ios_app_version"].stringValue ?? "default_value"
                    let isForcheUpdate = remoteConfig["ios_force_update"].boolValue
                    if let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        if iOSVersion != currentVersion {
                            // There is an update available
                            completion(iOSVersion,isForcheUpdate)
                        } else {
                            completion(nil, nil)
                        }
                    }
                }
            } else {
                // Handle error
                print("Error fetching remote config: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
            }
        }
    }
    
    func saveAppUpdateCheckDate() {
        UserDefaults.standard.setValue(Date(), forKey: AppUpdaterKey.lastUpdateCheckDate)
    }
    
    func daysBetweenDate(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}
