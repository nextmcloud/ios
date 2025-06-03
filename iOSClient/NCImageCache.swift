//
//  NCImageCache.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 18/10/23.
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
import LRUCache
import NextcloudKit
import RealmSwift

@objc class NCImageCache: NSObject {
@objc class NCImageCache: NSObject, @unchecked Sendable {
    @objc static let shared = NCImageCache()

    private let utility = NCUtility()
    private let global = NCGlobal.shared

    private let allowExtensions = [NCGlobal.shared.previewExt256]
    private var brandElementColor: UIColor?

    private let limit: Int = 1000
    private var totalSize: Int64 = 0
    public var countLimit: Int = 2000
    lazy var cache: LRUCache<String, UIImage> = {
        return LRUCache<String, UIImage>(countLimit: countLimit)
    }()

    public var isLoadingCache: Bool = false
    var isDidEnterBackground: Bool = false

    struct metadataInfo {
        var etag: String
        var date: NSDate
        var width: Int
        var height: Int
    }

    struct imageInfo {
        var image: UIImage?
        var size: CGSize?
        var date: Date
    }

    private typealias ThumbnailImageLRUCache = LRUCache<String, imageInfo>
    private typealias ThumbnailSizeLRUCache = LRUCache<String, CGSize?>

    private lazy var cacheImage: ThumbnailImageLRUCache = {
        return ThumbnailImageLRUCache(countLimit: limit)
    }()
    private lazy var cacheSize: ThumbnailSizeLRUCache = {
        return ThumbnailSizeLRUCache()
    }()
    private var metadatasInfo: [String: metadataInfo] = [:]
    private var metadatas: ThreadSafeArray<tableMetadata>?

    var createMediaCacheInProgress: Bool = false
    let showAllPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND (classFile == '\(NKCommon.TypeClassFile.image.rawValue)' OR classFile == '\(NKCommon.TypeClassFile.video.rawValue)') AND NOT (session CONTAINS[c] 'upload')"
    let showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND (classFile == '\(NKCommon.TypeClassFile.image.rawValue)' OR classFile == '\(NKCommon.TypeClassFile.video.rawValue)') AND NOT (session CONTAINS[c] 'upload') AND NOT (livePhotoFile != '' AND classFile == '\(NKCommon.TypeClassFile.video.rawValue)')"
    let showOnlyPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND classFile == %@ AND NOT (session CONTAINS[c] 'upload') AND NOT (livePhotoFile != '' AND classFile == '\(NKCommon.TypeClassFile.video.rawValue)')"

    override init() {
        super.init()

        countLimit = calculateMaxImages(percentage: 5.0, imageSizeKB: 30.0) // 5% of cache = 20
        NextcloudKit.shared.nkCommonInstance.writeLog("Counter cache image: \(countLimit)")

        NotificationCenter.default.addObserver(forName: LRUCacheMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAllValues()
            self.countLimit = self.countLimit - 500
            if self.countLimit <= 0 { self.countLimit = 100 }
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
#if DEBUG
        NCContentPresenter().messageNotification("Cache image memory warning \(self.countLimit)", error: .success, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, priority: .max)
#endif
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.isDidEnterBackground = true
            self.cache.removeAllValues()
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
#if !EXTENSION
            guard !self.isLoadingCache else {
                return
            }
            self.isDidEnterBackground = false

            var files: [NCFiles] = []
            var cost: Int = 0

            if let activeTableAccount = NCManageDatabase.shared.getActiveTableAccount(),
               NCImageCache.shared.cache.count == 0 {
                let session = NCSession.shared.getSession(account: activeTableAccount.account)

                for mainTabBarController in SceneManager.shared.getControllers() {
                    if let currentVC = mainTabBarController.selectedViewController as? UINavigationController,
                       let file = currentVC.visibleViewController as? NCFiles {
                        files.append(file)
                    }
                }

                DispatchQueue.global().async {
                    self.isLoadingCache = true

                    /// MEDIA
                    if let metadatas = NCManageDatabase.shared.getResultsMetadatas(predicate: self.getMediaPredicate(filterLivePhotoFile: true, session: session, showOnlyImages: false, showOnlyVideos: false), sortedByKeyPath: "datePhotosOriginal", freeze: true)?.prefix(self.countLimit) {
                        autoreleasepool {
                            self.cache.removeAllValues()

                            for metadata in metadatas {
                                guard !self.isDidEnterBackground else {
                                    self.cache.removeAllValues()
                                    break
                                }
                                if let image = self.utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: self.global.previewExt256) {
                                    self.addImageCache(ocId: metadata.ocId, etag: metadata.etag, image: image, ext: self.global.previewExt256, cost: cost)
                                    cost += 1
                                }
                            }
                        }
                    }

                    /// FILE
                    if !self.isDidEnterBackground {
                        for file in files where !file.serverUrl.isEmpty {
                            NCNetworking.shared.notifyAllDelegates { delegate in
                                delegate.transferReloadData(serverUrl: file.serverUrl)
                            }
                        }
                    }

                    self.isLoadingCache = false
                }
            }
#endif
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: LRUCacheMemoryWarningNotification, object: nil)
    }

    @objc func createMediaCache(account: String, withCacheSize: Bool) {
        if createMediaCacheInProgress {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] ThumbnailLRUCache image process already in progress")
            return
        }
        createMediaCacheInProgress = true

        self.metadatasInfo.removeAll()
        self.metadatas = nil
        self.metadatas = getMediaMetadatas(account: account)
        let ext = ".preview.ico"
        let manager = FileManager.default
        let resourceKeys = Set<URLResourceKey>([.nameKey, .pathKey, .fileSizeKey, .creationDateKey])
        struct FileInfo {
            var path: URL
            var ocIdEtag: String
            var date: Date
            var fileSize: Int
            var width: Int
            var height: Int
        }
        var files: [FileInfo] = []
        let startDate = Date()

        if let metadatas = metadatas {
            metadatas.forEach { metadata in
                metadatasInfo[metadata.ocId] = metadataInfo(etag: metadata.etag, date: metadata.date, width: metadata.width, height: metadata.height)
            }
        }

        if let enumerator = manager.enumerator(at: URL(fileURLWithPath: NCUtilityFileSystem().directoryProviderStorage), includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator where fileURL.lastPathComponent.hasSuffix(ext) {
                let fileName = fileURL.lastPathComponent
                let ocId = fileURL.deletingLastPathComponent().lastPathComponent
                guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                      let fileSize = resourceValues.fileSize,
                      fileSize > 0 else { continue }
                let width = metadatasInfo[ocId]?.width ?? 0
                let height = metadatasInfo[ocId]?.height ?? 0
                if withCacheSize {
                    if let date = metadatasInfo[ocId]?.date,
                       let etag = metadatasInfo[ocId]?.etag,
                       fileName == etag + ext {
                        files.append(FileInfo(path: fileURL, ocIdEtag: ocId + etag, date: date as Date, fileSize: fileSize, width: width, height: height))
                    } else {
                        let etag = fileName.replacingOccurrences(of: ".preview.ico", with: "")
                        files.append(FileInfo(path: fileURL, ocIdEtag: ocId + etag, date: Date.distantPast, fileSize: fileSize, width: width, height: height))
                    }
                } else if let date = metadatasInfo[ocId]?.date, let etag = metadatasInfo[ocId]?.etag, fileName == etag + ext {
                    files.append(FileInfo(path: fileURL, ocIdEtag: ocId + etag, date: date as Date, fileSize: fileSize, width: width, height: height))
                } else {
                    print("Nothing")
                }
            }
        }

        files.sort(by: { $0.date > $1.date })
        if let firstDate = files.first?.date, let lastDate = files.last?.date {
            print("First date: \(firstDate)")
            print("Last date: \(lastDate)")
        }

        cacheImage.removeAllValues()
        cacheSize.removeAllValues()
        var counter: Int = 0
        for file in files {
            if !withCacheSize, counter > limit {
                break
            }
            autoreleasepool {
                if let image = UIImage(contentsOfFile: file.path.path) {
                    if counter < limit {
                        cacheImage.setValue(imageInfo(image: image, size: image.size, date: file.date), forKey: file.ocIdEtag)
                        totalSize = totalSize + Int64(file.fileSize)
                    }
                    if file.width == 0, file.height == 0 {
                        cacheSize.setValue(image.size, forKey: file.ocIdEtag)
                    }
                }
            }
            counter += 1
        }

        let diffDate = Date().timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
        NextcloudKit.shared.nkCommonInstance.writeLog("--------- ThumbnailLRUCache image process ---------")
        NextcloudKit.shared.nkCommonInstance.writeLog("Counter cache image: \(cacheImage.count)")
        NextcloudKit.shared.nkCommonInstance.writeLog("Counter cache size: \(cacheSize.count)")
        NextcloudKit.shared.nkCommonInstance.writeLog("Total size images process: " + NCUtilityFileSystem().transformedSize(totalSize))
        NextcloudKit.shared.nkCommonInstance.writeLog("Time process: \(diffDate)")
        NextcloudKit.shared.nkCommonInstance.writeLog("--------- ThumbnailLRUCache image process ---------")

        createMediaCacheInProgress = false
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterCreateMediaCacheEnded)
    }
    
    func calculateMaxImages(percentage: Double, imageSizeKB: Double) -> Int {
        let totalRamBytes = Double(ProcessInfo.processInfo.physicalMemory)
        let cacheSizeBytes = totalRamBytes * (percentage / 100.0)
        let imageSizeBytes = imageSizeKB * 1024
        let maxImages = Int(cacheSizeBytes / imageSizeBytes)

        return maxImages
    }
    
    func getMediaMetadatas(account: String, predicate: NSPredicate? = nil) -> ThreadSafeArray<tableMetadata>? {
        return NCManageDatabase.shared.getMediaMetadatas(predicate: predicate ?? predicateBoth, sorted: "date")    }
        return NCManageDatabase.shared.getMediaMetadatas(predicate: predicate ?? predicateBoth, sorted: "date")
    }
        guard let tableAccount = NCManageDatabase.shared.getTableAccount(predicate: NSPredicate(format: "account == %@", account)) else { return nil }
        let startServerUrl = NCUtilityFileSystem().getHomeServer(urlBase: tableAccount.urlBase, userId: tableAccount.userId) + tableAccount.mediaPath
        let predicateBoth = NSPredicate(format: showBothPredicateMediaString, account, startServerUrl)
        return NCManageDatabase.shared.getMediaMetadatas(predicate: predicate ?? predicateBoth, sorted: "date")
    }
    

    func allowExtensions(ext: String) -> Bool {
        return allowExtensions.contains(ext)
    }

    func addImageCache(ocId: String, etag: String, data: Data, ext: String, cost: Int) {
        guard allowExtensions.contains(ext),
              let image = UIImage(data: data) else { return }

        cache.setValue(image, forKey: ocId + etag + ext, cost: cost)
    }

    func addImageCache(ocId: String, etag: String, image: UIImage, ext: String, cost: Int) {
        guard allowExtensions.contains(ext) else { return }

        cache.setValue(image, forKey: ocId + etag + ext, cost: cost)
    }

    func getImageCache(ocId: String, etag: String, ext: String) -> UIImage? {
        return cache.value(forKey: ocId + etag + ext)
    }

    func removeImageCache(ocIdPlusEtag: String) {
        for i in 0..<allowExtensions.count {
            cache.removeValue(forKey: ocIdPlusEtag + allowExtensions[i])
        }
    }

    func removeAll() {
        cache.removeAllValues()
    }

    // MARK: - MEDIA -

    func getMediaPredicate(filterLivePhotoFile: Bool, session: NCSession.Session, showOnlyImages: Bool, showOnlyVideos: Bool) -> NSPredicate {
            guard let tableAccount = NCManageDatabase.shared.getTableAccount(predicate: NSPredicate(format: "account == %@", session.account)) else { return NSPredicate() }
            var predicate = NSPredicate()
            let startServerUrl = NCUtilityFileSystem().getHomeServer(session: session) + tableAccount.mediaPath

            var showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND hasPreview == true AND (classFile == '\(NKCommon.TypeClassFile.image.rawValue)' OR classFile == '\(NKCommon.TypeClassFile.video.rawValue)') AND NOT (status IN %@)"
            var showOnlyPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND hasPreview == true AND classFile == %@ AND NOT (status IN %@)"

            if filterLivePhotoFile {
                showBothPredicateMediaString = showBothPredicateMediaString + " AND NOT (livePhotoFile != '' AND classFile == '\(NKCommon.TypeClassFile.video.rawValue)')"
                showOnlyPredicateMediaString = showOnlyPredicateMediaString + " AND NOT (livePhotoFile != '' AND classFile == '\(NKCommon.TypeClassFile.video.rawValue)')"
            }

            if showOnlyImages {
                predicate = NSPredicate(format: showOnlyPredicateMediaString, session.account, startServerUrl, NKCommon.TypeClassFile.image.rawValue, global.metadataStatusHideInView)
            } else if showOnlyVideos {
                predicate = NSPredicate(format: showOnlyPredicateMediaString, session.account, startServerUrl, NKCommon.TypeClassFile.video.rawValue, global.metadataStatusHideInView)
            } else {
                predicate = NSPredicate(format: showBothPredicateMediaString, session.account, startServerUrl, global.metadataStatusHideInView)
            }

            return predicate
        }

    // MARK: -

    struct images {
        static var file = UIImage()

        static var shared = UIImage()
        static var canShare = UIImage()
        static var shareByLink = UIImage()
        static var sharedWithMe = UIImage()

        static var favorite = UIImage()
        static var comment = UIImage()
        static var livePhoto = UIImage()
        static var offlineFlag = UIImage()
        static var local = UIImage()

        static var folderEncrypted = UIImage()
        static var folderSharedWithMe = UIImage()
        static var folderPublic = UIImage()
        static var folderGroup = UIImage()
        static var folderExternal = UIImage()
        static var folderAutomaticUpload = UIImage()
        static var folder = UIImage()

        static var checkedYes = UIImage()
        static var checkedNo = UIImage()

        static var buttonMore = UIImage()
        static var buttonStop = UIImage()
        static var buttonMoreLock = UIImage()

        static var buttonRestore = UIImage()
        static var buttonTrash = UIImage()
        
        static var iconContacts = UIImage()
        static var iconTalk = UIImage()
        static var iconCalendar = UIImage()
        static var iconDeck = UIImage()
        static var iconMail = UIImage()
        static var iconConfirm = UIImage()
        static var iconPages = UIImage()
        static var iconFile = UIImage()
    }

    func getImageShared(account: String) -> UIImage {
        return UIImage(named: "share")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getImageCanShare() -> UIImage {
        return UIImage(named: "share")!.imageColor(.systemGray)
    }
    func createImagesCache() {
        let utility = NCUtility()

        images.file = utility.loadImage(named: "doc", colors: [NCBrandColor.shared.iconImageColor2])

        images.shared = UIImage(named: "share")!.image(color: .systemGray, size: 50)
        images.canShare = UIImage(named: "share")!.image(color: .systemGray, size: 50)
        images.shareByLink = UIImage(named: "sharebylink")!.image(color: .systemGray, size: 50)
        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 50)
        
        images.favorite = utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
        images.livePhoto = utility.loadImage(named: "livephoto", colors: [.label])
        images.offlineFlag = UIImage(named: "offlineFlag")!
        images.local = utility.loadImage(named: "checkmark.circle.fill", colors: [.systemGreen])

        images.checkedYes = UIImage(named: "checkedYes")!
        images.checkedNo = UIImage(named: "local")!

        images.buttonMore = utility.loadImage(named: "ellipsis", colors: [NCBrandColor.shared.iconImageColor])
        images.buttonStop = utility.loadImage(named: "stop.circle", colors: [NCBrandColor.shared.iconImageColor])
        images.buttonMoreLock = utility.loadImage(named: "lock.fill", colors: [NCBrandColor.shared.iconImageColor])

        createImagesBrandCache()
    }

    func createImagesBrandCache() {

        let brandElement = NCBrandColor.shared.brandElement
        guard brandElement != self.brandElementColor else { return }
        self.brandElementColor = brandElement
        let utility = NCUtility()

    func createImagesCache() {
        let utility = NCUtility()

        images.file = UIImage(named: "file")!

        images.shared = UIImage(named: "share")!.image(color: .systemGray, size: 24)//50)
        images.canShare = UIImage(named: "share")!.image(color: .systemGray, size: 24)//50)
        images.shareByLink = UIImage(named: "sharebylink")!.image(color: .systemGray, size: 24)//50)
        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 24)//50)
        
        images.favorite = utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
        images.comment = UIImage(named: "comment")!.image(color: .systemGray, size: 24)//50)
        images.livePhoto = utility.loadImage(named: "livephoto", colors: [.label])
        images.offlineFlag = UIImage(named: "offlineFlag")!
        images.local = UIImage(named: "local")!

        images.checkedYes = UIImage(named: "checkedYes")!
        images.checkedNo = utility.loadImage(named: "circle")

        images.buttonMore = UIImage(named: "more")!.image(color: .systemGray, size: 24)//50)
        images.buttonStop = UIImage(named: "stop")!.image(color: .systemGray, size: 24)//50)
        images.buttonMoreLock = UIImage(named: "moreLock")!.image(color: .systemGray, size: 24)//50)
        images.buttonRestore = UIImage(named: "restore")!.image(color: .systemGray, size: 24)//50)
        images.buttonTrash = UIImage(named: "trash")!.image(color: .systemGray, size: 24)//50)

        createImagesBrandCache()
    }

    func createImagesBrandCache() {

        let brandElement = NCBrandColor.shared.brandElement
        guard brandElement != self.brandElementColor else { return }
        self.brandElementColor = brandElement
        
        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
        images.folderEncrypted = UIImage(named: "folderEncrypted")!
        images.folderSharedWithMe = UIImage(named: "folder-share")!
        images.folderPublic = UIImage(named: "folder-share")!
        images.folderGroup = UIImage(named: "folder_group")!
        images.folderExternal = UIImage(named: "folder_external")!
        images.folderAutomaticUpload = UIImage(named: "folder-photo")!
        images.folder = UIImage(named: "folder_nmcloud")!
        
        images.iconContacts = UIImage(named: "icon-contacts")!.image(color: brandElement, size: folderWidth)
        images.iconTalk = UIImage(named: "icon-talk")!.image(color: brandElement, size: folderWidth)
        images.iconCalendar = UIImage(named: "icon-calendar")!.image(color: brandElement, size: folderWidth)
        images.iconDeck = UIImage(named: "icon-deck")!.image(color: brandElement, size: folderWidth)
        images.iconMail = UIImage(named: "icon-mail")!.image(color: brandElement, size: folderWidth)
        images.iconConfirm = UIImage(named: "icon-confirm")!.image(color: brandElement, size: folderWidth)
        images.iconPages = UIImage(named: "icon-pages")!.image(color: brandElement, size: folderWidth)
//        images.iconFile = UIImage(named: "icon-file")!.image(color: brandElement, size: folderWidth)
        
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming)
    }
    
    // MARK: -
    
    func getImageFile() -> UIImage {
        return NCImageCache.images.file
    }
    
    func getImageShared() -> UIImage {
        return NCImageCache.images.shared
    }
    
    func getImageShared(account: String) -> UIImage {
        return NCImageCache.images.shared
    }

    func getImageCanShare() -> UIImage {
    func createImagesCache() {
        let utility = NCUtility()

        images.file = UIImage(named: "file")!

        images.shared = UIImage(named: "share")!.image(color: .systemGray, size: 24)//50)
        images.canShare = UIImage(named: "share")!.image(color: .systemGray, size: 24)//50)
        images.shareByLink = UIImage(named: "sharebylink")!.image(color: .systemGray, size: 24)//50)
        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 24)//50)
        
        images.favorite = utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
        images.comment = UIImage(named: "comment")!.image(color: .systemGray, size: 24)//50)
        images.livePhoto = utility.loadImage(named: "livephoto", colors: [.label])
        images.offlineFlag = UIImage(named: "offlineFlag")!
        images.local = UIImage(named: "local")!

        images.checkedYes = UIImage(named: "checkedYes")!
        images.checkedNo = utility.loadImage(named: "circle")

        images.buttonMore = UIImage(named: "more")!.image(color: .systemGray, size: 24)//50)
        images.buttonStop = UIImage(named: "stop")!.image(color: .systemGray, size: 24)//50)
        images.buttonMoreLock = UIImage(named: "moreLock")!.image(color: .systemGray, size: 24)//50)
        images.buttonRestore = UIImage(named: "restore")!.image(color: .systemGray, size: 24)//50)
        images.buttonTrash = UIImage(named: "trash")!.image(color: .systemGray, size: 24)//50)

        createImagesBrandCache()
    }

    func createImagesBrandCache() {

        let brandElement = NCBrandColor.shared.brandElement
        guard brandElement != self.brandElementColor else { return }
        self.brandElementColor = brandElement
        
        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
        images.folderEncrypted = UIImage(named: "folderEncrypted")!
        images.folderSharedWithMe = UIImage(named: "folder-share")!
        images.folderPublic = UIImage(named: "folder-share")!
        images.folderGroup = UIImage(named: "folder_group")!
        images.folderExternal = UIImage(named: "folder_external")!
        images.folderAutomaticUpload = UIImage(named: "folder-photo")!
        images.folder = UIImage(named: "folder_nmcloud")!
        
        images.iconContacts = UIImage(named: "icon-contacts")!.image(color: brandElement, size: folderWidth)
        images.iconTalk = UIImage(named: "icon-talk")!.image(color: brandElement, size: folderWidth)
        images.iconCalendar = UIImage(named: "icon-calendar")!.image(color: brandElement, size: folderWidth)
        images.iconDeck = UIImage(named: "icon-deck")!.image(color: brandElement, size: folderWidth)
        images.iconMail = UIImage(named: "icon-mail")!.image(color: brandElement, size: folderWidth)
        images.iconConfirm = UIImage(named: "icon-confirm")!.image(color: brandElement, size: folderWidth)
        images.iconPages = UIImage(named: "icon-pages")!.image(color: brandElement, size: folderWidth)
//        images.iconFile = UIImage(named: "icon-file")!.image(color: brandElement, size: folderWidth)
        
        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming)
    }
    
    // MARK: -
    
    func getImageFile() -> UIImage {
        return NCImageCache.images.file
    }
    
    func getImageShared() -> UIImage {
        return NCImageCache.images.shared
    }
    
    func getImageShared(account: String) -> UIImage {
        return NCImageCache.images.shared
    }

    func getImageCanShare() -> UIImage {
        return NCImageCache.images.canShare
    }

    func getImageShareByLink() -> UIImage {
        return NCImageCache.images.shareByLink
    }
    
    func getImageFavorite() -> UIImage {
        return NCImageCache.images.favorite
    }

    func getImageOfflineFlag() -> UIImage {
        return NCImageCache.images.offlineFlag
    }

    func getImageLocal() -> UIImage {
        return NCImageCache.images.local
    }

    func getImageCheckedYes() -> UIImage {
        return NCImageCache.images.checkedYes
    }

    func getImageCheckedNo() -> UIImage {
        return NCImageCache.images.checkedNo
    }

    func getImageButtonMore() -> UIImage {
        return UIImage(named: "more")!.imageColor(.systemGray)
        return NCImageCache.images.buttonMore
    }

    func getImageButtonStop() -> UIImage {
        return NCImageCache.images.buttonStop
    }

    func getImageButtonMoreLock() -> UIImage {
        return NCImageCache.images.buttonMoreLock
    }
    
    func getImageLivePhoto() -> UIImage {
        return NCImageCache.images.livePhoto
    }
    
    func getFolder(account: String) -> UIImage {
        return NCImageCache.images.folder
    }

    func getAddFolder() -> UIImage {
        return UIImage(named: "addFolder")!
    }

    func getAddFolderInfo() -> UIImage {
        return UIImage(named: "addFolderInfo")!.imageColor(NCBrandColor.shared.iconImageColor)
    }
    
    func getImageLivePhoto() -> UIImage {
        return NCImageCache.images.livePhoto
    }
    
    func getFolder(account: String) -> UIImage {
        return NCImageCache.images.folder
    }

    func getAddFolder() -> UIImage {
        return UIImage(named: "addFolder")!
    }

    func getEncryptedFolder() -> UIImage {
        return UIImage(named: "encryptedfolder")!.imageColor(NCBrandColor.shared.iconImageColor)
    }

    func getFolderSharedWithMe(account: String) -> UIImage {
        return UIImage(named: "folder_shared_with_me")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getAddFolderInfo() -> UIImage {
        return UIImage(named: "addFolderInfo")!.imageColor(NCBrandColor.shared.iconImageColor)
    }

    func getEncryptedFolder() -> UIImage {
        return NCImageCache.images.folderEncrypted
    }
    
    func getFolderEncrypted() -> UIImage {
        return NCImageCache.images.folderEncrypted
    }
    
    func getFolderSharedWithMe() -> UIImage {
        return NCImageCache.images.folderSharedWithMe
    }

    func getFolderAutomaticUpload(account: String) -> UIImage {
        return UIImage(named: "folderAutomaticUpload")!.image(color: NCBrandColor.shared.getElement(account: account))
        images.folderEncrypted = UIImage(named: "folderEncrypted")!
        images.folderSharedWithMe = UIImage(named: "folder_shared_with_me")!
        images.folderPublic = UIImage(named: "folder_public")!
        images.folderGroup = UIImage(named: "folder_group")!
        images.folderExternal = UIImage(named: "folder_external")!
        images.folderAutomaticUpload = UIImage(named: "folderAutomaticUpload")!
        images.folder = UIImage(named: "folder")!
        images.iconContacts = utility.loadImage(named: "person.crop.rectangle.stack", colors: [NCBrandColor.shared.iconImageColor])
        images.iconTalk = UIImage(named: "talk-template")!.image(color: brandElement)
        images.iconCalendar = utility.loadImage(named: "calendar", colors: [NCBrandColor.shared.iconImageColor])
        images.iconDeck = utility.loadImage(named: "square.stack.fill", colors: [NCBrandColor.shared.iconImageColor])
        images.iconMail = utility.loadImage(named: "mail", colors: [NCBrandColor.shared.iconImageColor])
        images.iconConfirm = utility.loadImage(named: "arrow.right", colors: [NCBrandColor.shared.iconImageColor])
        images.iconPages = utility.loadImage(named: "doc.richtext", colors: [NCBrandColor.shared.iconImageColor])
        images.iconFile = utility.loadImage(named: "doc", colors: [NCBrandColor.shared.iconImageColor])
    func getAddFolderInfo() -> UIImage {
        return UIImage(named: "addFolderInfo")!.imageColor(NCBrandColor.shared.iconImageColor)
    }

    func getEncryptedFolder() -> UIImage {
        return NCImageCache.images.folderEncrypted
    }
    
    func getFolderEncrypted() -> UIImage {
        return NCImageCache.images.folderEncrypted
    }
    
    func getFolderSharedWithMe() -> UIImage {
        return NCImageCache.images.folderSharedWithMe
    }
    
    func getFolderPublic() -> UIImage {
        return NCImageCache.images.folderPublic
    }
    
    func getFolderGroup() -> UIImage {
        return NCImageCache.images.folderGroup
    }
    
    func getFolderExternal() -> UIImage {
        return NCImageCache.images.folderExternal
    }
    
    func getFolderAutomaticUpload() -> UIImage {
        return NCImageCache.images.folderAutomaticUpload
    }
    
    func getFolder() -> UIImage {
        return NCImageCache.images.folder
    }
}
