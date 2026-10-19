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

    private init() {
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
    }

    private func cacheKey(ocId: String, etag: String, ext: String) -> NSString {
        imageCacheKey(ocId: ocId, etag: etag, ext: ext) as NSString
    }

    func addImageCache(ocId: String, etag: String, image: UIImage, ext: String) {
        cache.setObject(image, forKey: cacheKey(ocId: ocId, etag: etag, ext: ext))
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
        viewWidth: CGFloat,
        session: NCSession.Session,
        force: Bool = false
    ) {
        Task {
            await mediaWindowCache.update(
                imageCacheWindowItems: imageCacheWindowItems,
                centerIndex: centerIndex,
                numberOfColumns: numberOfColumns,
                viewWidth: viewWidth,
                session: session,
                force: force
            )
        }
    }

    // MARK: -

    func getImageFile(colors: [UIColor] = [NCBrandColor.shared.iconImageColor2]) -> UIImage {
        return utility.loadImage(named: "file", colors: colors, size: 24)
    }

    func getImageShared(colors: [UIColor] = NCBrandColor.shared.iconImageMultiColors) -> UIImage {
        return utility.loadImage(named: "share", colors: colors, size: 24)
    }

    func getImageCanShare(colors: [UIColor] = NCBrandColor.shared.iconImageMultiColors) -> UIImage {
        return utility.loadImage(named: "share", colors: colors, size: 24)
    }

    func getImageShareByLink(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
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
        return utility.loadImage(named: "stop.circle", colors: colors)
    }

    func getImageButtonMoreLock(colors: [UIColor] = [NCBrandColor.shared.iconImageColor]) -> UIImage {
        return utility.loadImage(named: "lock.fill", colors: colors)
    }

    func getFolder() -> UIImage {
        return UIImage(named: "folder")!
    }

    func getFolderEncrypted() -> UIImage {
        return UIImage(named: "folderEncrypted")!
    }

    func getFolderSharedWithMe() -> UIImage {
        return UIImage(named: "folder_shared_with_me")!
    }

    func getFolderPublic() -> UIImage {
        return UIImage(named: "folder_public")!
    }

    func getFolderGroup() -> UIImage {
        return UIImage(named: "folder_group")!
    }

    func getFolderExternal() -> UIImage {
        return UIImage(named: "folder_external")!
    }

    func getFolderAutomaticUpload() -> UIImage {
        return UIImage(named: "folderAutomaticUpload")!
    }

//    func createImagesCache() {
//        let utility = NCUtility()
//
//        images.file = UIImage(named: "file")!
//
//        images.shared = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.canShare = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.shareByLink = UIImage(named: "sharebylink")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
//        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 24)//50)
//
////        images.favorite = utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
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
//
//        createImagesBrandCache()
//    }
//
//    func createImagesBrandCache() {
//
//        let brandElement = NCBrandColor.shared.brandElement
//        guard brandElement != self.brandElementColor else { return }
//        self.brandElementColor = brandElement
//
//        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
//        images.folderEncrypted = UIImage(named: "folderEncrypted")!
//        images.folderSharedWithMe = UIImage(named: "folder-share")!
//        images.folderPublic = UIImage(named: "folder-share")!
//        images.folderGroup = UIImage(named: "folder_group")!
//        images.folderExternal = UIImage(named: "folder_external")!
//        images.folderAutomaticUpload = UIImage(named: "folder-photo")!
//        images.folder = UIImage(named: "folder_nmcloud")!
//
//        images.iconContacts = UIImage(named: "icon-contacts")!.image(color: brandElement, size: folderWidth)
//        images.iconTalk = UIImage(named: "icon-talk")!.image(color: brandElement, size: folderWidth)
//        images.iconCalendar = UIImage(named: "icon-calendar")!.image(color: brandElement, size: folderWidth)
//        images.iconDeck = UIImage(named: "icon-deck")!.image(color: brandElement, size: folderWidth)
//        images.iconMail = UIImage(named: "icon-mail")!.image(color: brandElement, size: folderWidth)
//        images.iconConfirm = UIImage(named: "icon-confirm")!.image(color: brandElement, size: folderWidth)
//        images.iconPages = UIImage(named: "icon-pages")!.image(color: brandElement, size: folderWidth)
////        images.iconFile = UIImage(named: "icon-file")!.image(color: brandElement, size: folderWidth)
//
//        NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming)
//    }
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
        viewWidth: CGFloat,
        session: NCSession.Session,
        force: Bool
    ) {
        guard imageCacheWindowItems.indices.contains(centerIndex) else {
            return
        }

        let ext = NCGlobal.shared.getSizeExtension(column: numberOfColumns, viewWidth: viewWidth)

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
