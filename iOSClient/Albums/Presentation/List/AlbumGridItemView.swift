//
//  AlbumGridItemView.swift
//  Nextcloud
//
//  Created by Dhanesh on 05/09/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AlbumGridItemView: View {
    
    let album: Album
    @Environment(\.localAccount) var localAccount: String
    
    private let fixedThumbnailHeight: CGFloat = 160
    
    private enum ImageState { case loading, empty, thumbnail(UIImage) }
    @State private var imageState: ImageState = .loading
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch imageState {
                case .loading:
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        )
                case .empty:
                    Image("EmptyAlbum")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geo.size.width,
                            height: fixedThumbnailHeight,
                            alignment: .top
                        )
                        .clipped()
                case .thumbnail(let img):
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: geo.size.width, height: fixedThumbnailHeight)
            .clipped()
            .overlay(frame)
            .cornerRadius(8)
        }
        .frame(height: fixedThumbnailHeight)
        .task(id: album.lastPhotoId) {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        if album.lastPhotoId == "-1" || (album.itemCount ?? 0) == 0 {
            imageState = .empty
            return
        }
        guard let photoId = album.lastPhotoId else {
            imageState = .empty
            return
        }
        
        let result = await NCNetworking.shared.downloadPreview(
            fileId: photoId,
            etag: "",
            account: localAccount
        )
        
        if let data = result.responseData?.data, let image = UIImage(data: data) {
            await MainActor.run { imageState = .thumbnail(image) }
        } else {
            await MainActor.run { imageState = .empty }
        }
    }
    
    private var frame: some View {
        RoundedRectangle(
            cornerRadius: 8
        )
        .stroke(
            Color.gray.opacity(1),
            lineWidth: 1 / UIScreen.main.scale
        )
    }
}
