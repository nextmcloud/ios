//
//  AlbumsGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 28/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI
import Foundation
import UIKit

struct AlbumsGridView: View {
    
    @Environment(\.localAccount) var localAccount: String
    
    let albums: [Album]
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 16) {
                
                Text("My albums")
                    .font(.system(size: 21, weight: .bold))
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums, id: \.id) { album in
                        NavigationLink(
                            destination: {
                                AlbumDetailsScreen(
                                    account: localAccount,
                                    album: album
                                )
                            }
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                
                                AlbumGridPhoto(album: album)
                                
                                Text(album.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                if let subtitle = makeSubtitle(for: album), !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(UIColor.systemGray))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func makeSubtitle(for album: Album) -> String? {
        guard let count = album.itemCount else { return nil }
        
        var parts: [String] = ["\(count) Items"]
        
        if count > 0, let end = album.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append(formatter.string(from: end))
        }
        
        return parts.joined(separator: " - ")
    }
}

fileprivate struct AlbumGridPhoto: View {
    
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

#if DEBUG
#Preview {
    AlbumsGridView(
        albums: [
            Album(
                href: "/Geburtstagsalbum",
                lastPhotoId: "birthday",
                itemCount: 16,
                location: "Berlin",
                dateRange: "Feb 2022",
                collaborators: "Anna, John"
            ),
            Album(
                href: "/Urlaub",
                lastPhotoId: "mountain",
                itemCount: 42,
                location: "Alps",
                dateRange: nil,
                collaborators: nil
            ),
            Album(
                href: "/Office Party",
                lastPhotoId: "-1",
                itemCount: 0,
                location: nil,
                dateRange: "Dec 2023",
                collaborators: nil
            )
        ]
    )
}
#endif
