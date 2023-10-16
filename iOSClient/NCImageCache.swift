// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2021 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import LRUCache
import NextcloudKit
import RealmSwift

@objc class NCImageCache: NSObject {
    @objc static let shared = NCImageCache()

    private let utility = NCUtility()
    private let utilityFileSystem = NCUtilityFileSystem()
    private let global = NCGlobal.shared
    private let database = NCManageDatabase.shared

    private let allowExtensions = [NCGlobal.shared.previewExt256]
    private var brandElementColor: UIColor?

    private var observerToken: NSObjectProtocol?

    public var countLimit: Int = 2000
    lazy var cache: LRUCache<String, UIImage> = {
        return LRUCache<String, UIImage>(countLimit: countLimit)
    }()

    public var isLoadingCache: Bool = false
    public var controller: UITabBarController?

    init() {
        observerToken = NotificationCenter.default.addObserver(forName: LRUCacheMemoryWarningNotification, object: nil, queue: nil) { _ in
            self.cache.removeAll()
            self.cache = LRUCache<String, UIImage>(countLimit: self.countLimit)
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.cache.removeAll()
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
                            self.cache.removeAll()
                            for metadata in metadatas {
                                guard !isAppInBackground else {
                                    self.cache.removeAll()
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
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
        }
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
        cache.removeAll()
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
    }
}
