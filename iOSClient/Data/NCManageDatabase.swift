// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2017 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import RealmSwift
import NextcloudKit
import CoreMedia
import Photos
import CommonCrypto

protocol DateCompareable {
    var dateKey: Date { get }
}

//final class NCManageDatabase: Sendable {
class NCManageDatabase: NSObject, @unchecked Sendable  {

//    @objc static let shared: NCManageDatabase = {
//            let instance = NCManageDatabase()
//            return instance
//        }()
    @objc static let shared = NCManageDatabase()

    internal let realmQueue = DispatchQueue(label: "com.nextcloud.realmQueue") // serial queue
    internal let realmQueueKey = DispatchSpecificKey<Bool>()
    internal let utilityFileSystem = NCUtilityFileSystem()

    override init() {
        super.init()
        let dirGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: NCBrandOptions.shared.capabilitiesGroup)
        let databaseFileUrlPath = dirGroup?.appendingPathComponent(NCGlobal.shared.appDatabaseNextcloud + "/" + databaseName)
        let bundleUrl: URL = Bundle.main.bundleURL
        let bundlePathExtension: String = bundleUrl.pathExtension
        let bundleFileName: String = (bundleUrl.path as NSString).lastPathComponent
        let isAppex: Bool = bundlePathExtension == "appex"

        realmQueue.setSpecific(key: realmQueueKey, value: true)

        // Disable file protection for directory DB
        if let folderPathURL = dirGroup?.appendingPathComponent(NCGlobal.shared.appDatabaseNextcloud) {
            let folderPath = folderPathURL.path
            do {
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: folderPath)
            } catch {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm directory setAttributes error: \(error)")
            }
        }

        if isAppex, bundleFileName == "File Provider Extension.appex" {
            let objectTypes = [NCKeyValue.self,
                               tableMetadata.self,
                               tableLocalFile.self,
                               tableDirectory.self,
                               tableTag.self,
                               tableAccount.self,
                               tableCapabilities.self,
                               tableE2eEncryption.self]

            openRealmAppex(path: databaseFileUrlPath, objectTypes: objectTypes)
        } else if isAppex {
            let objectTypes = [NCKeyValue.self,
                               tableMetadata.self,
                               tableLocalFile.self,
                               tableDirectory.self,
                               tableTag.self,
                               tableAccount.self,
                               tableCapabilities.self,
                               tableE2eEncryption.self,
                               tableE2eEncryptionLock.self,
                               tableE2eMetadata12.self,
                               tableE2eMetadata.self,
                               tableE2eUsers.self,
                               tableE2eCounter.self,
                               tableShare.self,
                               tableChunk.self,
                               tableAvatar.self,
                               tableDashboardWidget.self,
                               tableDashboardWidgetButton.self,
                               NCDBLayoutForView.self,
                               TableSecurityGuardDiagnostics.self]

            openRealmAppex(path: databaseFileUrlPath, objectTypes: objectTypes)
        } else {
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                openRealm(path: databaseFileUrlPath)
            }
        }
    }

    private func migrationSchema(_ migration: Migration, _ oldSchemaVersion: UInt64) {
        if oldSchemaVersion < 365 {
            migration.deleteData(forType: tableMetadata.className())
            migration.enumerateObjects(ofType: tableDirectory.className()) { _, newObject in
                newObject?["etag"] = ""
            }
        }
//        if oldSchemaVersion < 383 {
//            migration.enumerateObjects(ofType: tableAccount.className()) { oldObject, newObject in
//                if let oldDate = oldObject?["autoUploadSinceDate"] as? Date {
//                    newObject?["autoUploadOnlyNewSinceDate"] = oldDate
//                } else {
//                    newObject?["autoUploadOnlyNewSinceDate"] = Date()
//                }
//                newObject?["autoUploadOnlyNew"] = true
//            }
//        }
        
        if oldSchemaVersion < 383 {
            migration.enumerateObjects(ofType: tableAccount.className()) { oldObject, newObject in
                // Check if the property exists in the old schema by inspecting the object's schema properties
                let propertyExists = oldObject?.objectSchema.properties.contains { $0.name == "autoUploadSinceDate" } ?? false
                
                if propertyExists {
                    // If the property exists, migrate its value
                    if let oldDate = oldObject?["autoUploadSinceDate"] as? Date {
                        newObject?["autoUploadOnlyNewSinceDate"] = oldDate
                    } else {
                        newObject?["autoUploadOnlyNewSinceDate"] = Date() // Fallback to default value
                    }
                } else {
                    // If the property doesn't exist in the old version, initialize it with a default value
                    newObject?["autoUploadOnlyNewSinceDate"] = Date()
                }
                
                // Always set the "autoUploadOnlyNew" property
                newObject?["autoUploadOnlyNew"] = true
            }
        }
        if oldSchemaVersion < databaseSchemaVersion {
            // automatic conversion for delete object / properties
        }
    }

    private func compactDB(_ totalBytes: Int, _ usedBytes: Int) -> Bool {
        let usedPercentage = (Double(usedBytes) / Double(totalBytes)) * 100
        /// Compact the database if more than 25% of the space is free
        let shouldCompact = (usedPercentage < 75.0) && (totalBytes > 100 * 1024 * 1024)

        return shouldCompact
    }

    private func restoreDB(path databaseFileUrlPath: URL?) {
        if let realmURL = databaseFileUrlPath {
            let filesToDelete = [
                realmURL,
                realmURL.appendingPathExtension("lock"),
                realmURL.appendingPathExtension("note"),
                realmURL.appendingPathExtension("management")
            ]

            for file in filesToDelete {
                do {
                    try FileManager.default.removeItem(at: file)
                } catch { }
            }
        }

        do {
            _ = try Realm()
            restoreTableAccountFromFile()
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Account restoration: \(error)")
        }
    }

    private func openRealm(path databaseFileUrlPath: URL?) {
        // DEFAULTCONFIGURATION
        Realm.Configuration.defaultConfiguration =
        Realm.Configuration(fileURL: databaseFileUrlPath,
                            schemaVersion: databaseSchemaVersion,
                            migrationBlock: { migration, oldSchemaVersion in
            self.migrationSchema(migration, oldSchemaVersion)
        }, shouldCompactOnLaunch: { totalBytes, usedBytes in
            self.compactDB(totalBytes, usedBytes)
        })

        do {
            let realm = try Realm()
            if let url = realm.configuration.fileURL {
                print("Realm is located at: \(url)")
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm: \(error)")
            self.restoreDB(path: databaseFileUrlPath)
        }
    }

    private func openRealmAppex(path databaseFileUrlPath: URL?, objectTypes: [Object.Type]) {
        do {
            Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: databaseFileUrlPath,
                                                                           schemaVersion: databaseSchemaVersion,
                                                                           objectTypes: objectTypes)

            let realm = try Realm()
            if let url = realm.configuration.fileURL {
                print("Realm is located at: \(url)")
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm: \(error)")
            exit(1)
        }
    }

    // MARK: -

    @discardableResult
    func performRealmRead<T>(_ block: @escaping (Realm) throws -> T?, sync: Bool = true, completion: ((T?) -> Void)? = nil) -> T? {
        guard !isAppSuspending else {
            completion?(nil)
            return nil // Return nil because the result is handled asynchronously
        }

        if DispatchQueue.getSpecific(key: realmQueueKey) == true {
            // Already on realmQueue: execute directly to avoid deadlocks
            do {
                let realm = try Realm()
                let result = try block(realm)
                if sync {
                    return result
                } else {
                    completion?(result)
                    return nil // Return nil because the result is handled asynchronously
                }
            } catch {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm read error: \(error)")
                completion?(nil)
                return nil // Return nil because the result is handled asynchronously
            }
        } else {
            if sync {
                // Synchronous execution
                return realmQueue.sync {
                    do {
                        let realm = try Realm()
                        return try block(realm)
                    } catch {
                        NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm read error: \(error)")
                        return nil
                    }
                }
            } else {
                // Asynchronous execution
                realmQueue.async {
                    do {
                        let realm = try Realm()
                        let result = try block(realm)
                        completion?(result)
                    } catch {
                        NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm read error: \(error)")
                        completion?(nil)
                    }
                }
                return nil // Return nil because the result will be handled asynchronously
            }
        }
    }

    func performRealmWrite(sync: Bool = true, _ block: @escaping (Realm) throws -> Void) {
        guard !isAppSuspending
        else {
            return
        }

        let executionBlock: @Sendable () -> Void = {
            autoreleasepool {
                do {
                    let realm = try Realm()
                    try realm.write {
                        try block(realm)
                    }
                } catch {
                    NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm write error: \(error)")
                }
            }
        }

        if isAppInBackground || !sync {
            realmQueue.async(execute: executionBlock)
        } else {
            realmQueue.sync(execute: executionBlock)
        }
    }

    // MARK: - performRealmRead async/await, performRealmWrite async/await

    func performRealmReadAsync<T>(_ block: @escaping (Realm) throws -> T?) async -> T? {
        await withCheckedContinuation { continuation in
            realmQueue.async {
                if isAppSuspending {
                    // App is suspending — don't execute the block
                    continuation.resume(returning: nil)
                    return
                }

                autoreleasepool {
                    do {
                        let realm = try Realm()
                        let result = try block(realm)
                        continuation.resume(returning: result)
                    } catch {
                        NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm read error: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    func performRealmWriteAsync(_ block: @escaping (Realm) throws -> Void) async {
        await withCheckedContinuation { continuation in
            realmQueue.async {
                if isAppSuspending {
                    // App is suspending — don't execute the block
                    continuation.resume()
                    return
                }

                autoreleasepool {
                    do {
                        let realm = try Realm()
                        try realm.write {
                            try block(realm)
                        }
                    } catch {
                        NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Realm write error: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: -

    @objc func clearTable(_ table: Object.Type, account: String? = nil) {
        performRealmWrite { realm in
            var results: Results<Object>
            if let account = account {
                results = realm.objects(table).filter("account == %@", account)
            } else {
                results = realm.objects(table)
            }

            realm.delete(results)
        }
    }

    @objc func clearDatabase(account: String? = nil, removeAccount: Bool = false, removeAutoUpload: Bool = false) {
        if removeAccount {
            self.clearTable(tableAccount.self, account: account)
        }
        if removeAutoUpload {
            self.clearTable(tableAutoUploadTransfer.self, account: account)
        }

        self.clearTable(tableActivity.self, account: account)
        self.clearTable(tableActivityLatestId.self, account: account)
        self.clearTable(tableActivityPreview.self, account: account)
        self.clearTable(tableActivitySubjectRich.self, account: account)
        self.clearTable(tableAvatar.self)
        self.clearTable(tableCapabilities.self, account: account)
        self.clearTable(tableChunk.self, account: account)
        self.clearTable(tableComments.self, account: account)
        self.clearTable(tableDashboardWidget.self, account: account)
        self.clearTable(tableDashboardWidgetButton.self, account: account)
        self.clearTable(tableDirectEditingCreators.self, account: account)
        self.clearTable(tableDirectEditingEditors.self, account: account)
        self.clearTable(tableDirectory.self, account: account)
        self.clearTablesE2EE(account: account)
        self.clearTable(tableExternalSites.self, account: account)
        self.clearTable(tableGPS.self, account: nil)
        self.clearTable(TableGroupfolders.self, account: account)
        self.clearTable(TableGroupfoldersGroups.self, account: account)
        self.clearTable(tableLocalFile.self, account: account)
        self.clearTable(tableMetadata.self, account: account)
        self.clearTable(tableShare.self, account: account)
        self.clearTable(TableSecurityGuardDiagnostics.self, account: account)
        self.clearTable(tableTag.self, account: account)
        self.clearTable(tableTrash.self, account: account)
        self.clearTable(tableVideo.self, account: account)
        self.clearTable(TableDownloadLimit.self, account: account)
        self.clearTable(tableRecommendedFiles.self, account: account)
        self.clearTable(NCDBLayoutForView.self, account: account)
        if account == nil {
            self.clearTable(NCKeyValue.self)
        }
    }

    func clearTablesE2EE(account: String?) {
        self.clearTable(tableE2eEncryption.self, account: account)
        self.clearTable(tableE2eEncryptionLock.self, account: account)
        self.clearTable(tableE2eMetadata12.self, account: account)
        self.clearTable(tableE2eMetadata.self, account: account)
        self.clearTable(tableE2eUsers.self, account: account)
        self.clearTable(tableE2eCounter.self, account: account)
    }

    func getThreadConfined(_ object: Object) -> Any {
        return ThreadSafeReference(to: object)
    }

    func putThreadConfined(_ tableRef: ThreadSafeReference<Object>) -> Object? {
        do {
            let realm = try Realm()
            return realm.resolve(tableRef)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
        return nil
    }

    func realmRefresh() {
        realmQueue.sync {
            do {
                let realm = try Realm()
                realm.refresh()
            } catch let error as NSError {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not refresh database: \(error)")
            }
        }
    }

    func sha256Hash(_ input: String) -> String {
        let data = Data(input.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    // MARK: -
    // MARK: Func T

    func fetchPagedResults<T: Object>(ofType type: T.Type, primaryKey: String, recordsPerPage: Int, pageNumber: Int, filter: NSPredicate? = nil, sortedByKeyPath: String? = nil, sortedAscending: Bool = true) -> Results<T>? {
        let startIndex = recordsPerPage * (pageNumber - 1)

        do {
            let realm = try Realm()
            var results = realm.objects(type)

            if let filter, let sortedByKeyPath {
                results = results.filter(filter).sorted(byKeyPath: sortedByKeyPath, ascending: sortedAscending)
            }

            guard startIndex < results.count else {
                return nil
            }
            let pagedResults = results.dropFirst(startIndex).prefix(recordsPerPage)
            let pagedResultsKeys = pagedResults.compactMap { $0.value(forKey: primaryKey) as? String }

            return realm.objects(type).filter("\(primaryKey) IN %@", Array(pagedResultsKeys))
        } catch {
            print("Error opening Realm: \(error)")
            return nil
        }
    }

    // MARK: -
    // MARK: SWIFTUI PREVIEW

    func previewCreateDB() {
        /// Account
        let account = "marinofaggiana https://cloudtest.nextcloud.com"
        let account2 = "mariorossi https://cloudtest.nextcloud.com"
        addAccount(account, urlBase: "https://cloudtest.nextcloud.com", user: "marinofaggiana", userId: "marinofaggiana", password: "password")
        addAccount(account2, urlBase: "https://cloudtest.nextcloud.com", user: "mariorossi", userId: "mariorossi", password: "password")
        let userProfile = NKUserProfile()
        userProfile.displayName = "Marino Faggiana"
        userProfile.address = "Hirschstrasse 26, 70192 Stuttgart, Germany"
        userProfile.phone = "+49 (711) 252 428 - 90"
        userProfile.email = "cloudtest@nextcloud.com"
        setAccountUserProfile(account: account, userProfile: userProfile)
        let userProfile2 = NKUserProfile()
        userProfile2.displayName = "Mario Rossi"
        userProfile2.email = "cloudtest@nextcloud.com"
        setAccountUserProfile(account: account2, userProfile: userProfile2)
    }
}

class NCKeyValue: Object {
    @Persisted var key: String = ""
    @Persisted var value: String?
}
