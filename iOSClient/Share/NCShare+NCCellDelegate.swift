// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Henrik Storch
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

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
        // Menu is now shown via native context menu on the button
        // Only handle the case where there's no tableShare (add new link)
        if tableShare == nil {
//        if let tableShare = tableShare {
//            self.toggleShareMenu(for: tableShare, sender: sender)
            self.toggleShareMenu(for: tableShare, sendMail: (tableShare.shareType != NCShareCommon().SHARE_TYPE_LINK), folder: metadata?.directory ?? false, sender: sender)
        } else {
            self.makeNewLinkShare()
        }
    }

    func tapProfileMenu(with tableShare: tableShare?) -> UIMenu? {
        guard let tableShare else { return nil }
        return NCContextMenuProfile(userId: tableShare.shareWith, session: session, viewController: self).viewMenu()
    }

    func tapQuickStatus(with tableShare: tableShare?, sender: Any) {
        guard let tableShare else { return }
        presentQuickStatusActionSheet(for: tableShare, sender: sender)
    }

    func quickStatus(with tableShare: tableShare?, sender: Any) {
        guard let tableShare, let metadata else { return }
        self.toggleQuickPermissionsMenu(isDirectory: metadata.directory, share: tableShare, sender: sender)
    }
}
