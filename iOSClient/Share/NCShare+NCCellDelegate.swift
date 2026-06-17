// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

// MARK: - NCCell Delegates
extension NCShare: NCShareLinkCellDelegate, NCShareUserCellDelegate {

    func copyInternalLink(sender: Any) {
        guard let metadata = self.metadata else { return }

        NCNetworking.shared.readFile(serverUrlFileName: metadata.serverUrlFileName, account: metadata.account) { _, metadata, _, error in
            if error == .success, let metadata = metadata {
                let internalLink = metadata.urlBase + "/index.php/f/" + metadata.fileId
                NCShareCommon.copyLink(link: internalLink, viewController: self, sender: sender)
            } else {
                Task {
                    let windowScene = SceneManager.shared.getWindowScene(controller: self.controller)
                    await showErrorBanner(windowScene: windowScene, error: error)
                }
            }
        }
    }

    func tapCopy(with tableShare: tableShare?, sender: Any) {
        guard let tableShare = tableShare else {
            return copyInternalLink(sender: sender)
        }
        NCShareCommon.copyLink(link: tableShare.url, viewController: self, sender: sender)
    }

    func tapMenu(with tableShare: tableShare?, sender: Any) {
        if let tableShare = tableShare {
            self.toggleShareMenu(for: tableShare, sendMail: (tableShare.shareType != NKShare.ShareType.publicLink.rawValue), folder: metadata?.directory ?? false, sender: sender)
        } else {
            self.makeNewLinkShare()
        }
    }

    func showProfile(with tableShare: tableShare?, sender: Any) {
        guard let tableShare else { return }
        showProfileMenu(userId: tableShare.shareWith, session: session, sender: sender)
    }

    func quickStatus(with tableShare: tableShare?, sender: Any) {
        guard let tableShare, let metadata else { return }
        self.toggleQuickPermissionsMenu(isDirectory: metadata.directory, share: tableShare, sender: sender)
    }
}
