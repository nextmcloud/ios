// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2014 Marino Faggiana [Start 04/09/14]
// SPDX-FileCopyrightText: 2021 Marino Faggiana [Swift 19/02/21]
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import BackgroundTasks
import NextcloudKit
import LocalAuthentication
import Firebase
import WidgetKit
import Queuer
import EasyTipView
import SwiftUI
import RealmSwift
import MoEngageInApps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var backgroundSessionCompletionHandler: (() -> Void)?
    var activeLogin: NCLogin?
    var activeLoginWeb: NCLoginWeb?
    var taskAutoUploadDate: Date = Date()
    var orientationLock = UIInterfaceOrientationMask.all
    @objc let adjust = AdjustHelper()
    var isUiTestingEnabled: Bool {
        return ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    var notificationSettings: UNNotificationSettings?
    var pushKitToken: String?

    var loginFlowV2Token = ""
    var loginFlowV2Endpoint = ""
    var loginFlowV2Login = ""

    let backgroundQueue = DispatchQueue(label: "com.nextcloud.bgTaskQueue")
    let global = NCGlobal.shared

    var pushSubscriptionTask: Task<Void, Never>?

    let database = NCManageDatabase.shared
    var window: UIWindow?
    @objc var sceneIdentifier: String = ""
    @objc var activeViewController: UIViewController?
    @objc var account: String = ""
    @objc var urlBase: String = ""
    @objc var user: String = ""
    @objc var userId: String = ""
    @objc var password: String = ""
    var timerErrorNetworking: Timer?
    var tipView: EasyTipView?

    var pushSubscriptionTask: Task<Void, Never>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if isUiTestingEnabled {
            Task {
                await NCAccount().deleteAllAccounts()
            }
        }
        
        UINavigationBar.appearance().tintColor = NCBrandColor.shared.customer
        UIToolbar.appearance().tintColor = NCBrandColor.shared.customer
        
        let utilityFileSystem = NCUtilityFileSystem()
        let utility = NCUtility()

        utilityFileSystem.createDirectoryStandard()
        utilityFileSystem.emptyTemporaryDirectory()
        utilityFileSystem.clearCacheDirectory("com.limit-point.LivePhoto")

        let versionNextcloudiOS = String(format: NCBrandOptions.shared.textCopyrightNextcloudiOS, utility.getVersionBuild())

        NCAppVersionManager.shared.checkAndUpdateInstallState()
        NCSettingsBundleHelper.checkAndExecuteSettings(delay: 0)

        UserDefaults.standard.register(defaults: ["UserAgent": userAgent])

        #if !DEBUG
        if !NCPreferences().disableCrashservice, !NCBrandOptions.shared.disable_crash_service {
            FirebaseApp.configure()
        }
        #endif

        NCBrandColor.shared.createUserColors()
        NCImageCache.shared.createImagesCache()

        NextcloudKit.shared.setup(groupIdentifier: NCBrandOptions.shared.capabilitiesGroup,
                                  delegate: NCNetworking.shared)

        NextcloudKit.configureLogger(logLevel: (NCBrandOptions.shared.disable_log ? .disabled : NCPreferences().log))

        #if DEBUG
//      For the tags look NCGlobal LOG TAG

//      var black: [String] = []
//      black.append("NETWORKING TASKS")
//      NextcloudKit.configureLoggerBlacklist(blacklist: black)

//      var white: [String] = []
//      white.append("SYNC METADATA")
//      NextcloudKit.configureLoggerWhitelist(whitelist: white)
        #endif

        nkLog(start: "Start session with level \(NCPreferences().log) " + versionNextcloudiOS)

//        if NCBrandOptions.shared.disable_log {
//            utilityFileSystem.removeFile(atPath: NextcloudKit.shared.nkCommonInstance.filenamePathLog)
//            utilityFileSystem.removeFile(atPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + NextcloudKit.shared.nkCommonInstance.filenameLog)
//        } else {
//            NextcloudKit.shared.setupLog(pathLog: utilityFileSystem.directoryGroup,
//                                         levelLog: NCKeychain().logLevel,
//                                         copyLogToDocumentDirectory: true)
//            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Start session with level \(NCKeychain().logLevel) " + versionNextcloudiOS)
//        }
        
        // Push Notification & display notification
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.notificationSettings = settings
        }
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }

#if !targetEnvironment(simulator)
        let review = NCStoreReview()
        review.incrementAppRuns()
        review.showStoreReview()
#endif

        // BACKGROUND TASK
        //
        BGTaskScheduler.shared.register(forTaskWithIdentifier: global.refreshTask, using: backgroundQueue) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAppRefresh(appRefreshTask)
        }
        scheduleAppRefresh()

        BGTaskScheduler.shared.register(forTaskWithIdentifier: global.processingTask, using: backgroundQueue) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleProcessingTask(processingTask)
        }
        scheduleAppProcessing()

        if NCBrandOptions.shared.enforce_passcode_lock {
            NCPreferences().requestPasscodeAtStart = true
        }

        /// Activation singleton
        _ = NCAppStateManager.shared
        _ = NCNetworking.shared
        _ = NCDownloadAction.shared
        _ = NCNetworkingProcess.shared
        _ = NCTransferProgress.shared
        _ = NCActionCenter.shared
        
        NCTransferProgress.shared.setup()
        NCActionCenter.shared.setup()
        
//        if account.isEmpty {
//            if NCBrandOptions.shared.disable_intro {
//                openLogin(viewController: nil, selector: NCGlobal.shared.introLogin, openLoginWeb: false)
//            } else {
//                if let viewController = UIStoryboard(name: "NCIntro", bundle: nil).instantiateInitialViewController() {
//                    let navigationController = NCLoginNavigationController(rootViewController: viewController)
//                    window?.rootViewController = navigationController
//                    window?.makeKeyAndVisible()
//                }
//            }
//        } else {
//            NCPasscode.shared.presentPasscode(delegate: self) {
//                NCPasscode.shared.enableTouchFaceID()
//            }
//        }
        adjust.configAdjust()
        adjust.subsessionStart()
        TealiumHelper.shared.start()
        FirebaseApp.configure()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if self.notificationSettings?.authorizationStatus != .denied && UIApplication.shared.backgroundRefreshStatus == .available {
            let content = UNMutableNotificationContent()
            content.title = NCBrandOptions.shared.brand
            content.body = NSLocalizedString("_keep_running_", comment: "")
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(req)
        }

        nkLog(debug: "bye bye")
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Background Task

    /*
    @discussion Schedule a refresh task request to ask that the system launch your app briefly so that you can download data and keep your app's contents up-to-date. The system will fulfill this request intelligently based on system conditions and app usage.
     */
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: global.refreshTask)

        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Refresh after 60 seconds.

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            nkLog(tag: self.global.logTagTask, emoji: .error, message: "Refresh task failed to submit request: \(error)")
        }
    }

    /*
     @discussion Schedule a processing task request to ask that the system launch your app when conditions are favorable for battery life to handle deferrable, longer-running processing, such as syncing, database maintenance, or similar tasks. The system will attempt to fulfill this request to the best of its ability within the next two days as long as the user has used your app within the past week.
     */
    func scheduleAppProcessing() {
        let request = BGProcessingTaskRequest(identifier: global.processingTask)

        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // Refresh after 5 minutes.
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            nkLog(tag: self.global.logTagTask, emoji: .error, message: "Processing task failed to submit request: \(error)")
        }
    }

    func handleAppRefresh(_ task: BGAppRefreshTask) {
        nkLog(tag: self.global.logTagTask, emoji: .start, message: "Start refresh task")
        guard NCManageDatabase.shared.openRealmBackground() else {
            nkLog(tag: self.global.logTagTask, emoji: .error, message: "Failed to open Realm in background")
            task.setTaskCompleted(success: false)
            return
        }

        // Schedule next refresh
        scheduleAppRefresh()

        Task {
            defer {
                task.setTaskCompleted(success: true)
            }

            await backgroundSync(task: task)
        }
    }

    func handleProcessingTask(_ task: BGProcessingTask) {
        nkLog(tag: self.global.logTagTask, emoji: .start, message: "Start processing task")
        guard NCManageDatabase.shared.openRealmBackground() else {
            nkLog(tag: self.global.logTagTask, emoji: .error, message: "Failed to open Realm in background")
            task.setTaskCompleted(success: false)
            return
        }

        // Schedule next processing task
        scheduleAppProcessing()

       Task {
           defer {
               task.setTaskCompleted(success: true)
           }

           await backgroundSync(task: task)
       }
    }

    func backgroundSync(task: BGTask? = nil) async {
        // BGTask expiration flag
        var expired = false
        task?.expirationHandler = {
            expired = true
        }

        // Discover new items for Auto Upload
        let numAutoUpload = await NCAutoUpload.shared.initAutoUpload()
        nkLog(tag: self.global.logTagBgSync, emoji: .start, message: "Auto upload found \(numAutoUpload) new items")
        guard !expired else {
            return
        }

        // Fetch pending metadatas (bounded set)
        guard let allMetadatas = await NCManageDatabase.shared.getMetadatasAsync(
            predicate: NSPredicate(format: "status != %d", self.global.metadataStatusNormal),
            withSort: [RealmSwift.SortDescriptor(keyPath: "sessionDate", ascending: true)],
            withLimit: NCBrandOptions.shared.numMaximumProcess),
                !allMetadatas.isEmpty,
                !expired else {
            return
        }

        // Create all pending Auto Upload folders (fail-fast)
        let pendingCreateFolders = allMetadatas.lazy.filter {
            $0.status == self.global.metadataStatusWaitCreateFolder &&
            $0.sessionSelector == self.global.selectorUploadAutoUpload
        }

        for metadata in pendingCreateFolders {
            guard !expired else {
                return
            }
            let err = await NCNetworking.shared.createFolderForAutoUpload(
                serverUrlFileName: metadata.serverUrlFileName,
                account: metadata.account
            )
            // Fail-fast: abort the whole sync on first failure
            if err != .success {
                nkLog(tag: self.global.logTagBgSync, emoji: .error, message: "Create folder '\(metadata.serverUrlFileName)' failed: \(err.errorCode) – aborting sync")
                return
            }
        }

        // Capacity computation
        let downloading = allMetadatas.lazy.filter { $0.status == self.global.metadataStatusDownloading }.count
        let uploading   = allMetadatas.lazy.filter { $0.status == self.global.metadataStatusUploading }.count
        let used        = downloading + uploading
        let maximum     = NCBrandOptions.shared.numMaximumProcess
        let available   = max(0, maximum - used)

        // Only inject more work if overall utilization <= 20%
        let utilization = Double(used) / Double(maximum)
        guard !expired,
              available > 0,
              utilization <= 0.20 else {
            return
        }

        // Start Auto Uploads (cap by available slots)
        let metadatasToUpload = Array(
            allMetadatas.lazy.filter {
                $0.status == self.global.metadataStatusWaitUpload &&
                $0.sessionSelector == self.global.selectorUploadAutoUpload &&
                $0.chunk == 0
            }
            .prefix(available)
        )

        let cameraRoll = NCCameraRoll()
        for metadata in metadatasToUpload {
            guard !expired else {
                return
            }
            // Expand seed into concrete metadatas (e.g., Live Photo pair)
            let extracted = await cameraRoll.extractCameraRoll(from: metadata)

            for metadata in extracted {
                // Sequential await keeps ordering and simplifies backpressure
                let err = await NCNetworking.shared.uploadFileInBackground(metadata: metadata.detachedCopy())
                if err == .success {
                    nkLog(tag: self.global.logTagBgSync, message: "Queued upload \(metadata.fileName) -> \(metadata.serverUrl)")
                } else {
                    nkLog(tag: self.global.logTagBgSync, emoji: .error, message: "Upload failed \(metadata.fileName) -> \(metadata.serverUrl) [\(err.errorDescription)]")
                }
            }
        }
    }
    
//    func handleAppRefreshProcessingTask(taskText: String, completion: @escaping () -> Void = {}) {
//        Task {
//            var numAutoUpload = 0
//            guard let account = NCManageDatabase.shared.getActiveTableAccount()?.account else {
//                return
//            }
//
//            NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) start handle")
//
//            // Test every > 1 min
//            if Date() > self.taskAutoUploadDate.addingTimeInterval(60) {
//                self.taskAutoUploadDate = Date()
//                numAutoUpload = await NCAutoUpload.shared.initAutoUpload(account: account)
//                NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) auto upload with \(numAutoUpload) uploads")
//            } else {
//                NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) disabled auto upload")
//            }
//
//            let results = await NCNetworkingProcess.shared.refreshProcessingTask()
//            NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) networking process with download: \(results.counterDownloading) upload: \(results.counterUploading)")
//
//            if taskText == "ProcessingTask",
//               numAutoUpload == 0,
//               results.counterDownloading == 0,
//               results.counterUploading == 0,
//               let directories = NCManageDatabase.shared.getTablesDirectory(predicate: NSPredicate(format: "account == %@ AND offline == true", account), sorted: "offlineDate", ascending: true) {
//                for directory: tableDirectory in directories {
//                    // test only 3 time for day (every 8 h.)
//                    if let offlineDate = directory.offlineDate, offlineDate.addingTimeInterval(28800) > Date() {
//                        NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) skip synchronization for \(directory.serverUrl) in date \(offlineDate)")
//                        continue
//                    }
//                    let results = await NCNetworking.shared.synchronization(account: account, serverUrl: directory.serverUrl, add: false)
//                    NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) end synchronization for \(directory.serverUrl), errorCode: \(results.errorCode), item: \(results.num)")
//                }
//            }
//
//            let counter = NCManageDatabase.shared.getResultsMetadatas(predicate: NSPredicate(format: "account == %@ AND (session == %@ || session == %@) AND status != %d",
//                                                                                   account,
//                                                                                   NCNetworking.shared.sessionDownloadBackground,
//                                                                                   NCNetworking.shared.sessionUploadBackground,
//                                                                                   NCGlobal.shared.metadataStatusNormal))?.count ?? 0
//            UIApplication.shared.applicationIconBadgeNumber = counter
//
//            NextcloudKit.shared.nkCommonInstance.writeLog("[DEBUG] \(taskText) completion handle")
//            completion()
//        }
//    }

    // MARK: - Background Networking Session

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        nkLog(debug: "Handle events For background URLSession: \(identifier)")

        backgroundSessionCompletionHandler = completionHandler
    }

    // MARK: - Push Notifications

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let pref = UserDefaults(suiteName: NCBrandOptions.shared.capabilitiesGroup),
           let data = pref.object(forKey: "NOTIFICATION_DATA") as? [String: AnyObject] {
            nextcloudPushNotificationAction(data: data)
            pref.set(nil, forKey: "NOTIFICATION_DATA")
        }

        completionHandler()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let deviceToken = NCPushNotificationEncryption.shared().string(withDeviceToken: deviceToken) {
            NCPreferences().deviceTokenPushNotification = deviceToken
            pushSubscriptionTask = Task.detached {
                // Wait bounded time for maintenance to be OFF
                let canProceed = await NCAppStateManager.shared.waitForMaintenanceOffAsync()
                guard canProceed else {
                    nkLog(error: "[PUSH] Skipping subscription: maintenance mode still ON after timeout")
                    return
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)

                let tblAccounts = await NCManageDatabase.shared.getAllTableAccountAsync()
                for tblAccount in tblAccounts {
                    await NCPushNotification.shared.subscribingNextcloudServerPushNotification(account: tblAccount.account, urlBase: tblAccount.urlBase)
                }
            }
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NCPushNotification.shared.applicationdidReceiveRemoteNotification(userInfo: userInfo) { result in
            completionHandler(result)
        }
    }

    func subscribingPushNotification(account: String, urlBase: String, user: String) {
    #if !targetEnvironment(simulator)
            NCNetworking.shared.checkPushNotificationServerProxyCertificateUntrusted(viewController: UIApplication.shared.firstWindow?.rootViewController) { error in
                if error == .success {
                    NCPushNotification.shared.subscribingNextcloudServerPushNotification(account: account, urlBase: urlBase, user: user, pushKitToken: self.pushKitToken)
                }
            }
    #endif
        }
    
    func nextcloudPushNotificationAction(data: [String: AnyObject]) {
        guard let data = NCApplicationHandle().nextcloudPushNotificationAction(data: data)
        else {
            return
        }
        let account = data["account"] as? String ?? "unavailable"
        let app = data["app"] as? String

        func openNotification(controller: NCMainTabBarController) {
            if app == NCGlobal.shared.termsOfServiceName {
                Task {
                    await NCNetworking.shared.transferDispatcher.notifyAllDelegatesAsync { delegate in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        delegate.transferRequestData(serverUrl: nil)
                    }
                }
            } else if let navigationController = UIStoryboard(name: "NCNotification", bundle: nil).instantiateInitialViewController() as? UINavigationController,
                      let viewController = navigationController.topViewController as? NCNotification {
                viewController.modalPresentationStyle = .pageSheet
                viewController.session = NCSession.shared.getSession(account: account)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    controller.present(navigationController, animated: true, completion: nil)
                }
            }
        }

        if let controller = SceneManager.shared.getControllers().first(where: { $0.account == account }) {
            openNotification(controller: controller)
        } else if let tblAccount = NCManageDatabase.shared.getAllTableAccount().first(where: { $0.account == account }),
                  let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController {
            Task { @MainActor in
                await NCAccount().changeAccount(tblAccount.account, userProfile: nil, controller: controller)
                openNotification(controller: controller)
            }
        } else {
            let message = NSLocalizedString("_the_account_", comment: "") + " " + account + " " + NSLocalizedString("_does_not_exist_", comment: "")
            let alertController = UIAlertController(title: NSLocalizedString("_info_", comment: ""), message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
            UIApplication.shared.firstWindow?.rootViewController?.present(alertController, animated: true, completion: { })
        }
    }

    // MARK: - Login

    func openLogin(selector: Int, window: UIWindow? = nil) {
        UIApplication.shared.allSceneSessionDestructionExceptFirst()

//        func showLoginViewController(_ viewController: UIViewController?) {
//            guard let viewController else { return }
//            let navigationController = NCLoginNavigationController(rootViewController: viewController)
//
//            navigationController.modalPresentationStyle = .fullScreen
//            navigationController.navigationBar.barStyle = .black
//            navigationController.navigationBar.tintColor = NCBrandColor.shared.customerText
//            navigationController.navigationBar.barTintColor = NCBrandColor.shared.customer
//            navigationController.navigationBar.isTranslucent = false
//
//            if let controller = UIApplication.shared.firstWindow?.rootViewController {
//                if let presentedVC = controller.presentedViewController, !(presentedVC is NCLoginNavigationController) {
//                    presentedVC.dismiss(animated: false) {
//                        controller.present(navigationController, animated: true)
//                    }
//                } else {
//                    controller.present(navigationController, animated: true)
//                }
//            } else {
//                window?.rootViewController = navigationController
//                window?.makeKeyAndVisible()
//            }
//        }

        // Nextcloud standard login
        if selector == NCGlobal.shared.introSignup {
            if activeLogin?.view.window == nil {
                if selector == NCGlobal.shared.introSignup {
                    let web = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginProvider") as? NCLoginProvider
                    web?.urlBase = NCBrandOptions.shared.linkloginPreferredProviders
                    showLoginViewController(web)
                } else {
                    activeLogin = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin
                    if let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController, !controller.account.isEmpty {
                        let session = NCSession.shared.getSession(account: controller.account)
                        activeLogin?.urlBase = session.urlBase
                    }
                    showLoginViewController(activeLogin)
                }
            }
        } else {
            if activeLogin?.view.window == nil {
                activeLogin = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin
                activeLogin?.urlBase = NCBrandOptions.shared.disable_request_login_url ? NCBrandOptions.shared.loginBaseUrl : ""
                showLoginViewController(activeLogin)
            }
        }
    }

    @objc func openLogin(viewController: UIViewController?, selector: Int, openLoginWeb: Bool) {
//        openLogin(selector: NCGlobal.shared.introLogin)
        // [WEBPersonalized] [AppConfig]
        if NCBrandOptions.shared.use_login_web_personalized || NCBrandOptions.shared.use_AppConfig {

            if activeLoginWeb?.view.window == nil {
                activeLoginWeb = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginWeb") as? NCLoginWeb
                activeLoginWeb?.urlBase = NCBrandOptions.shared.loginBaseUrl
                showLoginViewController(activeLoginWeb, contextViewController: viewController)
            }
            return
        }

        // Nextcloud standard login
        if selector == NCGlobal.shared.introSignup {

            if activeLoginWeb?.view.window == nil {
                activeLoginWeb = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginWeb") as? NCLoginWeb
                if selector == NCGlobal.shared.introSignup {
                    activeLoginWeb?.urlBase = NCBrandOptions.shared.linkloginPreferredProviders
                } else {
                    activeLoginWeb?.urlBase = self.urlBase
                }
                showLoginViewController(activeLoginWeb, contextViewController: viewController)
            }

        } else if NCBrandOptions.shared.disable_intro && NCBrandOptions.shared.disable_request_login_url {

            if activeLoginWeb?.view.window == nil {
                activeLoginWeb = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginWeb") as? NCLoginWeb
                activeLoginWeb?.urlBase = NCBrandOptions.shared.loginBaseUrl
                showLoginViewController(activeLoginWeb, contextViewController: viewController)
            }

        } else if openLoginWeb {

            // Used also for reinsert the account (change passwd)
            if activeLoginWeb?.view.window == nil {
                activeLoginWeb = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginWeb") as? NCLoginWeb
                activeLoginWeb?.urlBase = urlBase
                activeLoginWeb?.user = user
                showLoginViewController(activeLoginWeb, contextViewController: viewController)
            }

        } else {

            if activeLogin?.view.window == nil {
                activeLogin = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin
                showLoginViewController(activeLogin, contextViewController: viewController)
            }
        }
    }
    
    func showLoginViewController(_ viewController: UIViewController?) {
        guard let viewController else { return }
        let navigationController = NCLoginNavigationController(rootViewController: viewController)

        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.tintColor = NCBrandColor.shared.customerText
        navigationController.navigationBar.barTintColor = NCBrandColor.shared.customer
        navigationController.navigationBar.isTranslucent = false

        if let controller = UIApplication.shared.firstWindow?.rootViewController {
            if let presentedVC = controller.presentedViewController, !(presentedVC is NCLoginNavigationController) {
                presentedVC.dismiss(animated: false) {
                    controller.present(navigationController, animated: true)
                }
            } else {
                controller.present(navigationController, animated: true)
            }
        } else {
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        }
    }
    
    func showLoginViewController(_ viewController: UIViewController?, contextViewController: UIViewController?) {

        if contextViewController == nil {
            if let viewController = viewController {
                let navigationController = NCLoginNavigationController(rootViewController: viewController)
                navigationController.navigationBar.barStyle = .black
                navigationController.navigationBar.tintColor = NCBrandColor.shared.customerText
                navigationController.navigationBar.barTintColor = NCBrandColor.shared.customer
                navigationController.navigationBar.isTranslucent = false
                window?.rootViewController = navigationController
                window?.makeKeyAndVisible()
            }
        } else if contextViewController is UINavigationController {
            if let contextViewController = contextViewController, let viewController = viewController {
                (contextViewController as? UINavigationController)?.pushViewController(viewController, animated: true)
            }
        } else {
            if let viewController = viewController, let contextViewController = contextViewController {
                let navigationController = NCLoginNavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .fullScreen
                navigationController.navigationBar.barStyle = .black
                navigationController.navigationBar.tintColor = NCBrandColor.shared.customerText
                navigationController.navigationBar.barTintColor = NCBrandColor.shared.customer
                navigationController.navigationBar.isTranslucent = false
                contextViewController.present(navigationController, animated: true) { }
            }
        }
    }
    
    @objc func startTimerErrorNetworking() {
        timerErrorNetworking = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(checkErrorNetworking), userInfo: nil, repeats: true)
    }

    @objc private func checkErrorNetworking() {
        guard !account.isEmpty, NCKeychain().getPassword(account: account).isEmpty else { return }
        openLogin(viewController: window?.rootViewController, selector: NCGlobal.shared.introLogin, openLoginWeb: true)
    }
    
    // MARK: -

    func trustCertificateError(host: String) {
        guard let activeTblAccount = NCManageDatabase.shared.getActiveTableAccount(),
              let currentHost = URL(string: activeTblAccount.urlBase)?.host,
              let pushNotificationServerProxyHost = URL(string: NCBrandOptions.shared.pushNotificationServerProxy)?.host,
              host != pushNotificationServerProxyHost,
              host == currentHost
        else { return }
        let certificateHostSavedPath = NCUtilityFileSystem().directoryCertificates + "/" + host + ".der"
        var title = NSLocalizedString("_ssl_certificate_changed_", comment: "")

        if !FileManager.default.fileExists(atPath: certificateHostSavedPath) {
            title = NSLocalizedString("_connect_server_anyway_", comment: "")
        }

        let alertController = UIAlertController(title: title, message: NSLocalizedString("_server_is_trusted_", comment: ""), preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_yes_", comment: ""), style: .default, handler: { _ in
            NCNetworking.shared.writeCertificate(host: host)
        }))

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_no_", comment: ""), style: .default, handler: { _ in }))

        alertController.addAction(UIAlertAction(title: NSLocalizedString("_certificate_details_", comment: ""), style: .default, handler: { _ in
            if let navigationController = UIStoryboard(name: "NCViewCertificateDetails", bundle: nil).instantiateInitialViewController() as? UINavigationController,
               let viewController = navigationController.topViewController as? NCViewCertificateDetails {
                viewController.delegate = self
                viewController.host = host
                UIApplication.shared.firstWindow?.rootViewController?.present(navigationController, animated: true)
            }
        }))

        UIApplication.shared.firstWindow?.rootViewController?.present(alertController, animated: true)
    }
    
    // MARK: - Account

    @objc func changeAccount(_ account: String, userProfile: NKUserProfile?) {
//        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeUser)
    }

    @objc func deleteAccount(_ account: String, wipe: Bool) {
        NCAccount().deleteAccount(account, wipe: wipe)
    }

    func deleteAllAccounts() {
        let accounts = NCManageDatabase.shared.getAccounts()
        accounts?.forEach({ account in
            deleteAccount(account, wipe: true)
        })
    }

    func updateShareAccounts() -> Error? {
        return NCAccount().updateAppsShareAccounts()
    }

    // MARK: - Reset Application

    @objc func resetApplication() {
        let utilityFileSystem = NCUtilityFileSystem()

        NCNetworking.shared.cancelAllTask()

        URLCache.shared.removeAllCachedResponses()

        utilityFileSystem.removeGroupDirectoryProviderStorage()
        utilityFileSystem.removeGroupApplicationSupport()
        utilityFileSystem.removeDocumentsDirectory()
        utilityFileSystem.removeTemporaryDirectory()

        NCPreferences().removeAll()
//        NCKeychain().removeAll()
//        NCNetworking.shared.removeAllKeyUserDefaultsData(account: nil)

        exit(0)
    }

    // MARK: - Universal Links

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let applicationHandle = NCApplicationHandle()
        return applicationHandle.applicationOpenUserActivity(userActivity)
    }
}

// MARK: - Extension

extension AppDelegate: NCViewCertificateDetailsDelegate {
    func viewCertificateDetailsDismiss(host: String) {
        trustCertificateError(host: host)
    }
}

extension AppDelegate: NCCreateFormUploadConflictDelegate {
    func dismissCreateFormUploadConflict(metadatas: [tableMetadata]?) {
        if let metadatas {
            Task {
                await NCManageDatabase.shared.addMetadatasAsync(metadatas)
            }
        }
    }
}

//MARK: NMC Customisation
extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
}
