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
    
    let photo: AlbumPhoto
    let metadata: tableMetadata?
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .scaledToFill()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .clipped()
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Don't re-download if we already have it.
        guard thumbnail == nil else { return }
        
        Task {
            guard let metadata = metadata else { return }

            let resultsPreview = await NextcloudKit.shared.downloadPreviewAsync(fileId: metadata.fileId, etag: metadata.etag, account: metadata.account) { task in
                Task {
                    let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: metadata.account,
                                                                                                path: metadata.fileId,
                                                                                                name: "DownloadPreview")
                    await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                }
            }
            if resultsPreview.error == .success, let data = resultsPreview.responseData?.data {
                NCUtility().createImageFileFrom(data: data, ocId: metadata.ocId, etag: metadata.etag, userId: metadata.userId, urlBase: metadata.urlBase)
                if let image = NCUtility().getImage(ocId: metadata.ocId, etag: metadata.etag, ext: NCGlobal.shared.previewExt512, userId: metadata.userId, urlBase: metadata.urlBase) {
                    Task { @MainActor in
                        self.thumbnail = image
                    }
                }
            } else {
                // Handle error or set a placeholder
                print("Failed to download thumbnail for \(photo.fileName)")
            }
        }
    }
}
