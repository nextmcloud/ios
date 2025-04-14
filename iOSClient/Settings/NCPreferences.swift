// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2023 Marino Faggiana
// SPDX-FileCopyrightText: 2026 Rasmus Wøldike
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import KeychainAccess
import NextcloudKit

final class NCPreferences: NSObject {
    private static let userDefaultsMigrationKey = "NCPreferencesUserDefaultsMigrationVersion"
    private static let userDefaultsMigrationVersion = 1

    let keychain = Keychain(service: "com.nextcloud.keychain")
    private let userDefaults: UserDefaults

    override init() {
        userDefaults = UserDefaults(suiteName: NCBrandOptions.shared.capabilitiesGroup) ?? .standard
        super.init()
        migrateUserDefaultsToAppGroupIfNeeded()
    }

    var showDescription: Bool {
        get {
            if let value = try? keychain.get("showDescription"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["showDescription"] = String(newValue)
        }
    }

    var showRecommendedFiles: Bool {
        get {
            if let value = try? keychain.get("showRecommendedFiles"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["showRecommendedFiles"] = String(newValue)
        }
    }

    var typeFilterScanDocument: NCGlobal.TypeFilterScanDocument {
        get {
            if let rawValue = try? keychain.get("ScanDocumentTypeFilter"), let value = NCGlobal.TypeFilterScanDocument(rawValue: rawValue) {
                return value
            } else {
                return .original
            }
        }
        set {
            keychain["ScanDocumentTypeFilter"] = newValue.rawValue
        }
    }

    @objc var passcode: String? {
        get {
            migrate(key: "passcodeBlock")
            if let value = try? keychain.get("passcodeBlock"), !value.isEmpty {
                return value
            }
            return nil
        }
        set {
            keychain["passcodeBlock"] = newValue
        }
    }

    @objc var resetAppCounterFail: Bool {
        get {
            if let value = try? keychain.get("resetAppCounterFail"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["resetAppCounterFail"] = String(newValue)
        }
    }

    var passcodeCounterFail: Int {
        get {
            if let value = try? keychain.get("passcodeCounterFail"), let result = Int(value) {
                return result
            }
            return 0
        }
        set {
            keychain["passcodeCounterFail"] = String(newValue)
        }
    }

    var passcodeCounterFailReset: Int {
        get {
            if let value = try? keychain.get("passcodeCounterFailReset"), let result = Int(value) {
                return result
            }
            return 0
        }
        set {
            keychain["passcodeCounterFailReset"] = String(newValue)
        }
    }

    /// Тhe deadline date when the wrong passcode attempt lockout expires.
    var passcodeLockoutEnd: Date? {
        get {
            if let value = try? keychain.get("passcodeLockoutEnd"), let result = Double(value) {
                return Date(timeIntervalSince1970: result)
            }
            return nil
        }
        set {
            keychain["passcodeLockoutEnd"] = newValue.map { String($0.timeIntervalSince1970) }
        }
    }

    func clearPasscodeFailures() {
        passcodeCounterFail = 0
        passcodeCounterFailReset = 0
        passcodeLockoutEnd = nil
    }

    var requestPasscodeAtStart: Bool {
//    @objc var requestPasscodeAtStart: Bool {
        get {
            let keychainOLD = Keychain(service: "Crypto Cloud")
            if let value = keychainOLD["notPasscodeAtStart"], !value.isEmpty {
                if value == "true" {
                    keychain["requestPasscodeAtStart"] = "false"
                } else if value == "false" {
                    keychain["requestPasscodeAtStart"] = "true"
                }
                keychainOLD["notPasscodeAtStart"] = nil
            }
            if NCBrandOptions.shared.doNotAskPasscodeAtStartup {
                return false
            } else if let value = try? keychain.get("requestPasscodeAtStart"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["requestPasscodeAtStart"] = String(newValue)
        }
    }

    @objc var touchFaceID: Bool {
        get {
            migrate(key: "enableTouchFaceID")
            if let value = try? keychain.get("enableTouchFaceID"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["enableTouchFaceID"] = String(newValue)
        }
    }

    var presentPasscode: Bool {
        return passcode != nil && requestPasscodeAtStart
    }

    @objc var incrementalNumber: String {
        migrate(key: "incrementalnumber")
        var incrementalString = String(format: "%04ld", 0)
        if let value = try? keychain.get("incrementalnumber"), var result = Int(value) {
            result += 1
            incrementalString = String(format: "%04ld", result)
        }
        keychain["incrementalnumber"] = incrementalString
        return incrementalString
    }

    @objc var showHiddenFiles: Bool {
        get {
            migrate(key: "showHiddenFiles")
            if let value = try? keychain.get("showHiddenFiles"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["showHiddenFiles"] = String(newValue)
        }
    }

    @objc var formatCompatibility: Bool {
        get {
            migrate(key: "formatCompatibility")
            if let value = try? keychain.get("formatCompatibility"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["formatCompatibility"] = String(newValue)
        }
    }

    @objc var disableFilesApp: Bool {
        get {
            migrate(key: "disablefilesapp")
            if let value = try? keychain.get("disablefilesapp"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["disablefilesapp"] = String(newValue)
        }
    }

    @objc var livePhoto: Bool {
        get {
            migrate(key: "livePhoto")
            if let value = try? keychain.get("livePhoto"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["livePhoto"] = String(newValue)
        }
    }

    @objc var disableCrashservice: Bool {
        get {
            migrate(key: "crashservice")
            if let value = try? keychain.get("crashservice"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["crashservice"] = String(newValue)
        }
    }

    /// Stores and retrieves the current log level from the keychain.
    var log: NKLogLevel {
//    @objc var logLevel: Int {
        get {
            migrate(key: "logLevel")
            if let value = try? keychain.get("logLevel"),
               let intValue = Int(value),
               let level = NKLogLevel(rawValue: intValue) {
                return level
            }
            return NKLogLevel.normal
        }
        set {
            keychain["logLevel"] = String(newValue.rawValue)
        }
    }

    @objc var accountRequest: Bool {
        get {
            migrate(key: "accountRequest")
            if let value = try? keychain.get("accountRequest"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["accountRequest"] = String(newValue)
        }
    }

    @objc var removePhotoCameraRoll: Bool {
        get {
            migrate(key: "removePhotoCameraRoll")
            if let value = try? keychain.get("removePhotoCameraRoll"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["removePhotoCameraRoll"] = String(newValue)
        }
    }

    var saveCameraMediaToCameraRoll: Bool {
        get {
            return getBoolPreference(key: "saveCameraMediaToCameraRoll", defaultValue: true)
        }
        set {
            setUserDefaults(newValue, forKey: "saveCameraMediaToCameraRoll")
        }
    }

    var privacyScreenEnabled: Bool {
//    @objc var privacyScreenEnabled: Bool {
        get {
            migrate(key: "privacyScreen")
            if NCBrandOptions.shared.enforce_privacyScreenEnabled {
                return true
            }
            if let value = try? keychain.get("privacyScreen"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["privacyScreen"] = String(newValue)
        }
    }

    @objc var cleanUpDay: Int {
        get {
            migrate(key: "cleanUpDay")
            if let value = try? keychain.get("cleanUpDay"), let result = Int(value) {
                return result
            }
            return NCBrandOptions.shared.cleanUpDay
        }
        set {
            keychain["cleanUpDay"] = String(newValue)
        }
    }

    var mediaColumnCount: Int {
        get {
            if let value = try? keychain.get("mediaColumnCount"), let result = Int(value) {
                return result
            }
            return 3
        }
        set {
            keychain["mediaColumnCount"] = String(newValue)
        }
    }

    var mediaTypeLayout: String {
        get {
            if let value = try? keychain.get("mediaTypeLayout") {
                return value
            }
            return NCGlobal.shared.mediaLayoutRatio
        }
        set {
            keychain["mediaTypeLayout"] = String(newValue)
        }
    }
    
    var mediaSortDate: String {
        get {
            migrate(key: "mediaSortDate")
            if let value = try? keychain.get("mediaSortDate") {
                return value
            }
            return "date"
        }
        set {
            keychain["mediaSortDate"] = newValue
        }
    }
    
    var textRecognitionStatus: Bool {
        get {
            migrate(key: "textRecognitionStatus")
            if let value = try? keychain.get("textRecognitionStatus"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["textRecognitionStatus"] = String(newValue)
        }
    }

    var deleteAllScanImages: Bool {
        get {
            migrate(key: "deleteAllScanImages")
            if let value = try? keychain.get("deleteAllScanImages"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["deleteAllScanImages"] = String(newValue)
        }
    }

    var qualityScanDocument: Double {
        get {
            migrate(key: "qualityScanDocument")
            if let value = try? keychain.get("qualityScanDocument"), let result = Double(value) {
                return result
            }
            return 2
        }
        set {
            keychain["qualityScanDocument"] = String(newValue)
        }
    }

    var appearanceAutomatic: Bool {
        get {
            if let value = try? keychain.get("appearanceAutomatic"), let result = Bool(value) {
                return result
            }
            return true
        }
        set {
            keychain["appearanceAutomatic"] = String(newValue)
        }
    }

    var appearanceInterfaceStyle: UIUserInterfaceStyle {
        get {
            if let value = try? keychain.get("appearanceInterfaceStyle") {
                if value == "light" {
                    return .light
                } else {
                    return .dark
                }
            }
            return .light
        }
        set {
            if newValue == .light {
                keychain["appearanceInterfaceStyle"] = "light"
            } else {
                keychain["appearanceInterfaceStyle"] = "dark"
            }
        }
    }

    var screenAwakeMode: AwakeMode {
        get {
            if let value = try? keychain.get("screenAwakeMode") {
                if value == "off" {
                    return .off
                } else if value == "on" {
                    return .on
                } else {
                    return .whileCharging
                }
            }
            return .off
        }
        set {
            if newValue == .off {
                keychain["screenAwakeMode"] = "off"
            } else if newValue == .on {
                keychain["screenAwakeMode"] = "on"
            } else {
                keychain["screenAwakeMode"] = "whileCharging"
            }
        }
    }

    var fileNameType: Bool {
        get {
            if let value = try? keychain.get("fileNameType"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["fileNameType"] = String(newValue)
        }
    }

    var fileNameOriginal: Bool {
        get {
            if let value = try? keychain.get("fileNameOriginal"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["fileNameOriginal"] = String(newValue)
        }
    }

    var fileNameMask: String {
        get {
            if let value = try? keychain.get("fileNameMask") {
                return value
            }
            return ""
        }
        set {
            keychain["fileNameMask"] = String(newValue)
        }
    }

    var location: Bool {
        get {
            if let value = try? keychain.get("location"), let result = Bool(value) {
                return result
            }
            return false
        }
        set {
            keychain["location"] = String(newValue)
        }
    }

    // MARK: -

    func getPassword(account: String) -> String {
        let key = "password" + account
        migrate(key: key)
        let password = (try? keychain.get(key)) ?? ""
        return password
    }

    func setPassword(account: String, password: String?) {
        let key = "password" + account
        keychain[key] = password
    }

    func setPersonalFilesOnly(account: String, value: Bool) {
        let key = "personalFilesOnly" + account
        keychain[key] = String(value)
    }

    func getPersonalFilesOnly(account: String) -> Bool {
        let key = "personalFilesOnly" + account
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        } else {
            return false
        }
    }

    func setFavoriteOnTop(account: String, value: Bool) {
        let key = "favoriteOnTop" + account
        keychain[key] = String(value)
    }

    func getFavoriteOnTop(account: String) -> Bool {
        let key = "favoriteOnTop" + account
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        } else {
            return true
        }
    }

    func setDirectoryOnTop(account: String, value: Bool) {
        let key = "directoryOnTop" + account
        keychain[key] = String(value)
    }

    func getDirectoryOnTop(account: String) -> Bool {
        let key = "directoryOnTop" + account
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        } else {
            return true
        }
    }

    func setShowHiddenFiles(account: String, value: Bool) {
        let key = "showHiddenFiles" + account
        keychain[key] = String(value)
    }

    func getShowHiddenFiles(account: String) -> Bool {
        let key = "showHiddenFiles" + account
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        } else {
            return false
        }
    }

    func setTitleButtonHeader(account: String, value: String?) {
        let key = "titleButtonHeader" + account
        keychain[key] = value
    }

    func getTitleButtonHeader(account: String) -> String? {
        let key = "titleButtonHeader" + account
        return (try? keychain.get(key)) ?? ""
    }
    
    @objc func getOriginalFileName(key: String) -> Bool {
        migrate(key: key)
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        }
        return false
    }

    @objc func setOriginalFileName(key: String, value: Bool) {
        keychain[key] = String(value)
    }

    @objc func getFileNameMask(key: String) -> String {
        migrate(key: key)
        if let value = try? keychain.get(key) {
            return value
        } else {
            return ""
        }
    }

    @objc func setFileNameMask(key: String, mask: String?) {
        keychain[key] = mask
    }

    @objc func getFileNameType(key: String) -> Bool {
        migrate(key: key)
        if let value = try? keychain.get(key), let result = Bool(value) {
            return result
        } else {
            return false
        }
    }

    @objc func setFileNameType(key: String, prefix: Bool) {
        keychain[key] = String(prefix)
    }
    
    // MARK: - E2EE

    func getEndToEndCertificate(account: String) -> String? {
        let key = "EndToEndCertificate_" + account
        migrate(key: key)
        return try? keychain.get(key)
    }

    func setEndToEndCertificate(account: String, certificate: String?) {
        let key = "EndToEndCertificate_" + account
        keychain[key] = certificate
    }

    func getEndToEndPrivateKey(account: String) -> String? {
        let key = "EndToEndPrivateKey_" + account
        migrate(key: key)
        return try? keychain.get(key)
    }

    func setEndToEndPrivateKey(account: String, privateKey: String?) {
        let key = "EndToEndPrivateKey_" + account
        keychain[key] = privateKey
    }

    func getEndToEndPublicKey(account: String) -> String? {
        let key = "EndToEndPublicKeyServer_" + account
        migrate(key: key)
        return try? keychain.get(key)
    }

    func setEndToEndPublicKey(account: String, publicKey: String?) {
        let key = "EndToEndPublicKeyServer_" + account
        keychain[key] = publicKey
    }

    func getEndToEndPassphrase(account: String) -> String? {
        let key = "EndToEndPassphrase_" + account
        migrate(key: key)
        return try? keychain.get(key)
    }

    func setEndToEndPassphrase(account: String, passphrase: String?) {
        let key = "EndToEndPassphrase_" + account
        keychain[key] = passphrase
    }

    func isEndToEndEnabled(account: String) -> Bool {
        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: account)
        guard let certificate = getEndToEndCertificate(account: account), !certificate.isEmpty,
              let publicKey = getEndToEndPublicKey(account: account), !publicKey.isEmpty,
              let privateKey = getEndToEndPrivateKey(account: account), !privateKey.isEmpty,
              let passphrase = getEndToEndPassphrase(account: account), !passphrase.isEmpty else {
            return false
        }
        return true
    }

    /// Indicates that the locally active E2EE key set no longer matches the
    /// key currently published by the server. The key material is retained so
    /// it can continue to decrypt older storage spaces, but it must not write.
    func isEndToEndServerKeyStale(account: String) -> Bool {
        getBoolPreference(
            key: "EndToEndServerKeyStale",
            account: account,
            defaultValue: false
        )
    }

    func setEndToEndServerKeyStale(account: String, stale: Bool) {
        let key = "EndToEndServerKeyStale_\(account)"
        setUserDefaults(stale, forKey: key)
    }

    /// Archives the current E2EE credentials as an immutable Keychain item.
    ///
    /// Repeated attempts with unchanged credentials reuse the existing
    /// snapshot. The archive index is written only after the snapshot itself,
    /// so callers can safely stop before clearing the active credentials if
    /// either Keychain operation fails.
    @discardableResult
    func archiveCurrentEndToEndKeySet(account: String) throws -> NCEndToEndKeySet? {
        guard let candidate = NCEndToEndKeySet(
            certificate: getEndToEndCertificate(account: account),
            privateKey: getEndToEndPrivateKey(account: account),
            publicKey: getEndToEndPublicKey(account: account),
            passphrase: getEndToEndPassphrase(account: account)
        ) else {
            return nil
        }

        let archivedKeySets = try getArchivedEndToEndKeySets(account: account)
        if let existingKeySet = archivedKeySets.first(where: { $0.containsSameKeyMaterial(as: candidate) }) {
            return existingKeySet
        }

        let snapshotKey = archivedEndToEndKeySetKey(account: account, identifier: candidate.identifier)
        let snapshotData = try JSONEncoder().encode(candidate)
        try keychain.set(snapshotData, key: snapshotKey)

        do {
            let identifiers = archivedKeySets.map(\.identifier) + [candidate.identifier]
            let indexData = try JSONEncoder().encode(identifiers)
            try keychain.set(indexData, key: archivedEndToEndKeySetIndexKey(account: account))
        } catch {
            try? keychain.remove(snapshotKey)
            throw error
        }

        return candidate
    }

    /// Returns E2EE snapshots in archival order without exposing mutation APIs.
    func getArchivedEndToEndKeySets(account: String) throws -> [NCEndToEndKeySet] {
        let indexKey = archivedEndToEndKeySetIndexKey(account: account)
        guard let indexData = try keychain.getData(indexKey) else {
            return []
        }

        let identifiers = try JSONDecoder().decode([String].self, from: indexData)
        return try identifiers.map { identifier in
            let snapshotKey = archivedEndToEndKeySetKey(account: account, identifier: identifier)
            guard let snapshotData = try keychain.getData(snapshotKey) else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let keySet = try JSONDecoder().decode(NCEndToEndKeySet.self, from: snapshotData)
            guard keySet.identifier == identifier else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return keySet
        }
    }

    /// Clears only the active credentials, preserving archived key sets.
    func clearCurrentKeysEndToEnd(account: String) {
        setEndToEndCertificate(account: account, certificate: nil)
        setEndToEndPrivateKey(account: account, privateKey: nil)
        setEndToEndPublicKey(account: account, publicKey: nil)
        setEndToEndPassphrase(account: account, passphrase: nil)
    }

    /// Clears active and archived E2EE credentials for explicit local removal.
    func clearAllKeysEndToEnd(account: String) {
        clearCurrentKeysEndToEnd(account: account)
        setEndToEndServerKeyStale(account: account, stale: false)

        let snapshotPrefix = archivedEndToEndKeySetPrefix(account: account)
        for key in keychain.allKeys().filter({ $0.hasPrefix(snapshotPrefix) }) {
            try? keychain.remove(key)
        }
        try? keychain.remove(archivedEndToEndKeySetIndexKey(account: account))
    }

    private func archivedEndToEndKeySetIndexKey(account: String) -> String {
        "EndToEndArchivedKeySetIndex_" + account
    }

    private func archivedEndToEndKeySetPrefix(account: String) -> String {
        "EndToEndArchivedKeySet_" + account + "_"
    }

    private func archivedEndToEndKeySetKey(account: String, identifier: String) -> String {
        archivedEndToEndKeySetPrefix(account: account) + identifier
    }

    // MARK: - PUSH NOTIFICATION

    @objc func getPushNotificationPublicKey(account: String) -> Data? {
        let key = "PNPublicKey" + account
        return try? keychain.getData(key)
    }

    @objc func setPushNotificationPublicKey(account: String, data: Data?) {
        let key = "PNPublicKey" + account
        keychain[data: key] = data
    }

    @objc func getPushNotificationPrivateKey(account: String) -> Data? {
        let key = "PNPrivateKey" + account
        return try? keychain.getData(key)
    }

    @objc func setPushNotificationPrivateKey(account: String, data: Data?) {
        let key = "PNPrivateKey" + account
        keychain[data: key] = data
    }

    @objc func getPushNotificationSubscribingPublicKey(account: String) -> String? {
        let key = "PNSubscribingPublicKey" + account
        return try? keychain.get(key)
    }

    @objc func setPushNotificationSubscribingPublicKey(account: String, publicKey: String?) {
        let key = "PNSubscribingPublicKey" + account
        keychain[key] = publicKey
    }

    @objc func getPushNotificationToken(account: String) -> String? {
        let key = "PNToken" + account
        return try? keychain.get(key)
    }

    @objc func setPushNotificationToken(account: String, token: String?) {
        let key = "PNToken" + account
        keychain[key] = token
    }

    @objc func getPushNotificationDeviceIdentifier(account: String) -> String? {
        let key = "PNDeviceIdentifier" + account
        return try? keychain.get(key)
    }

    @objc func setPushNotificationDeviceIdentifier(account: String, deviceIdentifier: String?) {
        let key = "PNDeviceIdentifier" + account
        keychain[key] = deviceIdentifier
    }

    @objc func getPushNotificationDeviceIdentifierSignature(account: String) -> String? {
        let key = "PNDeviceIdentifierSignature" + account
        return try? keychain.get(key)
    }

    @objc func setPushNotificationDeviceIdentifierSignature(account: String, deviceIdentifierSignature: String?) {
        let key = "PNDeviceIdentifierSignature" + account
        keychain[key] = deviceIdentifierSignature
    }

    @objc func clearAllKeysPushNotification(account: String) {
        setPushNotificationPublicKey(account: account, data: nil)
        setPushNotificationSubscribingPublicKey(account: account, publicKey: nil)
        setPushNotificationPrivateKey(account: account, data: nil)
        setPushNotificationToken(account: account, token: nil)
        setPushNotificationDeviceIdentifier(account: account, deviceIdentifier: nil)
        setPushNotificationDeviceIdentifierSignature(account: account, deviceIdentifierSignature: nil)
    }

    // MARK: - Certificates

    func setClientCertificate(account: String, p12Data: Data?, p12Password: String?) {
        var key = "ClientCertificateData" + account
        keychain[data: key] = p12Data

        key = "ClientCertificatePassword" + account
        keychain[key] = p12Password
    }

    func getClientCertificate(account: String) -> (p12Data: Data?, p12Password: String?) {
        var key = "ClientCertificateData" + account
        let data = try? keychain.getData(key)

        key = "ClientCertificatePassword" + account
        let password = keychain[key]

        return (data, password)
    }

    // MARK: - Albums

    func setAutoUploadAlbumIds(account: String, albumIds: [String]) {
        let key = "AlbumIds" + account
        keychain[key] = albumIds.joined(separator: ",")
    }

    func getAutoUploadAlbumIds(account: String) -> [String] {
        let value = getStringPreference(key: "AlbumIds", account: account, defaultValue: "")
        let arrayValue = value.components(separatedBy: ",").filter { !$0.isEmpty }
        return arrayValue
    }

    // MARK: - Upload Asset (autoupload folder)

    func setUploadUseAutoUploadFolder(account: String, value: Bool) {
        let userDefaultsKey = "UploadUseAutoUploadFolder" + "_\(account)"
        setUserDefaults(value, forKey: userDefaultsKey)
    }

    func getUploadUseAutoUploadFolder(account: String) -> Bool {
        return getBoolPreference(key: "UploadUseAutoUploadFolder", account: account, defaultValue: false)

    }

    func setUploadUseAutoUploadSubFolder(account: String, value: Bool) {
        let userDefaultsKey = "UploadUseAutoUploadSubFolder" + "_\(account)"
        setUserDefaults(value, forKey: userDefaultsKey)
    }

    func getUploadUseAutoUploadSubFolder(account: String) -> Bool {
        return getBoolPreference(key: "UploadUseAutoUploadSubFolder", account: account, defaultValue: false)
    }

    func cleaningWeek() -> Bool {
        let date = Date()
        let year = Calendar.current.component(.yearForWeekOfYear, from: date)
        let week = Calendar.current.component(.weekOfYear, from: date)
        let weekString = String(format: "%04d-W%02d", year, week) // "2025-W44"
        let value = getStringPreference(key: "cleaningWeek", defaultValue: "")

        return (value == weekString) ? false : true
    }

    func setDoneCleaningWeek() {
        let date = Date()
        let year = Calendar.current.component(.yearForWeekOfYear, from: date)
        let week = Calendar.current.component(.weekOfYear, from: date)
        let weekString = String(format: "%04d-W%02d", year, week) // "2025-W44"
        setUserDefaults(weekString, forKey: "cleaningWeek")
    }

    // MARK: - Media Viewer

    var mediaViewerRepeatCurrentItem: Bool {
        get {
            getBoolPreference(
                key: "mediaViewerRepeatCurrentItem",
                defaultValue: false
            )
        }
        set {
            setUserDefaults(
                newValue,
                forKey: "mediaViewerRepeatCurrentItem"
            )
        }
    }

    var mediaViewerAutoAdvance: Bool {
        get {
            getBoolPreference(
                key: "mediaViewerAutoAdvance",
                defaultValue: false
            )
        }
        set {
            setUserDefaults(
                newValue,
                forKey: "mediaViewerAutoAdvance"
            )
        }
    }

    // MARK: - Video

    func alwaysUseVLCForVideo(account: String, ocId: String) -> Bool {
        let key = alwaysUseVLCForVideoKey(
            account: account,
            ocId: ocId
        )

        return userDefaults.object(forKey: key) as? Bool == true
    }

    func setAlwaysUseVLCForVideo(_ value: Bool, account: String, ocId: String) {
        let key = alwaysUseVLCForVideoKey(
            account: account,
            ocId: ocId
        )

        if value {
            userDefaults.set(true, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func alwaysUseVLCForVideoKey(
        account: String,
        ocId: String
    ) -> String {
        "Preferences_alwaysUseVLCForVideo_\(account)|\(ocId)"
    }

    // MARK: -

    private func migrate(key: String) {
        let keychainOLD = Keychain(service: "Crypto Cloud")
        if let value = keychainOLD[key], !value.isEmpty {
            keychain[key] = value
            keychainOLD[key] = nil
        }
    }

    private func migrateUserDefaultsToAppGroupIfNeeded() {
        guard userDefaults !== UserDefaults.standard,
              Bundle.main.object(forInfoDictionaryKey: "NSExtension") == nil,
              userDefaults.integer(forKey: Self.userDefaultsMigrationKey) < Self.userDefaultsMigrationVersion else {
            return
        }

        defer {
            userDefaults.set(Self.userDefaultsMigrationVersion, forKey: Self.userDefaultsMigrationKey)
        }

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let legacyPreferences = UserDefaults.standard.persistentDomain(forName: bundleIdentifier) else {
            return
        }

        for (key, value) in legacyPreferences where key.hasPrefix("Preferences_") {
            if userDefaults.object(forKey: key) == nil {
                userDefaults.set(value, forKey: key)
            }
        }
    }

    func removeAll() {
        try? keychain.removeAll()
    }

    private func setUserDefaults(_ value: Any?, forKey key: String) {
        let keyPreferences = "Preferences_\(key)"
        userDefaults.set(value, forKey: keyPreferences)
    }

    private func getBoolPreference(key: String, account: String? = nil, defaultValue: Bool) -> Bool {
        let suffix = account ?? ""
        let userDefaultsKey = account != nil ? "Preferences_\(key)_\(suffix)" : "Preferences_\(key)"
        let keychainKey = account != nil ? "\(key)\(suffix)" : key

        if let value = userDefaults.object(forKey: userDefaultsKey) as? Bool {
            return value
        }

        if let value = try? keychain.get(keychainKey), let boolValue = Bool(value) {
            userDefaults.set(boolValue, forKey: userDefaultsKey)
            try? keychain.remove(keychainKey)
            return boolValue
        }

        return defaultValue
    }

    private func getStringPreference(key: String, account: String? = nil, defaultValue: String) -> String {
        let suffix = account ?? ""
        let userDefaultsKey = account != nil ? "Preferences_\(key)_\(suffix)" : "Preferences_\(key)"
        let keychainKey = account != nil ? "\(key)\(suffix)" : key

        if let value = userDefaults.object(forKey: userDefaultsKey) as? String {
            return value
        }

        if let value = try? keychain.get(keychainKey) {
            userDefaults.set(value, forKey: userDefaultsKey)
            try? keychain.remove(keychainKey)
            return value
        }

        return defaultValue
    }

    private func getIntPreference(key: String, account: String? = nil, defaultValue: Int) -> Int {
        let suffix = account ?? ""
        let userDefaultsKey = account != nil ? "Preferences_\(key)_\(suffix)" : "Preferences_\(key)"
        let keychainKey = account != nil ? "\(key)\(suffix)" : key

        if let value = userDefaults.object(forKey: userDefaultsKey) as? Int {
            return value
        }

        if let value = try? keychain.get(keychainKey), let intValue = Int(value) {
            userDefaults.set(intValue, forKey: userDefaultsKey)
            try? keychain.remove(keychainKey)
            return intValue
        }

        return defaultValue
    }

    @objc func removeAll() {
        try? keychain.removeAll()
    }
}
