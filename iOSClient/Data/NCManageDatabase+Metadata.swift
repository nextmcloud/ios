//
//  NCManageDatabase+Metadata.swift
//  Nextcloud
//
//  Created by Henrik Storch on 30.11.21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
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

class tableMetadata: Object {
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? tableMetadata,
           self.account == object.account,
           self.etag == object.etag,
           self.fileId == object.fileId,
           self.path == object.path,
           self.fileName == object.fileName,
           self.fileNameView == object.fileNameView,
           self.date == object.date,
           self.datePhotosOriginal == object.datePhotosOriginal,
           self.permissions == object.permissions,
           self.hasPreview == object.hasPreview,
           self.note == object.note,
           self.lock == object.lock,
           self.favorite == object.favorite,
           self.livePhotoFile == object.livePhotoFile,
           self.sharePermissionsCollaborationServices == object.sharePermissionsCollaborationServices,
           self.height == object.height,
           self.width == object.width,
           self.latitude == object.latitude,
           self.longitude == object.longitude,
           self.altitude == object.altitude,
           self.status == object.status,
           Array(self.tags).elementsEqual(Array(object.tags)),
           Array(self.shareType).elementsEqual(Array(object.shareType)),
           Array(self.sharePermissionsCloudMesh).elementsEqual(Array(object.sharePermissionsCloudMesh)) {
            return true
        } else {
            return false
        }
    }

    @objc dynamic var account = ""
    @objc dynamic var assetLocalIdentifier = ""
    @objc dynamic var checksums = ""
    @objc dynamic var chunk: Int = 0
    @objc dynamic var classFile = ""
    @objc dynamic var commentsUnread: Bool = false
    @objc dynamic var contentType = ""
    @objc dynamic var creationDate = NSDate()
    @objc dynamic var dataFingerprint = ""
    @objc dynamic var date = NSDate()
    @objc dynamic var datePhotosOriginal = NSDate()
    @objc dynamic var directory: Bool = false
    @objc dynamic var downloadURL = ""
    @objc dynamic var e2eEncrypted: Bool = false
    @objc dynamic var edited: Bool = false
    @objc dynamic var etag = ""
    let exifPhotos = List<NCKeyValue>()
    @objc dynamic var favorite: Bool = false
    @objc dynamic var fileId = ""
    @objc dynamic var fileName = ""
    @objc dynamic var fileNameView = ""
    @objc dynamic var hasPreview: Bool = false
    @objc dynamic var hidden: Bool = false
    @objc dynamic var iconName = ""
    @objc dynamic var iconUrl = ""
    @objc dynamic var isFlaggedAsLivePhotoByServer: Bool = false // Indicating if the file is sent as a live photo from the server, or if we should detect it as such and convert it client-side
    @objc dynamic var isExtractFile: Bool = false
    @objc dynamic var livePhotoFile = "" // If this is not empty, the media is a live photo. New media gets this straight from server, but old media needs to be detected as live photo (look isFlaggedAsLivePhotoByServer)
    @objc dynamic var mountType = ""
    @objc dynamic var name = "" // for unifiedSearch is the provider.id
    @objc dynamic var note = ""
    @objc dynamic var ocId = ""
    @objc dynamic var ocIdTransfer = ""
    @objc dynamic var ownerId = ""
    @objc dynamic var ownerDisplayName = ""
    @objc public var lock = false
    @objc public var lockOwner = ""
    @objc public var lockOwnerEditor = ""
    @objc public var lockOwnerType = 0
    @objc public var lockOwnerDisplayName = ""
    @objc public var lockTime: Date?
    @objc public var lockTimeOut: Date?
    @objc dynamic var path = ""
    @objc dynamic var permissions = ""
    @objc dynamic var placePhotos: String?
    @objc dynamic var quotaUsedBytes: Int64 = 0
    @objc dynamic var quotaAvailableBytes: Int64 = 0
    @objc dynamic var resourceType = ""
    @objc dynamic var richWorkspace: String?
    @objc dynamic var sceneIdentifier: String?
    @objc dynamic var serverUrl = ""
    @objc dynamic var serverUrlFileName = ""
    @objc dynamic var serverUrlTo = ""
    @objc dynamic var session = ""
    @objc dynamic var sessionDate: Date?
    @objc dynamic var sessionError = ""
    @objc dynamic var sessionSelector = ""
    @objc dynamic var sessionTaskIdentifier: Int = 0
    @objc dynamic var sharePermissionsCollaborationServices: Int = 0
    let sharePermissionsCloudMesh = List<String>()
    let shareType = List<Int>()
    @objc dynamic var size: Int64 = 0
    @objc dynamic var status: Int = 0
    @objc dynamic var storeFlag: String?
    @objc dynamic var subline: String?
    let tags = List<String>()
    @objc dynamic var trashbinFileName = ""
    @objc dynamic var trashbinOriginalLocation = ""
    @objc dynamic var trashbinDeletionTime = NSDate()
    @objc dynamic var uploadDate = NSDate()
    @objc dynamic var url = ""
    @objc dynamic var urlBase = ""
    @objc dynamic var user = ""
    @objc dynamic var userId = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var altitude: Double = 0
    @objc dynamic var height: Int = 0
    @objc dynamic var width: Int = 0
    @objc dynamic var errorCode: Int = 0
    @objc dynamic var nativeFormat: Bool = false
    @objc dynamic var autoUploadServerUrlBase: String?
    @objc dynamic var typeIdentifier: String = ""

    override static func primaryKey() -> String {
        return "ocId"
    }
}

extension tableMetadata {
    var fileExtension: String {
        (fileNameView as NSString).pathExtension
    }

    var fileNoExtension: String {
        (fileNameView as NSString).deletingPathExtension
    }

    var isRenameable: Bool {
        if lock {
            return false
        }
        if !isDirectoryE2EE && e2eEncrypted {
            return false
        }
        return true
    }
    
    var isPrintable: Bool {
        if isDocumentViewableOnly {
            return false
        }
        if ["application/pdf", "com.adobe.pdf"].contains(contentType) || contentType.hasPrefix("text/") || classFile == NKCommon.TypeClassFile.image.rawValue {
            return true
        }
        return false
    }

    var isPrintable: Bool {
        if isDocumentViewableOnly {
            return false
        }
        if ["application/pdf", "com.adobe.pdf"].contains(contentType) || contentType.hasPrefix("text/") || classFile == NKCommon.TypeClassFile.image.rawValue {
            return true
        }
        return false
    }
    
    var isSavebleInCameraRoll: Bool {
        return (classFile == NKCommon.TypeClassFile.image.rawValue && contentType != "image/svg+xml") || classFile == NKCommon.TypeClassFile.video.rawValue
        return (classFile == NKTypeClassFile.image.rawValue && contentType != "image/svg+xml") || classFile == NKTypeClassFile.video.rawValue
    }
    
    var isDocumentViewableOnly: Bool {
        sharePermissionsCollaborationServices == NCPermissions().permissionReadShare && classFile == NKCommon.TypeClassFile.document.rawValue
    }
    

    var isDocumentViewableOnly: Bool {
        sharePermissionsCollaborationServices == NCPermissions().permissionReadShare && classFile == NKCommon.TypeClassFile.document.rawValue
    }

    var isAudioOrVideo: Bool {
        return classFile == NKTypeClassFile.audio.rawValue || classFile == NKTypeClassFile.video.rawValue
    }

    var isImageOrVideo: Bool {
        return classFile == NKTypeClassFile.image.rawValue || classFile == NKTypeClassFile.video.rawValue
    }

    var isVideo: Bool {
        return classFile == NKTypeClassFile.video.rawValue
    }

    var isAudio: Bool {
        return classFile == NKTypeClassFile.audio.rawValue
    }

    var isImage: Bool {
        return classFile == NKTypeClassFile.image.rawValue
    }

    var isSavebleAsImage: Bool {
        classFile == NKTypeClassFile.image.rawValue && contentType != "image/svg+xml"
    }

    var isCopyableInPasteboard: Bool {
        !isDocumentViewableOnly && !directory
    }

    var isCopyableMovable: Bool {
        !isDocumentViewableOnly && !isDirectoryE2EE && !e2eEncrypted
    }

    var isModifiableWithQuickLook: Bool {
        if directory || isDocumentViewableOnly || isDirectoryE2EE {
            return false
        }
        return isPDF || isImage
    }

    var isDeletable: Bool {
        if !isDirectoryE2EE && e2eEncrypted {
            return false
        }
        return true
    }

    var canSetAsAvailableOffline: Bool {
//        return session.isEmpty && !isDirectoryE2EE && !e2eEncrypted
        return session.isEmpty && !isDocumentViewableOnly
        return session.isEmpty && !isDocumentViewableOnly //!isDirectoryE2EE && !e2eEncrypted
    }

    var canShare: Bool {
        return session.isEmpty && !isDocumentViewableOnly && !directory && !NCBrandOptions.shared.disable_openin_file
    }

    var canSetDirectoryAsE2EE: Bool {
        return directory && size == 0 && !e2eEncrypted && NCKeychain().isEndToEndEnabled(account: account)
    }

    var canUnsetDirectoryAsE2EE: Bool {
        return !isDirectoryE2EE && directory && size == 0 && e2eEncrypted && NCKeychain().isEndToEndEnabled(account: account)
    }

    var canOpenExternalEditor: Bool {
        if isDocumentViewableOnly {
            return false
        }
        let utility = NCUtility()
        let editors = utility.editorsDirectEditing(account: account, contentType: contentType)
        let isRichDocument = utility.isTypeFileRichDocument(self)
        return classFile == NKCommon.TypeClassFile.document.rawValue && editors.contains(NCGlobal.shared.editorText) && ((editors.contains(NCGlobal.shared.editorOnlyoffice) || isRichDocument))
    }

    var isWaitingTransfer: Bool {
        status == NCGlobal.shared.metadataStatusWaitDownload || status == NCGlobal.shared.metadataStatusWaitUpload || status == NCGlobal.shared.metadataStatusUploadError
    }

    var isInTransfer: Bool {
        status == NCGlobal.shared.metadataStatusDownloading || status == NCGlobal.shared.metadataStatusUploading
    }

    var isTransferInForeground: Bool {
        (status > 0 && (chunk > 0 || e2eEncrypted))
    }
    
    var isDownloadUpload: Bool {
        status == NCGlobal.shared.metadataStatusDownloading || status == NCGlobal.shared.metadataStatusUploading
    }
    
    var isDownload: Bool {
        status == NCGlobal.shared.metadataStatusWaitDownload || status == NCGlobal.shared.metadataStatusDownloading
    }

    var isUpload: Bool {
        status == NCGlobal.shared.metadataStatusWaitUpload || status == NCGlobal.shared.metadataStatusUploading
    }

    var isDirectory: Bool {
        directory
    }

    @objc var isDirectoryE2EE: Bool {
        let session = NCSession.Session(account: account, urlBase: urlBase, user: user, userId: userId)
        return NCUtilityFileSystem().isDirectoryE2EE(session: session, serverUrl: serverUrl)
    }

    var isDirectoryE2EETop: Bool {
        NCUtilityFileSystem().isDirectoryE2EETop(account: account, serverUrl: serverUrl)
    }

    var isLivePhoto: Bool {
        !livePhotoFile.isEmpty
    }

    var isNotFlaggedAsLivePhotoByServer: Bool {
        !isFlaggedAsLivePhotoByServer
    }

    var imageSize: CGSize {
        CGSize(width: width, height: height)
    }

    var hasPreviewBorder: Bool {
        !isImage && !isAudioOrVideo && hasPreview && NCUtilityFileSystem().fileProviderStorageImageExists(ocId, etag: etag, ext: NCGlobal.shared.previewExt1024)
    }

    var isAvailableEditorView: Bool {
        guard !isPDF,
              classFile == NKTypeClassFile.document.rawValue,
              NextcloudKit.shared.isNetworkReachable() else { return false }
        let utility = NCUtility()
        let directEditingEditors = utility.editorsDirectEditing(account: account, contentType: contentType)
        let richDocumentEditor = utility.isTypeFileRichDocument(self)
        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: account)

        if capabilities.richDocumentsEnabled,
           richDocumentEditor,
           directEditingEditors.isEmpty {
            // RichDocument: Collabora
            return true
        } else if directEditingEditors.contains("Nextcloud Text") || directEditingEditors.contains("onlyoffice") {
            // DirectEditing: Nextcloud Text - OnlyOffice
           return true
        }
        return false
    }

    var isAvailableRichDocumentEditorView: Bool {
        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: account)
        guard classFile == NKTypeClassFile.document.rawValue,
              capabilities.richDocumentsEnabled,
              NextcloudKit.shared.isNetworkReachable() else { return false }

        if NCUtility().isTypeFileRichDocument(self) {
            return true
        }
        return false
    }

    var isAvailableDirectEditingEditorView: Bool {
        guard (classFile == NKTypeClassFile.document.rawValue) && NextcloudKit.shared.isNetworkReachable() else { return false }
        let editors = NCUtility().editorsDirectEditing(account: account, contentType: contentType)

        if editors.contains("Nextcloud Text") || editors.contains("ONLYOFFICE") {
            return true
        }
        return false
    }

    var isPDF: Bool {
        return (contentType == "application/pdf" || contentType == "com.adobe.pdf")
    }

    /// Returns false if the user is lokced out of the file. I.e. The file is locked but by somone else
    func canUnlock(as user: String) -> Bool {
        return !lock || (lockOwner == user && lockOwnerType == 0)
    }

    // Return if is sharable
    func isSharable() -> Bool {
        guard NCGlobal.shared.capabilityE2EEEnabled, !isDirectoryE2EE, !e2eEncrypted else { return false }
        if !NCCapabilities.shared.getCapabilities(account: account).capabilityFileSharingApiEnabled || (NCCapabilities.shared.getCapabilities(account: account).capabilityE2EEEnabled && isDirectoryE2EE), !e2eEncrypted {
            return false
        }
        return !e2eEncrypted
        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: account)
        if !capabilities.fileSharingApiEnabled || (capabilities.e2EEEnabled && isDirectoryE2EE) {
//        if !NCCapabilities.shared.getCapabilities(account: account).capabilityFileSharingApiEnabled || (NCCapabilities.shared.getCapabilities(account: account).capabilityE2EEEnabled && isDirectoryE2EE), !e2eEncrypted {
            return false
        }
        return !e2eEncrypted
    }

    /// Returns a detached (unmanaged) deep copy of the current `tableMetadata` object.
    ///
    /// - Note: The Realm `List` properties containing primitive types (e.g., `tags`, `shareType`) are copied automatically
    ///         by the Realm initializer `init(value:)`. For `List` containing Realm objects (e.g., `exifPhotos`), this method
    ///         creates new instances to ensure the copy is fully detached and safe to use outside of a Realm context.
    ///
    /// - Returns: A new `tableMetadata` instance fully detached from Realm.
    func detachedCopy() -> tableMetadata {
        // Use Realm's built-in copy constructor for primitive properties and List of primitives
        let detached = tableMetadata(value: self)

        // Deep copy of List of Realm objects (exifPhotos)
        detached.exifPhotos.removeAll()
        detached.exifPhotos.append(objectsIn: self.exifPhotos.map { NCKeyValue(value: $0) })

        return detached
    }
}

extension NCManageDatabase {
    func convertFileToMetadata(_ file: NKFile, isDirectoryE2EE: Bool) -> tableMetadata {
        let metadata = tableMetadata()

        metadata.account = file.account
        metadata.checksums = file.checksums
        metadata.commentsUnread = file.commentsUnread
        metadata.contentType = file.contentType
        if let date = file.creationDate {
            metadata.creationDate = date as NSDate
        } else {
            metadata.creationDate = file.date as NSDate
        }
        metadata.dataFingerprint = file.dataFingerprint
        metadata.date = file.date as NSDate
        if let datePhotosOriginal = file.datePhotosOriginal {
            metadata.datePhotosOriginal = datePhotosOriginal as NSDate
        } else {
            metadata.datePhotosOriginal = metadata.date
        }
        metadata.directory = file.directory
        metadata.downloadURL = file.downloadURL
        metadata.e2eEncrypted = file.e2eEncrypted
        metadata.etag = file.etag
        for dict in file.exifPhotos {
            for (key, value) in dict {
                let keyValue = NCKeyValue()
                keyValue.key = key
                keyValue.value = value
                metadata.exifPhotos.append(keyValue)
            }
        }
        metadata.favorite = file.favorite
        metadata.fileId = file.fileId
        metadata.fileName = file.fileName
        metadata.fileNameView = file.fileName
        metadata.hasPreview = file.hasPreview
        metadata.hidden = file.hidden
        metadata.iconName = file.iconName
        switch (file.fileName as NSString).pathExtension {
        case "odg":
            metadata.iconName = "diagram"
        case "csv", "xlsm" :
            metadata.iconName = "file_xls"
        default:
            metadata.iconName = file.iconName
        }
        metadata.mountType = file.mountType
        metadata.name = file.name
        metadata.note = file.note
        metadata.ocId = file.ocId
        metadata.ocIdTransfer = file.ocId
        metadata.ownerId = file.ownerId
        metadata.ownerDisplayName = file.ownerDisplayName
        metadata.lock = file.lock
        metadata.lockOwner = file.lockOwner
        metadata.lockOwnerEditor = file.lockOwnerEditor
        metadata.lockOwnerType = file.lockOwnerType
        metadata.lockOwnerDisplayName = file.lockOwnerDisplayName
        metadata.lockTime = file.lockTime
        metadata.lockTimeOut = file.lockTimeOut
        metadata.path = file.path
        metadata.permissions = file.permissions
        metadata.placePhotos = file.placePhotos
        metadata.quotaUsedBytes = file.quotaUsedBytes
        metadata.quotaAvailableBytes = file.quotaAvailableBytes
        metadata.richWorkspace = file.richWorkspace
        metadata.resourceType = file.resourceType
        metadata.serverUrl = file.serverUrl
        metadata.serveUrlFileName = file.serverUrl + "/" + file.fileName
        metadata.sharePermissionsCollaborationServices = file.sharePermissionsCollaborationServices
        for element in file.sharePermissionsCloudMesh {
            metadata.sharePermissionsCloudMesh.append(element)
        }
        for element in file.shareType {
            metadata.shareType.append(element)
        }
        for element in file.tags {
            metadata.tags.append(element)
        }
        metadata.size = file.size
        metadata.classFile = file.classFile
        // iOS 12.0,* don't detect UTI text/markdown, text/x-markdown
        if (metadata.contentType == "text/markdown" || metadata.contentType == "text/x-markdown") && metadata.classFile == NKCommon.TypeClassFile.unknow.rawValue {
            metadata.classFile = NKCommon.TypeClassFile.document.rawValue
        }
        if let date = file.uploadDate {
            metadata.uploadDate = date as NSDate
        } else {
            metadata.uploadDate = file.date as NSDate
        }
        metadata.urlBase = file.urlBase
        metadata.user = file.user
        metadata.userId = file.userId
        metadata.latitude = file.latitude
        metadata.longitude = file.longitude
        metadata.altitude = file.altitude
        metadata.height = Int(file.height)
        metadata.width = Int(file.width)
        metadata.livePhotoFile = file.livePhotoFile
        metadata.isFlaggedAsLivePhotoByServer = file.isFlaggedAsLivePhotoByServer

        // E2EE find the fileName for fileNameView
        if isDirectoryE2EE || file.e2eEncrypted {
            if let tableE2eEncryption = getE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameIdentifier == %@", file.account, file.serverUrl, file.fileName)) {
                metadata.fileNameView = tableE2eEncryption.fileName
                let results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: metadata.fileNameView, mimeType: file.contentType, directory: file.directory, account: file.account)
                metadata.contentType = results.mimeType
                metadata.iconName = results.iconName
                metadata.classFile = results.classFile
            }
        }
        return metadata
    }

    func convertFilesToMetadatas(_ files: [NKFile], useFirstAsMetadataFolder: Bool, completion: @escaping (_ metadataFolder: tableMetadata, _ metadatas: [tableMetadata]) -> Void) {
        var counter: Int = 0
        var isDirectoryE2EE: Bool = false
        let listServerUrl = ThreadSafeDictionary<String, Bool>()
        var metadataFolder = tableMetadata()
        var metadatas: [tableMetadata] = []

        for file in files {
            if let key = listServerUrl[file.serverUrl] {
                isDirectoryE2EE = key
            } else {
                isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(file: file)
                listServerUrl[file.serverUrl] = isDirectoryE2EE
            }

            let metadata = convertFileToMetadata(file, isDirectoryE2EE: isDirectoryE2EE)

            if counter == 0 && useFirstAsMetadataFolder {
                metadataFolder = tableMetadata(value: metadata)
            } else {
                metadatas.append(metadata)
            }

            counter += 1
        }
        completion(metadataFolder, metadatas)
    }
    
    func convertFilesToMetadatas(_ files: [NKFile], useMetadataFolder: Bool, completion: @escaping (_ metadataFolder: tableMetadata, _ metadatasFolder: [tableMetadata], _ metadatas: [tableMetadata]) -> Void) {

        var counter: Int = 0
        var isDirectoryE2EE: Bool = false
        let listServerUrl = ThreadSafeDictionary<String, Bool>()

        var metadataFolder = tableMetadata()
        var metadataFolders: [tableMetadata] = []
        var metadatas: [tableMetadata] = []

        for file in files {

            if let key = listServerUrl[file.serverUrl] {
                isDirectoryE2EE = key
            } else {
                isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(file: file)
                listServerUrl[file.serverUrl] = isDirectoryE2EE
            }

            let metadata = convertFileToMetadata(file, isDirectoryE2EE: isDirectoryE2EE)

            if counter == 0 && useMetadataFolder {
                metadataFolder = tableMetadata.init(value: metadata)
            } else {
                metadatas.append(metadata)
                if metadata.directory {
                    metadataFolders.append(metadata)
                }
            }

            counter += 1
        }

        completion(metadataFolder, metadataFolders, metadatas)
    }

    
    func convertFilesToMetadatas(_ files: [NKFile], useMetadataFolder: Bool, completion: @escaping (_ metadataFolder: tableMetadata, _ metadatasFolder: [tableMetadata], _ metadatas: [tableMetadata]) -> Void) {

        var counter: Int = 0
        var isDirectoryE2EE: Bool = false
        let listServerUrl = ThreadSafeDictionary<String, Bool>()

        var metadataFolder = tableMetadata()
        var metadataFolders: [tableMetadata] = []
        var metadatas: [tableMetadata] = []

        for file in files {

            if let key = listServerUrl[file.serverUrl] {
                isDirectoryE2EE = key
            } else {
                isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(file: file)
                listServerUrl[file.serverUrl] = isDirectoryE2EE
            }

            let metadata = convertFileToMetadata(file, isDirectoryE2EE: isDirectoryE2EE)

            if counter == 0 && useMetadataFolder {
                metadataFolder = tableMetadata.init(value: metadata)
            } else {
                metadatas.append(metadata)
                if metadata.directory {
                    metadataFolders.append(metadata)
                }
            }

            counter += 1
        }

        completion(metadataFolder, metadataFolders, metadatas)
    }
    

    func convertFilesToMetadatasAsync(_ files: [NKFile], useFirstAsMetadataFolder: Bool) async -> (metadataFolder: tableMetadata, metadatas: [tableMetadata]) {
        await withCheckedContinuation { continuation in
            convertFilesToMetadatas(files, useFirstAsMetadataFolder: useFirstAsMetadataFolder) { metadataFolder, metadatas in
                continuation.resume(returning: (metadataFolder, metadatas))
            }
        }
    }

    func getMetadataDirectoryFrom(files: [NKFile]) -> tableMetadata? {
        guard let file = files.first else { return nil }
        let isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(file: file)
        let metadata = convertFileToMetadata(file, isDirectoryE2EE: isDirectoryE2EE)

        return metadata
    }

    func convertFilesToMetadatas(_ files: [NKFile], useFirstAsMetadataFolder: Bool) async -> (metadataFolder: tableMetadata, metadatas: [tableMetadata]) {
        await withUnsafeContinuation({ continuation in
            convertFilesToMetadatas(files, useFirstAsMetadataFolder: useFirstAsMetadataFolder) { metadataFolder, metadatas in
                continuation.resume(returning: (metadataFolder, metadatas))
            }
        })
    }

    func createMetadata(fileName: String, fileNameView: String, ocId: String, serverUrl: String, url: String, contentType: String, isUrl: Bool = false, name: String = NCGlobal.shared.appName, subline: String? = nil, iconName: String? = nil, iconUrl: String? = nil, directory: Bool = false, session: NCSession.Session, sceneIdentifier: String?) -> tableMetadata {
        let metadata = tableMetadata()

        if isUrl {
            metadata.contentType = "text/uri-list"
            if let iconName = iconName {
                metadata.iconName = iconName
            } else {
                metadata.iconName = NKCommon.TypeClassFile.url.rawValue
            }
            metadata.classFile = NKCommon.TypeClassFile.url.rawValue
        } else {
            let (mimeType, classFile, iconName, _, _, _) = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: fileName, mimeType: contentType, directory: directory, account: session.account)
            metadata.contentType = mimeType
            metadata.iconName = iconName
            metadata.classFile = classFile
            // iOS 12.0,* don't detect UTI text/markdown, text/x-markdown
            if classFile == NKCommon.TypeClassFile.unknow.rawValue && (mimeType == "text/x-markdown" || mimeType == "text/markdown") {
                metadata.iconName = NKCommon.TypeIconFile.txt.rawValue
                metadata.classFile = NKCommon.TypeClassFile.document.rawValue
            }
        }
        if let iconUrl = iconUrl {
            metadata.iconUrl = iconUrl
        }

        let fileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        metadata.account = session.account
        metadata.creationDate = Date() as NSDate
        metadata.date = Date() as NSDate
        metadata.directory = directory
        metadata.hasPreview = true
        metadata.etag = ocId
        metadata.fileName = fileName
        metadata.fileNameView = fileName
        metadata.name = name
        metadata.ocId = ocId
        metadata.ocIdTransfer = ocId
        metadata.permissions = "RGDNVW"
        metadata.serverUrl = serverUrl
        metadata.serveUrlFileName = serverUrl + "/" + fileName
        metadata.subline = subline
        metadata.uploadDate = Date() as NSDate
        metadata.url = url
        metadata.urlBase = session.urlBase
        metadata.user = session.user
        metadata.userId = session.userId
        metadata.sceneIdentifier = sceneIdentifier
        metadata.nativeFormat = !NCKeychain().formatCompatibility

        if !metadata.urlBase.isEmpty, metadata.serverUrl.hasPrefix(metadata.urlBase) {
            metadata.path = String(metadata.serverUrl.dropFirst(metadata.urlBase.count)) + "/"
        }
        return metadata
    }

    func isMetadataShareOrMounted(metadata: tableMetadata, metadataFolder: tableMetadata?) -> Bool {
        let permissions = NCPermissions()
        var isShare = false
        var isMounted = false

        if metadataFolder != nil {
            isShare = metadata.permissions.contains(permissions.permissionShared) && !metadataFolder!.permissions.contains(permissions.permissionShared)
            isMounted = metadata.permissions.contains(permissions.permissionMounted) && !metadataFolder!.permissions.contains(permissions.permissionMounted)
        } else if let directory = getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", metadata.account, metadata.serverUrl)) {
            isShare = metadata.permissions.contains(permissions.permissionShared) && !directory.permissions.contains(permissions.permissionShared)
            isMounted = metadata.permissions.contains(permissions.permissionMounted) && !directory.permissions.contains(permissions.permissionMounted)
        }

        if isShare || isMounted {
            return true
        } else {
            return false
        }
    }

    // MARK: - Set

    @discardableResult
    func addMetadata(_ metadata: tableMetadata) -> tableMetadata {
        do {
            let realm = try Realm()
            try realm.write {
                return tableMetadata(value: realm.create(tableMetadata.self, value: metadata, update: .all))
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
    // MARK: - Realm Write

    func addMetadataIfNeededAsync(_ metadata: tableMetadata, sync: Bool = true) {
        let detached = metadata.detachedCopy()

        performRealmWrite(sync: sync) { realm in
            if realm.object(ofType: tableMetadata.self, forPrimaryKey: metadata.ocId) == nil {
                realm.add(detached)
            }
        }
    }

    func addAndReturnMetadata(_ metadata: tableMetadata) -> tableMetadata? {
        let detached = metadata.detachedCopy()

        performRealmWrite { realm in
            realm.add(detached, update: .all)
        }

        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@", metadata.ocId)
                .first
                .map { $0.detachedCopy() }
        }
    }

    func addAndReturnMetadataAsync(_ metadata: tableMetadata) async -> tableMetadata? {
        let detached = metadata.detachedCopy()

        await performRealmWriteAsync { realm in
            realm.add(detached, update: .all)
        }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@", metadata.ocId)
                .first?
                .detachedCopy()
        }
    }

    func addMetadata(_ metadata: tableMetadata, sync: Bool = true) {
        let detached = metadata.detachedCopy()

        performRealmWrite(sync: sync) { realm in
            realm.add(detached, update: .all)
        }
    }

        return tableMetadata(value: metadata)
    }

    func addMetadatas(_ metadatas: [tableMetadata]) {
        do {
            let realm = try Realm()
            try realm.write {
                for metadata in metadatas {
                    realm.create(tableMetadata.self, value: metadata, update: .all)
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func deleteMetadata(predicate: NSPredicate) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter(predicate)
                realm.delete(results)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func deleteMetadataOcId(_ ocId: String?) {
    func addMetadataAsync(_ metadata: tableMetadata) async {
        let detached = metadata.detachedCopy()

        await performRealmWriteAsync { realm in
            realm.add(detached, update: .all)
        }
    }

    func addMetadatas(_ metadatas: [tableMetadata], sync: Bool = true) {
        let detached = metadatas.map { $0.detachedCopy() }

        performRealmWrite(sync: sync) { realm in
            realm.add(detached, update: .all)
        }
    }

    func addMetadatasAsync(_ metadatas: [tableMetadata]) async {
        let detached = metadatas.map { $0.detachedCopy() }

        await performRealmWriteAsync { realm in
            realm.add(detached, update: .all)
        }
    }

    func deleteMetadataAsync(predicate: NSPredicate) async {
        await performRealmWriteAsync { realm in
            let result = realm.objects(tableMetadata.self)
                .filter(predicate)
            realm.delete(result)
        }
    }

    func deleteMetadataOcId(_ ocId: String?, sync: Bool = true) {
        guard let ocId else { return }

        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("ocId == %@", ocId)
                realm.delete(results)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
    }

    func deleteMetadataOcIds(_ ocIds: [String]) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("ocId IN %@", ocIds)
                realm.delete(results)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
    }

    func deleteMetadatas(_ metadatas: [tableMetadata]) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(metadatas)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func renameMetadata(fileNameNew: String, ocId: String, status: Int = NCGlobal.shared.metadataStatusNormal) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first {
                    let fileNameView = result.fileNameView
                    let fileIdMOV = result.livePhotoFile
                    let directoryServerUrl = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileNameView)
                    let resultsType = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: fileNameNew, mimeType: "", directory: result.directory, account: result.account)

                    result.fileName = fileNameNew
                    result.fileNameView = fileNameNew
                    result.iconName = resultsType.iconName
                    result.contentType = resultsType.mimeType
                    result.classFile = resultsType.classFile
                    result.status = status
    func deleteMetadataOcIdAsync(_ ocId: String?) async {
        guard let ocId else { return }

        await performRealmWriteAsync { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
            realm.delete(result)
        }
    }

    func deleteMetadataOcIds(_ ocIds: [String], sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("ocId IN %@", ocIds)
            realm.delete(result)
        }
    }

    // Asynchronously deletes an array of `tableMetadata` entries from the Realm database.
    /// - Parameter metadatas: The `tableMetadata` objects to be deleted.
    func deleteMetadatasAsync(_ metadatas: [tableMetadata]) async {
        guard !metadatas.isEmpty else {
            return
        }
        let detached = metadatas.map { $0.detachedCopy() }

        await performRealmWriteAsync { realm in
            for detached in detached {
                if let managed = realm.object(ofType: tableMetadata.self, forPrimaryKey: detached.ocId) {
                    realm.delete(managed)
                }
            }
        }
    }

    func renameMetadata(fileNameNew: String, ocId: String, status: Int = NCGlobal.shared.metadataStatusNormal, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                let fileNameView = result.fileNameView
                let fileIdMOV = result.livePhotoFile
                let directoryServerUrl = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileNameView)

                result.fileName = fileNameNew
                result.fileNameView = fileNameNew
                result.status = status

                    if status == NCGlobal.shared.metadataStatusNormal {
                        result.sessionDate = nil
                    } else {
                        result.sessionDate = Date()
                    }

                    if result.directory,
                       let resultDirectory = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", result.account, directoryServerUrl).first {
                        let serverUrlTo = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileNameNew)

                        resultDirectory.serverUrl = serverUrlTo
                    } else {
                        let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileNameView
                        let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileNameNew

                        self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                    }

                    if result.isLivePhoto,
                       let resultMOV = realm.objects(tableMetadata.self).filter("fileId == %@ AND account == %@", fileIdMOV, result.account).first {
                        let fileNameView = resultMOV.fileNameView
                        let fileName = (fileNameNew as NSString).deletingPathExtension
                        let ext = (resultMOV.fileName as NSString).pathExtension
                        resultMOV.fileName = fileName + "." + ext
                        resultMOV.fileNameView = fileName + "." + ext

                        let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileNameView
                        let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileName + "." + ext

                        self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                    }
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func restoreMetadataFileName(ocId: String) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first,
                   let encodedURLString = result.serveUrlFileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: encodedURLString) {
                    let fileIdMOV = result.livePhotoFile
                    let directoryServerUrl = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileNameView)
                    let lastPathComponent = url.lastPathComponent
                    let fileName = lastPathComponent.removingPercentEncoding ?? lastPathComponent
                    let fileNameView = result.fileNameView

                    result.fileName = fileName
                    result.fileNameView = fileName
                    result.status = NCGlobal.shared.metadataStatusNormal
                    result.sessionDate = nil

                    if result.directory,
                       let resultDirectory = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", result.account, directoryServerUrl).first {
                        let serverUrlTo = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileName)

                        resultDirectory.serverUrl = serverUrlTo
                    } else {
                        let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileNameView
                        let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileName

                        self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                    }

                    if result.isLivePhoto,
                       let resultMOV = realm.objects(tableMetadata.self).filter("fileId == %@ AND account == %@", fileIdMOV, result.account).first {
                        let fileNameView = resultMOV.fileNameView
                        let fileName = (fileName as NSString).deletingPathExtension
                        let ext = (resultMOV.fileName as NSString).pathExtension
                        resultMOV.fileName = fileName + "." + ext
                        resultMOV.fileNameView = fileName + "." + ext

                        let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileNameView
                        let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileName + "." + ext

                        self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                    }
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataServeUrlFileNameStatusNormal(ocId: String) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first {
                    result.serveUrlFileName = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileName)
                    result.status = NCGlobal.shared.metadataStatusNormal
                    result.sessionDate = nil
    func renameMetadataAsync(fileNameNew: String, ocId: String, status: Int = NCGlobal.shared.metadataStatusNormal) async {
        await performRealmWriteAsync { realm in
            guard let metadata = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first else {
                return
            }

            let oldFileNameView = metadata.fileNameView
            let fileIdMOV = metadata.livePhotoFile
            let account = metadata.account
            let originalServerUrl = metadata.serverUrl

            metadata.fileName = fileNameNew
            metadata.fileNameView = fileNameNew
            metadata.status = status
            metadata.sessionDate = (status == NCGlobal.shared.metadataStatusNormal) ? nil : Date()

            if metadata.directory {
                let oldDirUrl = self.utilityFileSystem.stringAppendServerUrl(originalServerUrl, addFileName: oldFileNameView)
                let newDirUrl = self.utilityFileSystem.stringAppendServerUrl(originalServerUrl, addFileName: fileNameNew)

                if let dir = realm.objects(tableDirectory.self)
                    .filter("account == %@ AND serverUrl == %@", account, oldDirUrl)
                    .first {
                    dir.serverUrl = newDirUrl
                }
            } else {
                let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + oldFileNameView
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + fileNameNew
                self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
            }

            if metadata.isLivePhoto,
               let livePhotoMetadata = realm.objects(tableMetadata.self)
                    .filter("fileId == %@ AND account == %@", fileIdMOV, account)
                    .first {

                let oldMOVNameView = livePhotoMetadata.fileNameView
                let baseName = (fileNameNew as NSString).deletingPathExtension
                let ext = (livePhotoMetadata.fileName as NSString).pathExtension
                let newMOVName = baseName + "." + ext

                livePhotoMetadata.fileName = newMOVName
                livePhotoMetadata.fileNameView = newMOVName

                let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(livePhotoMetadata.ocId) + "/" + oldMOVNameView
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(livePhotoMetadata.ocId) + "/" + newMOVName

                self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
            }
        }
    }

    func restoreMetadataFileName(ocId: String, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first,
               let encodedURLString = result.serverUrlFileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encodedURLString) {
                let fileIdMOV = result.livePhotoFile
                let directoryServerUrl = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileNameView)
                let lastPathComponent = url.lastPathComponent
                let fileName = lastPathComponent.removingPercentEncoding ?? lastPathComponent
                let fileNameView = result.fileNameView

                result.fileName = fileName
                result.fileNameView = fileName
                result.status = NCGlobal.shared.metadataStatusNormal
                result.sessionDate = nil

                if result.directory,
                   let resultDirectory = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", result.account, directoryServerUrl).first {
                    let serverUrlTo = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileName)

                    resultDirectory.serverUrl = serverUrlTo
                } else {
                    let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileNameView
                    let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileName

                    self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                }

                if result.isLivePhoto,
                   let resultMOV = realm.objects(tableMetadata.self).filter("fileId == %@ AND account == %@", fileIdMOV, result.account).first {
                    let fileNameView = resultMOV.fileNameView
                    let fileName = (fileName as NSString).deletingPathExtension
                    let ext = (resultMOV.fileName as NSString).pathExtension
                    resultMOV.fileName = fileName + "." + ext
                    resultMOV.fileNameView = fileName + "." + ext

                    let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileNameView
                    let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileName + "." + ext

                    self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataEtagResource(ocId: String, etagResource: String?) {
        guard let etagResource else { return }

        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                result?.etagResource = etagResource
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataLivePhotoByServer(account: String, ocId: String, livePhotoFile: String) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("account == %@ AND ocId == %@", account, ocId).first {
                    result.isFlaggedAsLivePhotoByServer = true
                    result.livePhotoFile = livePhotoFile
                }
    /// Asynchronously restores the file name of a metadata entry and updates related file system and Realm entries.
    /// - Parameter ocId: The object ID (ocId) of the file to restore.
    func restoreMetadataFileNameAsync(ocId: String) async {
        await performRealmWriteAsync { realm in
            guard let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first,
                  let encodedURLString = result.serverUrlFileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedURLString)
            else {
                return
            }

            let fileIdMOV = result.livePhotoFile
            let directoryServerUrl = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileNameView)
            let lastPathComponent = url.lastPathComponent
            let fileName = lastPathComponent.removingPercentEncoding ?? lastPathComponent
            let fileNameView = result.fileNameView

            result.fileName = fileName
            result.fileNameView = fileName
            result.status = NCGlobal.shared.metadataStatusNormal
            result.sessionDate = nil

            if result.directory,
               let resultDirectory = realm.objects(tableDirectory.self)
                   .filter("account == %@ AND serverUrl == %@", result.account, directoryServerUrl)
                   .first {
                let serverUrlTo = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: fileName)
                resultDirectory.serverUrl = serverUrlTo
            } else {
                let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileNameView
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.ocId) + "/" + fileName
                self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
            }

            if result.isLivePhoto,
               let resultMOV = realm.objects(tableMetadata.self)
                   .filter("fileId == %@ AND account == %@", fileIdMOV, result.account)
                   .first {
                let fileNameViewMOV = resultMOV.fileNameView
                let baseName = (fileName as NSString).deletingPathExtension
                let ext = (resultMOV.fileName as NSString).pathExtension
                let fullFileName = baseName + "." + ext

                resultMOV.fileName = fullFileName
                resultMOV.fileNameView = fullFileName

                let atPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fileNameViewMOV
                let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(resultMOV.ocId) + "/" + fullFileName
                self.utilityFileSystem.moveFile(atPath: atPath, toPath: toPath)
            }
        }
    }

    func setMetadataServerUrlFileNameStatusNormal(ocId: String, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                result.serverUrlFileName = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileName)
                result.status = NCGlobal.shared.metadataStatusNormal
                result.sessionDate = nil
            }
        }
    }

    func setMetadataServerUrlFileNameStatusNormalAsync(ocId: String) async {
        await performRealmWriteAsync { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                result.serverUrlFileName = self.utilityFileSystem.stringAppendServerUrl(result.serverUrl, addFileName: result.fileName)
                result.status = NCGlobal.shared.metadataStatusNormal
                result.sessionDate = nil
            }
        }
    }

    func setMetadataLivePhotoByServerAsync(account: String,
                                           ocId: String,
                                           livePhotoFile: String) async {
        await performRealmWriteAsync { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("account == %@ AND ocId == %@", account, ocId)
                .first {
                result.isFlaggedAsLivePhotoByServer = true
                result.livePhotoFile = livePhotoFile
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func updateMetadatasFavorite(account: String, metadatas: [tableMetadata]) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("account == %@ AND favorite == true", account)
                for result in results {
                    result.favorite = false
                }
                realm.add(metadatas, update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
    func updateMetadatasFavoriteAsync(account: String, metadatas: [tableMetadata]) async {
        guard !metadatas.isEmpty else { return }

        await performRealmWriteAsync { realm in
            let oldFavorites = realm.objects(tableMetadata.self)
                .filter("account == %@ AND favorite == true", account)
            for item in oldFavorites {
                item.favorite = false
            }
            realm.add(metadatas, update: .all)
        }
    }

    func updateMetadatasFiles(_ metadatas: [tableMetadata], serverUrl: String, account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter(NSPredicate(format: "account == %@ AND serverUrl == %@ AND status == %d", account, serverUrl, NCGlobal.shared.metadataStatusNormal))
                realm.delete(results)
                for metadata in metadatas {
                    if realm.objects(tableMetadata.self).filter(NSPredicate(format: "ocId == %@ AND status != %d", metadata.ocId, NCGlobal.shared.metadataStatusNormal)).first != nil {
                        continue
                    }
                    realm.add(tableMetadata(value: metadata), update: .all)
                }
        let detached = metadatas.map { $0.detachedCopy() }

        performRealmWrite(sync: false) { realm in
            let ocIdsToSkip = Set(
                realm.objects(tableMetadata.self)
                    .filter("status != %d", NCGlobal.shared.metadataStatusNormal)
                    .map(\.ocId)
                )

            let resultsToDelete = realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND status == %d", account, serverUrl, NCGlobal.shared.metadataStatusNormal)
                .filter { !ocIdsToSkip.contains($0.ocId) }

            realm.delete(resultsToDelete)

            for metadata in detached {
                guard !ocIdsToSkip.contains(metadata.ocId)
                else {
                    continue
                }
                realm.add(metadata, update: .all)
            }
        }
    }

    /// Updates metadata files in Realm asynchronously.
    /// - Parameters:
    ///   - metadatas: Array of `tableMetadata` objects to insert or update.
    ///   - serverUrl: Server URL identifier.
    ///   - account: Account identifier.
    func updateMetadatasFilesAsync(_ metadatas: [tableMetadata], serverUrl: String, account: String) async {
        await performRealmWriteAsync { realm in
            let ocIdsToSkip = Set(
                realm.objects(tableMetadata.self)
                    .filter("status != %d", NCGlobal.shared.metadataStatusNormal)
                    .map(\.ocId)
            )

            let resultsToDelete = realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND status == %d", account, serverUrl, NCGlobal.shared.metadataStatusNormal)
                .filter { !ocIdsToSkip.contains($0.ocId) }

            realm.delete(resultsToDelete)

            for metadata in metadatas {
                guard !ocIdsToSkip.contains(metadata.ocId) else { continue }
                realm.add(metadata.detachedCopy(), update: .all)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataEncrypted(ocId: String, encrypted: Bool) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                result?.e2eEncrypted = encrypted
    func setMetadataEncrypted(ocId: String, encrypted: Bool, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first
            result?.e2eEncrypted = encrypted
        }
    }

    func setMetadataEncryptedAsync(ocId: String, encrypted: Bool) async {
        await performRealmWriteAsync { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first
            result?.e2eEncrypted = encrypted
        }
    }

    func setMetadataFileNameView(serverUrl: String, fileName: String, newFileNameView: String, account: String, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND fileName == %@", account, serverUrl, fileName)
                .first
            result?.fileNameView = newFileNameView
        }
    }

    func setMetadataFileNameViewAsync(serverUrl: String, fileName: String, newFileNameView: String, account: String) async {
        await performRealmWriteAsync { realm in
            let result = realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND fileName == %@", account, serverUrl, fileName)
                .first
            result?.fileNameView = newFileNameView
        }
    }

    func moveMetadata(ocId: String, serverUrlTo: String, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                result.serverUrl = serverUrlTo
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataFileNameView(serverUrl: String, fileName: String, newFileNameView: String, account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableMetadata.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@", account, serverUrl, fileName).first
                result?.fileNameView = newFileNameView
    func moveMetadataAsync(ocId: String, serverUrlTo: String) async {
        await performRealmWriteAsync { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                result.serverUrl = serverUrlTo
            }
        }
    }

    func clearAssetLocalIdentifiersAsync(_ assetLocalIdentifiers: [String]) async {
        await performRealmWriteAsync { realm in
            let results = realm.objects(tableMetadata.self)
                .filter("assetLocalIdentifier IN %@", assetLocalIdentifiers)
            for result in results {
                result.assetLocalIdentifier = ""
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func moveMetadata(ocId: String, serverUrlTo: String) {
        do {
            let realm = try Realm()
            try realm.write {
                if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first {
                    result.serverUrl = serverUrlTo
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func clearAssetLocalIdentifiers(_ assetLocalIdentifiers: [String]) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("assetLocalIdentifier IN %@", assetLocalIdentifiers)
                for result in results {
                    result.assetLocalIdentifier = ""
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataFavorite(ocId: String, favorite: Bool?, saveOldFavorite: String?, status: Int) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                if let favorite {
                    result?.favorite = favorite
                }
                result?.storeFlag = saveOldFavorite
                result?.status = status
    /// Asynchronously sets the favorite status of a `tableMetadata` entry.
    /// Optionally stores the previous favorite flag and updates the sync status.
    func setMetadataFavoriteAsync(ocId: String, favorite: Bool?, saveOldFavorite: String?, status: Int) async {
        await performRealmWriteAsync { realm in
            guard let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first else {
                return
            }

            if let favorite {
                result.favorite = favorite
            }

            result.storeFlag = saveOldFavorite
            result.status = status
            result.sessionDate = (status == NCGlobal.shared.metadataStatusNormal) ? nil : Date()
        }
    }

    func setMetadataCopyMove(ocId: String, serverUrlTo: String, overwrite: String?, status: Int, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            if let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first {
                result.serverUrlTo = serverUrlTo
                result.storeFlag = overwrite
                result.status = status

                if status == NCGlobal.shared.metadataStatusNormal {
                    result?.sessionDate = nil
                } else {
                    result?.sessionDate = Date()
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func setMetadataCopyMove(ocId: String, serverUrlTo: String, overwrite: String?, status: Int) {
        do {
            let realm = try Realm()
            try realm.write {
                let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
                result?.serverUrlTo = serverUrlTo
                result?.storeFlag = overwrite
                result?.status = status

                if status == NCGlobal.shared.metadataStatusNormal {
                    result?.sessionDate = nil
                } else {
                    result?.sessionDate = Date()
                }
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
    /// Asynchronously updates a `tableMetadata` entry to set copy/move status and target server URL.
    func setMetadataCopyMoveAsync(ocId: String, serverUrlTo: String, overwrite: String?, status: Int) async {
        await performRealmWriteAsync { realm in
            guard let result = realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first else {
                return
            }

            result.serverUrlTo = serverUrlTo
            result.storeFlag = overwrite
            result.status = status
            result.sessionDate = (status == NCGlobal.shared.metadataStatusNormal) ? nil : Date()
        }
    }

    func clearMetadatasUpload(account: String, sync: Bool = true) {
        performRealmWrite(sync: sync) { realm in
            let results = realm.objects(tableMetadata.self)
                .filter("account == %@ AND (status == %d OR status == %d)", account, NCGlobal.shared.metadataStatusWaitUpload, NCGlobal.shared.metadataStatusUploadError)
            realm.delete(results)
        }
    }

    // MARK: - GetMetadata

    func getMetadata(predicate: NSPredicate) -> tableMetadata? {
        do {
            let realm = try Realm()
            guard let result = realm.objects(tableMetadata.self).filter(predicate).first else { return nil }
            return tableMetadata(value: result)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .first
                .map { $0.detachedCopy() }
        }

        return nil
    }

    func getMetadatas(predicate: NSPredicate) -> [tableMetadata] {
        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate)
            return Array(results.map { tableMetadata(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return []
    }

    func getMetadatas(predicate: NSPredicate, sortedByKeyPath: String, ascending: Bool = false) -> [tableMetadata]? {
        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sortedByKeyPath, ascending: ascending)
            return Array(results.map { tableMetadata(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
    func getMetadataAsync(predicate: NSPredicate) async -> tableMetadata? {
        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .first
                .map { $0.detachedCopy() }
        }
    }

    func getMetadatas(predicate: NSPredicate) -> [tableMetadata] {
        performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .map { $0.detachedCopy() }
        } ?? []
    }

    func getMetadatas(predicate: NSPredicate,
                      sortedByKeyPath: String,
                      ascending: Bool = false) -> [tableMetadata]? {
        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .sorted(byKeyPath: sortedByKeyPath, ascending: ascending)
                .map { $0.detachedCopy() }
        }
    }

    func getMetadatasAsync(predicate: NSPredicate,
                           sortedByKeyPath: String,
                           ascending: Bool = false,
                           limit: Int? = nil) async -> [tableMetadata]? {
        return await performRealmReadAsync { realm in
            let results = realm.objects(tableMetadata.self)
                .filter(predicate)
                .sorted(byKeyPath: sortedByKeyPath,
                        ascending: ascending)

            if let limit {
                let sliced = results.prefix(limit)
                return sliced.map { $0.detachedCopy() }
            } else {
                return results.map { $0.detachedCopy() }
            }
        }
        return nil
    }

    func getMetadatas(predicate: NSPredicate, numItems: Int, sorted: String, ascending: Bool) -> [tableMetadata] {
        var counter: Int = 0
        var metadatas: [tableMetadata] = []

        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
            for result in results where counter < numItems {
                metadatas.append(tableMetadata(value: result))
                counter += 1
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return metadatas
    func getMetadatas(predicate: NSPredicate,
                      numItems: Int,
                      sorted: String,
                      ascending: Bool) -> [tableMetadata] {
        return performRealmRead { realm in
            let results = realm.objects(tableMetadata.self)
                .filter(predicate)
                .sorted(byKeyPath: sorted, ascending: ascending)
            return results.prefix(numItems)
                .map { $0.detachedCopy() }
        } ?? []
    }

    func getMetadataFromOcId(_ ocId: String?) -> tableMetadata? {
        guard let ocId else { return nil }

        do {
            let realm = try Realm()
            guard let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first else { return nil }
            return tableMetadata(value: result)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getMetadataFromOcIdAndocIdTransfer(_ ocId: String?) -> tableMetadata? {
        guard let ocId else { return nil }

        do {
            let realm = try Realm()
            if let result = realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first {
                return tableMetadata(value: result)
            }
            if let result = realm.objects(tableMetadata.self).filter("ocIdTransfer == %@", ocId).first {
                return tableMetadata(value: result)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first
                .map { $0.detachedCopy() }
        }
    }

    func getMetadataFromOcIdAsync(_ ocId: String?) async -> tableMetadata? {
        guard let ocId else { return nil }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@", ocId)
                .first
                .map { $0.detachedCopy() }
        }
    }

    func getMetadataFromOcIdAndocIdTransferAsync(_ ocId: String?) async -> tableMetadata? {
        guard let ocId else {
            return nil
        }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter("ocId == %@ OR ocIdTransfer == %@", ocId, ocId)
                .first
                .map { $0.detachedCopy() }
        }
        return nil
    }

    func getMetadataFolder(session: NCSession.Session, serverUrl: String) -> tableMetadata? {
        var serverUrl = serverUrl
        var fileName = ""
        let serverUrlHome = utilityFileSystem.getHomeServer(session: session)

        if serverUrlHome == serverUrl {
            fileName = "."
            serverUrl = ".."
        } else {
            fileName = (serverUrl as NSString).lastPathComponent
            if let path = utilityFileSystem.deleteLastPath(serverUrlPath: serverUrl) {
                serverUrl = path
            }
        }

        do {
            let realm = try Realm()
            guard let result = realm.objects(tableMetadata.self).filter("account == %@ AND serverUrl == %@ AND fileName == %@", session.account, serverUrl, fileName).first else { return nil }
            return tableMetadata(value: result)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND fileName == %@", session.account, serverUrl, fileName)
                .first
                .map { $0.detachedCopy() }
        }
    }

    /// Asynchronously retrieves the metadata for a folder, based on its session and serverUrl.
    /// Handles the home directory case (".") and detaches the Realm object before returning.
    func getMetadataFolderAsync(session: NCSession.Session, serverUrl: String) async -> tableMetadata? {
        var serverUrl = serverUrl
        var fileName = ""
        let serverUrlHome = utilityFileSystem.getHomeServer(session: session)

        if serverUrlHome == serverUrl {
            fileName = "."
            serverUrl = ".."
        } else {
            fileName = (serverUrl as NSString).lastPathComponent
            if let path = utilityFileSystem.deleteLastPath(serverUrlPath: serverUrl) {
                serverUrl = path
            }
        }

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter("account == %@ AND serverUrl == %@ AND fileName == %@", session.account, serverUrl, fileName)
                .first
                .map { $0.detachedCopy() }
        }
        return nil
    }

    func getMetadataLivePhoto(metadata: tableMetadata) -> tableMetadata? {
        guard metadata.isLivePhoto else { return nil }

        do {
            let realm = try Realm()
            guard let result = realm.objects(tableMetadata.self).filter(NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileId == %@",
                                                                                    metadata.account,
                                                                                    metadata.serverUrl,
                                                                                    metadata.livePhotoFile)).first else { return nil }
            return tableMetadata(value: result)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        guard metadata.isLivePhoto else {
            return nil
        }
        let detached = metadata.detachedCopy()

        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter(NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileId == %@",
                                    detached.account,
                                    detached.serverUrl,
                                    detached.livePhotoFile))
                .first
                .map { $0.detachedCopy() }
        }
    }

    func getMetadataLivePhotoAsync(metadata: tableMetadata) async -> tableMetadata? {
        guard metadata.isLivePhoto else {
            return nil
        }
        let detached = metadata.detachedCopy()

        return await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileId == %@",
                                    detached.account,
                                    detached.serverUrl,
                                    detached.livePhotoFile))
                .first
                .map { $0.detachedCopy() }
        }
        return nil
    }

    func getMetadataConflict(account: String, serverUrl: String, fileNameView: String, nativeFormat: Bool) -> tableMetadata? {
        let fileNameExtension = (fileNameView as NSString).pathExtension.lowercased()
        let fileNameNoExtension = (fileNameView as NSString).deletingPathExtension
        var fileNameConflict = fileNameView

        if fileNameExtension == "heic", !nativeFormat {
            fileNameConflict = fileNameNoExtension + ".jpg"
        }
        return getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView == %@",
                                                  account,
                                                  serverUrl,
                                                  fileNameConflict))
    }

    // MARK: - GetResult(s)Metadata

    func getResultsMetadatasPredicate(_ predicate: NSPredicate, layoutForView: NCDBLayoutForView?, directoryOnTop: Bool = true) -> [tableMetadata] {
        do {
            let realm = try Realm()
            var results = realm.objects(tableMetadata.self).filter(predicate).freeze()
            let layout: NCDBLayoutForView = layoutForView ?? NCDBLayoutForView()

            if layout.sort == "fileName" {
                let sortedResults = results.sorted {
                    let ordered = layout.ascending ? ComparisonResult.orderedAscending : ComparisonResult.orderedDescending
                    // 1. favorite order
                    if $0.favorite == $1.favorite {
                        // 2. directory order TOP
                        if directoryOnTop {
                            if $0.directory == $1.directory {
                                // 3. natural fileName
                                return $0.fileNameView.localizedStandardCompare($1.fileNameView) == ordered
                            } else {
                                return $0.directory && !$1.directory
                            }
                        } else {
                            return $0.fileNameView.localizedStandardCompare($1.fileNameView) == ordered
                        }
                    } else {
                        return $0.favorite && !$1.favorite
                    }
                }
                return sortedResults
            } else {
                if directoryOnTop {
                    results = results.sorted(byKeyPath: layout.sort, ascending: layout.ascending).sorted(byKeyPath: "favorite", ascending: false).sorted(byKeyPath: "directory", ascending: false)
                } else {
                    results = results.sorted(byKeyPath: layout.sort, ascending: layout.ascending).sorted(byKeyPath: "favorite", ascending: false)
                }
            }
            return Array(results)

        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return []
    }

    func getResultsMetadatas(predicate: NSPredicate, sortedByKeyPath: String, ascending: Bool, arraySlice: Int) -> [tableMetadata] {
        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sortedByKeyPath, ascending: ascending).prefix(arraySlice)
            return Array(results)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return []
    }

    func getResultMetadata(predicate: NSPredicate) -> tableMetadata? {
        do {
            let realm = try Realm()
            return realm.objects(tableMetadata.self).filter(predicate).first
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getResultMetadataFromFileName(_ fileName: String, serverUrl: String, sessionTaskIdentifier: Int) -> tableMetadata? {
        do {
            let realm = try Realm()
            return realm.objects(tableMetadata.self).filter("fileName == %@ AND serverUrl == %@ AND sessionTaskIdentifier == %d", fileName, serverUrl, sessionTaskIdentifier).first
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getResultsMetadatasFromGroupfolders(session: NCSession.Session) -> Results<tableMetadata>? {
        var ocId: [String] = []
        let homeServerUrl = utilityFileSystem.getHomeServer(session: session)

        do {
            let realm = try Realm()
            let groupfolders = realm.objects(TableGroupfolders.self).filter("account == %@", session.account).sorted(byKeyPath: "mountPoint", ascending: true)
    /// Asynchronously retrieves and sorts `tableMetadata` associated with groupfolders for a given session.
    /// - Parameters:
    ///   - session: The `NCSession.Session` containing account and server information.
    ///   - layoutForView: An optional layout configuration used for sorting.
    /// - Returns: An array of sorted and detached `tableMetadata` objects.
    func getMetadatasFromGroupfoldersAsync(session: NCSession.Session, layoutForView: NCDBLayoutForView?) async -> [tableMetadata] {
        let homeServerUrl = utilityFileSystem.getHomeServer(session: session)

        return await performRealmReadAsync { realm in
            var ocIds: [String] = []

            // Safely fetch and detach groupfolders
            let groupfolders = realm.objects(TableGroupfolders.self)
                .filter("account == %@", session.account)
                .sorted(byKeyPath: "mountPoint", ascending: true)
                .map { TableGroupfolders(value: $0) }

            for groupfolder in groupfolders {
                let mountPoint = groupfolder.mountPoint.hasPrefix("/") ? groupfolder.mountPoint : "/" + groupfolder.mountPoint
                let serverUrlFileName = homeServerUrl + mountPoint

                if let directory = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", session.account, serverUrlFileName).first,
                   let result = realm.objects(tableMetadata.self).filter("ocId == %@", directory.ocId).first {
                    ocId.append(result.ocId)
                }
            }

            return realm.objects(tableMetadata.self).filter("ocId IN %@", ocId)
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }

        return nil
    }

    func getTableMetadatasDirectoryFavoriteIdentifierRank(account: String) -> [String: NSNumber] {
        var listIdentifierRank: [String: NSNumber] = [:]
        var counter = 10 as Int64

        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter("account == %@ AND directory == true AND favorite == true", account).sorted(byKeyPath: "fileNameView", ascending: true)
            for result in results {
            // Fetch and detach the corresponding metadatas
            let metadatas = realm.objects(tableMetadata.self)
                .filter("ocId IN %@", ocIds)
                .map { $0.detachedCopy() }

            let sorted = self.sortedMetadata(layoutForView: layoutForView, account: session.account, metadatas: Array(metadatas))

            return sorted
        } ?? []
    }

    // MARK: - Realm Read

    func getMetadatasAsync(predicate: NSPredicate) async -> [tableMetadata] {
        await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .map { $0.detachedCopy() }
        } ?? []
    }

    func getTableMetadatasDirectoryFavoriteIdentifierRankAsync(account: String) async -> [String: NSNumber] {
        let result = await performRealmReadAsync { realm in
            var listIdentifierRank: [String: NSNumber] = [:]
            var counter = Int64(10)

            let results = realm.objects(tableMetadata.self)
                .filter("account == %@ AND directory == true AND favorite == true", account)
                .sorted(byKeyPath: "fileNameView", ascending: true)

            results.forEach { item in
                counter += 1
                listIdentifierRank[item.ocId] = NSNumber(value: counter)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return listIdentifierRank
    }

    @objc func clearMetadatasUpload(account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("account == %@ AND (status == %d OR status == %d)", account, NCGlobal.shared.metadataStatusWaitUpload, NCGlobal.shared.metadataStatusUploadError)
                realm.delete(results)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func getAssetLocalIdentifiersUploaded() -> [String]? {
        var assetLocalIdentifiers: [String] = []

        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter("assetLocalIdentifier != ''")
            for result in results {
                assetLocalIdentifiers.append(result.assetLocalIdentifier)
            }
            return assetLocalIdentifiers
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getMetadataFromDirectory(account: String, serverUrl: String) -> Bool {
        do {
            let realm = try Realm()
            guard let directory = realm.objects(tableDirectory.self).filter("account == %@ AND serverUrl == %@", account, serverUrl).first,
                  realm.objects(tableMetadata.self).filter("ocId == %@", directory.ocId).first != nil else { return false }
            return true
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return false
            
            return listIdentifierRank
        }
        return result ?? [:]
    }

    @objc func clearMetadatasUpload(account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("account == %@ AND (status == %d OR status == %d)", account, NCGlobal.shared.metadataStatusWaitUpload, NCGlobal.shared.metadataStatusUploadError)
                realm.delete(results)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }

    func getAssetLocalIdentifiersUploadedAsync() async -> [String]? {
        return await performRealmReadAsync { realm in
            let results = realm.objects(tableMetadata.self).filter("assetLocalIdentifier != ''")
            return results.map { $0.assetLocalIdentifier }
        }
    }

    @objc func clearMetadatasUpload(account: String) {
        do {
            let realm = try Realm()
            try realm.write {
                let results = realm.objects(tableMetadata.self).filter("account == %@ AND (status == %d OR status == %d)", account, NCGlobal.shared.metadataStatusWaitUpload, NCGlobal.shared.metadataStatusUploadError)
                realm.delete(results)
            }
        } catch let error {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not write to database: \(error)")
        }
    }
    
    func getMetadataFromFileId(_ fileId: String?) -> tableMetadata? {
        guard let fileId else { return nil }

        do {
            let realm = try Realm()
            if let result = realm.objects(tableMetadata.self).filter("fileId == %@", fileId).first {
                return tableMetadata(value: result)
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        guard let fileId else {
            return nil
        }

        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter("fileId == %@", fileId)
                .first
                .map { $0.detachedCopy() }
        }
        return nil
    }

    func getResultMetadataFromOcId(_ ocId: String?) -> tableMetadata? {
        guard let ocId else { return nil }

        do {
            let realm = try Realm()
            return realm.objects(tableMetadata.self).filter("ocId == %@", ocId).first
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getResultsMetadatas(predicate: NSPredicate, sortedByKeyPath: String? = nil, ascending: Bool = false, freeze: Bool = false) -> Results<tableMetadata>? {
        do {
            let realm = try Realm()
            if let sortedByKeyPath {
                let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sortedByKeyPath, ascending: ascending)
                if freeze {
                    return results.freeze()
                }
                return results
            } else {
                let results = realm.objects(tableMetadata.self).filter(predicate)
                if freeze {
                    return results.freeze()
                }
                return results
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] Could not access database: \(error)")
        }
        return nil
    }

    func getCalculateCumulativeHash(for metadatas: [tableMetadata], account: String, serverUrl: String) -> String {
        let concatenatedEtags = metadatas.map { $0.etag }.joined(separator: "-")
        return sha256Hash(concatenatedEtags)
    }
    
    func getMediaMetadatas(predicate: NSPredicate) -> ThreadSafeArray<tableMetadata>? {

        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
            return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }

        return nil
    }
    
    func getMediaMetadatas(predicate: NSPredicate, sorted: String? = nil, ascending: Bool = false) -> ThreadSafeArray<tableMetadata>? {

        do {
            let realm = try Realm()
            if let sorted {
                var results: [tableMetadata] = []
                switch NCKeychain().mediaSortDate {
                case "date":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.date as Date) > ($1.date as Date) }
                case "creationDate":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.creationDate as Date) > ($1.creationDate as Date) }
                case "uploadDate":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.uploadDate as Date) > ($1.uploadDate as Date) }
                default:
                    let results = realm.objects(tableMetadata.self).filter(predicate)
                    return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
                }
                return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
            } else {
                let results = realm.objects(tableMetadata.self).filter(predicate)
                return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }
        return nil
    }
    
    func getAdvancedMetadatas(predicate: NSPredicate, page: Int = 0, limit: Int = 0, sorted: String, ascending: Bool) -> [tableMetadata] {

    /// Asynchronously retrieves a `tableMetadata` object matching the given `fileId`, if available.
    /// - Parameter fileId: The file identifier used to query the Realm database.
    /// - Returns: A detached copy of the `tableMetadata` object, or `nil` if not found.
    func getMetadataFromFileIdAsync(_ fileId: String?) async -> tableMetadata? {
        guard let fileId else {
            return nil
        }

        return await performRealmReadAsync { realm in
            let object = realm.objects(tableMetadata.self)
                .filter("fileId == %@", fileId)
                .first
            return object?.detachedCopy()
        }
    }

    /// Asynchronously retrieves and sorts `tableMetadata` objects matching a given predicate and layout.
    func getMetadatasAsync(predicate: NSPredicate,
                           withLayout layoutForView: NCDBLayoutForView?,
                           withAccount account: String) async -> [tableMetadata] {
        let detachedMetadatas = await performRealmReadAsync { realm in
            realm.objects(tableMetadata.self)
                .filter(predicate)
                .map { $0.detachedCopy() }
        } ?? []

        let sorted = self.sortedMetadata(layoutForView: layoutForView, account: account, metadatas: detachedMetadatas)

        return sorted
    }

    func getMetadatasAsync(predicate: NSPredicate,
                           withSort sortDescriptors: [RealmSwift.SortDescriptor] = [],
                           withLimit limit: Int? = nil) async -> [tableMetadata]? {
        await performRealmReadAsync { realm in
            var results = realm.objects(tableMetadata.self)
                .filter(predicate)

            if !sortDescriptors.isEmpty {
                results = results.sorted(by: sortDescriptors)
            }

            if let limit {
                let sliced = results.prefix(limit)
                return sliced.map { $0.detachedCopy() }
            } else {
                return results.map { $0.detachedCopy() }
            }
        }
    }

    func hasUploadingMetadataWithChunksOrE2EE() -> Bool {
        return performRealmRead { realm in
            realm.objects(tableMetadata.self)
                .filter("status == %d AND (chunk > 0 OR e2eEncrypted == true)", NCGlobal.shared.metadataStatusUploading)
                .first != nil
        } ?? false
    }

    func createMetadatasFolder(assets: [PHAsset],
                               useSubFolder: Bool,
                               session: NCSession.Session, completion: @escaping ([tableMetadata]) -> Void) {
        var foldersCreated: Set<String> = []
        var metadatas: [tableMetadata] = []

        do {
            let realm = try Realm()
            realm.refresh()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
            if !results.isEmpty {
                if page == 0 || limit == 0 {
                    return Array(results.map { tableMetadata.init(value: $0) })
                } else {
                    let nFrom = (page - 1) * limit
                    let nTo = nFrom + (limit - 1)
                    for n in nFrom...nTo {
                        if n == results.count {
                            break
                        }
                        metadatas.append(tableMetadata.init(value: results[n]))
                    }
                }
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }

        return metadatas
    }
    
    func getMediaMetadatas(predicate: NSPredicate) -> ThreadSafeArray<tableMetadata>? {

        do {
            let realm = try Realm()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: "date", ascending: false)
            return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }

        return nil
    }
    
    func getMediaMetadatas(predicate: NSPredicate, sorted: String? = nil, ascending: Bool = false) -> ThreadSafeArray<tableMetadata>? {

        do {
            let realm = try Realm()
            if let sorted {
                var results: [tableMetadata] = []
                switch NCKeychain().mediaSortDate {
                case "date":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.date as Date) > ($1.date as Date) }
                case "creationDate":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.creationDate as Date) > ($1.creationDate as Date) }
                case "uploadDate":
                    results = realm.objects(tableMetadata.self).filter(predicate).sorted { ($0.uploadDate as Date) > ($1.uploadDate as Date) }
                default:
                    let results = realm.objects(tableMetadata.self).filter(predicate)
                    return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
                }
                return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
            } else {
                let results = realm.objects(tableMetadata.self).filter(predicate)
                return ThreadSafeArray(results.map { tableMetadata.init(value: $0) })
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }
        return nil
    }
    
    func getAdvancedMetadatas(predicate: NSPredicate, page: Int = 0, limit: Int = 0, sorted: String, ascending: Bool) -> [tableMetadata] {

        var metadatas: [tableMetadata] = []

        do {
            let realm = try Realm()
            realm.refresh()
            let results = realm.objects(tableMetadata.self).filter(predicate).sorted(byKeyPath: sorted, ascending: ascending)
            if !results.isEmpty {
                if page == 0 || limit == 0 {
                    return Array(results.map { tableMetadata.init(value: $0) })
                } else {
                    let nFrom = (page - 1) * limit
                    let nTo = nFrom + (limit - 1)
                    for n in nFrom...nTo {
                        if n == results.count {
                            break
                        }
                        metadatas.append(tableMetadata.init(value: results[n]))
                    }
                }
            }
        } catch let error as NSError {
            NextcloudKit.shared.nkCommonInstance.writeLog("Could not access database: \(error)")
        }

        return metadatas
    }
}
