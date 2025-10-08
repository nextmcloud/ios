// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import Alamofire
import NextcloudKit

extension NCNetworking {
    func createRecommendations(session: NCSession.Session) async {
        let homeServer = self.utilityFileSystem.getHomeServer(urlBase: session.urlBase, userId: session.userId)
        var recommendationsToInsert: [NKRecommendation] = []
        let options = NKRequestOptions(queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue)
    func createRecommendations(session: NCSession.Session, serverUrl: String, collectionView: UICollectionView) async {
        let home = self.utilityFileSystem.getHomeServer(urlBase: session.urlBase, userId: session.userId)
        guard home == serverUrl else {
            return
        }

        let showHiddenFiles = NCPreferences().getShowHiddenFiles(account: session.account)
        var recommendationsToInsert: [NKRecommendation] = []
        let results = await NextcloudKit.shared.getRecommendedFilesAsync(account: session.account, taskHandler: { task in
            Task {
                let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: session.account,
                                                                                            name: "getRecommendedFiles")
                await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
            }
        })
        var serverUrlFileName = ""

        let results = await NCNetworking.shared.getRecommendedFiles(account: session.account, options: options)
        if results.error == .success,
           let recommendations = results.recommendations {
            for recommendation in recommendations {
                var serverUrlFileName = ""

                if recommendation.directory.last == "/" {
                    serverUrlFileName = homeServer + recommendation.directory + recommendation.name
                } else {
                    serverUrlFileName = homeServer + recommendation.directory + "/" + recommendation.name
                }

                let results = await NCNetworking.shared.readFileOrFolder(serverUrlFileName: serverUrlFileName, depth: "0", showHiddenFiles: NCKeychain().showHiddenFiles, account: session.account)

                if results.error == .success, let file = results.files?.first {
                    let isDirectoryE2EE = self.utilityFileSystem.isDirectoryE2EE(file: file)
                    let metadata = self.database.convertFileToMetadata(file, isDirectoryE2EE: isDirectoryE2EE)
                    self.database.addMetadata(metadata)
                    let metadata = await self.database.convertFileToMetadataAsync(file, isDirectoryE2EE: isDirectoryE2EE)
                    self.database.addMetadataIfNeededAsync(metadata, sync: false)
                serverUrlFileName = self.utilityFileSystem.createServerUrl(serverUrl: home + recommendation.directory, fileName: recommendation.name)

                let results = await NextcloudKit.shared.readFileOrFolderAsync(serverUrlFileName: serverUrlFileName, depth: "0", showHiddenFiles: showHiddenFiles, account: session.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: session.account,
                                                                                                    path: serverUrlFileName,
                                                                                                    name: "readFileOrFolder")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                }

                if results.error == .success, let file = results.files?.first {
                    let metadata = await NCManageDatabase.shared.convertFileToMetadataAsync(file)
                    NCManageDatabase.shared.addMetadataIfNeededAsync(metadata, sync: false)

                    if metadata.isLivePhoto, metadata.isVideo {
                        continue
                    } else {
                        recommendationsToInsert.append(recommendation)
                    }
                }
            }
            self.database.createRecommendedFiles(account: session.account, recommendations: recommendationsToInsert)
            self.database.realmRefresh()

            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadHeader, userInfo: ["account": session.account])

            await NCManageDatabase.shared.createRecommendedFilesAsync(account: session.account, recommendations: recommendationsToInsert)
            await collectionView.reloadData()
        }
    }
}
