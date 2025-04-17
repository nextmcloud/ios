//
//  NCCollectionViewCommon+CollectionViewDataSource.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 02/07/24.
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
import NextcloudKit
import RealmSwift

extension NCCollectionViewCommon: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberItems = dataSource.numberOfItemsInSection(section)
        emptyDataSet?.numberOfItemsInSection(numberItems, section: section)
        // get auto upload folder
        self.autoUploadFileName = self.database.getAccountAutoUploadFileName()
        self.autoUploadDirectory = self.database.getAccountAutoUploadDirectory(session: self.session)
        // get layout for view
        self.layoutForView = self.database.getLayoutForView(account: self.session.account, key: self.layoutKey, serverUrl: self.serverUrl)
        
        return self.dataSource.numberOfItemsInSection(section)
        return numberItems
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath),
              let cell = (cell as? NCCellProtocol) else { return }
        let existsIcon = utilityFileSystem.fileProviderStoragePreviewIconExists(metadata.ocId, etag: metadata.etag)

        func downloadAvatar(fileName: String, user: String, dispalyName: String?) {
            if let image = NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName) {
                cell.fileAvatarImageView?.contentMode = .scaleAspectFill
                cell.fileAvatarImageView?.image = image
            } else {
                NCNetworking.shared.downloadAvatar(user: user, dispalyName: dispalyName, fileName: fileName, cell: cell, view: collectionView)
            }
        }
        /// CONTENT MODE
        cell.filePreviewImageView?.layer.borderWidth = 0
        if existsIcon {
            cell.filePreviewImageView?.contentMode = .scaleAspectFill
        } else {
            cell.filePreviewImageView?.contentMode = .scaleAspectFit
        }
        cell.fileAvatarImageView?.contentMode = .center
        /// THUMBNAIL
        if !metadata.directory {
            if metadata.hasPreviewBorder {
                cell.filePreviewImageView?.layer.borderWidth = 0.2
                cell.filePreviewImageView?.layer.borderColor = UIColor.lightGray.cgColor
            }
            if metadata.name == NCGlobal.shared.appName {
                if layoutForView?.layout == NCGlobal.shared.layoutPhotoRatio || layoutForView?.layout == NCGlobal.shared.layoutPhotoSquare {
                    if let image = NCImageCache.shared.getPreviewImageCache(ocId: metadata.ocId, etag: metadata.etag) {
                        cell.filePreviewImageView?.image = image
                    } else if let image = UIImage(contentsOfFile: self.utilityFileSystem.getDirectoryProviderStoragePreviewOcId(metadata.ocId, etag: metadata.etag)) {
                        cell.filePreviewImageView?.image = image
                        NCImageCache.shared.addPreviewImageCache(metadata: metadata, image: image)
                    }
                } else {
                    if let image = NCImageCache.shared.getIconImageCache(ocId: metadata.ocId, etag: metadata.etag) {
                        cell.filePreviewImageView?.image = image
                    } else if metadata.hasPreview {
                        cell.filePreviewImageView?.image = utility.getIcon(metadata: metadata)
                    }
                }
                if cell.filePreviewImageView?.image == nil {
                    if metadata.iconName.isEmpty {
                        cell.filePreviewImageView?.image = NCImageCache.images.file
                    } else {
                        cell.filePreviewImageView?.image = utility.loadImage(named: metadata.iconName, useTypeIconFile: true)
                    }
                    if metadata.hasPreview && metadata.status == NCGlobal.shared.metadataStatusNormal && !existsIcon {
                        for case let operation as NCCollectionViewDownloadThumbnail in NCNetworking.shared.downloadThumbnailQueue.operations where operation.metadata.ocId == metadata.ocId { return }
                        NCNetworking.shared.downloadThumbnailQueue.addOperation(NCCollectionViewDownloadThumbnail(metadata: metadata, cell: cell, collectionView: collectionView))
                    }
                }
            } else {
                /// APP NAME - UNIFIED SEARCH
                switch metadata.iconName {
                case let str where str.contains("contacts"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconContacts
                case let str where str.contains("conversation"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconTalk
                case let str where str.contains("calendar"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconCalendar
                case let str where str.contains("deck"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconDeck
                case let str where str.contains("mail"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconMail
                case let str where str.contains("talk"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconTalk
                case let str where str.contains("confirm"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconConfirm
                case let str where str.contains("pages"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconPages
                default:
                    cell.filePreviewImageView?.image = NCImageCache.images.iconFile
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            guard let metadata = self.dataSource.cellForItemAt(indexPath: indexPath) else { return }
            for case let operation as NCCollectionViewDownloadThumbnail in NCNetworking.shared.downloadThumbnailQueue.operations where operation.metadata.ocId == metadata.ocId {
                        operation.cancel()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let metadata = self.dataSource.cellForItemAt(indexPath: indexPath) else { return }
        let existsImagePreview = utilityFileSystem.fileProviderStorageImageExists(metadata.ocId, etag: metadata.etag)
        let ext = global.getSizeExtension(column: self.numberOfColumns)

        if metadata.hasPreview,
           !existsImagePreview,
           NCNetworking.shared.downloadThumbnailQueue.operations.filter({ ($0 as? NCMediaDownloadThumbnail)?.metadata.ocId == metadata.ocId }).isEmpty {
            NCNetworking.shared.downloadThumbnailQueue.addOperation(NCCollectionViewDownloadThumbnail(metadata: metadata, collectionView: collectionView, ext: ext))
        }
    }

    private func photoCell(cell: NCPhotoCell, indexPath: IndexPath, metadata: tableMetadata, ext: String) -> NCPhotoCell {
        let width = UIScreen.main.bounds.width / CGFloat(self.numberOfColumns)

        cell.ocId = metadata.ocId
        cell.ocIdTransfer = metadata.ocIdTransfer
        cell.hideButtonMore(true)
        cell.hideImageStatus(true)

        /// Image
        ///
        if let image = NCImageCache.shared.getImageCache(ocId: metadata.ocId, etag: metadata.etag, ext: ext) {

            cell.filePreviewImageView?.image = image
            cell.filePreviewImageView?.contentMode = .scaleAspectFill

        } else {

            if isPinchGestureActive || ext == global.previewExt512 || ext == global.previewExt1024 {
                cell.filePreviewImageView?.image = self.utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: ext)
            }

            DispatchQueue.global(qos: .userInteractive).async {
                let image = self.utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: ext)
                if let image {
                    self.imageCache.addImageCache(ocId: metadata.ocId, etag: metadata.etag, image: image, ext: ext, cost: indexPath.row)
                    DispatchQueue.main.async {
                        cell.filePreviewImageView?.image = image
                        cell.filePreviewImageView?.contentMode = .scaleAspectFill
                    }
                } else {
                    DispatchQueue.main.async {
                        cell.filePreviewImageView?.contentMode = .scaleAspectFit
                        if metadata.iconName.isEmpty {
                            cell.filePreviewImageView?.image = NCImageCache.shared.getImageFile()
                        } else {
                            cell.filePreviewImageView?.image = self.utility.loadImage(named: metadata.iconName, useTypeIconFile: true, account: metadata.account)
                        }
                    }
                }
            }
        }

        /// Status
        ///
        if metadata.isLivePhoto {
            cell.fileStatusImage?.image = utility.loadImage(named: "livephoto", colors: isLayoutPhoto ? [.white] : [NCBrandColor.shared.iconImageColor2])
        } else if metadata.isVideo {
            cell.fileStatusImage?.image = utility.loadImage(named: "play.circle", colors: NCBrandColor.shared.iconImageMultiColors)
        }

        /// Edit mode
        if fileSelect.contains(metadata.ocId) {
            cell.selectMode(true)
            cell.selected(true, isEditMode: isEditMode)
        } else {
            cell.selectMode(false)
            cell.selected(false, isEditMode: isEditMode)
        }

        if width > 100 {
            cell.hideButtonMore(false)
            cell.hideImageStatus(false)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: NCCellProtocol & UICollectionViewCell
        let permissions = NCPermissions()
        var isShare = false
        var isMounted = false
        var a11yValues: [String] = []

        // LAYOUT PHOTO
        if layoutForView?.layout == NCGlobal.shared.layoutPhotoRatio || layoutForView?.layout == NCGlobal.shared.layoutPhotoSquare {
            guard let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? NCPhotoCell else { return NCPhotoCell() }
            photoCell.photoCellDelegate = self
            cell = photoCell
        } else if layoutForView?.layout == NCGlobal.shared.layoutGrid {
        // LAYOUT GRID
            guard let gridCell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as? NCGridCell else { return NCGridCell() }
            gridCell.gridCellDelegate = self
            cell = gridCell
        } else {
        // LAYOUT LIST
            guard let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as? NCListCell else { return NCListCell() }
            listCell.listCellDelegate = self
            cell = listCell
        }
        guard let metadata = dataSource.cellForItemAt(indexPath: indexPath) else { return cell }
        let metadata = self.dataSource.getMetadata(indexPath: indexPath) ?? tableMetadata()
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)
        let shares = NCManageDatabase.shared.getTableShares(metadata: metadata)
        let existsImagePreview = utilityFileSystem.fileProviderStorageImageExists(metadata.ocId, etag: metadata.etag)
        let ext = global.getSizeExtension(column: self.numberOfColumns)

        defer {
            if !metadata.isSharable() || NCCapabilities.shared.disableSharesView(account: metadata.account) {
                cell.hideButtonShare(true)
            }
        }

        // E2EE create preview
        if self.isDirectoryEncrypted,
           metadata.isImageOrVideo,
           !utilityFileSystem.fileProviderStorageImageExists(metadata.ocId, etag: metadata.etag) {
            utility.createImageFileFrom(metadata: metadata)
        }

        /// CONTENT MODE
        cell.fileAvatarImageView?.contentMode = .center
        cell.filePreviewImageView?.layer.borderWidth = 0

        if existsImagePreview && layoutForView?.layout != global.layoutPhotoRatio {
            cell.filePreviewImageView?.contentMode = .scaleAspectFill
        } else {
            cell.filePreviewImageView?.contentMode = .scaleAspectFit
        }

        if metadataFolder != nil {
            isShare = metadata.permissions.contains(permissions.permissionShared) && !metadataFolder!.permissions.contains(permissions.permissionShared)
            isMounted = metadata.permissions.contains(permissions.permissionMounted) && !metadataFolder!.permissions.contains(permissions.permissionMounted)
        }

        cell.fileAccount = metadata.account
        cell.fileOcId = metadata.ocId
        cell.fileOcIdTransfer = metadata.ocIdTransfer
        cell.fileUser = metadata.ownerId
        cell.fileSelectImage?.image = nil
        cell.fileStatusImage?.image = nil
        cell.fileLocalImage?.image = nil
        cell.fileFavoriteImage?.image = nil
        cell.fileMoreImage?.image = nil
        cell.filePreviewImageView?.image = nil
        cell.filePreviewImageView?.backgroundColor = nil
        cell.fileProgressView?.isHidden = true
        cell.fileProgressView?.progress = 0.0
        cell.hideButtonShare(false)
        cell.hideButtonMore(false)
        cell.titleInfoTrailingDefault()
        
        if isSearchingMode {
            cell.fileTitleLabel?.text = metadata.fileName
            cell.fileTitleLabel?.lineBreakMode = .byTruncatingTail
            if metadata.name == global.appName {
                cell.fileInfoLabel?.text = utility.dateDiff(metadata.date as Date) + " · " + utilityFileSystem.transformedSize(metadata.size)
            } else {
                cell.fileInfoLabel?.text = metadata.subline
            }
            cell.fileSubinfoLabel?.isHidden = true
        } else if !metadata.sessionError.isEmpty, metadata.status != global.metadataStatusNormal {
            // Temporary issue fix for NMC-3771: iOS v9.1.6 > multiple uploads cause error messages
            if metadata.sessionError == "423: WebDAV Locked: Trying to access locked resource" || metadata.sessionError == "423: WebDAV gesperrt: Zugriffsversuch auf eine gesperrte Ressource" {
                cell.fileTitleLabel?.text = metadata.fileName
                cell.fileTitleLabel?.lineBreakMode = .byTruncatingMiddle
            } else {
                cell.fileSubinfoLabel?.isHidden = false
                cell.fileInfoLabel?.text = metadata.sessionError
            }
        } else {
            cell.fileSubinfoLabel?.isHidden = false
            cell.fileTitleLabel?.text = metadata.fileNameView
            cell.fileTitleLabel?.lineBreakMode = .byTruncatingMiddle
            cell.writeInfoDateSize(date: metadata.date, size: metadata.size)
        }

        if metadata.status == NCGlobal.shared.metadataStatusDownloading || metadata.status == NCGlobal.shared.metadataStatusUploading {
            cell.fileProgressView?.isHidden = false
        }
        
        // Accessibility [shared] if metadata.ownerId != appDelegate.userId, appDelegate.account == metadata.account {
        if metadata.ownerId != metadata.userId {
            a11yValues.append(NSLocalizedString("_shared_with_you_by_", comment: "") + " " + metadata.ownerDisplayName)
        }

        if metadata.directory {
            let tableDirectory = database.getTableDirectory(ocId: metadata.ocId)
            if metadata.e2eEncrypted {
                cell.filePreviewImageView?.image = imageCache.getFolderEncrypted()
            } else if isShare {
                cell.filePreviewImageView?.image = imageCache.getFolderSharedWithMe()
            } else if !metadata.shareType.isEmpty {
                metadata.shareType.contains(3) ?
                (cell.filePreviewImageView?.image = imageCache.getFolderPublic()) :
                (cell.filePreviewImageView?.image = imageCache.getFolderSharedWithMe())
            } else if !metadata.shareType.isEmpty && metadata.shareType.contains(3) {
                cell.filePreviewImageView?.image = imageCache.getFolderPublic()
            } else if metadata.mountType == "group" {
                cell.filePreviewImageView?.image = imageCache.getFolderGroup()
            } else if isMounted {
                cell.filePreviewImageView?.image = imageCache.getFolderExternal()
            } else if metadata.fileName == autoUploadFileName && metadata.serverUrl == autoUploadDirectory {
                cell.filePreviewImageView?.image = imageCache.getFolderAutomaticUpload()
            } else {
                cell.filePreviewImageView?.image = imageCache.getFolder()
            }

            // Local image: offline
            if let tableDirectory, tableDirectory.offline {
                cell.fileLocalImage?.image = imageCache.getImageOfflineFlag()
            }

            // color folder
            cell.filePreviewImageView?.image = cell.filePreviewImageView?.image?.colorizeFolder(metadata: metadata, tableDirectory: tableDirectory)

        } else {

            if metadata.hasPreviewBorder {
                cell.filePreviewImageView?.layer.borderWidth = 0.2
                cell.filePreviewImageView?.layer.borderColor = UIColor.lightGray.cgColor
            }

            if metadata.name == global.appName {
                if let image = NCImageCache.shared.getImageCache(ocId: metadata.ocId, etag: metadata.etag, ext: ext) {
                    cell.filePreviewImageView?.image = image
                } else if metadata.fileExtension == "odg" {
                    cell.filePreviewImageView?.image = UIImage(named: "diagram")
                } else if let image = utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: ext) {
                    cell.filePreviewImageView?.image = image
                }

                if cell.filePreviewImageView?.image == nil {
                    if metadata.iconName.isEmpty {
                        cell.filePreviewImageView?.image = NCImageCache.shared.getImageFile()
                    } else {
                        cell.filePreviewImageView?.image = utility.loadImage(named: metadata.iconName, useTypeIconFile: true, account: metadata.account)
                    }
                }
            } else {
                /// APP NAME - UNIFIED SEARCH
                switch metadata.iconName {
                case let str where str.contains("contacts"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconContacts
                case let str where str.contains("conversation"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconTalk
                case let str where str.contains("calendar"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconCalendar
                case let str where str.contains("deck"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconDeck
                case let str where str.contains("mail"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconMail
                case let str where str.contains("talk"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconTalk
                case let str where str.contains("confirm"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconConfirm
                case let str where str.contains("pages"):
                    cell.filePreviewImageView?.image = NCImageCache.images.iconPages
                default:
                    cell.filePreviewImageView?.image = NCImageCache.images.file
                }
                if !metadata.iconUrl.isEmpty {
                    if let ownerId = getAvatarFromIconUrl(metadata: metadata) {
                        let fileName = NCSession.shared.getFileName(urlBase: metadata.urlBase, user: ownerId)
                        let results = NCManageDatabase.shared.getImageAvatarLoaded(fileName: fileName)
                        if results.image == nil {
                            cell.filePreviewImageView?.image = utility.loadUserImage(for: ownerId, displayName: nil, urlBase: metadata.urlBase)
                        } else {
                            cell.filePreviewImageView?.image = results.image
                        }
                        if !(results.tableAvatar?.loaded ?? false),
                           NCNetworking.shared.downloadAvatarQueue.operations.filter({ ($0 as? NCOperationDownloadAvatar)?.fileName == fileName }).isEmpty {
                            NCNetworking.shared.downloadAvatarQueue.addOperation(NCOperationDownloadAvatar(user: ownerId, fileName: fileName, account: metadata.account, view: collectionView, isPreviewImageView: true))
                        }
                    }
                }
            }

            let tableLocalFile = database.getResultsTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))?.first
            // image local
            if let tableLocalFile, tableLocalFile.offline {
                a11yValues.append(NSLocalizedString("_offline_", comment: ""))
                cell.fileLocalImage?.image = imageCache.getImageOfflineFlag()
            } else if utilityFileSystem.fileProviderStorageExists(metadata) {
                cell.fileLocalImage?.image = imageCache.getImageLocal()
            }
        }

        // image Favorite
        if metadata.favorite {
            cell.fileFavoriteImage?.image = imageCache.getImageFavorite()
            a11yValues.append(NSLocalizedString("_favorite_short_", comment: ""))
        }

        // Share image
        if isShare || !metadata.shareType.isEmpty {
            cell.fileSharedImage?.image = NCImageCache.images.shared
        } else {
            cell.fileSharedImage?.image = NCImageCache.images.canShare.image(color: NCBrandColor.shared.gray60, size: 50)
            cell.fileSharedImage?.image = NCImageCache.images.canShare.image(color: NCBrandColor.shared.gray60)
            cell.fileSharedLabel?.text = ""
        }
        if appDelegate.account != metadata.account {
            cell.fileSharedImage?.image = NCImageCache.images.shared
        }
        cell.fileSharedLabel?.text = NSLocalizedString("_shared_", comment: "")
        cell.fileSharedLabel?.textColor = NCBrandColor.shared.customer
        if (!metadata.shareType.isEmpty || !(shares.share?.isEmpty ?? true) || (shares.firstShareLink != nil)){
            cell.fileSharedImage?.image = cell.fileSharedImage?.image?.imageColor(NCBrandColor.shared.customer)
        } else {
            cell.fileSharedImage?.image = NCImageCache.images.canShare.image(color: NCBrandColor.shared.gray60, size: 50)
            cell.fileSharedLabel?.text = ""
        }
        
        if metadata.permissions.contains("S"), (metadata.permissions.range(of: "S") != nil) {
            cell.fileSharedImage?.image = NCImageCache.images.sharedWithMe
            cell.fileSharedLabel?.text = NSLocalizedString("_recieved_", comment: "")
            cell.fileSharedLabel?.textColor = NCBrandColor.shared.notificationAction
        }

        // Button More
        if metadata.isInTransfer || metadata.isWaitingTransfer {
            cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCImageCache.images.buttonStop)
        } else if metadata.lock == true {
            cell.setButtonMore(named: NCGlobal.shared.buttonMoreLock, image: NCImageCache.images.buttonMoreLock)
            a11yValues.append(String(format: NSLocalizedString("_locked_by_", comment: ""), metadata.lockOwnerDisplayName))
        } else {
            cell.fileSharedImage?.image = NCImageCache.images.canShare.image(color: NCBrandColor.shared.gray60, size: 50)
            cell.fileSharedImage?.image = NCImageCache.images.canShare.image(color: NCBrandColor.shared.gray60)
            cell.fileSharedLabel?.text = ""
        }
        
        if metadata.permissions.contains("S"), (metadata.permissions.range(of: "S") != nil) {
            cell.fileSharedImage?.image = NCImageCache.images.sharedWithMe
            cell.fileSharedLabel?.text = NSLocalizedString("_recieved_", comment: "")
            cell.fileSharedLabel?.textColor = NCBrandColor.shared.notificationAction
        }

        // Button More
        if metadata.isInTransfer || metadata.isWaitingTransfer {
            cell.setButtonMore(named: NCGlobal.shared.buttonMoreStop, image: NCImageCache.images.buttonStop)
        } else if metadata.lock == true {
            cell.setButtonMore(named: NCGlobal.shared.buttonMoreLock, image: NCImageCache.images.buttonMoreLock)
            a11yValues.append(String(format: NSLocalizedString("_locked_by_", comment: ""), metadata.lockOwnerDisplayName))
        } else {
            cell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCImageCache.images.buttonMore)
        }

        // Staus
        if metadata.isLivePhoto {
            cell.fileStatusImage?.image = NCImageCache.shared.getImageLivePhoto()
            a11yValues.append(NSLocalizedString("_upload_mov_livephoto_", comment: ""))
        } else if metadata.isVideo {
            cell.fileStatusImage?.image = utility.loadImage(named: "play.circle", colors: NCBrandColor.shared.iconImageMultiColors)
        }
        switch metadata.status {
        case NCGlobal.shared.metadataStatusWaitCreateFolder:
            cell.fileStatusImage?.image = utility.loadImage(named: "arrow.triangle.2.circlepath", colors: NCBrandColor.shared.iconImageMultiColors)
            cell.fileInfoLabel?.text = NSLocalizedString("_status_wait_create_folder_", comment: "")
        case NCGlobal.shared.metadataStatusWaitFavorite:
            cell.fileStatusImage?.image = utility.loadImage(named: "star.circle", colors: NCBrandColor.shared.iconImageMultiColors)
            cell.fileInfoLabel?.text = NSLocalizedString("_status_wait_favorite_", comment: "")
        case NCGlobal.shared.metadataStatusWaitCopy:
            cell.fileStatusImage?.image = utility.loadImage(named: "c.circle", colors: NCBrandColor.shared.iconImageMultiColors)
            cell.fileInfoLabel?.text = NSLocalizedString("_status_wait_copy_", comment: "")
        case NCGlobal.shared.metadataStatusWaitMove:
            cell.fileStatusImage?.image = utility.loadImage(named: "m.circle", colors: NCBrandColor.shared.iconImageMultiColors)
            cell.fileInfoLabel?.text = NSLocalizedString("_status_wait_move_", comment: "")
        case NCGlobal.shared.metadataStatusWaitRename:
            cell.fileStatusImage?.image = utility.loadImage(named: "a.circle", colors: NCBrandColor.shared.iconImageMultiColors)
            cell.fileInfoLabel?.text = NSLocalizedString("_status_wait_rename_", comment: "")
        case NCGlobal.shared.metadataStatusWaitDownload:
            cell.fileStatusImage?.image = utility.loadImage(named: "arrow.triangle.2.circlepath", colors: NCBrandColor.shared.iconImageMultiColors)
        case NCGlobal.shared.metadataStatusDownloading:
            if #available(iOS 17.0, *) {
                cell.fileStatusImage?.image = utility.loadImage(named: "arrowshape.down.circle", colors: NCBrandColor.shared.iconImageMultiColors)
            }
        case NCGlobal.shared.metadataStatusDownloadError, NCGlobal.shared.metadataStatusUploadError:
            cell.fileStatusImage?.image = utility.loadImage(named: "exclamationmark.circle", colors: NCBrandColor.shared.iconImageMultiColors)
        default:
            break
        }

        // URL
        if metadata.classFile == NKCommon.TypeClassFile.url.rawValue {
            cell.fileLocalImage?.image = nil
            cell.hideButtonShare(true)
            cell.hideButtonMore(true)
            if let ownerId = getAvatarFromIconUrl(metadata: metadata) {
                cell.fileUser = ownerId
            }
        }

        // Separator
        if collectionView.numberOfItems(inSection: indexPath.section) == indexPath.row + 1 || isSearchingMode {
            cell.cellSeparatorView?.isHidden = true
        } else {
            cell.cellSeparatorView?.isHidden = false
        }

        // Edit mode
        if isEditMode {
            cell.selectMode(true)
            if fileSelect.contains(metadata.ocId) {
                cell.selected(true, isEditMode: isEditMode)
                a11yValues.append(NSLocalizedString("_selected_", comment: ""))
            } else {
                cell.selected(false, isEditMode: isEditMode)
            }
        } else {
            cell.selectMode(false)
        }

        // Accessibility
        cell.setAccessibility(label: metadata.fileNameView + ", " + (cell.fileInfoLabel?.text ?? "") + (cell.fileSubinfoLabel?.text ?? ""), value: a11yValues.joined(separator: ", "))

        // Color string find in search
        cell.fileTitleLabel?.textColor = NCBrandColor.shared.textColor
        cell.fileTitleLabel?.font = .systemFont(ofSize: 15)

        if isSearchingMode, let literalSearch = self.literalSearch, let title = cell.fileTitleLabel?.text {
            let longestWordRange = (title.lowercased() as NSString).range(of: literalSearch)
            let attributedString = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
            attributedString.setAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: longestWordRange)
            cell.fileTitleLabel?.attributedText = attributedString
        }

        // TAGS
        cell.setTags(tags: Array(metadata.tags))

        // Hide buttons
        if metadata.name != global.appName {
            cell.titleInfoTrailingFull()
            cell.hideButtonShare(true)
            cell.hideButtonMore(true)
        }

        cell.setIconOutlines()

        // Hide lines on iPhone
        if !UIDevice.current.orientation.isLandscape && UIDevice.current.model.hasPrefix("iPhone") {
            cell.cellSeparatorView?.isHidden = true
            cell.fileSharedLabel?.isHidden = true
        }else{
            cell.cellSeparatorView?.isHidden = false
            cell.fileSharedLabel?.isHidden = false
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionHeader {

            if dataSource.getMetadataSourceForAllSections().isEmpty {

                
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFirstHeaderEmptyData", for: indexPath) as? NCSectionFirstHeaderEmptyData else { return NCSectionFirstHeaderEmptyData() }
                self.sectionFirstHeaderEmptyData = header
                header.delegate = self
                
            }
            if let header = header as? NCSectionFirstHeader {
                let recommendations = self.database.getRecommendedFiles(account: self.session.account)
                var sectionText = NSLocalizedString("_all_files_", comment: "")

            if indexPath.section == 0 {
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderMenu", for: indexPath) as? NCSectionHeaderMenu else { return UICollectionReusableView() }
                let (_, heightHeaderRichWorkspace, heightHeaderSection) = getHeaderHeight(section: indexPath.section)

                self.headerMenu = header
                self.headerMenu?.setViewTransfer(isHidden: true)
                if layoutForView?.layout == NCGlobal.shared.layoutGrid {
                    header.setImageSwitchList()
                    header.buttonSwitch.accessibilityLabel = NSLocalizedString("_list_view_", comment: "")
                } else {
                    header.setImageSwitchGrid()
                    header.buttonSwitch.accessibilityLabel = NSLocalizedString("_grid_view_", comment: "")
                }

                header.delegate = self
                
                if !isSearchingMode, headerMenuTransferView, isHeaderMenuTransferViewEnabled() != nil, let ocId = NCNetworking.shared.transferInForegorund?.ocId {
                    let text = String(format: NSLocalizedString("_upload_foreground_msg_", comment: ""), NCBrandOptions.shared.brand)
//                    header.setViewTransfer(isHidden: false, text: text)
                    header.setViewTransfer(isHidden: false, ocId: ocId, text: text, progress: NCNetworking.shared.transferInForegorund?.progress)
                } else {
                    header.setViewTransfer(isHidden: true)
                }
                
                if headerMenuButtonsView {
                    header.setStatusButtonsView(enable: !dataSource.isEmpty())
                    header.setButtonsView(height: NCGlobal.shared.heightButtonsView)
                    header.setSortedTitle(layoutForView?.titleButtonHeader ?? "")
                } else {
                    header.setButtonsView(height: 0)
                }

                header.setRichWorkspaceHeight(heightHeaderRichWorkspace)
                header.setRichWorkspaceText(richWorkspaceText)

                header.setContent(text: text)
            }
        }

        if kind == UICollectionView.elementKindSectionHeader || kind == mediaSectionHeader {
            if self.dataSource.isEmpty() {
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFirstHeaderEmptyData", for: indexPath) as? NCSectionFirstHeaderEmptyData else { return NCSectionFirstHeaderEmptyData() }

                self.sectionFirstHeaderEmptyData = header
                setContent(header: header, indexPath: indexPath)

                return header

            } else if indexPath.section == 0 {
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFirstHeader", for: indexPath) as? NCSectionFirstHeader else { return NCSectionFirstHeader() }

                self.sectionFirstHeader = header
//                setContent(header: header, indexPath: indexPath)
                if layoutForView?.layout == NCGlobal.shared.layoutGrid {
                    header.setImageSwitchList()
                    header.buttonSwitch.accessibilityLabel = NSLocalizedString("_list_view_", comment: "")
                } else {
                    header.setImageSwitchGrid()
                    header.buttonSwitch.accessibilityLabel = NSLocalizedString("_grid_view_", comment: "")
                }
                header.delegate = self

                if !isSearchingMode, headerMenuTransferView, isHeaderMenuTransferViewEnabled() != nil {
                    header.setViewTransfer(isHidden: false)
                } else {
                    header.setViewTransfer(isHidden: true)
                }
                
                if headerMenuButtonsView {
                    header.setStatusButtonsView(enable: !dataSource.getMetadataSourceForAllSections().isEmpty)
                    header.setButtonsView(height: NCGlobal.shared.heightButtonsView)
                    header.setSortedTitle(layoutForView?.titleButtonHeader ?? "")
                } else {
                    header.setButtonsView(height: 0)
                }

                header.setRichWorkspaceHeight(heightHeaderRichWorkspace)
                header.setRichWorkspaceText(richWorkspaceText)

                header.setSectionHeight(heightHeaderSection)
                if heightHeaderSection == 0 {
                    header.labelSection.text = ""
                } else {
                    header.labelSection.text = self.dataSource.getSectionValueLocalization(indexPath: indexPath)
                }
                header.labelSection.textColor = NCBrandColor.shared.textColor

                return header

            } else {
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as? NCSectionHeader else { return NCSectionHeader() }

                setContent(header: header, indexPath: indexPath)

                return header
            }
        } else {
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath) as? NCSectionFooter else { return NCSectionFooter() }
            let sections = self.dataSource.numberOfSections()
            let section = indexPath.section
            let metadataForSection = self.dataSource.getMetadataForSection(indexPath.section)
            let isPaginated = metadataForSection?.lastSearchResult?.isPaginated ?? false
            let metadatasCount: Int = metadataForSection?.metadatas.count ?? 0
            let unifiedSearchInProgress = metadataForSection?.unifiedSearchInProgress ?? false

            footer.delegate = self
            footer.metadataForSection = metadataForSection

            footer.setTitleLabel("")
            footer.setButtonText(NSLocalizedString("_show_more_results_", comment: ""))
            footer.buttonSection.setTitleColor(NCBrandColor.shared.customer, for: .normal)
            footer.separatorIsHidden(true)
            footer.buttonIsHidden(true)
            footer.hideActivityIndicatorSection()

            if isSearchingMode {
                if sections > 1 && section != sections - 1 {
                    footer.separatorIsHidden(false)
                }

                // If the number of entries(metadatas) is lower than the cursor, then there are no more entries.
                // The blind spot in this is when the number of entries is the same as the cursor. If so, we don't have a way of knowing if there are no more entries.
                // This is as good as it gets for determining last page without server-side flag.
                let isLastPage = (metadatasCount < metadataForSection?.lastSearchResult?.cursor ?? 0) || metadataForSection?.lastSearchResult?.entries.isEmpty == true

                if isSearchingMode && isPaginated && metadatasCount > 0 && !isLastPage {
                    footer.buttonIsHidden(false)
                }

                if unifiedSearchInProgress {
                    footer.showActivityIndicatorSection()
                }
            } else {
                if sections == 1 || section == sections - 1 {
                    let info = self.dataSource.getFooterInformation()
                    footer.setTitleLabel(directories: info.directories, files: info.files, size: info.size)
                } else {
                    footer.separatorIsHidden(false)
                }
            }
            return footer
        }
    }

    func setContent(header: UICollectionReusableView, indexPath: IndexPath) {
        if let header = header as? NCSectionHeader {
            let text = self.dataSource.getSectionValueLocalization(indexPath: indexPath)

            header.setContent(text: text)
        }
    }
    
    // MARK: -

    func getAvatarFromIconUrl(metadata: tableMetadata) -> String? {
        var ownerId: String?

        if metadata.iconUrl.contains("http") && metadata.iconUrl.contains("avatar") {
            let splitIconUrl = metadata.iconUrl.components(separatedBy: "/")
            var found: Bool = false
            for item in splitIconUrl {
                if found {
                    ownerId = item
                    break
                }
                if item == "avatar" { found = true}
            }
        }
        return ownerId
    }
    
    // MARK: - Cancel (Download Upload)

    // sessionIdentifierDownload: String = "com.nextcloud.nextcloudkit.session.download"
    // sessionIdentifierUpload: String = "com.nextcloud.nextcloudkit.session.upload"

    // sessionUploadBackground: String = "com.nextcloud.session.upload.background"
    // sessionUploadBackgroundWWan: String = "com.nextcloud.session.upload.backgroundWWan"
    // sessionUploadBackgroundExtension: String = "com.nextcloud.session.upload.extension"

    func cancelSession(metadata: tableMetadata) async {

        let fileNameLocalPath = utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)
        utilityFileSystem.removeFile(atPath: utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId))
        NCManageDatabase.shared.deleteLocalFileOcId(metadata.ocId)

        // No session found
        if metadata.session.isEmpty {
            NCNetworking.shared.uploadRequest.removeValue(forKey: fileNameLocalPath)
            NCNetworking.shared.downloadRequest.removeValue(forKey: fileNameLocalPath)
            NCManageDatabase.shared.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource)
            return
        }

        // DOWNLOAD FOREGROUND
        if metadata.session == NextcloudKit.shared.nkCommonInstance.identifierSessionDownload {
            if let request = NCNetworking.shared.downloadRequest[fileNameLocalPath] {
                request.cancel()
            } else if let metadata = NCManageDatabase.shared.getMetadataFromOcId(metadata.ocId) {
                NCManageDatabase.shared.setMetadataSession(ocId: metadata.ocId,
                                                           session: "",
                                                           sessionError: "",
                                                           selector: "",
                                                           status: NCGlobal.shared.metadataStatusNormal)
                NotificationCenter.default.post(name: Notification.Name(rawValue: NCGlobal.shared.notificationCenterDownloadCancelFile),
                                                object: nil,
                                                userInfo: ["ocId": metadata.ocId,
                                                           "serverUrl": metadata.serverUrl,
                                                           "account": metadata.account])
            }
            return
        }

        // DOWNLOAD BACKGROUND
        if metadata.session == NCNetworking.shared.sessionDownloadBackground {
            let session: URLSession? = NCNetworking.shared.sessionManagerDownloadBackground
            if let tasks = await session?.tasks {
                for task in tasks.2 { // ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])
                    if task.taskIdentifier == metadata.sessionTaskIdentifier {
                        task.cancel()
                    }
                }
            }
        }

        // UPLOAD FOREGROUND
        if metadata.session == NextcloudKit.shared.nkCommonInstance.identifierSessionUpload {
            if let request = NCNetworking.shared.uploadRequest[fileNameLocalPath] {
                request.cancel()
                NCNetworking.shared.uploadRequest.removeValue(forKey: fileNameLocalPath)
            }
            NCManageDatabase.shared.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
            NotificationCenter.default.post(name: Notification.Name(rawValue: NCGlobal.shared.notificationCenterUploadCancelFile),
                                            object: nil,
                                            userInfo: ["ocId": metadata.ocId,
                                                       "serverUrl": metadata.serverUrl,
                                                       "account": metadata.account])
            return
        }

        // UPLOAD BACKGROUND
        var session: URLSession?
        if metadata.session == NCNetworking.shared.sessionUploadBackground {
            session = NCNetworking.shared.sessionManagerUploadBackground
        } else if metadata.session == NCNetworking.shared.sessionUploadBackgroundWWan {
            session = NCNetworking.shared.sessionManagerUploadBackgroundWWan
        }
        if let tasks = await session?.tasks {
            for task in tasks.1 { // ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])
                if task.taskIdentifier == metadata.sessionTaskIdentifier {
                    task.cancel()
                    NCManageDatabase.shared.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
                    NotificationCenter.default.post(name: Notification.Name(rawValue: NCGlobal.shared.notificationCenterUploadCancelFile),
                                                    object: nil,
                                                    userInfo: ["ocId": metadata.ocId,
                                                               "serverUrl": metadata.serverUrl,
                                                               "account": metadata.account])
                }
            }
        }
    }
}
