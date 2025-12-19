// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2021 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

final class NCImageCache: @unchecked Sendable {
    static let shared = NCImageCache()

    private let utility = NCUtility()
    private let cache = NSCache<NSString, UIImage>()
    private let maximumCachedImages = 510
    private let utilityFileSystem = NCUtilityFileSystem()
    private let global = NCGlobal.shared
    private let database = NCManageDatabase.shared

    private lazy var mediaWindowCache = MediaWindowCache(
        maximumCachedImages: maximumCachedImages,
        imageCache: self
    )

    struct ImageCacheWindowItem: Sendable {
        let ocId: String
        let etag: String
    }
    private func imageCacheKey(ocId: String, etag: String, ext: String) -> String {
        "\(ocId)-\(etag)-\(ext)"
    }
    private var observerToken: NSObjectProtocol?

    public var countLimit: Int = 2000
    lazy var cache: LRUCache<String, UIImage> = {
        return LRUCache<String, UIImage>(countLimit: countLimit)
    }()

    public var isLoadingCache: Bool = false
    public var controller: UITabBarController?

    let showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND (classFile == '\(NKTypeClassFile.image.rawValue)' OR classFile == '\(NKTypeClassFile.video.rawValue)') AND NOT (session CONTAINS[c] 'upload') AND NOT (livePhotoFile != '' AND classFile == '\(NKTypeClassFile.video.rawValue)')"

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

    init() {
        observerToken = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAll()
        }
        countLimit = calculateMaxImages(percentage: 5.0, imageSizeKB: 30.0) // 5% of cache = 20
        NextcloudKit.shared.nkCommonInstance.writeLog("Counter cache image: \(countLimit)")

        NotificationCenter.default.addObserver(forName: LRUCacheMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAllValues()

            self.countLimit = self.countLimit - 500
            if self.countLimit <= 0 { self.countLimit = 100 }
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
        }
#if DEBUG
        NCContentPresenter().messageNotification("Cache image memory warning \(self.countLimit)", error: .success, delay: NCGlobal.shared.dismissAfterSecond, type: NCContentPresenter.messageType.error, priority: .max)
#endif
        cache.countLimit = maximumCachedImages

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.removeAll()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.removeAll()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.cache.removeAllValues()
//            self.cache.removeAll()
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
#if !EXTENSION
            Task {
                guard let controller = self.controller as? NCMainTabBarController,
                    !self.isLoadingCache else {
                    return
                }

                DispatchQueue.global().async {
                    self.isLoadingCache = true
                }
                var cost: Int = 0
                let session = await NCSession.shared.getSession(account: controller.account)

                if let tblAccount = await self.database.getTableAccountAsync(predicate: NSPredicate(format: "account == %@", controller.account)),
                   NCImageCache.shared.cache.count == 0 {

                    // MEDIA
                    let predicate = self.getMediaPredicate(session: session, mediaPath: tblAccount.mediaPath, showOnlyImages: false, showOnlyVideos: false)
                    guard let metadatas = await self.database.getMetadatasAsync(predicate: predicate, sortedByKeyPath: "date", limit: self.countLimit) else {
                        return
                    }

                    self.isLoadingCache = true
                    self.database.filterAndNormalizeLivePhotos(from: metadatas) { metadatas in
                        autoreleasepool {
                            self.cache.removeAllValues()
                            for metadata in metadatas {
                                guard !isAppInBackground else {
                                    self.cache.removeAllValues()
                                    break
                                }
                                if let image = self.utility.getImage(ocId: metadata.ocId,
                                                                     etag: metadata.etag,
                                                                     ext: self.global.previewExt256,
                                                                     userId: metadata.userId,
                                                                     urlBase: metadata.urlBase) {
                                    self.addImageCache(ocId: metadata.ocId, etag: metadata.etag, image: image, ext: self.global.previewExt256, cost: cost)
                                    cost += 1
                                }
                            }
                            self.isLoadingCache = false
                        }
                    }
                }
            }
#endif
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: LRUCacheMemoryWarningNotification, object: nil)
    }

    private func cacheKey(ocId: String, etag: String, ext: String) -> NSString {
        imageCacheKey(ocId: ocId, etag: etag, ext: ext) as NSString
    }

    func addImageCache(ocId: String, etag: String, image: UIImage, ext: String) {
        cache.setObject(image, forKey: cacheKey(ocId: ocId, etag: etag, ext: ext))
    }

    @objc func createMediaCache(account: String, withCacheSize: Bool) {
        if createMediaCacheInProgress {
            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] ThumbnailLRUCache image process already in progress")
//            NextcloudKit.shared.nkCommonInstance.writeLog("[ERROR] ThumbnailLRUCache image process already in progress")
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

    func addImageCache(image: UIImage, key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func getImageCache(ocId: String, etag: String, ext: String) -> UIImage? {
        cache.object(forKey: cacheKey(ocId: ocId, etag: etag, ext: ext))
    }

    func getImageCache(key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
        Task {
            await mediaWindowCache.removeAll()
        }
    }

    // MARK: - MEDIA -

    func getMediaPredicate(session: NCSession.Session,
                           mediaPath: String,
                           showOnlyImages: Bool,
                           showOnlyVideos: Bool) -> NSPredicate {
        let startServerUrl = self.utilityFileSystem.getHomeServer(session: session) + mediaPath

        let showBothPredicate = """
        account == %@ AND
        serverUrl BEGINSWITH %@ AND
        mediaSearch == true AND
        hasPreview == true AND
        (
        classFile == '\(NKTypeClassFile.image.rawValue)' OR classFile == '\(NKTypeClassFile.video.rawValue)'
        ) AND
        NOT (status IN %@)
        """

        let showOnlyPredicateImage = """
        account == %@ AND
        serverUrl BEGINSWITH %@ AND
        mediaSearch == true AND
        hasPreview == true AND
        (
        classFile == '\(NKTypeClassFile.image.rawValue)' OR (classFile == '\(NKTypeClassFile.video.rawValue)' AND livePhotoFile != '')
        ) AND
        NOT (status IN %@)
        """

        let showOnlyPredicateVideo = """
        account == %@ AND
        serverUrl BEGINSWITH %@ AND
        mediaSearch == true AND
        hasPreview == true AND
        classFile == 'video' AND
        NOT (status IN %@)
        """

        if showOnlyImages {
            return NSPredicate(format: showOnlyPredicateImage,
                               session.account,
                               startServerUrl,
                               global.metadataStatusHideInView)
        } else if showOnlyVideos {
            return NSPredicate(format: showOnlyPredicateVideo,
                               session.account,
                               startServerUrl,
                               global.metadataStatusHideInView)
        } else {
            return NSPredicate(format: showBothPredicate,
                               session.account,
                               startServerUrl,
                               global.metadataStatusHideInView)
        }
    }

    // MARK: -

    func updateImageCacheWindow(
        imageCacheWindowItems: [ImageCacheWindowItem],
        centerIndex: Int,
        numberOfColumns: Int,
        session: NCSession.Session,
        force: Bool = false
    ) {
        Task {
            await mediaWindowCache.update(
                imageCacheWindowItems: imageCacheWindowItems,
                centerIndex: centerIndex,
                numberOfColumns: numberOfColumns,
                session: session,
                force: force
            )
        }
    }

    // MARK: -

    func getImageFile(colors: [UIColor] = [NCBrandColor.shared.iconImageColor2]) -> UIImage {
        utility.loadImage(named: "doc", colors: colors)
    }

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
    
    func createImagesCache() {
        let utility = NCUtility()

//        images.file = UIImage(named: "file")!
//
//        images.shared = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.canShare = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.shareByLink = UIImage(named: "sharebylink")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 24)//50)
//
////        images.favorite = utility.loadImage(named: "star", colors: [NCBrandColor.shared.yellowFavorite]) //utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
//        images.comment = UIImage(named: "comment")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.livePhoto = utility.loadImage(named: "livephoto", colors: [.label])
//        images.offlineFlag = utility.loadImage(named: "arrow.down.circle.fill", colors: [.systemGreen], size: 24)
//        images.local = utility.loadImage(named: "checkmark.circle.fill", colors: [.systemGreen], size: 24)
//
//        images.checkedYes = UIImage(named: "checkedYes")!
//        images.checkedNo = utility.loadImage(named: "circle", colors: [NCBrandColor.shared.iconImageColor], size: 24)
//
//        images.buttonMore = UIImage(named: "more")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.buttonStop = utility.loadImage(named: "stop.circle", colors: [NCBrandColor.shared.iconImageColor], size: 24)
//        images.buttonMoreLock = utility.loadImage(named: "lock.fill", colors: [NCBrandColor.shared.iconImageColor], size: 24)
//        images.buttonRestore = UIImage(named: "restore")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.buttonTrash = UIImage(named: "trashIcon")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)

        createImagesBrandCache()
    }

    func getImageCanShare() -> UIImage {
        return UIImage(named: "share")!.imageColor(.systemGray)
    }

    func getImageShareByLink(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        utility.loadImage(named: "link", colors: colors)
    }

    func getImageFavorite(colors: [UIColor] = [NCBrandColor.shared.yellowFavorite]) -> UIImage {
        utility.loadImage(named: "star.fill", colors: colors)
    }

    func getImageOfflineFlag(colors: [UIColor] = [.systemGreen]) -> UIImage {
        utility.loadImage(named: "arrow.down.circle.fill", colors: colors)
    }

    func getImageLocal(colors: [UIColor] = [.systemGreen]) -> UIImage {
        utility.loadImage(named: "checkmark.circle.fill", colors: colors)
    }

    func getImageCheckedYes(color: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(paletteColors: [.white, color])
        return UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
    }

    func getImageCheckedNo(color: UIColor) -> UIImage? {
        let weightConfig = UIImage.SymbolConfiguration(weight: .light)
        let colorConfig = UIImage.SymbolConfiguration(paletteColors: [color])
        let config = weightConfig.applying(colorConfig)
        return UIImage(systemName: "circle", withConfiguration: config)
    }

    func getImageButtonMore() -> UIImage {
        return UIImage(named: "more")!.imageColor(.systemGray)
    }

    func getImageButtonStop(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        utility.loadImage(named: "stop.circle", colors: colors)
    }

    func getImageButtonMoreLock(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        utility.loadImage(named: "lock.fill", colors: colors)
    }

    func getFolder(account: String) -> UIImage {
        UIImage(named: "folder")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getAddFolder() -> UIImage {
        return UIImage(named: "addFolder")!
    }

    func getAddFolderInfo() -> UIImage {
        return UIImage(named: "addFolderInfo")!.imageColor(NCBrandColor.shared.iconImageColor)
    }

    func getFolderEncrypted(account: String) -> UIImage {
        UIImage(named: "folderEncrypted")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getEncryptedFolder() -> UIImage {
        return UIImage(named: "encryptedfolder")!.imageColor(NCBrandColor.shared.iconImageColor)
    }

    func getFolderSharedWithMe(account: String) -> UIImage {
        UIImage(named: "folder_shared_with_me")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getFolderPublic(account: String) -> UIImage {
        UIImage(named: "folder_public")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getFolderGroup(account: String) -> UIImage {
        UIImage(named: "folder_group")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getFolderExternal(account: String) -> UIImage {
        UIImage(named: "folder_external")!.image(color: NCBrandColor.shared.getElement(account: account))
    }

    func getFolderAutomaticUpload(account: String) -> UIImage {
        return UIImage(named: "folderAutomaticUpload")!.image(color: NCBrandColor.shared.getElement(account: account))
    }
}

private actor MediaWindowCache {
    private let maximumCachedImages: Int
    private unowned let imageCache: NCImageCache

    private var lastCacheCenterIndex: Int?
    private var lastCacheExtension: String?
    private var cacheWindowTask: Task<Void, Never>?
    private var missingImageCacheKeys: Set<String> = []

    private var cacheWindowRadius: Int {
        maximumCachedImages / 2
    }

    private var cacheWindowUpdateThreshold: Int {
        maximumCachedImages / 6
    }

    init(
        maximumCachedImages: Int,
        imageCache: NCImageCache
    ) {
        self.maximumCachedImages = maximumCachedImages
        self.imageCache = imageCache
    }

    func removeAll() {
        cacheWindowTask?.cancel()
        cacheWindowTask = nil
        lastCacheCenterIndex = nil
        lastCacheExtension = nil
        missingImageCacheKeys.removeAll()
    }

    func update(
        imageCacheWindowItems: [NCImageCache.ImageCacheWindowItem],
        centerIndex: Int,
        numberOfColumns: Int,
        session: NCSession.Session,
        force: Bool
    ) {
        guard imageCacheWindowItems.indices.contains(centerIndex) else {
            return
        }

        let ext = NCGlobal.shared.getSizeExtension(column: numberOfColumns)

        if !force,
           lastCacheExtension == ext,
           let lastCacheCenterIndex,
           abs(centerIndex - lastCacheCenterIndex) < cacheWindowUpdateThreshold {
            return
        }

        lastCacheCenterIndex = centerIndex
        lastCacheExtension = ext

        cacheWindowTask?.cancel()

        cacheWindowTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.load(imageCacheWindowItems: imageCacheWindowItems, centerIndex: centerIndex, ext: ext, session: session)
        }
    }

    private func load(imageCacheWindowItems: [NCImageCache.ImageCacheWindowItem], centerIndex: Int, ext: String, session: NCSession.Session) async {
        let itemCount = imageCacheWindowItems.count
        guard imageCacheWindowItems.indices.contains(centerIndex) else {
            return
        }
        let lowerBound = max(0, centerIndex - cacheWindowRadius)
        let upperBound = min(
            itemCount,
            centerIndex + cacheWindowRadius + 1
        )
        let items = Array(imageCacheWindowItems[lowerBound..<upperBound])
        let userId = session.userId
        let urlBase = session.urlBase

        var cacheHits = 0
        var diskReads = 0
        var knownMissingImages = 0
        var newMissingImages = 0
        var loadedImages = 0

        print(
            "[MEDIA CACHE] START center: \(centerIndex) " +
            "range: \(lowerBound)..<\(upperBound) " +
            "items: \(items.count) ext: \(ext)"
        )

        for item in items {
            guard !Task.isCancelled else {
                print(
                    "[MEDIA CACHE] CANCELLED center: \(centerIndex) " +
                    "hits: \(cacheHits) diskReads: \(diskReads) " +
                    "knownMissing: \(knownMissingImages) " +
                    "newMissing: \(newMissingImages) loaded: \(loadedImages)"
                )
                return
            }

            let key = imageCacheKey(ocId: item.ocId, etag: item.etag, ext: ext)

            if missingImageCacheKeys.contains(key) {
                knownMissingImages += 1
                continue
            }

            if imageCache.getImageCache(ocId: item.ocId, etag: item.etag, ext: ext) != nil {
                cacheHits += 1
                continue
            }

            diskReads += 1

            let image = await Task.detached(priority: .utility) {
                autoreleasepool {
                    NCUtility().getImage(ocId: item.ocId, etag: item.etag, ext: ext, userId: userId, urlBase: urlBase)
                }
            }.value

            guard !Task.isCancelled else {
                print(
                    "[MEDIA CACHE] CANCELLED center: \(centerIndex) " +
                    "hits: \(cacheHits) diskReads: \(diskReads) " +
                    "knownMissing: \(knownMissingImages) " +
                    "newMissing: \(newMissingImages) loaded: \(loadedImages)"
                )
                return
            }

            guard let image else {
                missingImageCacheKeys.insert(key)
                newMissingImages += 1
                continue
            }

            imageCache.addImageCache(ocId: item.ocId, etag: item.etag, image: image, ext: ext)

            loadedImages += 1
        }

        print(
            "[MEDIA CACHE] END center: \(centerIndex) " +
            "hits: \(cacheHits) diskReads: \(diskReads) " +
            "knownMissing: \(knownMissingImages) " +
            "newMissing: \(newMissingImages) loaded: \(loadedImages)"
        )
    }

    private func imageCacheKey(ocId: String, etag: String, ext: String) -> String {
        "\(ocId)-\(etag)-\(ext)"
    }

    func createImagesBrandCache() {

        let brandElement = NCBrandColor.shared.brandElement
        guard brandElement != self.brandElementColor else { return }
        self.brandElementColor = brandElement
        
        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
        let utility = NCUtility()

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
    
    func getImageFile(colors: [UIColor] = [NCBrandColor.shared.iconImageColor2]) -> UIImage {
        return UIImage(named: "file")!.image(color: colors.first!, size: 24)
    }

    func getImageShared(colors: [UIColor] = [NCBrandColor.shared.iconSystemGrayColor]) -> UIImage {
        return utility.loadImage(named: "share", colors: colors, size: 24)
    }

    func getImageCanShare(colors: [UIColor] = [NCBrandColor.shared.iconSystemGrayColor]) -> UIImage {
        return utility.loadImage(named: "share", colors: colors, size: 24)
    }

    func getImageShareByLink(colors: [UIColor] = [NCBrandColor.shared.iconSystemGrayColor]) -> UIImage {
        return utility.loadImage(named: "share", colors: colors, size: 24)
    }

    func getImageSharedWithMe(colors: [UIColor] = [NCBrandColor.shared.iconSystemGrayColor]) -> UIImage {
        return utility.loadImage(named: "cloudUpload", colors: [NCBrandColor.shared.nmcIconSharedWithMe], size: 24)
    }
    
    func getImageFavorite(colors: [UIColor] = [NCBrandColor.shared.yellowFavorite]) -> UIImage {
        return utility.loadImage(named: "star.fill", colors: colors, size: 24)
    }
            
    func getImageShared() -> UIImage {
        return NCImageCache.images.shared
    }

    func getImageOfflineFlag(colors: [UIColor] = [.systemGreen]) -> UIImage {
        return utility.loadImage(named: "arrow.down.circle.fill", colors: colors, size: 24)
    }

    func getImageLocal(colors: [UIColor] = [.systemGreen]) -> UIImage {
        return utility.loadImage(named: "checkmark.circle.fill", colors: colors, size: 24)
    }

    func getImageCheckedYes(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return UIImage(named: "checkedYes")!
    }

    func getImageCheckedNo(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return utility.loadImage(named: "circle", colors: colors, size: 24)
    }

    func getImageButtonMore(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return UIImage(named: "more")!.image(color: .systemGray, size: 24)
    }

    func getImageButtonStop(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return utility.loadImage(named: "stop.circle", colors: colors, size: 24)
    }

    func getImageButtonMoreLock(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return utility.loadImage(named: "lock.fill", colors: colors, size: 24)
    }

    func getFolder(account: String) -> UIImage {
        return UIImage(named: "folder")!
    }

    func getFolder(account: String) -> UIImage {
        return UIImage(named: "folder")!
    }

    func getFolderEncrypted(account: String) -> UIImage {
        return UIImage(named: "folderEncrypted")!
    }

    func getFolderEncrypted(account: String) -> UIImage {
        return UIImage(named: "folderEncrypted")!
    }

    func getFolderSharedWithMe(account: String) -> UIImage {
        return UIImage(named: "folder_shared_with_me")!
    }

    func getFolderPublic(account: String) -> UIImage {
        return UIImage(named: "folder_public")!
    }

    func getFolderGroup(account: String) -> UIImage {
        return UIImage(named: "folder_group")!
    }

    func getFolderExternal(account: String) -> UIImage {
        return UIImage(named: "folder_external")!
    }

    func getFolderAutomaticUpload(account: String) -> UIImage {
        return UIImage(named: "folderAutomaticUpload")!
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
    
    func getFolderSharedWithMe(account: String) -> UIImage {
        return UIImage(named: "folder_shared_with_me")!
    }

    func getFolderPublic(account: String) -> UIImage {
        return UIImage(named: "folder_public")!
    }

    func getFolderGroup(account: String) -> UIImage {
        return UIImage(named: "folder_group")!
    }

    func getFolderExternal(account: String) -> UIImage {
        return UIImage(named: "folder_external")!
    }

    func getFolderAutomaticUpload(account: String) -> UIImage {
        return UIImage(named: "folderAutomaticUpload")!
    }
}
