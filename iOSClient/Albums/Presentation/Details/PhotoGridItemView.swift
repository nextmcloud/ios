//
//  PhotoGridItemView.swift
//  Nextcloud
//
//  Created by Dhanesh on 04/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI
import NextcloudKit

struct PhotoGridItemView: View {
    @Environment(\.localAccount) var localAccount: String
    
    let album: Album
    let photo: AlbumPhoto
    let isVideo: Bool
    let metadata: tableMetadata?
    let iconSize: CGFloat
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Color.gray.opacity(0.2))
                if isLoading { ProgressView().controlSize(.small) }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .overlay(
            Group {
                if isVideo {
                    Image(systemName: "play.fill")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.white)
                        .padding(8)
                }
            },
            alignment: .bottomLeading
        )
        .cornerRadius(8)
        .task(id: metadata?.fileId ?? album.lastPhotoId) {
            self.thumbnail = nil
            self.isLoading = false
            
            // If it's a photo entry, skip if it's a directory
            if let meta = metadata {
                guard !meta.fileId.isEmpty, !meta.isDirectory else { return }
            }
            
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Fallback to album.lastPhotoId if this tile represents the album itself
        let fId = metadata?.fileId ?? album.lastPhotoId
        guard let fileId = fId, !fileId.isEmpty, fileId != "-1" else { return }

        // Use NCGlobal.shared as the fallback for account details
        let userId = metadata?.userId ?? "" //localAccount.userId
        let urlBase = metadata?.urlBase ?? "" //NCGlobal.shared.urlBase

        // 1. Check Disk Cache
        if let cachedImage = NCUtility().getImage(ocId: fileId,
                                                 etag: metadata?.etag ?? "",
                                                 ext: NCGlobal.shared.previewExt512,
                                                 userId: userId,
                                                 urlBase: urlBase) {
            self.thumbnail = cachedImage
            return
        }

        // 2. Download Preview
        await MainActor.run { self.isLoading = true }
        let resultsPreview = await NextcloudKit.shared.downloadPreviewAsync(
            fileId: fileId,
            etag: metadata?.etag ?? "",
            account: localAccount
        ) { _ in }
        
        if resultsPreview.error == .success, let data = resultsPreview.responseData?.data, let downloadedImage = UIImage(data: data) {
            await MainActor.run {
                self.thumbnail = downloadedImage
                self.isLoading = false
            }
            
            // 3. Save to Disk
            Task.detached(priority: .background) {
                await NCUtility().createImageFileFrom(data: data, ocId: fileId, etag: metadata?.etag ?? "", userId: userId, urlBase: urlBase)
            }
        }
        await MainActor.run { self.isLoading = false }
    }
}

