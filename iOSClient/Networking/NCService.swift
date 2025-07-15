//
//  NCService.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/03/18.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
@preconcurrency import NextcloudKit
import RealmSwift
import SVGKit

class NCService: NSObject {
    let utilityFileSystem = NCUtilityFileSystem()
    let utility = NCUtility()
    let database = NCManageDatabase.shared

    // MARK: -

    public func startRequestServicesServer(account: String, controller: NCMainTabBarController?) {
        guard !account.isEmpty
        else {
            return
        }

        self.database.clearAllAvatarLoaded()
        self.addInternalTypeIdentifier(account: account)

        Task(priority: .background) {
            let result = await requestServerStatus(account: account, controller: controller)
            if result {
                requestServerCapabilities(account: account, controller: controller)
                getAvatar(account: account)
                NCNetworkingE2EE().unlockAll(account: account)
                sendClientDiagnosticsRemoteOperation(account: account)
                synchronize(account: account)
        Task(priority: .utility) {
            await self.database.clearAllAvatarLoadedAsync()
            let result = await requestServerStatus(account: account, controller: controller)
            if result {
                await requestServerCapabilities(account: account, controller: controller)
                await getAvatar(account: account)
                await NCNetworkingE2EE().unlockAll(account: account)
                await sendClientDiagnosticsRemoteOperation(account: account)
                await synchronize(account: account)
                await requestDashboardWidget(account: account)
            }
        }
    }

    // MARK: -

    private func requestServerStatus(account: String, controller: NCMainTabBarController?) async -> Bool {
        let serverUrl = NCSession.shared.getSession(account: account).urlBase
        switch await NCNetworking.shared.getServerStatus(serverUrl: serverUrl, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) {
        case .success(let serverInfo):
            if serverInfo.maintenance {
                return false
            } else if serverInfo.productName.lowercased().contains("owncloud") {
                let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_warning_owncloud_")
                NCContentPresenter().showWarning(error: error, priority: .max)
                return false
            } else if serverInfo.versionMajor <= NCGlobal.shared.nextcloud_unsupported_version {
                let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_warning_unsupported_")
                NCContentPresenter().showWarning(error: error, priority: .max)
            }
        case .failure:
            return false
        }

        let resultUserProfile = await NCNetworking.shared.getUserProfile(account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue))
        if resultUserProfile.error == .success,
           let userProfile = resultUserProfile.userProfile {
            self.database.setAccountUserProfile(account: resultUserProfile.account, userProfile: userProfile)
           let userProfile = resultUserProfile.userProfile,
           userId == userProfile.userId {
            await self.database.setAccountUserProfileAsync(account: resultUserProfile.account, userProfile: userProfile)
            return true
        } else {
            return false
        }
    }

    func synchronize(account: String) {
        NextcloudKit.shared.listingFavorites(showHiddenFiles: NCKeychain().showHiddenFiles,
                                             account: account,
                                             options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { account, files, _, error in
            guard error == .success, let files else { return }
            self.database.convertFilesToMetadatas(files, useFirstAsMetadataFolder: false) { _, metadatas in
                self.database.updateMetadatasFavorite(account: account, metadatas: metadatas)
            }
            NextcloudKit.shared.nkCommonInstance.writeLog("[INFO] Synchronize Favorite")
            self.synchronizeOffline(account: account)
        }
    }

    func getAvatar(account: String) {
        let session = NCSession.shared.getSession(account: account)
        let fileName = NCSession.shared.getFileName(urlBase: session.urlBase, user: session.user)
        let etag = self.database.getTableAvatar(fileName: fileName)?.etag

        NextcloudKit.shared.downloadAvatar(user: session.userId,
                                           fileNameLocalPath: utilityFileSystem.directoryUserData + "/" + fileName,
                                           sizeImage: NCGlobal.shared.avatarSize,
                                           avatarSizeRounded: NCGlobal.shared.avatarSizeRounded,
                                           etag: etag,
                                           account: account,
                                           options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { _, _, _, newEtag, _, error in
            if let newEtag,
               etag != newEtag,
               error == .success {
                self.database.addAvatar(fileName: fileName, etag: newEtag)

                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadAvatar, userInfo: ["error": error])
            } else if error.errorCode == NCGlobal.shared.errorNotModified {
                self.database.setAvatarLoaded(fileName: fileName)
            }
        }
    }

    private func requestServerCapabilities(account: String, controller: NCMainTabBarController?) {
        let session = NCSession.shared.getSession(account: account)
        NextcloudKit.shared.getCapabilities(account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { account, presponseData, error in
            guard error == .success, let data = presponseData?.data else {
                NCBrandColor.shared.settingThemingColor(account: account)
                NCImageCache.shared.createImagesBrandCache()
                return
            }

            data.printJson()

            self.database.addCapabilitiesJSon(data, account: account)

            guard let capability = self.database.setCapabilities(account: account, data: data) else {
                return
            }

            // Recommendations
            if NCCapabilities.shared.getCapabilities(account: account).capabilityRecommendations {
                Task.detached {
                    let session = NCSession.shared.getSession(account: account)
                    await NCNetworking.shared.createRecommendations(session: session)
                }
            } else {
                self.database.deleteAllRecommendedFiles(account: account)
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadHeader, userInfo: ["account": account])
            }

            // Theming
            if NCBrandColor.shared.settingThemingColor(account: account) {
                NCImageCache.shared.createImagesBrandCache()
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming, userInfo: ["account": account])
            }
            
            // File Sharing
            if NCGlobal.shared.capabilityFileSharingApiEnabled {
                let home = self.utilityFileSystem.getHomeServer(urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId)
                NextcloudKit.shared.readShares(parameters: NKShareParameter()) { account, shares, data, error in
                    if error == .success {
                        NCManageDatabase.shared.deleteTableShare(account: account)
                        if let shares = shares, !shares.isEmpty {
                            NCManageDatabase.shared.addShare(account: account, home: home, shares: shares)
                            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
                        }
                    }
                }
            }
            
            // File Sharing
            if NCGlobal.shared.capabilityFileSharingApiEnabled {
                let home = self.utilityFileSystem.getHomeServer(urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId)
                NextcloudKit.shared.readShares(parameters: NKShareParameter()) { account, shares, data, error in
                    if error == .success {
                        NCManageDatabase.shared.deleteTableShare(account: account)
                        if let shares = shares, !shares.isEmpty {
                            NCManageDatabase.shared.addShare(account: account, home: home, shares: shares)
                            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
                        }
                    }
                }
            }
            
            // File Sharing
            if NCGlobal.shared.capabilityFileSharingApiEnabled {
                let home = self.utilityFileSystem.getHomeServer(urlBase: self.appDelegate.urlBase, userId: self.appDelegate.userId)
                let home = self.utilityFileSystem.getHomeServer(session: session)
                NextcloudKit.shared.readShares(parameters: NKShareParameter()) { account, shares, data, error in
                    if error == .success {
                        NCManageDatabase.shared.deleteTableShare(account: account)
                        if let shares = shares, !shares.isEmpty {
                            NCManageDatabase.shared.addShare(account: account, home: home, shares: shares)
                            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
                        }
                    }
                }
            }

            // Text direct editor detail
            if capability.capabilityServerVersionMajor >= NCGlobal.shared.nextcloudVersion18 {
                let options = NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)
                NextcloudKit.shared.NCTextObtainEditorDetails(account: account, options: options) { account, editors, creators, _, error in
                    if error == .success {
                        self.database.addDirectEditing(account: account, editors: editors, creators: creators)
                    }
                }
            }

            // External file Server
            if capability.capabilityExternalSites {
                NextcloudKit.shared.getExternalSite(account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { account, externalSites, _, error in
                    if error == .success {
                        self.database.deleteExternalSites(account: account)
                        for externalSite in externalSites {
                            self.database.addExternalSites(externalSite, account: account)
                        }
                    }
                }
            } else {
                self.database.deleteExternalSites(account: account)
            }

            // User Status
            if capability.capabilityUserStatusEnabled {
                NextcloudKit.shared.getUserStatus(account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { account, clearAt, icon, message, messageId, messageIsPredefined, status, statusIsUserDefined, _, _, error in
                    if error == .success {
                        self.database.setAccountUserStatus(userStatusClearAt: clearAt, userStatusIcon: icon, userStatusMessage: message, userStatusMessageId: messageId, userStatusMessageIsPredefined: messageIsPredefined, userStatusStatus: status, userStatusStatusIsUserDefined: statusIsUserDefined, account: account)
                    }
                }
            }

            // Notifications
            controller?.availableNotifications = false
            if capability.capabilityNotification.count > 0 {
                NextcloudKit.shared.getNotifications(account: account) { _ in
                } completion: { _, notifications, _, error in
                    if error == .success, let notifications = notifications, notifications.count > 0 {
                        controller?.availableNotifications = true
                    }
                }
            }

            // Added UTI for Collabora
            capability.capabilityRichDocumentsMimetypes.forEach { mimeType in
                NextcloudKit.shared.nkCommonInstance.addInternalTypeIdentifier(typeIdentifier: mimeType, classFile: NKCommon.TypeClassFile.document.rawValue, editor: NCGlobal.shared.editorCollabora, iconName: NKCommon.TypeIconFile.document.rawValue, name: "document", account: account)
            }

            // Added UTI for ONLYOFFICE & Text
            if let directEditingCreators = self.database.getDirectEditingCreators(account: account) {
                for directEditing in directEditingCreators {
                    NextcloudKit.shared.nkCommonInstance.addInternalTypeIdentifier(typeIdentifier: directEditing.mimetype, classFile: NKCommon.TypeClassFile.document.rawValue, editor: directEditing.editor, iconName: NKCommon.TypeIconFile.document.rawValue, name: "document", account: account)
                }
            }
        }
    private func getAvatar(account: String) async {
        let session = NCSession.shared.getSession(account: account)
        let fileName = NCSession.shared.getFileName(urlBase: session.urlBase, user: session.user)

        let tblAvatar = await self.database.getTableAvatarAsync(fileName: fileName)
        let resultsDownload = await NextcloudKit.shared.downloadAvatarAsync(user: session.userId,
                                                                            fileNameLocalPath: self.utilityFileSystem.directoryUserData + "/" + fileName,
                                                                            sizeImage: NCGlobal.shared.avatarSize,
                                                                            etagResource: tblAvatar?.etag,
                                                                            account: account)

        if  resultsDownload.error == .success,
            let etag = resultsDownload.etag,
            etag != tblAvatar?.etag {
            await self.database.addAvatarAsync(fileName: fileName, etag: etag)
            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadAvatar, userInfo: ["error": resultsDownload.error])
        } else {
            await self.database.setAvatarLoadedAsync(fileName: fileName)
        }
    }

    private func requestServerCapabilities(account: String, controller: NCMainTabBarController?) async {
        let resultsCapabilities = await NextcloudKit.shared.getCapabilitiesAsync(account: account)
        guard resultsCapabilities.error == .success,
              let data = resultsCapabilities.responseData?.data,
              let capabilities = resultsCapabilities.capabilities else {
            return
        }

        await self.database.addCapabilitiesAsync(data: data, account: account)

        // Text direct editor (Nextcloud Text, Office, Collabora)
        let resultsTextEditor = await NextcloudKit.shared.textObtainEditorDetailsAsync(account: account)
        if resultsTextEditor.error == .success,
           let data = resultsTextEditor.responseData?.data {
            await self.database.addCapabilitiesEditorsAsync(data: data, account: account)
        }

        // Recommendations
        if !capabilities.recommendations {
            await self.database.deleteAllRecommendedFilesAsync(account: account)
        }

        // Theming
        if NCBrandColor.shared.settingThemingColor(account: account) {
            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming, userInfo: ["account": account])
        }

        // External file Server
        if capabilities.externalSites {
            let results = await NextcloudKit.shared.getExternalSiteAsync(account: account)
            if results.error == .success {
                await self.database.deleteExternalSitesAsync(account: account)
                for site in results.externalSite {
                    await self.database.addExternalSitesAsync(site, account: account)
                }
            }
        } else {
            await self.database.deleteExternalSitesAsync(account: account)
        }

        // User Status
        if capabilities.userStatusEnabled {
            let results = await NextcloudKit.shared.getUserStatusAsync(account: account)
            if results.error == .success {
                await self.database.setAccountUserStatusAsync(userStatusClearAt: results.clearAt,
                                                              userStatusIcon: results.icon,
                                                              userStatusMessage: results.message,
                                                              userStatusMessageId: results.messageId,
                                                              userStatusMessageIsPredefined: results.messageIsPredefined,
                                                              userStatusStatus: results.status,
                                                              userStatusStatusIsUserDefined: results.statusIsUserDefined,
                                                              account: results.account)
            }
        }

        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterUpdateNotification)
    }

    // MARK: -

    @objc func synchronizeOffline(account: String) {
        // Synchronize Directory
        Task {
            if let directories = self.database.getTablesDirectory(predicate: NSPredicate(format: "account == %@ AND offline == true", account), sorted: "serverUrl", ascending: true) {
                for directory: tableDirectory in directories {
                    await NCNetworking.shared.synchronization(account: account, serverUrl: directory.serverUrl, add: false)
                }
            }
        }

        // Synchronize Files
        let files = self.database.getTableLocalFiles(predicate: NSPredicate(format: "account == %@ AND offline == true", account), sorted: "fileName", ascending: true)
        for file: tableLocalFile in files {
            guard let metadata = self.database.getMetadataFromOcId(file.ocId) else { continue }
            if NCNetworking.shared.isSynchronizable(ocId: metadata.ocId, fileName: metadata.fileName, etag: metadata.etag) {
                self.database.setMetadatasSessionInWaitDownload(metadatas: [metadata],
                                                                session: NCNetworking.shared.sessionDownloadBackground,
                                                                selector: NCGlobal.shared.selectorSynchronizationOffline)
    func synchronize(account: String) async {
        let showHiddenFiles = NCKeychain().getShowHiddenFiles(account: account)

        nkLog(tag: self.global.logTagSync, emoji: .start, message: "Synchronize favorite for account: \(account)")

        await self.database.cleanTablesOcIds(account: account)

        let resultsFavorite = await NextcloudKit.shared.listingFavoritesAsync(showHiddenFiles: showHiddenFiles, account: account)
        if resultsFavorite.error == .success, let files = resultsFavorite.files {
            let (_, metadatas) = await self.database.convertFilesToMetadatasAsync(files, useFirstAsMetadataFolder: false)
            await self.database.updateMetadatasFavoriteAsync(account: account, metadatas: metadatas)
        }

        // file already in dowloading
        let predicate = NSPredicate(format: "account == %@ AND status == %d", account, self.global.metadataStatusDownloadingAllMode)
        let metadatasInDownload = await self.database.getMetadatasAsync(predicate: predicate,
                                                                        withLimit: nil)

        // Synchronize Directory
        let directories = await self.database.getTablesDirectoryAsync(predicate: NSPredicate(format: "account == %@ AND offline == true", account), sorted: "serverUrl", ascending: true)
        for directory in directories {
            await NCNetworking.shared.synchronization(account: account, serverUrl: directory.serverUrl, metadatasInDownload: metadatasInDownload)
        }

        // Synchronize Files
        let files = await self.database.getTableLocalFilesAsync(predicate: NSPredicate(format: "account == %@ AND offline == true", account), sorted: "fileName", ascending: true)
        for file in files {
            if let metadata = await self.database.getMetadataFromOcIdAsync(file.ocId),
               await NCNetworking.shared.isFileDifferent(ocId: metadata.ocId, fileName: metadata.fileName, etag: metadata.etag, metadatasInDownload: metadatasInDownload) {
                await self.database.setMetadataSessionInWaitDownloadAsync(ocId: metadata.ocId,
                                                                          session: NCNetworking.shared.sessionDownloadBackground,
                                                                          selector: NCGlobal.shared.selectorSynchronizationOffline)
            }
        }
    }

    // MARK: -

    private func requestDashboardWidget(account: String) async {
        let results = await NextcloudKit.shared.getDashboardWidgetAsync(account: account)
        if results.error == .success,
           let dashboardWidgets = results.dashboardWidgets {
            await NCManageDatabase.shared.addDashboardWidgetAsync(account: account, dashboardWidgets: dashboardWidgets)
            for widget in dashboardWidgets {
                if let url = URL(string: widget.iconUrl),
                   let fileName = widget.iconClass {
                    let results = await NextcloudKit.shared.downloadPreviewAsync(url: url, account: account)
                    if results.error == .success,
                       let data = results.responseData?.data {
                        let size = CGSize(width: 256, height: 256)
                        let finalImage: UIImage?
                        if let uiImage = UIImage(data: data)?.resizeImage(size: size) {
                            finalImage = uiImage
                        } else if let svgImage = SVGKImage(data: data) {
                            svgImage.size = size
                            finalImage = svgImage.uiImage
                        } else {
                            print("Unsupported image format")
                            continue
                        }
                        if let image = finalImage {
                            let filePath = (self.utilityFileSystem.directoryUserData as NSString).appendingPathComponent(fileName + ".png")
                            do {
                                try image.pngData()?.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                            } catch {
                                print("Failed to write image to disk: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: -

    func sendClientDiagnosticsRemoteOperation(account: String) {
        guard NCCapabilities.shared.getCapabilities(account: account).capabilitySecurityGuardDiagnostics,
              self.database.existsDiagnostics(account: account) else {
    func sendClientDiagnosticsRemoteOperation(account: String) async {
        let capabilities = await NKCapabilities.shared.getCapabilitiesAsync(for: account)
        guard capabilities.securityGuardDiagnostics,
              await self.database.existsDiagnosticsAsync(account: account) else {
            return
        }

        struct Issues: Codable {
            struct SyncConflicts: Codable {
                var count: Int?
                var oldest: TimeInterval?
            }

            struct VirusDetected: Codable {
                var count: Int?
                var oldest: TimeInterval?
            }

            struct E2EError: Codable {
                var count: Int?
                var oldest: TimeInterval?
            }

            struct Problem: Codable {
                struct Error: Codable {
                    var count: Int
                    var oldest: TimeInterval
                }

                var forbidden: Error?               // NCGlobal.shared.diagnosticProblemsForbidden
                var badResponse: Error?             // NCGlobal.shared.diagnosticProblemsBadResponse
                var uploadServerError: Error?       // NCGlobal.shared.diagnosticProblemsUploadServerError
            }

            var syncConflicts: SyncConflicts
            var virusDetected: VirusDetected
            var e2eeErrors: E2EError
            var problems: Problem?

            enum CodingKeys: String, CodingKey {
                case syncConflicts = "sync_conflicts"
                case virusDetected = "virus_detected"
                case e2eeErrors = "e2ee_errors"
                case problems
            }
        }

        var ids: [ObjectId] = []

        var syncConflicts: Issues.SyncConflicts = Issues.SyncConflicts()
        var virusDetected: Issues.VirusDetected = Issues.VirusDetected()
        var e2eeErrors: Issues.E2EError = Issues.E2EError()

        var problems: Issues.Problem? = Issues.Problem()
        var problemForbidden: Issues.Problem.Error?
        var problemBadResponse: Issues.Problem.Error?
        var problemUploadServerError: Issues.Problem.Error?

        if let result = self.database.getDiagnostics(account: account, issue: NCGlobal.shared.diagnosticIssueSyncConflicts)?.first {
            syncConflicts = Issues.SyncConflicts(count: result.counter, oldest: result.oldest)
            ids.append(result.id)
        }
        if let result = self.database.getDiagnostics(account: account, issue: NCGlobal.shared.diagnosticIssueVirusDetected)?.first {
            virusDetected = Issues.VirusDetected(count: result.counter, oldest: result.oldest)
            ids.append(result.id)
        }
        if let result = self.database.getDiagnostics(account: account, issue: NCGlobal.shared.diagnosticIssueE2eeErrors)?.first {
            e2eeErrors = Issues.E2EError(count: result.counter, oldest: result.oldest)
            ids.append(result.id)
        }
        if let results = self.database.getDiagnostics(account: account, issue: NCGlobal.shared.diagnosticIssueProblems) {
            for result in results {
                switch result.error {
                case NCGlobal.shared.diagnosticProblemsForbidden:
                    if result.counter >= 1 {
                        problemForbidden = Issues.Problem.Error(count: result.counter, oldest: result.oldest)
                        ids.append(result.id)
                    }
                case NCGlobal.shared.diagnosticProblemsBadResponse:
                    if result.counter >= 2 {
                        problemBadResponse = Issues.Problem.Error(count: result.counter, oldest: result.oldest)
                        ids.append(result.id)
                    }
                case NCGlobal.shared.diagnosticProblemsUploadServerError:
                    if result.counter >= 1 {
                        problemUploadServerError = Issues.Problem.Error(count: result.counter, oldest: result.oldest)
                        ids.append(result.id)
                    }
                default:
                    break
                }
            }
            problems = Issues.Problem(forbidden: problemForbidden, badResponse: problemBadResponse, uploadServerError: problemUploadServerError)
        }

        do {
            let issues = Issues(syncConflicts: syncConflicts, virusDetected: virusDetected, e2eeErrors: e2eeErrors, problems: problems)
            let data = try JSONEncoder().encode(issues)
            data.printJson()
            NextcloudKit.shared.sendClientDiagnosticsRemoteOperation(data: data, account: account, options: NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)) { _, _, error in
                if error == .success {
                    self.database.deleteDiagnostics(account: account, ids: ids)
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
