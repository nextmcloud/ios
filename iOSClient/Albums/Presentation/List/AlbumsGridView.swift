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
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    ForEach(albums, id: \.id) { album in
                        
                        NavigationLink(
                            destination: {
                                AlbumDetailsScreen(
                                    viewModel: .init(
                                        account: localAccount,
                                        album: album
                                    )
                                )
                            }
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                
                                AlbumGridPhoto(album: album)
                                
                                Text(album.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                if let subtitle = makeSubtitle(for: album), !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
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
    
    private enum ImageState { case loading, empty, thumbnail(UIImage) }
    @State private var imageState: ImageState = .loading
    
    var body: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width
            let clampedHeight = min(max(cellWidth, 140), 200) // 140–200 cap
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
                
                switch imageState {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case .empty:
                    Image("EmptyAlbum")
                        .resizable()
                        .scaledToFit()   // fit inside box, no overflow
                        .padding(16)
                case .thumbnail(let img):
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()  // fill box, center crop
                }
            }
            .frame(width: cellWidth, height: clampedHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .aspectRatio(1, contentMode: .fit) // keep grid cell square-ish
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
