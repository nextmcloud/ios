import UIKit

final class NCMediaPreloader {
    static let shared = NCMediaPreloader()

    private var preloadedMedia: NCMedia?
    private var isPreloading = false

    private init() {}

    func preloadIfNeeded() {
        // Avoid duplicate work
        if preloadedMedia != nil || isPreloading { return }
        isPreloading = true
        defer { isPreloading = false }

        let storyboard = UIStoryboard(name: "NCMedia", bundle: nil)

        let mediaVC: NCMedia? = {
            if let media = storyboard.instantiateInitialViewController() as? NCMedia {
                return media
            }
            if let media = storyboard.instantiateViewController(withIdentifier: "NCMedia") as? NCMedia {
                return media
            }
            return nil
        }()

        guard let media = mediaVC else {
            return
        }

        media.isInGeneralPhotosSelectionContext = true

        // Force view load to trigger viewDidLoad and setup
        _ = media.view

        // Kick off initial data work
        Task {
            await media.loadDataSource()
            await media.searchMediaUI(true)
        }

        preloadedMedia = media
    }

    func getPreloaded() -> NCMedia? {
        return preloadedMedia
    }
}
