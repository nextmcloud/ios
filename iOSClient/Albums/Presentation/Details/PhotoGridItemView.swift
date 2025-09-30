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
    let isVideo: Bool
    
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
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Don't re-download if we already have it.
        guard thumbnail == nil else { return }
        
        let result = await NCNetworking.shared.downloadPreview(
            fileId: photo.id,
            etag: "",
            account: localAccount
        )
        
        if let data = result.responseData?.data, let image = UIImage(data: data) {
            await MainActor.run {
                self.thumbnail = image
            }
        } else {
            // Handle error or set a placeholder
            print("Failed to download thumbnail for \(photo.fileName)")
        }
    }
}
