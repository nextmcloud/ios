// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

class NCFavorite: NCCollectionViewCommon {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        titleCurrentFolder = NSLocalizedString("_favorites_", comment: "")
        layoutKey = NCGlobal.shared.layoutViewFavorite
        enableSearchBar = false
        headerMenuButtonsView = true
        headerRichWorkspaceDisable = true
        emptyImageName = "star.fill"
        emptyImageColors = [NCBrandColor.shared.yellowFavorite]
        emptyTitle = "_favorite_no_files_"
        emptyDescription = "_tutorial_favorite_view_"
    }

    // MARK: - View Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            await self.reloadDataSource()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            await getServerData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        Task {
            await NCNetworking.shared.networkingTasks.cancel(identifier: "NCFavorite")
        }
    }

    // MARK: - DataSource

    override func reloadDataSource() async {
        var predicate: NSPredicate?

        if self.serverUrl.isEmpty {
           predicate = NSPredicate(format: "account == %@ AND favorite == true AND NOT (status IN %@)", session.account, global.metadataStatusHideInView)
        }

        let metadatas = self.database.getResultsMetadatasPredicate(predicate, layoutForView: layoutForView)

        self.dataSource = NCCollectionViewDataSource(metadatas: metadatas, layoutForView: layoutForView)

        super.reloadDataSource()
    }

    override func getServerData() {
        NextcloudKit.shared.listingFavorites(showHiddenFiles: NCKeychain().showHiddenFiles, account: session.account) { task in
        let metadatas = await self.database.getMetadatasAsync(predicate: predicate,
                                                              withLayout: layoutForView,
                                                              withAccount: session.account)
        let metadatas = await self.database.getMetadatasAsyncDataSource(withServerUrl: self.serverUrl,
                                                                        withUserId: self.session.userId,
                                                                        withAccount: self.session.account,
                                                                        withLayout: self.layoutForView,
                                                                        withPreficate: predicate)

        self.dataSource = NCCollectionViewDataSource(metadatas: metadatas,
                                                     layoutForView: layoutForView,
                                                     account: session.account)
        await super.reloadDataSource()

        cachingAsync(metadatas: metadatas)
    }

    override func getServerData(forced: Bool = false) async {
        defer {
            restoreDefaultTitle()
        }

        // If is already in-flight, do nothing
        if await NCNetworking.shared.networkingTasks.isReading(identifier: "NCFavorite") {
            return
        }

        showLoadingTitle()

        let showHiddenFiles = NCPreferences().getShowHiddenFiles(account: session.account)
        let resultsListingFavorites = await NextcloudKit.shared.listingFavoritesAsync(showHiddenFiles: showHiddenFiles,
                                                                                      account: session.account) { task in
            Task {
                await NCNetworking.shared.networkingTasks.track(identifier: "NCFavorite", task: task)
            }
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }
        } completion: { account, files, _, error in
            if error == .success, let files {
                self.database.convertFilesToMetadatas(files, useFirstAsMetadataFolder: false) { _, metadatas in
                    self.database.updateMetadatasFavorite(account: account, metadatas: metadatas)
                    self.reloadDataSource()
                }
            }
            self.refreshControl.endRefreshing()
        }

        if resultsListingFavorites.error == .success, let files = resultsListingFavorites.files {
            let (_, metadatas) = await self.database.convertFilesToMetadatasAsync(files)
            await self.database.updateMetadatasFavoriteAsync(account: session.account, metadatas: metadatas)
            await self.reloadDataSource()
        }
    }
}
