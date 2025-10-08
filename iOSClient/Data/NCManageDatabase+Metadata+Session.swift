//
//  NCManageDatabase+Metadata+Session.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/02/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
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

extension NCManageDatabase {
    func setMetadataSession(ocId: String,
                            newFileName: String? = nil,
                            session: String? = nil,
                            sessionTaskIdentifier: Int? = nil,
                            sessionError: String? = nil,
                            selector: String? = nil,
                            status: Int? = nil,
                            etag: String? = nil,
                            errorCode: Int? = nil) {

        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first {
                    if let newFileName = newFileName {
                        result.fileName = newFileName
                        result.fileNameView = newFileName
                    }
                    if let session {
                        result.session = session
                    }
                    if let sessionTaskIdentifier {
                        result.sessionTaskIdentifier = sessionTaskIdentifier
                    }
                    if let sessionError {
                        result.sessionError = sessionError
                        if sessionError.isEmpty {
                            result.errorCode = 0
                        }
                    }
                    if let selector {
                        result.sessionSelector = selector
                    }
                    if let status {
                        result.status = status
                        if status == NCGlobal.shared.metadataStatusWaitDownload || status == NCGlobal.shared.metadataStatusWaitUpload {
                            result.sessionDate = Date()
                        } else if status == NCGlobal.shared.metadataStatusNormal {
                            result.sessionDate = nil
                        }
                    }
                    if let etag {
                        result.etag = etag
                    }
                    if let errorCode {
                        result.errorCode = errorCode
                    }
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")

    // MARK: - Realm Write

    /// Updates session-related fields for a given `tableMetadata` object, in an async-safe Realm write.
    ///
    /// - Parameters:
    ///   - ocId: Unique identifier of the metadata entry.
    ///   - newFileName: Optional new filename.
    ///   - session: Optional session identifier.
    ///   - sessionTaskIdentifier: Optional task ID.
    ///   - sessionError: Optional error string (clears error code if empty).
    ///   - selector: Optional session selector.
    ///   - status: Optional metadata status (may reset sessionDate).
    ///   - etag: Optional ETag string.
    ///   - errorCode: Optional error code to persist.
    /// - Returns: A detached copy of the updated `tableMetadata` object, or `nil` if not found.
    @discardableResult
    func setMetadataSessionAsync(account: String? = nil,
                                 ocId: String? = nil,
                                 serverUrlFileName: String? = nil,
                                 newFileName: String? = nil,
                                 session: String? = nil,
                                 sessionTaskIdentifier: Int? = nil,
                                 sessionError: String? = nil,
                                 selector: String? = nil,
                                 status: Int? = nil,
                                 etag: String? = nil,
                                 errorCode: Int? = nil,
                                 progress: Double? = nil) async -> tableMetadata? {
        var query: NSPredicate = NSPredicate()
        if let ocId {
            query = NSPredicate(format: "ocId == %@", ocId)
        } else if let account, let serverUrlFileName {
            query = NSPredicate(format: "account == %@ AND serverUrlFileName == %@", account, serverUrlFileName)
        } else {
            return nil
        }

        await performRealmWriteAsync { realm in
            guard let metadata = realm.objects(tableMetadata.self)
                .filter(query)
                .first else {
                    return
            }

            if let name = newFileName {
                metadata.fileName = name
                metadata.fileNameView = name
            }

            if let session {
                metadata.session = session
            }

            if let sessionTaskIdentifier {
                metadata.sessionTaskIdentifier = sessionTaskIdentifier
            }

            if let sessionError {
                metadata.sessionError = sessionError
                if sessionError.isEmpty {
                    metadata.errorCode = 0
                }
            }

            if let selector {
                metadata.sessionSelector = selector
            }

            if let status {
                metadata.status = status
                switch status {
                case NCGlobal.shared.metadataStatusWaitDownload,
                     NCGlobal.shared.metadataStatusWaitUpload:
                    metadata.sessionDate = Date()
                case NCGlobal.shared.metadataStatusNormal:
                    metadata.sessionDate = nil
                default: break
                }
            }

            if let etag {
                metadata.etag = etag
            }

            if let errorCode {
                metadata.errorCode = errorCode
            }

            if let progress {
                metadata.progress = progress
            }
        }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(query)
                .first?
                .detachedCopy()
        }
    }

    func setMetadataProgress(fileName: String,
                             serverUrl: String,
                             taskIdentifier: Int,
                             progress: Double) async {
        await performRealmWriteAsync { realm in
            guard let metadata = realm.objects(tableMetadata.self)
                .filter("fileName == %@ AND serverUrl == %@ and sessionTaskIdentifier == %d", fileName, serverUrl, taskIdentifier)
                .first else {
                return
            }
            metadata.progress = progress
            print(progress)
        }
    }

    func setMetadataProgress(ocId: String,
                             progress: Double) async {
        await performRealmWriteAsync { realm in
            guard let metadata = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first else {
                return
            }
            metadata.progress = progress
            print(progress)
        }
    }

    /// Asynchronously sets a metadata record into "wait download" state.
    /// - Parameters:
    ///   - ocId: The object ID of the metadata.
    ///   - session: The session name to associate.
    ///   - selector: The selector name to track the download.
    ///   - sceneIdentifier: Optional scene ID.
    /// - Returns: An unmanaged copy of the updated metadata, or nil if not found.
    @discardableResult
    func setMetadatasSessionInWaitDownload(metadatas: [tableMetadata], session: String, selector: String, sceneIdentifier: String? = nil) -> tableMetadata? {
        if metadatas.isEmpty { return nil }
        var metadataUpdated: tableMetadata?

        do {
            let realm = try Realm()
            try realm.write {
                for metadata in metadatas {
                    if let result = realm.objects(tableMetadata.self).filter("ocId == %@", metadata.ocId).first {
                        result.sceneIdentifier = sceneIdentifier
                        result.session = session
                        result.sessionTaskIdentifier = 0
                        result.sessionError = ""
                        result.sessionSelector = selector
                        result.status = NCGlobal.shared.metadataStatusWaitDownload
                        result.sessionDate = Date()
                        metadataUpdated = tableMetadata(value: result)
                    } else {
                        metadata.sceneIdentifier = sceneIdentifier
                        metadata.session = session
                        metadata.sessionTaskIdentifier = 0
                        metadata.sessionError = ""
                        metadata.sessionSelector = selector
                        metadata.status = NCGlobal.shared.metadataStatusWaitDownload
                        metadata.sessionDate = Date()
                        realm.add(metadata, update: .all)
                        metadataUpdated = tableMetadata(value: metadata)
                    }
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }

        return metadataUpdated
    }

    func clearMetadataSession(metadatas: [tableMetadata]) {
        do {
            let realm = try Realm()
            try realm.write {
                for metadata in metadatas {
                    if let result = realm.objects(tableMetadata.self).filter("ocId == %@", metadata.ocId).first {
                        result.sceneIdentifier = nil
                        result.session = ""
                        result.sessionTaskIdentifier = 0
                        result.sessionError = ""
                        result.sessionSelector = ""
                        result.sessionDate = nil
                        result.status = NCGlobal.shared.metadataStatusNormal
                    }
                }
    func setMetadataSessionInWaitDownloadAsync(ocId: String,
                                               session: String,
                                               selector: String,
                                               sceneIdentifier: String? = nil) async -> tableMetadata? {
        await performRealmWriteAsync { realm in
            guard let metadata = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first else {
                return
            }

            metadata.sceneIdentifier = sceneIdentifier
            metadata.session = session
            metadata.sessionTaskIdentifier = 0
            metadata.sessionError = ""
            metadata.sessionSelector = selector
            metadata.status = NCGlobal.shared.metadataStatusWaitDownload
            metadata.sessionDate = Date()
            metadata.progress = 0
        }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first?
                .detachedCopy()
        }
    }

    /// Asynchronously clears session-related metadata for a list of `tableMetadata` entries.
    /// - Parameter metadatas: An array of `tableMetadata` objects to be cleared and updated.
    func clearMetadatasSessionAsync(metadatas: [tableMetadata]) async {
        guard !metadatas.isEmpty else {
            return
        }

        // Detach objects before modifying
        var detachedMetadatas = metadatas.map { $0.detachedCopy() }

        // Apply modifications
        detachedMetadatas = detachedMetadatas.map { metadata in
            metadata.sceneIdentifier = nil
            metadata.session = ""
            metadata.sessionTaskIdentifier = 0
            metadata.sessionError = ""
            metadata.sessionSelector = ""
            metadata.sessionDate = nil
            metadata.status = NCGlobal.shared.metadataStatusNormal
            metadata.progress = 0
            return metadata
        }

        // Write to Realm asynchronously
        await performRealmWriteAsync { realm in
            detachedMetadatas.forEach { metadata in
                realm.add(metadata, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func clearMetadataSession(metadata: tableMetadata) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", metadata.ocId).first {
                    result.sceneIdentifier = nil
                    result.session = ""
                    result.sessionTaskIdentifier = 0
                    result.sessionError = ""
                    result.sessionSelector = ""
                    result.sessionDate = nil
                    result.status = NCGlobal.shared.metadataStatusNormal
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    @discardableResult
    func setMetadataStatus(ocId: String, status: Int) -> tableMetadata? {
        var result: tableMetadata?

        do {
            let realm = try Realm()
            try realm.write {
                result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                result?.status = status

                if status == NCGlobal.shared.metadataStatusNormal {
                    result?.sessionDate = nil
                } else {
                    result?.sessionDate = Date()
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
        if let result {
            return tableMetadata.init(value: result)
        } else {
            return nil
        }
    }

    func getMetadata(from url: URL?, sessionTaskIdentifier: Int) -> tableMetadata? {
    // MARK: - Realm Read

    func getMetadataAsync(from url: URL?, sessionTaskIdentifier: Int) async -> tableMetadata? {
        guard let url,
              var serverUrl = url.deletingLastPathComponent().absoluteString.removingPercentEncoding
        else { return nil }
        let fileName = url.lastPathComponent

        if serverUrl.hasSuffix("/") {
            serverUrl = String(serverUrl.dropLast())
        }
        let predicate = NSPredicate(format: "serverUrl == %@ AND fileName == %@ AND sessionTaskIdentifier == %d",
                                    serverUrl,
                                    fileName,
                                    sessionTaskIdentifier)

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .first
                .map { $0.detachedCopy() }
        }
    }

    func updateBadge() async {
        #if !EXTENSION
        let num = await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(NSPredicate(format: "status != %i", NCGlobal.shared.metadataStatusNormal))
                .count
        } ?? 0
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = num
        }
        #endif
    }
}
