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
    public var countLimit: Int = 2000
    lazy var cache: LRUCache<String, UIImage> = {
        return LRUCache<String, UIImage>(countLimit: countLimit)
    }()

    public var isLoadingCache: Bool = false
    public var controller: UITabBarController?

    let showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND (classFile == '\(NKTypeClassFile.image.rawValue)' OR classFile == '\(NKTypeClassFile.video.rawValue)') AND NOT (session CONTAINS[c] 'upload') AND NOT (livePhotoFile != '' AND classFile == '\(NKTypeClassFile.video.rawValue)')"

    init() {

        cache.countLimit = maximumCachedImages

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.removeAll()
        }

        observerToken = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAll()
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
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

    func getImageOfflineFlag(colors: [UIColor] = [.systemGreen]) -> UIImage {
        return utility.loadImage(named: "arrow.down.circle.fill", colors: colors, size: 24)
    }

    func getImageLocal(colors: [UIColor] = [.systemGreen]) -> UIImage {
        return utility.loadImage(named: "checkmark.circle.fill", colors: colors, size: 24)
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
}
