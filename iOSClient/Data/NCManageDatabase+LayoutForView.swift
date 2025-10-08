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

    // MARK: - Realm write

    func setLayoutForView(account: String,
                          key: String,
                          serverUrl: String,
                          layout: String? = nil) {
        let keyStore = serverUrl.isEmpty ? key : serverUrl
        let indexKey = account + " " + keyStore
        var finalObject = NCDBLayoutForView()

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
            if let layout {
                finalObject.layout = layout
            }

            realm.add(finalObject, update: .all)
        }
    }

    @discardableResult
    func setLayoutForView(layoutForView: NCDBLayoutForView, withSubFolders subFolders: Bool = false) -> NCDBLayoutForView? {
        let object = NCDBLayoutForView(value: layoutForView)

        if subFolders {
            let keyStore = layoutForView.keyStore
            if let layouts = performRealmRead({
                $0.objects(NCDBLayoutForView.self)
                    .filter("keyStore BEGINSWITH %@", keyStore)
                    .map { NCDBLayoutForView(value: $0) }
            }) {
                for layout in layouts {
                    layout.layout = layoutForView.layout
                    layout.sort = layoutForView.sort
                    layout.ascending = layoutForView.ascending
                    layout.groupBy = layoutForView.groupBy
                    layout.columnGrid = layoutForView.columnGrid
                    layout.columnPhoto = layoutForView.columnPhoto

                    performRealmWrite { realm in
                        realm.add(layout, update: .all)
                    }
                }
            }
        } else {
            performRealmWrite { realm in
                realm.add(object, update: .all)
            }
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

    func getLayoutsForView(keyStore: String) -> Results<NCDBLayoutForView>? {
        return performRealmRead({
            $0.objects(NCDBLayoutForView.self)
                .filter("keyStore BEGINSWITH %@", keyStore)
        })
    }

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

        let tblAccount = performRealmRead { realm in
            realm.objects(tableAccount.self)
                .filter("account == %@", account)
                .first
        }

        if let tblAccount {
            let home = utilityFileSystem.getHomeServer(urlBase: tblAccount.urlBase, userId: tblAccount.userId)
            let defaultServerUrlAutoUpload = utilityFileSystem.createServerUrl(serverUrl: home, fileName: NCBrandOptions.shared.folderDefaultAutoUpload)
            var serverUrlAutoUpload = tblAccount.autoUploadDirectory.isEmpty ? home : tblAccount.autoUploadDirectory

            if tblAccount.autoUploadFileName.isEmpty {
                serverUrlAutoUpload += "/" + NCBrandOptions.shared.folderDefaultAutoUpload
            } else {
                serverUrlAutoUpload += "/" + tblAccount.autoUploadFileName
            }

            if serverUrl == defaultServerUrlAutoUpload || serverUrl == serverUrlAutoUpload {

                // AutoUpload serverUrl / Photo
                let photosLayoutForView = NCDBLayoutForView()
                photosLayoutForView.index = index
                photosLayoutForView.account = account
                photosLayoutForView.keyStore = keyStore
                photosLayoutForView.layout = NCGlobal.shared.layoutPhotoSquare
                photosLayoutForView.sort = "date"
                photosLayoutForView.ascending = false

                DispatchQueue.global(qos: .utility).async {
                    self.setLayoutForView(layoutForView: photosLayoutForView)
                }

                return photosLayoutForView

            } else if !serverUrl.isEmpty,
                      let serverDirectoryUp = NCUtilityFileSystem().serverDirectoryUp(serverUrl: serverUrl, home: home) {

                // Get previus serverUrl
                let index = account + " " + serverDirectoryUp
                if let previusLayoutForView = performRealmRead({
                    $0.objects(NCDBLayoutForView.self)
                        .filter("index == %@", index)
                        .first
                        .map { NCDBLayoutForView(value: $0) }
                }) {
                    previusLayoutForView.index = account + " " + serverUrl
                    previusLayoutForView.keyStore = serverUrl

                    DispatchQueue.global(qos: .utility).async {
                        self.setLayoutForView(layoutForView: previusLayoutForView)
                    }

                    return previusLayoutForView
                }
            }
        }

        // Standatd layout
        let layout = layout ?? NCGlobal.shared.layoutList
        DispatchQueue.global(qos: .utility).async {
            self.setLayoutForView(account: account, key: key, serverUrl: serverUrl, layout: layout)
        }

        let placeholder = NCDBLayoutForView()
        placeholder.index = index
        placeholder.account = account
        placeholder.keyStore = keyStore
        placeholder.layout = layout

        return placeholder
    }

    func updatePhotoLayoutForView(account: String,
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

            self.performRealmWrite { realm in
                updateBlock(&layout)
                realm.add(layout, update: .all)
            }
        }
    }
}
