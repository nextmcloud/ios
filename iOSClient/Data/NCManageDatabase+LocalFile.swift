//
//  NCManageDatabase+LocalFile.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 01/08/23.
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

class tableLocalFile: Object {
    @objc dynamic var account = ""
    @objc dynamic var etag = ""
    @objc dynamic var exifDate: NSDate?
    @objc dynamic var exifLatitude = ""
    @objc dynamic var exifLongitude = ""
    @objc dynamic var exifLensModel: String?
    @objc dynamic var favorite: Bool = false
    @objc dynamic var fileName = ""
    @objc dynamic var ocId = ""
    @objc dynamic var offline: Bool = false
    @objc dynamic var lastOpeningDate = NSDate()

    override static func primaryKey() -> String {
        return "ocId"
    }
}

extension NCManageDatabase {
    // MARK: -
    // MARK: Table LocalFile - return RESULT
    func getTableLocalFile(ocId: String) -> tableLocalFile? {
        do {
            let realm = try Realm()
            return realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")

    // MARK: - Realm Write

    /// Adds or updates multiple local file entries corresponding to the given metadata array.
    /// Uses async Realm read + single write transaction. Assumes `tableLocalFile` has a primary key.
    /// - Parameters:
    ///   - metadatas: Array of `tableMetadata` to map into `tableLocalFile`.
    ///   - offline: Optional override for the `offline` flag applied to all items.
    func addLocalFilesAsync(metadatas: [tableMetadata], offline: Bool? = nil) async {
        guard !metadatas.isEmpty else {
            return
        }

        // Extract ocIds for efficient lookup
        let ocIds = metadatas.compactMap { $0.ocId }
        guard !ocIds.isEmpty else {
            return
        }

        // Preload existing entries to avoid creating duplicates
        let existingMap: [String: tableLocalFile] = await performRealmReadAsync { realm in
                let existing = realm.objects(tableLocalFile.self)
                    .filter(NSPredicate(format: "ocId IN %@", ocIds))
                return Dictionary(uniqueKeysWithValues:
                    existing.map { ($0.ocId, tableLocalFile(value: $0)) } // detached copy via value init
                )
            } ?? [:]

        await performRealmWriteAsync { realm in
            for metadata in metadatas {
                // Reuse existing object or create a new one
                let local = existingMap[metadata.ocId] ?? tableLocalFile()

                local.account = metadata.account
                local.etag = metadata.etag
                local.exifDate = NSDate()
                local.exifLatitude = "-1"
                local.exifLongitude = "-1"
                local.ocId = metadata.ocId
                local.fileName = metadata.fileName

                if let offline {
                    local.offline = offline
                }

                realm.add(local, update: .all)
            }
        }
        return nil
    }

    // MARK: -
    // MARK: Table LocalFile

    func addLocalFile(metadata: tableMetadata, offline: Bool? = nil) {
        do {
            let realm = try Realm()
            try realm.write {
                let addObject = getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) ?? tableLocalFile()
    func addLocalFile(account: String, etag: String, ocId: String, fileName: String) {
        performRealmWrite { realm in
           let addObject = tableLocalFile()
           addObject.account = account
           addObject.etag = etag
           addObject.exifDate = NSDate()
           addObject.exifLatitude = "-1"
           addObject.exifLongitude = "-1"
           addObject.ocId = ocId
           addObject.fileName = fileName
           realm.add(addObject, update: .all)
       }
    }

    func deleteLocalFileAsync(id: String?) async {
        guard let id else { return }

        await performRealmWriteAsync { realm in
            let results = realm.objects(tableLocalFile.self)
                .filter("ocId == %@", id)
            realm.delete(results)
        }
    }

    func setLocalFile(ocId: String, exifDate: NSDate?, exifLatitude: String, exifLongitude: String, exifLensModel: String?) {
        performRealmWrite { realm in
            if let result = realm.objects(tableLocalFile.self)
                .filter("ocId == %@", ocId)
                .first {
                result.exifDate = exifDate
                result.exifLatitude = exifLatitude
                result.exifLongitude = exifLongitude
                if let lensModel = exifLensModel, !lensModel.isEmpty {
                    result.exifLensModel = lensModel
                }
            }
        }
    }

    func setOffLocalFileAsync(ocId: String) async {
        await performRealmWriteAsync { realm in
            if let result = realm.objects(tableLocalFile.self)
                .filter("ocId == %@", ocId)
                .first {
                result.offline = false
            }
        }
    }

    func setLocalFileLastOpeningDateAsync(metadata: tableMetadata) async {
        await performRealmWriteAsync { realm in
            if let result = realm.objects(tableLocalFile.self)
                .filter("ocId == %@", metadata.ocId)
                .first {
                result.lastOpeningDate = NSDate()
            } else {
                let addObject = tableLocalFile()
                addObject.account = metadata.account
                addObject.etag = metadata.etag
                addObject.exifDate = NSDate()
                addObject.exifLatitude = "-1"
                addObject.exifLongitude = "-1"
                addObject.ocId = metadata.ocId
                addObject.fileName = metadata.fileName
                if let offline {
                    addObject.offline = offline
                }
                realm.add(addObject, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func addLocalFile(account: String, etag: String, ocId: String, fileName: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let addObject = tableLocalFile()
                addObject.account = account
                addObject.etag = etag
                addObject.exifDate = NSDate()
                addObject.exifLatitude = "-1"
                addObject.exifLongitude = "-1"
                addObject.ocId = ocId
                addObject.fileName = fileName
                realm.add(addObject, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func deleteLocalFileOcId(_ ocId: String?) {
        guard let ocId else { return }

        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId)
                realm.delete(results)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setLocalFile(ocId: String, fileName: String?) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first
                if let fileName {
                    result?.fileName = fileName
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    @objc func setLocalFile(ocId: String, exifDate: NSDate?, exifLatitude: String, exifLongitude: String, exifLensModel: String?) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first {
                    result.exifDate = exifDate
                    result.exifLatitude = exifLatitude
                    result.exifLongitude = exifLongitude
                    if exifLensModel?.count ?? 0 > 0 {
                        result.exifLensModel = exifLensModel
                    }
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setOffLocalFile(ocId: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableLocalFile.self).filter("ocId == %@", ocId).first
                result?.offline = false
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func getTableLocalFile(account: String) -> [tableLocalFile] {
        do {
            let realm = try Realm()
            let results = realm.objects(tableLocalFile.self).filter("account == %@", account)
            return Array(results.map { tableLocalFile.init(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return []
    func getTableLocalFilesAsyncs(predicate: NSPredicate) async -> [tableLocalFile] {
    func getTableLocalFilesAsync(predicate: NSPredicate, sorted: String = "fileName", ascending: Bool = true) async -> [tableLocalFile] {
        await performRealmReadAsync { realm in
            realm.objects(tableLocalFile.self)
                .filter(predicate)
                .sorted(byKeyPath: sorted, ascending: ascending)
                .map { tableLocalFile(value: $0) }
        } ?? []
    }

    func getTableLocalFile(predicate: NSPredicate) -> tableLocalFile? {
        do {
            let realm = try Realm()
            guard let result = realm.objects(tableLocalFile.self).filter(predicate).first else { return nil }
            return tableLocalFile.init(value: result)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getResultsTableLocalFile(predicate: NSPredicate) -> Results<tableLocalFile>? {
        do {
            let realm = try Realm()
            return realm.objects(tableLocalFile.self).filter(predicate)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
    func getTableLocalFileAsync(predicate: NSPredicate) async -> tableLocalFile? {
        await performRealmReadAsync { realm in
            realm.objects(tableLocalFile.self)
                .filter(predicate)
                .first
                .map { tableLocalFile(value: $0) }
        }
    }

    func getTableLocal(predicate: NSPredicate,
                       completion: @escaping (_ localFile: tableLocalFile?) -> Void) {
        performRealmRead({ realm in
            return realm.objects(tableLocalFile.self)
                .filter(predicate)
                .first
        }, sync: false) { result in
            let detachedResult = result.map { tableLocalFile(value: $0) }
            let deliver: () -> Void = {
                completion(detachedResult)
            }

            DispatchQueue.main.async(execute: deliver)
        }
        return nil
    }

    func getTableLocalFiles(predicate: NSPredicate, sorted: String, ascending: Bool) -> [tableLocalFile] {
        do {
            let realm = try Realm()
            let results = realm.objects(tableLocalFile.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
            return Array(results.map { tableLocalFile.init(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return []
    }

    func getResultsTableLocalFile(predicate: NSPredicate, sorted: String, ascending: Bool) -> Results<tableLocalFile>? {
        do {
            let realm = try Realm()
            return realm.objects(tableLocalFile.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func setLastOpeningDate(metadata: tableMetadata) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableLocalFile.self).filter("ocId == %@", metadata.ocId).first {
                    result.lastOpeningDate = NSDate()
                } else {
                    let addObject = tableLocalFile()
                    addObject.account = metadata.account
                    addObject.etag = metadata.etag
                    addObject.exifDate = NSDate()
                    addObject.exifLatitude = "-1"
                    addObject.exifLongitude = "-1"
                    addObject.ocId = metadata.ocId
                    addObject.fileName = metadata.fileName
                    realm.add(addObject, update: .all)
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        return performRealmRead { realm in
            Array(
                realm.objects(tableLocalFile.self)
                    .filter(predicate)
                    .sorted(byKeyPath: sorted, ascending: ascending)
                    .map { tableLocalFile(value: $0) }
            )
        } ?? []
    }

    func getTableLocalFilesAsync(predicate: NSPredicate, sorted: String, ascending: Bool) async -> [tableLocalFile] {
        await performRealmReadAsync { realm in
            realm.objects(tableLocalFile.self)
                .filter(predicate)
                .sorted(byKeyPath: sorted, ascending: ascending)
                .map { tableLocalFile(value: $0) }
        } ?? []
    }

    func getResultTableLocalFile(ocId: String) -> tableLocalFile? {
        return performRealmRead { realm in
            realm.objects(tableLocalFile.self)
                .filter("ocId == %@", ocId)
                .first
        }
    }
}
