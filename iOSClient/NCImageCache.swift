// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2021 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import LRUCache
import NextcloudKit
import RealmSwift

final class NCImageCache: @unchecked Sendable {
    static let shared = NCImageCache()

    private let utility = NCUtility()
    private let utilityFileSystem = NCUtilityFileSystem()
    private let global = NCGlobal.shared
    private let database = NCManageDatabase.shared

    private let allowExtensions = [NCGlobal.shared.previewExt256]
    private var brandElementColor: UIColor?

    public var countLimit: Int = 2000
    lazy var cache: LRUCache<String, UIImage> = {
        return LRUCache<String, UIImage>(countLimit: countLimit)
    }()

    public var isLoadingCache: Bool = false
    public var controller: UITabBarController?

    let showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND (classFile == '\(NKTypeClassFile.image.rawValue)' OR classFile == '\(NKTypeClassFile.video.rawValue)') AND NOT (session CONTAINS[c] 'upload') AND NOT (livePhotoFile != '' AND classFile == '\(NKTypeClassFile.video.rawValue)')"

    init() {
        NotificationCenter.default.addObserver(forName: LRUCacheMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAllValues()
//            self.countLimit = self.countLimit - 500
//            if self.countLimit <= 0 { self.countLimit = 100 }
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
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
                    guard let metadatas = await self.database.getMetadatasAsync(predicate: predicate, sortedByKeyPath: "datePhotosOriginal", limit: self.countLimit) else {
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
        cache.setValue(image, forKey: key)
    }

    func getImageCache(ocId: String, etag: String, ext: String) -> UIImage? {
        return cache.value(forKey: ocId + etag + ext)
    }

    func getImageCache(key: String) -> UIImage? {
        return cache.value(forKey: key)
    }

    func removeImageCache(ocIdPlusEtag: String) {
        for i in 0..<allowExtensions.count {
            cache.removeValue(forKey: ocIdPlusEtag + allowExtensions[i])
        }
    }

    func removeAll() {
//        cache.removeAll()
        self.cache.removeAllValues()
    }

    // MARK: - MEDIA -

    func getMediaPredicate(session: NCSession.Session,
                           mediaPath: String,
                           showOnlyImages: Bool,
                           showOnlyVideos: Bool) -> NSPredicate {
        var predicate = NSPredicate()
        let startServerUrl = self.utilityFileSystem.getHomeServer(session: session) + mediaPath
        let showBothPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND mediaSearch == true AND hasPreview == true AND (classFile == '\(NKTypeClassFile.image.rawValue)' OR classFile == '\(NKTypeClassFile.video.rawValue)') AND NOT (status IN %@)"
        let showOnlyPredicateMediaString = "account == %@ AND serverUrl BEGINSWITH %@ AND mediaSearch == true AND hasPreview == true AND classFile == %@ AND NOT (status IN %@)"

        if showOnlyImages {
            predicate = NSPredicate(format: showOnlyPredicateMediaString, session.account, startServerUrl, NKTypeClassFile.image.rawValue, global.metadataStatusHideInView)
        } else if showOnlyVideos {
            predicate = NSPredicate(format: showOnlyPredicateMediaString, session.account, startServerUrl, NKTypeClassFile.video.rawValue, global.metadataStatusHideInView)
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
    
    func createImagesCache() {
        let utility = NCUtility()

        images.file = UIImage(named: "file")!

        images.shared = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.canShare = UIImage(named: "share")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.shareByLink = UIImage(named: "sharebylink")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: NCBrandColor.shared.nmcIconSharedWithMe, size: 24)//50)
        
        images.favorite = utility.loadImage(named: "star.fill", colors: [NCBrandColor.shared.yellowFavorite])
        images.comment = UIImage(named: "comment")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.livePhoto = utility.loadImage(named: "livephoto", colors: [.label])
        images.offlineFlag = utility.loadImage(named: "arrow.down.circle.fill", colors: [.systemGreen], size: 24)
        images.local = utility.loadImage(named: "checkmark.circle.fill", colors: [.systemGreen], size: 24)

        images.checkedYes = UIImage(named: "checkedYes")!
        images.checkedNo = utility.loadImage(named: "circle", colors: [NCBrandColor.shared.iconImageColor], size: 24)

        images.buttonMore = UIImage(named: "more")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.buttonStop = utility.loadImage(named: "stop.circle", colors: [NCBrandColor.shared.iconImageColor], size: 24)
        images.buttonMoreLock = utility.loadImage(named: "lock.fill", colors: [NCBrandColor.shared.iconImageColor], size: 24)
        images.buttonRestore = UIImage(named: "restore")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)
        images.buttonTrash = UIImage(named: "trashIcon")!.image(color: NCBrandColor.shared.iconImageColor, size: 24)//50)

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
