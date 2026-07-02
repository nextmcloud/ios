import UIKit
import NextcloudKit
import RealmSwift

public final class NCMediaService {
    public enum FetchError: Error {
        case missingAccount
    }
    
    public static let shared = NCMediaService()
    
    private init() {}
    
    func fetchMetadatas(account: String,
                        session: NCSession.Session,
                        database: NCManageDatabase,
                        imageCache: NCImageCache,
                        global: NCGlobal,
                        showOnlyImages: Bool,
                        showOnlyVideos: Bool) async -> Result<[tableMetadata], FetchError> {
        
        guard let tblAccount = await database.getTableAccountAsync(predicate: NSPredicate(format: "account == %@", account)) else {
            return .failure(.missingAccount)
        }
        
        let capabilities = await NKCapabilities.shared.getCapabilities(for: account)
        
        let mediaPredicate = imageCache.getMediaPredicate(session: session,
                                                         mediaPath: tblAccount.mediaPath,
                                                         showOnlyImages: showOnlyImages,
                                                         showOnlyVideos: showOnlyVideos)
        
        let sortedByKeyPath: String
        if capabilities.serverVersionMajor >= global.nextcloudVersionFuture {
            sortedByKeyPath = "datePhotosOriginal"
        } else {
            sortedByKeyPath = "date"
        }
        
        guard let metadatas = await database.getMetadatasAsync(predicate: mediaPredicate,
                                                              sortedByKeyPath: sortedByKeyPath,
                                                              ascending: false) else {
            return .success([])
        }
        
        let normalizedMetadatas: [tableMetadata] = await withCheckedContinuation { (continuation: CheckedContinuation<[tableMetadata], Never>) in
            database.filterAndNormalizeLivePhotos(from: metadatas) { normalizedArray in
                continuation.resume(returning: normalizedArray)
            }
        }
        
        return .success(normalizedMetadatas)
    }
}
