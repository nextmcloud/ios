//
//  NCManageDatabase+Capabilities.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 29/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
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

import Foundation
import UIKit
import RealmSwift
import NextcloudKit

class tableCapabilities: Object {
    @Persisted(primaryKey: true) var account = ""
    @Persisted var capabilities: Data?
    @Persisted var editors: Data?
}

extension NCManageDatabase {
    func addCapabilitiesJSon(_ data: Data, account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let addObject = tableCapabilities()
                addObject.account = account
                addObject.jsondata = data
                realm.add(addObject, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func getCapabilities(account: String) -> Data? {
        do {
            let realm = try Realm()
            guard let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first else { return nil }
            return result.jsondata
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }

        return nil
    }

    @discardableResult
    func setCapabilities(account: String, data: Data? = nil) -> NCCapabilities.Capabilities? {
        let jsonData: Data?

    // MARK: - Realm write

    /// Stores the raw JSON capabilities in Realm associated with an account.
    /// - Parameters:
    ///   - data: The raw JSON data returned from the capabilities endpoint.
    ///   - account: The account identifier.
    /// - Throws: Rethrows any error encountered during the Realm write operation.
    func setDataCapabilities(data: Data, account: String) async {
        await performRealmWriteAsync { realm in
            let object = realm.object(ofType: tableCapabilities.self, forPrimaryKey: account)
            let addObject: tableCapabilities

            if let existing = object {
                addObject = existing
            } else {
                let newObject = tableCapabilities()
                newObject.account = account
                addObject = newObject
            }

            addObject.capabilities = data

            realm.add(addObject, update: .all)
        }
    }

    /// Stores the raw JSON editors data in Realm associated with an account.
    /// - Parameters:
    ///   - data: The raw JSON data returned from the text editors endpoint.
    ///   - account: The account identifier.
    /// - Throws: Rethrows any error encountered during the Realm write operation.
    func setDataCapabilitiesEditors(data: Data, account: String) async {
        await performRealmWriteAsync { realm in
            let object = realm.object(ofType: tableCapabilities.self, forPrimaryKey: account)
            let addObject: tableCapabilities

            if let existing = object {
                addObject = existing
            } else {
                let newObject = tableCapabilities()
                newObject.account = account
                addObject = newObject
            }

            addObject.editors = data

        if let data {
            jsonData = data
        } else {
            do {
                let realm = try Realm()
                guard let result = realm.objects(tableCapabilities.self).filter("account == %@", account).first,
                      let data = result.jsondata else {
                    return nil
                }
                jsonData = data
            } catch let error as NSError {
                NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
                return nil
            }
        }
        guard let jsonData = jsonData else {
            return nil
        }

        do {
            let json = try JSONDecoder().decode(CapabilityNextcloud.self, from: jsonData)
            let data = json.ocs.data
            let capabilities = NCCapabilities.Capabilities()

            capabilities.capabilityServerVersion = data.version.string
            capabilities.capabilityServerVersionMajor = data.version.major

            if capabilities.capabilityServerVersionMajor > 0 {
                NextcloudKit.shared.updateSession(account: account, nextcloudVersion: capabilities.capabilityServerVersionMajor)
            }

            capabilities.capabilityFileSharingApiEnabled = data.capabilities.filessharing?.apienabled ?? false
            capabilities.capabilityFileSharingDefaultPermission = data.capabilities.filessharing?.defaultpermissions ?? 0
            capabilities.capabilityFileSharingPubPasswdEnforced = data.capabilities.filessharing?.ncpublic?.password?.enforced ?? false
            capabilities.capabilityFileSharingPubExpireDateEnforced = data.capabilities.filessharing?.ncpublic?.expiredate?.enforced ?? false
            capabilities.capabilityFileSharingPubExpireDateDays = data.capabilities.filessharing?.ncpublic?.expiredate?.days ?? 0
            capabilities.capabilityFileSharingInternalExpireDateEnforced = data.capabilities.filessharing?.ncpublic?.expiredateinternal?.enforced ?? false
            capabilities.capabilityFileSharingInternalExpireDateDays = data.capabilities.filessharing?.ncpublic?.expiredateinternal?.days ?? 0
            capabilities.capabilityFileSharingRemoteExpireDateEnforced = data.capabilities.filessharing?.ncpublic?.expiredateremote?.enforced ?? false
            capabilities.capabilityFileSharingRemoteExpireDateDays = data.capabilities.filessharing?.ncpublic?.expiredateremote?.days ?? 0
            capabilities.capabilityFileSharingDownloadLimit = data.capabilities.downloadLimit?.enabled ?? false
            capabilities.capabilityFileSharingDownloadLimitDefaultLimit = data.capabilities.downloadLimit?.defaultLimit ?? 1

            capabilities.capabilityThemingColor = data.capabilities.theming?.color ?? ""
            capabilities.capabilityThemingColorElement = data.capabilities.theming?.colorelement ?? ""
            capabilities.capabilityThemingColorText = data.capabilities.theming?.colortext ?? ""
            capabilities.capabilityThemingName = data.capabilities.theming?.name ?? ""
            capabilities.capabilityThemingSlogan = data.capabilities.theming?.slogan ?? ""

            capabilities.capabilityE2EEEnabled = data.capabilities.endtoendencryption?.enabled ?? false
            capabilities.capabilityE2EEApiVersion = data.capabilities.endtoendencryption?.apiversion ?? ""

            capabilities.capabilityRichDocumentsEnabled = json.ocs.data.capabilities.richdocuments?.directediting ?? false
            capabilities.capabilityRichDocumentsMimetypes.removeAll()
            if let mimetypes = data.capabilities.richdocuments?.mimetypes {
                for mimetype in mimetypes {
                    capabilities.capabilityRichDocumentsMimetypes.append(mimetype)
                }
            }

            capabilities.capabilityAssistantEnabled = data.capabilities.assistant?.enabled ?? false

            capabilities.capabilityActivityEnabled = data.capabilities.activity != nil

            capabilities.capabilityActivity.removeAll()
            if let activities = data.capabilities.activity?.apiv2 {
                for activity in activities {
                    capabilities.capabilityActivity.append(activity)
                }
            }

            capabilities.capabilityNotification.removeAll()
            if let notifications = data.capabilities.notifications?.ocsendpoints {
                for notification in notifications {
                    capabilities.capabilityNotification.append(notification)
                }
            }

            capabilities.capabilityFilesUndelete = data.capabilities.files?.undelete ?? false
            capabilities.capabilityFilesLockVersion = data.capabilities.files?.locking ?? ""
            capabilities.capabilityFilesComments = data.capabilities.files?.comments ?? false
            capabilities.capabilityFilesBigfilechunking = data.capabilities.files?.bigfilechunking ?? false

            capabilities.capabilityUserStatusEnabled = data.capabilities.userstatus?.enabled ?? false
            if data.capabilities.external != nil {
                capabilities.capabilityExternalSites = true
            }
            capabilities.capabilityGroupfoldersEnabled = data.capabilities.groupfolders?.hasGroupFolders ?? false

            if capabilities.capabilityServerVersionMajor >= NCGlobal.shared.nextcloudVersion28 {
                capabilities.isLivePhotoServerAvailable = true
            }

            capabilities.capabilitySecurityGuardDiagnostics = data.capabilities.securityguard?.diagnostics ?? false

            capabilities.capabilityForbiddenFileNames = data.capabilities.files?.forbiddenFileNames ?? []
            capabilities.capabilityForbiddenFileNameBasenames = data.capabilities.files?.forbiddenFileNameBasenames ?? []
            capabilities.capabilityForbiddenFileNameCharacters = data.capabilities.files?.forbiddenFileNameCharacters ?? []
            capabilities.capabilityForbiddenFileNameExtensions = data.capabilities.files?.forbiddenFileNameExtensions ?? []

            capabilities.capabilityRecommendations = data.capabilities.recommendations?.enabled ?? false

            NCCapabilities.shared.appendCapabilities(account: account, capabilities: capabilities)

            return capabilities
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
            return nil
            realm.add(addObject, update: .all)
        }
    }

    /// Applies cached capabilities and editors from Realm for a given account.
    ///
    /// This function reads the cached `capabilities` and `editors` JSON `Data`
    /// from the local Realm `tableCapabilities` object associated with the specified account.
    ///
    /// - If `capabilities` is found, it is applied using `NextcloudKit.shared.setCapabilitiesAsync`.
    /// - If `editors` is found, the data is decoded via `NKEditorDetailsConverter` into
    ///   `[NKEditorDetailsEditor]` and `[NKEditorDetailsCreator]`, then injected into the shared `NKCapabilities` object.
    ///
    /// The combined updated capabilities are then re-appended via `appendCapabilitiesAsync`.
    /// Errors during decoding or async storage are caught and logged.
    ///
    /// - Parameter account: The identifier of the account whose cached capabilities should be applied.
    @discardableResult
    func getCapabilities(account: String) async -> NKCapabilities.Capabilities? {
        let results = await performRealmReadAsync { realm in
            realm.object(ofType: tableCapabilities.self, forPrimaryKey: account)
                .map { tableCapabilities(value: $0) }
        }
        var capabilities: NKCapabilities.Capabilities?

        do {
            if let data = results?.capabilities {
                capabilities = try await NextcloudKit.shared.setCapabilitiesAsync(account: account, data: data)
            }
            if let data = results?.editors {
                let (editors, creators) = try NKEditorDetailsConverter.from(data: data)

                if capabilities == nil {
                    capabilities = await NKCapabilities.shared.getCapabilities(for: account)
                }

                capabilities?.directEditingEditors = editors
                capabilities?.directEditingCreators = creators

                if let capabilities {
                    await NKCapabilities.shared.setCapabilities(for: account, capabilities: capabilities)
                }
            }
        } catch {
            nkLog(error: "Error reading capabilities JSON in Realm \(error)")
        }

        // use Networking
        NCNetworking.shared.capabilities[account] = capabilities

        return capabilities
    }
}
