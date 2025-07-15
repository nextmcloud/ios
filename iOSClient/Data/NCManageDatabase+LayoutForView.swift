//
//  NCManageDatabase+LayoutForView.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 28/11/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
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

class NCDBLayoutForView: Object {
    @Persisted(primaryKey: true) var index = ""
    @Persisted var account = ""
    @Persisted var keyStore = ""
    @Persisted var layout: String = NCGlobal.shared.layoutList
    @Persisted var sort: String = "fileName"
    @Persisted var ascending: Bool = true
    @Persisted var groupBy: String = "none"
    @Persisted var titleButtonHeader: String = "_sorted_by_name_a_z_"
    @Persisted var columnGrid: Int = 3
    @Persisted var columnPhoto: Int = 3
}

extension NCManageDatabase {
    @discardableResult
    func setLayoutForView(account: String,
                          key: String,
                          serverUrl: String,
                          layout: String? = nil,
                          sort: String? = nil,
                          ascending: Bool? = nil,
                          groupBy: String? = nil,
                          titleButtonHeader: String? = nil,
                          columnGrid: Int? = nil,
                          columnPhoto: Int? = nil) -> NCDBLayoutForView? {
        var keyStore = key
        if !serverUrl.isEmpty { keyStore = serverUrl}
        let index = account + " " + keyStore
        var addObject = NCDBLayoutForView()

        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(NCDBLayoutForView.self).filter("index == %@", index).first {
                    addObject = result
                } else {
                    addObject.index = index
                }
                addObject.account = account
                addObject.keyStore = keyStore
                if let layout {
                    addObject.layout = layout
                }
                if let sort {
                    addObject.sort = sort
                }
                if let sort {
                    addObject.sort = sort
                }
                if let ascending {
                    addObject.ascending = ascending
                }
                if let groupBy {
                    addObject.groupBy = groupBy
                }
                if let titleButtonHeader {
                    addObject.titleButtonHeader = titleButtonHeader
                }
                if let columnGrid {
                    addObject.columnGrid = columnGrid
                }
                if let columnPhoto {
                    addObject.columnPhoto = columnPhoto
                }
                realm.add(addObject, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
        return NCDBLayoutForView(value: addObject)
    }

    @discardableResult
    func setLayoutForView(layoutForView: NCDBLayoutForView) -> NCDBLayoutForView? {
        let result = NCDBLayoutForView(value: layoutForView)

        do {
            let realm = try Realm()
            try realm.write {
                realm.add(result, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
            return nil
        }
        return NCDBLayoutForView(value: result)
    }

    func getLayoutForView(account: String, key: String, serverUrl: String) -> NCDBLayoutForView? {
        var keyStore = key
        if !serverUrl.isEmpty { keyStore = serverUrl}
        let index = account + " " + keyStore

        do {
            let realm = try Realm()
            if let result = realm.objects(NCDBLayoutForView.self).filter("index == %@", index).first {
                return NCDBLayoutForView(value: result)
            } else {
                return setLayoutForView(account: account, key: key, serverUrl: serverUrl)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return setLayoutForView(account: account, key: key, serverUrl: serverUrl)
    // MARK: - Realm read

    func getLayoutForView(account: String, key: String, serverUrl: String, layout: String? = nil) -> NCDBLayoutForView {
        let keyStore = serverUrl.isEmpty ? key : serverUrl
        let index = account + " " + keyStore

        if let layout = performRealmRead({
            $0.objects(NCDBLayoutForView.self)
                .filter("index == %@", index)
                .first
                .map { NCDBLayoutForView(value: $0) }
        }) {
            return layout
        }

        DispatchQueue.global(qos: .utility).async {
            _ = self.setLayoutForView(account: account, key: key, serverUrl: serverUrl, layout: layout)
        }

        let placeholder = NCDBLayoutForView()
        placeholder.index = index
        placeholder.account = account
        placeholder.keyStore = keyStore
        if let layout {
            placeholder.layout = layout
        }
        return placeholder
    }

    /// Returns the stored layout for a given account and key, or creates a placeholder.
    /// If not found, triggers an async write to persist the layout.
    func getLayoutForViewAsync(account: String, key: String, serverUrl: String, layout: String? = nil) async -> NCDBLayoutForView {
        let keyStore = serverUrl.isEmpty ? key : serverUrl
        let index = account + " " + keyStore

        // Try to read from Realm
        if let existing = await performRealmReadAsync({ realm in
            realm.objects(NCDBLayoutForView.self)
                .filter("index == %@", index)
                .first
                .map { NCDBLayoutForView(value: $0) }
        }) {
            return existing
        }

        // Return placeholder immediately
        let placeholder = NCDBLayoutForView()
        placeholder.index = index
        placeholder.account = account
        placeholder.keyStore = keyStore
        if let layout {
            placeholder.layout = layout
        }
        return placeholder
    }

    func updateLayoutForView(account: String,
                             key: String,
                             serverUrl: String,
                             updateBlock: @escaping (inout NCDBLayoutForView) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let keyStore = serverUrl.isEmpty ? key : serverUrl
            let index = account + " " + keyStore

            var layout: NCDBLayoutForView

            if let existing = self.performRealmRead({
                $0.objects(NCDBLayoutForView.self)
                    .filter("index == %@", index)
                    .first
            }) {
                layout = existing
            } else {
                layout = NCDBLayoutForView()
                layout.index = index
                layout.account = account
                layout.keyStore = keyStore
            }

            // Applica la modifica in modo sicuro
            self.performRealmWrite { realm in
                updateBlock(&layout)
                realm.add(layout, update: .all)
            }
        }
    }
}
