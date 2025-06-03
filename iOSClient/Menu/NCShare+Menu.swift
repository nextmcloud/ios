//
//  NCShare+Menu.swift
//  Nextcloud
//
//  Created by Henrik Storch on 16.03.22.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
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
import NextcloudKit

extension NCShare {
    func toggleShareMenu(for share: tableShare, sendMail: Bool, folder: Bool, sender: Any) {

        let capabilities = NCCapabilities.shared.getCapabilities(account: self.metadata.account)
        var actions = [NCMenuAction]()

        if !folder {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_open_in_", comment: ""),
                    icon: utility.loadImage(named: "viewInFolder").imageColor(NCBrandColor.shared.brandElement),
//    func toggleShareMenu(for share: tableShare, sender: Any?) {
    func toggleShareMenu(for share: tableShare, sendMail: Bool, folder: Bool, sender: Any) {
        let capabilities = NCCapabilities.shared.getCapabilities(account: self.metadata.account)
        var actions = [NCMenuAction]()

        if share.shareType == NCShareCommon().SHARE_TYPE_LINK, canReshare {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_share_add_sharelink_", comment: ""),
                    icon: utility.loadImage(named: "plus", colors: [NCBrandColor.shared.iconImageColor]),
                    sender: sender,
//    func toggleShareMenu(for share: tableShare, sendMail: Bool, folder: Bool, sender: Any) {
//
//        var actions = [NCMenuAction]()
//
//        if !folder {
//            actions.append(
//                NCMenuAction(
//                    title: NSLocalizedString("_open_in_", comment: ""),
//                    icon: utility.loadImage(named: "viewInFolder").imageColor(NCBrandColor.shared.brandElement),
                    action: { _ in
                        NCShareCommon().copyLink(link: share.url, viewController: self, sender: sender)
                    }
                )
            )
        }

        actions.append(
            NCMenuAction(
//                title: NSLocalizedString("_details_", comment: ""),
//                icon: utility.loadImage(named: "pencil", colors: [NCBrandColor.shared.iconImageColor]),
//                accessibilityIdentifier: "shareMenu/details",
                title: NSLocalizedString("_advance_permissions_", comment: ""),
                icon: utility.loadImage(named: "rename").imageColor(NCBrandColor.shared.brandElement),
                title: NSLocalizedString("_advance_permissions_", comment: ""),
                icon: utility.loadImage(named: "rename").imageColor(NCBrandColor.shared.brandElement),
                accessibilityIdentifier: "shareMenu/details",
                sender: sender,
//                title: NSLocalizedString("_details_", comment: ""),
//                icon: utility.loadImage(named: "pencil", colors: [NCBrandColor.shared.iconImageColor]),
//                accessibilityIdentifier: "shareMenu/details",
                
                action: { _ in
                    guard
                        let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
                        let navigationController = self.navigationController, !share.isInvalidated else { return }
                    advancePermission.networking = self.networking
                    advancePermission.share = share
                    advancePermission.oldTableShare = tableShare(value: share)
                    advancePermission.metadata = self.metadata

                    if let downloadLimit = try? self.database.getDownloadLimit(byAccount: self.metadata.account, shareToken: share.token) {
                        advancePermission.downloadLimit = .limited(limit: downloadLimit.limit, count: downloadLimit.count)
                    }

                    navigationController.pushViewController(advancePermission, animated: true)
                }
            )
        )
        
        if sendMail {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_send_new_email_", comment: ""),
                    icon: NCUtility().loadImage(named: "email").imageColor(NCBrandColor.shared.brandElement),
                    action: { menuAction in
                        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
                        guard let viewNewUserComment = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as? NCShareNewUserAddComment else { return }
                        viewNewUserComment.metadata = self.metadata
                        viewNewUserComment.share = tableShare(value: share)
                        viewNewUserComment.networking = self.networking
                        self.navigationController?.pushViewController(viewNewUserComment, animated: true)
                    }
                )
            )
        }
        
        actions.append(
            NCMenuAction(
                title: NSLocalizedString("_share_unshare_", comment: ""),
                icon: utility.loadImage(named: "trash").imageColor(NCBrandColor.shared.brandElement),
                destructive: true,
                icon: utility.loadImage(named: "trash").imageColor(NCBrandColor.shared.brandElement),
                sender: sender,
                action: { _ in
                    Task {
                        if share.shareType != NCShareCommon().SHARE_TYPE_LINK, let metadata = self.metadata, metadata.e2eEncrypted && capabilities.capabilityE2EEApiVersion == NCGlobal.shared.e2eeVersionV20 {
                            let serverUrl = metadata.serverUrl + "/" + metadata.fileName
                            if NCNetworkingE2EE().isInUpload(account: metadata.account, serverUrl: serverUrl) {
                                let error = NKError(errorCode: NCGlobal.shared.errorE2EEUploadInProgress, errorDescription: NSLocalizedString("_e2e_in_upload_", comment: ""))
                                return NCContentPresenter().showInfo(error: error)
                            }
                            let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, addUserId: nil, removeUserId: share.shareWith, account: metadata.account)
                            if error != .success {
                                return NCContentPresenter().showError(error: error)
                            }
                        }
                        self.networking?.unShare(idShare: share.idShare)
                    }
                }
            )
        )

        self.presentMenu(with: actions, sender: sender)
    }

    func toggleQuickPermissionsMenu(isDirectory: Bool, share: tableShare, sender: Any?) {
        var actions = [NCMenuAction]()
        let permissions = NCPermissions()

        actions.append(contentsOf:
            [NCMenuAction(
                title: NSLocalizedString("_share_read_only_", comment: ""),
                icon: UIImage(),
                selected: tableShare.permissions == (permissions.permissionReadShare + permissions.permissionShareShare) || tableShare.permissions == permissions.permissionReadShare,
                icon: utility.loadImage(named: "eye", colors: [NCBrandColor.shared.iconImageColor]),
                selected: share.permissions == (permissions.permissionReadShare + permissions.permissionShareShare) || share.permissions == permissions.permissionReadShare,
//                icon: UIImage(),
//                selected: tableShare.permissions == (NCGlobal.shared.permissionReadShare + NCGlobal.shared.permissionShareShare) || tableShare.permissions == NCGlobal.shared.permissionReadShare,
                on: false,
                sender: sender,
                action: { _ in
                    let permissions = permissions.getPermissionValue(canCreate: false, canEdit: false, canDelete: false, canShare: false, isDirectory: isDirectory)
                    self.updateSharePermissions(share: share, permissions: permissions)
                }
            ),
            NCMenuAction(
//                title: NSLocalizedString("_share_editing_", comment: ""),
                title: isDirectory ? NSLocalizedString("_share_allow_upload_", comment: "") : NSLocalizedString("_share_editing_", comment: ""),
                icon: UIImage(),
                selected: hasUploadPermission(tableShare: tableShare),
                icon: utility.loadImage(named: "pencil", colors: [NCBrandColor.shared.iconImageColor]),
                selected: hasUploadPermission(tableShare: share),
//                icon: UIImage(),
//                selected: hasUploadPermission(tableShare: tableShare),
                on: false,
                sender: sender,
                action: { _ in
                    let permissions = permissions.getPermissionValue(canCreate: true, canEdit: true, canDelete: true, canShare: true, isDirectory: isDirectory)
                    self.updateSharePermissions(share: share, permissions: permissions)
                }
            ),
            NCMenuAction(
                title: NSLocalizedString("_custom_permissions_", comment: ""),
                icon: utility.loadImage(named: "ellipsis", colors: [NCBrandColor.shared.iconImageColor]),
                sender: sender,
                action: { _ in
                    guard
                        let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
                        let navigationController = self.navigationController, !share.isInvalidated else { return }
                    advancePermission.networking = self.networking
                    advancePermission.share = tableShare(value: share)
                    advancePermission.oldTableShare = tableShare(value: share)
                    advancePermission.metadata = self.metadata

                    if let downloadLimit = try? self.database.getDownloadLimit(byAccount: self.metadata.account, shareToken: share.token) {
                        advancePermission.downloadLimit = .limited(limit: downloadLimit.limit, count: downloadLimit.count)
                    }

                    navigationController.pushViewController(advancePermission, animated: true)
                }
            )]
        )

//        if isDirectory && (share.shareType == NCShareCommon().SHARE_TYPE_LINK /* public link */ || share.shareType == NCShareCommon().SHARE_TYPE_EMAIL) {
//            actions.insert(NCMenuAction(
//                       title: NSLocalizedString("_share_file_drop_", comment: ""),
//                       icon: utility.loadImage(named: "arrow.up.document", colors: [NCBrandColor.shared.iconImageColor]),
//                       selected: share.permissions == permissions.permissionCreateShare,
//                       on: false,
//                       sender: sender,
//                       action: { _ in
//                           let permissions = permissions.getPermissionValue(canRead: false, canCreate: true, canEdit: false, canDelete: false, canShare: false, isDirectory: isDirectory)
//                           self.updateSharePermissions(share: share, permissions: permissions)
//                       }
//                   ), at: 2)
//        }
//
//        self.presentMenu(with: actions, sender: sender)
        if isDirectory,
           NCShareCommon().isFileDropOptionVisible(isDirectory: isDirectory, shareType: tableShare.shareType) {
            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_share_file_drop_", comment: ""),
                    icon: tableShare.permissions == permissions.permissionCreateShare ? UIImage(named: "success")?.image(color: NCBrandColor.shared.customer, size: 25.0) ?? UIImage() : UIImage(),
                    selected: false,
                    on: false,
                    action: { menuAction in
                        self.updateSharePermissions(share: tableShare, permissions: permissions.permissionCreateShare)
                    }
                )
            )
        }
        
        self.presentMenu(with: actions)
        self.presentMenu(with: actions, sender: sender)
    }

    fileprivate func hasUploadPermission(tableShare: tableShare) -> Bool {
        let permissions = NCPermissions()
        let uploadPermissions = [
            permissions.permissionMaxFileShare,
            permissions.permissionMaxFolderShare,
            permissions.permissionDefaultFileRemoteShareNoSupportShareOption,
            permissions.permissionDefaultFolderRemoteShareNoSupportShareOption]
        return uploadPermissions.contains(tableShare.permissions)
    }

    func updateSharePermissions(share: tableShare, permissions: Int) {
        let updatedShare = tableShare(value: share)
        updatedShare.permissions = permissions

        var downloadLimit: DownloadLimitViewModel = .unlimited

        do {
            if let model = try database.getDownloadLimit(byAccount: metadata.account, shareToken: updatedShare.token) {
                downloadLimit = .limited(limit: model.limit, count: model.count)
            }
            if let model = try database.getDownloadLimit(byAccount: metadata.account, shareToken: updatedShare.token) {
                downloadLimit = .limited(limit: model.limit, count: model.count)
            }
        } catch {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Failed to get download limit from database!")
            return
        }

        networking?.updateShare(updatedShare, downloadLimit: downloadLimit)
    }
}
