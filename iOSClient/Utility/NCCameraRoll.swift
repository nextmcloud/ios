//
//  NCCameraRoll.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 21/12/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
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
import Photos
import UIKit
import NextcloudKit
import AVFoundation

/// Structure representing an extracted asset result
struct ExtractedAsset {
    let metadata: tableMetadata
    let filePath: String
}

/// Protocol for camera roll extraction to allow mocking and flexibility
protocol CameraRollExtractor {
    func extractCameraRoll(from: [tableMetadata], progress: NCCameraRoll.ProgressHandler?) async -> [tableMetadata]
    func extractCameraRoll(from: tableMetadata) async -> [tableMetadata]
}

/// NCCameraRoll handles the extraction of image and video assets from the user's photo library
final class NCCameraRoll: CameraRollExtractor {
    let utilityFileSystem = NCUtilityFileSystem()
    let database = NCManageDatabase.shared

    func extractCameraRoll(from metadata: tableMetadata, completition: @escaping (_ metadatas: [tableMetadata]) -> Void) {
        var metadatas: [tableMetadata] = []
        let metadataSource = tableMetadata.init(value: metadata)
        var chunkSize = NCGlobal.shared.chunkSizeMBCellular
        if NCNetworking.shared.networkReachability == NKCommon.TypeReachability.reachableEthernetOrWiFi {
            chunkSize = NCGlobal.shared.chunkSizeMBEthernetOrWiFi
    /// Progress handler typealias to track extraction progress
    typealias ProgressHandler = (_ extracted: Int, _ total: Int, _ latest: tableMetadata?) -> Void

    /// Extracts a list of camera roll assets
    /// - Parameters:
    ///   - metadatas: An array of tableMetadata objects to extract
    ///   - progress: Optional closure to track progress
    /// - Returns: Array of extracted metadata
    func extractCameraRoll(from metadatas: [tableMetadata], progress: ProgressHandler? = nil) async -> [tableMetadata] {
        let total = metadatas.count
        var extracted: Int = 0
        var results: [tableMetadata] = []

        await withTaskGroup(of: [tableMetadata].self) { group in
            for metadata in metadatas {
                group.addTask {
                    let result = await self.extractCameraRoll(from: metadata)
                    return result
                }
            }

            for await result in group {
                for item in result {
                    extracted += 1
                    progress?(extracted, total, item)
                    nkLog(debug: "Extracted from camera roll: \(item.fileNameView)")
                }
                results.append(contentsOf: result)
            }
        }
        guard !metadata.isExtractFile else { return  completition([metadataSource]) }

        return results
    }

    /// Extracts a single camera roll asset
    /// - Parameter metadata: Metadata to extract
    /// - Returns: Extracted metadata, possibly including a paired Live Photo
    func extractCameraRoll(from metadata: tableMetadata) async -> [tableMetadata] {
        guard !metadata.isExtractFile else {
            return [metadata]
        }

        var metadatas: [tableMetadata] = []
        let metadataSource = metadata.detachedCopy()
        let chunkSize = NCNetworking.shared.networkReachability == .reachableEthernetOrWiFi
            ? NCGlobal.shared.chunkSizeMBEthernetOrWiFi
            : NCGlobal.shared.chunkSizeMBCellular

        guard !metadataSource.assetLocalIdentifier.isEmpty else {
            let filePath = utilityFileSystem.getDirectoryProviderStorageOcId(metadataSource.ocId, fileNameView: metadataSource.fileName)
            metadataSource.size = utilityFileSystem.getFileSize(filePath: filePath)
            let results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: metadataSource.fileNameView, mimeType: metadataSource.contentType, directory: false, account: metadataSource.account)
            metadataSource.contentType = results.mimeType
            metadataSource.iconName = results.iconName
            metadataSource.classFile = results.classFile
            let results = await NKTypeIdentifiers.shared.getInternalType(fileName: metadataSource.fileNameView, mimeType: metadataSource.contentType, directory: false, account: metadataSource.account)

            metadataSource.contentType = results.mimeType
            metadataSource.iconName = results.iconName
            metadataSource.classFile = results.classFile
            metadataSource.typeIdentifier = results.typeIdentifier

            metadataSource.size = utilityFileSystem.getFileSize(filePath: filePath)

            if let date = utilityFileSystem.getFileCreationDate(filePath: filePath) {
                metadataSource.creationDate = date
            }
            if let date = utilityFileSystem.getFileModificationDate(filePath: filePath) {
                metadataSource.date = date
            }
            metadataSource.chunk = metadataSource.size > chunkSize ? chunkSize : 0
            metadataSource.e2eEncrypted = metadata.isDirectoryE2EE
            if metadataSource.chunk > 0 || metadataSource.e2eEncrypted {
                metadataSource.session = NCNetworking.shared.sessionUpload
            }
            metadataSource.isExtractFile = true

            if let metadata = self.database.addAndReturnMetadata(metadataSource) {
                metadatas.append(metadata)
            }
            return metadatas
        }

        do {
            let result = try await extractImageVideoFromAssetLocalIdentifier(
                metadata: metadataSource,
                modifyMetadataForUpload: true
            )

            let toPath = self.utilityFileSystem.getDirectoryProviderStorageOcId(result.metadata.ocId, fileNameView: result.metadata.fileNameView)
            self.utilityFileSystem.moveFile(atPath: result.filePath, toPath: toPath)
            metadatas.append(result.metadata)

            let fetchAssets = PHAsset.fetchAssets(withLocalIdentifiers: [metadataSource.assetLocalIdentifier], options: nil)
            if result.metadata.isLivePhoto, let asset = fetchAssets.firstObject,
               let livePhotoMetadata = await createMetadataLivePhoto(metadata: result.metadata, asset: asset) {
                if let metadata = self.database.addAndReturnMetadata(livePhotoMetadata) {
                    metadatas.append(metadata)
                }
            }
        } catch {
            nkLog(error: "Error during extraction: \(error.localizedDescription), of filename: \(metadataSource.fileNameView)")
        }

        return metadatas
    }

    /// Wrapper to call the async `extractImageVideoFromAssetLocalIdentifierAsync` using a completion handler.
    /// - Parameters:
    ///   - metadata: The metadata to extract.
    ///   - modifyMetadataForUpload: Whether to modify the metadata before returning.
    ///   - completion: Completion handler with result or error.
    func extractImageVideoFromAssetLocalIdentifier(metadata: tableMetadata, modifyMetadataForUpload: Bool, completion: @escaping (Result<ExtractedAsset, Error>) -> Void) {
        Task {
            do {
                let result = try await extractImageVideoFromAssetLocalIdentifier(
                    metadata: metadata,
                    modifyMetadataForUpload: modifyMetadataForUpload
                )
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Extracts image or video data from a given asset identifier
    /// - Parameters:
    ///   - originalMetadata: Metadata describing the asset
    ///   - modifyMetadataForUpload: Whether to update metadata for upload and store it in the database
    /// - Returns: An `ExtractedAsset` containing the updated metadata and path to the extracted file
    func extractImageVideoFromAssetLocalIdentifier(metadata: tableMetadata, modifyMetadataForUpload: Bool) async throws -> ExtractedAsset {
        // Determine the appropriate chunk size based on the current network connection
        let chunkSize = NCNetworking.shared.networkReachability == .reachableEthernetOrWiFi
            ? NCGlobal.shared.chunkSizeMBEthernetOrWiFi
            : NCGlobal.shared.chunkSizeMBCellular

        // Fetch the PHAsset using the local identifier
        guard let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [metadata.assetLocalIdentifier],
            options: nil
        ).firstObject else {
            throw NSError(domain: "ExtractAssetError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Asset not found"])
        }

        // Determine file extension and prepare filename
        let ext = (asset.originalFilename as NSString).pathExtension.lowercased()
        let fileName = metadataUpdatedFilename(for: asset, original: metadata.fileNameView, ext: ext, native: metadata.nativeFormat)
        let filePath = NSTemporaryDirectory() + fileName

        metadata.fileName = fileName
        metadata.fileNameView = fileName
        metadata.serverUrlFileName = metadata.serverUrl + "/" + metadata.fileName

        // Safely set the content type if available
        if let type = contentType(for: asset, ext: ext) {
            metadata.contentType = type
        }

        // Extract file data from asset
        switch asset.mediaType {
        case .image:
            try await extractImage(asset: asset, ext: ext, filePath: filePath, compatibilityFormat: !metadata.nativeFormat)
        case .video:
            try await extractVideo( asset: asset, filePath: filePath)
        default:
            throw NSError(domain: "ExtractAssetError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])
        }

        // Populate metadata with extracted file info
        metadata.creationDate = (asset.creationDate ?? Date()) as NSDate
        metadata.date = (asset.modificationDate ?? Date()) as NSDate
        metadata.size = self.utilityFileSystem.getFileSize(filePath: filePath)

        // Optionally update metadata for upload and persist it
        if modifyMetadataForUpload {
            if let metadata = await updateMetadataForUploadAsync(metadata: metadata, size: Int(metadata.size), chunkSize: chunkSize) {
                return ExtractedAsset(metadata: metadata, filePath: filePath)
            } else {
                throw NSError(domain: "ExtractAssetError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Asset not found"])
            }
        } else {
            return ExtractedAsset(metadata: metadata, filePath: filePath)
        }
    }

    private func metadataUpdatedFilename(for asset: PHAsset, original: String, ext: String, native: Bool) -> String {
        if asset.mediaType == .image && (ext == "heic" || ext == "dng") && !native {
            return (original as NSString).deletingPathExtension + ".jpg"
        }
        return original
    }

    private func contentType(for asset: PHAsset, ext: String) -> String? {
        if asset.mediaType == .image && (ext == "heic" || ext == "dng") {
            return "image/jpeg"
        }
        return nil
    }

    private func updateMetadataForUpload(metadata: tableMetadata, size: Int, chunkSize: Int) -> tableMetadata? {
        metadata.chunk = size > chunkSize ? chunkSize : 0
        metadata.e2eEncrypted = metadata.isDirectoryE2EE
        if metadata.chunk > 0 || metadata.e2eEncrypted {
            metadata.session = NCNetworking.shared.sessionUpload
        }
        metadata.isExtractFile = true
        return self.database.addAndReturnMetadata(metadata)
    }

    private func updateMetadataForUploadAsync(metadata: tableMetadata, size: Int, chunkSize: Int) async -> tableMetadata? {
        metadata.chunk = size > chunkSize ? chunkSize : 0
        metadata.e2eEncrypted = metadata.isDirectoryE2EE
        if metadata.chunk > 0 || metadata.e2eEncrypted {
            metadata.session = NCNetworking.shared.sessionUpload
        }
        metadata.isExtractFile = true
        return await self.database.addAndReturnMetadataAsync(metadata)
    }

    private func extractImage(asset: PHAsset, ext: String, filePath: String, compatibilityFormat: Bool) async throws {
        let imageData: Data? = try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = compatibilityFormat ? .opportunistic : .highQualityFormat
            options.isSynchronous = true
            if ext == "dng" { options.version = .original }

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "ExtractAssetError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Image data is nil"]))
                }
            } else {
                completition(metadatas)
            }
        }
    }

    func extractCameraRoll(from metadata: tableMetadata) async -> [tableMetadata] {
        await withUnsafeContinuation({ continuation in
            extractCameraRoll(from: metadata) { metadatas in
                continuation.resume(returning: metadatas)
            }
        })
    }

    func extractImageVideoFromAssetLocalIdentifier(metadata: tableMetadata,
                                                   modifyMetadataForUpload: Bool,
                                                   completion: @escaping (_ metadata: tableMetadata?, _ fileNamePath: String?, _ error: Bool) -> Void) {

        var fileNamePath: String?
        var metadata = metadata
        var compatibilityFormat: Bool = false
        var chunkSize = NCGlobal.shared.chunkSizeMBCellular
        if NCNetworking.shared.networkReachability == NKCommon.TypeReachability.reachableEthernetOrWiFi {
            chunkSize = NCGlobal.shared.chunkSizeMBEthernetOrWiFi
        }

        func callCompletionWithError(_ error: Bool = true) {
            if error {
                completion(nil, nil, true)
            } else {
                if modifyMetadataForUpload {
                    if metadata.size > chunkSize {
                        metadata.chunk = chunkSize
                    } else {
                        metadata.chunk = 0
                    }
                    metadata.e2eEncrypted = metadata.isDirectoryE2EE
                    if metadata.chunk > 0 || metadata.e2eEncrypted {
                        metadata.session = NCNetworking.shared.sessionUpload
                    }
                    metadata.isExtractFile = true
                    metadata = self.database.addMetadata(metadata)
                }
                completion(metadata, fileNamePath, error)
            }
        }

        let fetchAssets = PHAsset.fetchAssets(withLocalIdentifiers: [metadata.assetLocalIdentifier], options: nil)
        guard fetchAssets.count > 0, let asset = fetchAssets.firstObject else {
            return callCompletionWithError()
        }

        let extensionAsset = asset.originalFilename.pathExtension.lowercased()
        let creationDate = asset.creationDate ?? Date()
        let modificationDate = asset.modificationDate ?? Date()

        if asset.mediaType == PHAssetMediaType.image && (extensionAsset == "heic" || extensionAsset == "dng") && !metadata.nativeFormat {
            let fileName = (metadata.fileNameView as NSString).deletingPathExtension + ".jpg"
            metadata.contentType = "image/jpeg"
            fileNamePath = NSTemporaryDirectory() + fileName
            metadata.fileNameView = fileName
            metadata.fileName = fileName
            compatibilityFormat = true
        } else {
            fileNamePath = NSTemporaryDirectory() + metadata.fileNameView
        }

        guard let fileNamePath = fileNamePath else { return callCompletionWithError() }

        if asset.mediaType == PHAssetMediaType.image {

            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            if compatibilityFormat {
                options.deliveryMode = .opportunistic
            } else {
                options.deliveryMode = .highQualityFormat
            }
            options.isSynchronous = true
            if extensionAsset == "DNG" {
                options.version = PHImageRequestOptionsVersion.original
            }
            options.progressHandler = { progress, error, _, _ in
                print(progress)
                if error != nil { return callCompletionWithError() }
            }

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard var data = data else { return callCompletionWithError() }
                if compatibilityFormat {
                    guard let ciImage = CIImage(data: data), let colorSpace = ciImage.colorSpace, let dataJPEG = CIContext().jpegRepresentation(of: ciImage, colorSpace: colorSpace) else { return callCompletionWithError() }
                    data = dataJPEG
                }
                self.utilityFileSystem.removeFile(atPath: fileNamePath)
                do {
                    try data.write(to: URL(fileURLWithPath: fileNamePath), options: .atomic)
                } catch { return callCompletionWithError() }
                metadata.creationDate = creationDate as NSDate
                metadata.date = modificationDate as NSDate
                metadata.size = self.utilityFileSystem.getFileSize(filePath: fileNamePath)
                return callCompletionWithError(false)
            }

        } else if asset.mediaType == PHAssetMediaType.video {

            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = PHVideoRequestOptionsVersion.current
            options.progressHandler = { progress, error, _, _ in
                print(progress)
                if error != nil { return callCompletionWithError() }
            }

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
                if let asset = asset as? AVURLAsset {
                    self.utilityFileSystem.removeFile(atPath: fileNamePath)
                    do {
                        try FileManager.default.copyItem(at: asset.url, to: URL(fileURLWithPath: fileNamePath))
                        metadata.creationDate = creationDate as NSDate
                        metadata.date = modificationDate as NSDate
                        metadata.size = self.utilityFileSystem.getFileSize(filePath: fileNamePath)
                        return callCompletionWithError(false)
                    } catch { return callCompletionWithError() }
                } else if let asset = asset as? AVComposition, asset.tracks.count > 1, let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) {
                    exporter.outputURL = URL(fileURLWithPath: fileNamePath)
                    exporter.outputFileType = AVFileType.mp4
                    exporter.shouldOptimizeForNetworkUse = true
                    exporter.exportAsynchronously {
                        if exporter.status == .completed {
                            metadata.creationDate = creationDate as NSDate
                            metadata.date = modificationDate as NSDate
                            metadata.size = self.utilityFileSystem.getFileSize(filePath: fileNamePath)
                            return callCompletionWithError(false)
                        } else { return callCompletionWithError() }
            }
        }

        var data = imageData!

        if compatibilityFormat {
            guard let ciImage = CIImage(data: data),
                  let colorSpace = ciImage.colorSpace,
                  let jpegData = CIContext().jpegRepresentation(of: ciImage, colorSpace: colorSpace)
            else {
                throw NSError(domain: "ExtractAssetError", code: 3, userInfo: [NSLocalizedDescriptionKey: "JPEG conversion failed"])
            }
            data = jpegData
        }

        self.utilityFileSystem.removeFile(atPath: filePath)
        try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }

    private func extractVideo(asset: PHAsset, filePath: String) async throws {
        let videoAsset: AVAsset = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.version = .current

                PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
                    if let asset = asset {
                        continuation.resume(returning: asset)
                    } else {
                        continuation.resume(throwing: NSError(domain: "ExtractAssetError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Video asset is nil"]))
                    }
                } else {
                    return callCompletionWithError()
                }
            }
        } else {
            return callCompletionWithError()
        }

        self.utilityFileSystem.removeFile(atPath: filePath)

        if let urlAsset = videoAsset as? AVURLAsset {
            try FileManager.default.copyItem(at: urlAsset.url, to: URL(fileURLWithPath: filePath))
        } else if let composition = videoAsset as? AVComposition, composition.tracks.count > 1,
                  let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) {
            exporter.outputURL = URL(fileURLWithPath: filePath)
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true

            try await withCheckedThrowingContinuation { continuation in
                exporter.exportAsynchronously {
                    // Capture of 'exporter' with non-sendable type 'AVAssetExportSession' in a '@Sendable' closure I don't know how fix
                    if exporter.status == .completed {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: NSError(domain: "ExtractAssetError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Video export failed"]))
                    }
                }
            }
        } else {
            throw NSError(domain: "ExtractAssetError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unsupported video format"])
        }
    }

    private func createMetadataLivePhoto(metadata: tableMetadata,
                                         asset: PHAsset?,
                                         completion: @escaping (_ metadata: tableMetadata?) -> Void) {

        guard let asset = asset else { return completion(nil) }
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
        options.isNetworkAccessAllowed = true
        let ocId = NSUUID().uuidString
        let fileName = (metadata.fileName as NSString).deletingPathExtension + ".mov"
        let fileNamePath = utilityFileSystem.getDirectoryProviderStorageOcId(ocId, fileNameView: fileName)
        var chunkSize = NCGlobal.shared.chunkSizeMBCellular
        if NCNetworking.shared.networkReachability == NKCommon.TypeReachability.reachableEthernetOrWiFi {
            chunkSize = NCGlobal.shared.chunkSizeMBEthernetOrWiFi
        }

        PHImageManager.default().requestLivePhoto(for: asset, targetSize: UIScreen.main.bounds.size, contentMode: PHImageContentMode.default, options: options) { livePhoto, _ in
            guard let livePhoto = livePhoto else { return completion(nil) }
            var videoResource: PHAssetResource?
            for resource in PHAssetResource.assetResources(for: livePhoto) where resource.type == PHAssetResourceType.pairedVideo {
                videoResource = resource
                break
            }
            guard let videoResource = videoResource else { return completion(nil) }
            self.utilityFileSystem.removeFile(atPath: fileNamePath)
            PHAssetResourceManager.default().writeData(for: videoResource, toFile: URL(fileURLWithPath: fileNamePath), options: nil) { error in
                guard error == nil else { return completion(nil) }
    /// Represents a camera roll extractor that creates metadata for Live Photos.
    /// This method is compatible with Swift 6, avoids non-Sendable captures,
    /// and performs safe background processing.
    private func createMetadataLivePhoto(metadata: tableMetadata, asset: PHAsset?) async -> tableMetadata? {
        guard let asset else { return nil }

        let options = PHLivePhotoRequestOptions()
        let ocId = UUID().uuidString
        let fileName = (metadata.fileName as NSString).deletingPathExtension + ".mov"
        let fileNamePath = utilityFileSystem.getDirectoryProviderStorageOcId(ocId, fileNameView: fileName)
        let chunkSize = NCNetworking.shared.networkReachability == .reachableEthernetOrWiFi
            ? NCGlobal.shared.chunkSizeMBEthernetOrWiFi
            : NCGlobal.shared.chunkSizeMBCellular

        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true

        // UIScreen.main.bounds safely in Swift 6
        let screenSize = await MainActor.run {
            UIScreen.main.bounds.size
        }

        // Request the live photo from the asset
        let livePhoto = await withCheckedContinuation { (continuation: CheckedContinuation<PHLivePhoto?, Never>) in
            PHImageManager.default().requestLivePhoto(
                for: asset,
                targetSize: screenSize,
                contentMode: .default,
                options: options
            ) { photo, _ in
                continuation.resume(returning: photo)
            }
        }

        guard let livePhoto else { return nil }

        // Find the paired video component of the Live Photo
        let videoResource = PHAssetResource.assetResources(for: livePhoto)
            .first(where: { $0.type == .pairedVideo })
        guard let resource = videoResource else { return nil }

        utilityFileSystem.removeFile(atPath: fileNamePath)

        // Write video resource to file and create metadata
        return await withCheckedContinuation { (continuation: CheckedContinuation<tableMetadata?, Never>) in
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: URL(fileURLWithPath: fileNamePath),
                options: nil
            ) { error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let session = NCSession.shared.getSession(account: metadata.account)
                let metadataLivePhoto = self.database.createMetadata(fileName: fileName,
                                                                     ocId: ocId,
                                                                     serverUrl: metadata.serverUrl,
                                                                     session: session,
                                                                     sceneIdentifier: metadata.sceneIdentifier)

                metadataLivePhoto.livePhotoFile = metadata.fileName
                metadataLivePhoto.isExtractFile = true
                metadataLivePhoto.session = metadata.session
                metadataLivePhoto.sessionSelector = metadata.sessionSelector
                metadataLivePhoto.size = self.utilityFileSystem.getFileSize(filePath: fileNamePath)
                metadataLivePhoto.status = metadata.status
                metadataLivePhoto.chunk = metadataLivePhoto.size > chunkSize ? chunkSize : 0
                metadataLivePhoto.e2eEncrypted = metadata.isDirectoryE2EE
                if metadataLivePhoto.chunk > 0 || metadataLivePhoto.e2eEncrypted {
                    metadataLivePhoto.session = NCNetworking.shared.sessionUpload
                }
                metadataLivePhoto.creationDate = metadata.creationDate
                metadataLivePhoto.date = metadata.date
                metadataLivePhoto.uploadDate = metadata.uploadDate

                continuation.resume(returning: metadataLivePhoto)
            }
        }
    }
}

/// Mock implementation of CameraRollExtractor for unit testing
final class MockCameraRollExtractor: CameraRollExtractor {
    func extractCameraRoll(from metadatas: [tableMetadata], progress: NCCameraRoll.ProgressHandler?) async -> [tableMetadata] {
        progress?(metadatas.count, metadatas.count, metadatas.last)
        return metadatas
    }

    func extractCameraRoll(from metadata: tableMetadata) async -> [tableMetadata] {
        return [metadata]
    }
}
