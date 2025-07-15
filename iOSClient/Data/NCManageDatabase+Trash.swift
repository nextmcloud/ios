//
//  NCManageDatabase+Trash.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 13/11/23.
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

class tableTrash: Object {
    @objc dynamic var account = ""
    @objc dynamic var classFile = ""
    @objc dynamic var contentType = ""
    @objc dynamic var date = NSDate()
    @objc dynamic var directory: Bool = false
    @objc dynamic var fileId = ""
    @objc dynamic var fileName = ""
    @objc dynamic var filePath = ""
    @objc dynamic var hasPreview: Bool = false
    @objc dynamic var iconName = ""
    @objc dynamic var size: Int64 = 0
    @objc dynamic var trashbinFileName = ""
    @objc dynamic var trashbinOriginalLocation = ""
    @objc dynamic var trashbinDeletionTime = NSDate()

    override static func primaryKey() -> String {
        return "fileId"
    }
}

extension NCManageDatabase {
    func addTrash(account: String, items: [NKTrash]) {
        do {
            let realm = try Realm()
            try realm.write {
                for trash in items {
                    let object = tableTrash()
                    object.account = account
                    object.contentType = trash.contentType
                    object.date = trash.date as NSDate
                    object.directory = trash.directory
                    object.fileId = trash.fileId
                    object.fileName = trash.fileName
                    object.filePath = trash.filePath
                    object.hasPreview = trash.hasPreview
                    object.iconName = trash.iconName
                    object.size = trash.size
                    object.trashbinDeletionTime = trash.trashbinDeletionTime as NSDate
                    object.trashbinFileName = trash.trashbinFileName
                    object.trashbinOriginalLocation = trash.trashbinOriginalLocation
                    object.classFile = trash.classFile
                    realm.add(object, update: .all)
                }

    // MARK: - Realm write

    /// Adds a list of `NKTrash` items to the Realm database, associated with the given account.
    /// This function creates new `tableTrash` objects and inserts or updates them in the Realm, wrapped in an async write operation.
    /// - Parameters:
    ///   - account: The account string used to associate each trash item.
    ///   - items: An array of `NKTrash` items to be added to the database.
    func addTrashAsync(items: [NKTrash], account: String) async {
        await performRealmWriteAsync { realm in
            items.forEach { trash in
                let object = tableTrash()
                object.account = account
                object.contentType = trash.contentType
                object.date = trash.date as NSDate
                object.directory = trash.directory
                object.fileId = trash.fileId
                object.fileName = trash.fileName
                object.filePath = trash.filePath
                object.hasPreview = trash.hasPreview
                object.iconName = trash.iconName
                object.size = trash.size
                object.trashbinDeletionTime = trash.trashbinDeletionTime as NSDate
                object.trashbinFileName = trash.trashbinFileName
                object.trashbinOriginalLocation = trash.trashbinOriginalLocation
                object.classFile = trash.classFile
                realm.add(object, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func deleteTrash(filePath: String?, account: String) {
        var predicate = NSPredicate()

        do {
            let realm = try Realm()
            try realm.write {
                if filePath == nil {
                    predicate = NSPredicate(format: "account == %@", account)
                } else {
                    predicate = NSPredicate(format: "account == %@ AND filePath == %@", account, filePath!)
                }
                let result = realm.objects(tableTrash.self).filter(predicate)
                realm.delete(result)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func deleteTrash(fileId: String?, account: String) {
        var predicate = NSPredicate()

        do {
            let realm = try Realm()
            try realm.write {
                if fileId == nil {
                    predicate = NSPredicate(format: "account == %@", account)
                } else {
                    predicate = NSPredicate(format: "account == %@ AND fileId == %@", account, fileId!)
                }
                let result = realm.objects(tableTrash.self).filter(predicate)
                realm.delete(result)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func getResultsTrash(filePath: String, account: String) -> Results<tableTrash>? {
        do {
            let realm = try Realm()
            return realm.objects(tableTrash.self).filter("account == %@ AND filePath == %@", account, filePath).sorted(byKeyPath: "trashbinDeletionTime", ascending: false)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access to database: \(error)")
    /// Asynchronously deletes `tableTrash` objects matching the given `fileId` and `account`.
    /// - Parameters:
    ///   - fileId: Optional file ID to filter the trash entries. If `nil`, all entries for the account will be deleted.
    ///   - account: The account associated with the trash entries.
    func deleteTrashAsync(fileId: String?, account: String) async {
        let predicate: NSPredicate
        if let fileId {
            predicate = NSPredicate(format: "account == %@ AND fileId == %@", account, fileId)
        } else {
            predicate = NSPredicate(format: "account == %@", account)
        }

        await performRealmWriteAsync { realm in
            let results = realm.objects(tableTrash.self).filter(predicate)
            realm.delete(results)
        }
        return nil
    }

    func getResultTrashItem(fileId: String, account: String) -> tableTrash? {
        do {
            let realm = try Realm()
            return realm.objects(tableTrash.self).filter("account == %@ AND fileId == %@", account, fileId).first
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access to database: \(error)")
    // MARK: - Realm read

    func getTableTrash(fileId: String, account: String) -> tableTrash? {
        performRealmRead { realm in
            realm.objects(tableTrash.self)
                .filter("account == %@ AND fileId == %@", account, fileId)
                .first
                .map { tableTrash(value: $0) }
        }
    }

    /// Asynchronously retrieves sorted trash results by filePath and account.
    /// - Returns: A `Results<tableTrash>` collection, or `nil` if Realm fails to open.
    func getTableTrashAsync(filePath: String, account: String) async -> [tableTrash] {
        await performRealmReadAsync { realm in
            let results = realm.objects(tableTrash.self)
                .filter("account == %@ AND filePath == %@", account, filePath)
                .sorted(byKeyPath: "trashbinDeletionTime", ascending: false)
            return results.map { tableTrash(value: $0) }
        } ?? []
    }

    /// Asynchronously retrieves the first `tableTrash` object matching the given `fileId` and `account`.
    /// - Parameters:
    ///   - fileId: The ID of the file to search for.
    ///   - account: The account associated with the file.
    /// - Returns: The matching `tableTrash` object, or `nil` if not found.
    func getTableTrashAsync(fileId: String, account: String) async -> tableTrash? {
        await performRealmReadAsync { realm in
            return realm.objects(tableTrash.self)
                .filter("account == %@ AND fileId == %@", account, fileId)
                .first
                .map { tableTrash(value: $0) }
        }
        return nil
    }
}
