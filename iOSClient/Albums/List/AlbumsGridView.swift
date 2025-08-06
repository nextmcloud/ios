//
//  AlbumsGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 28/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

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
                                
                                if album.lastPhotoId == "-1" || album.itemCount == 0 {
                                    Image("EmptyAlbum")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 182, height: 140) // make flexible if needed
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                } else {
                                    Image(album.lastPhotoId ?? "")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 182, height: 140) // make flexible if needed
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                
                                //                            if let image = NCUtility.createFilePreviewImage(
                                //                                ocId: album.lastPhotoId,
                                //                                etag: metadata.etag,
                                //                                fileNameView: metadata.fileNameView,
                                //                                classFile: metadata.classFile,
                                //                                status: metadata.status,
                                //                                createPreviewMedia: true
                                //                            ) {
                                //
                                //
                                //
                                //                            }
                                
                                Text(album.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                let subtitle: String = {
                                    var parts: [String] = []
                                    
                                    if let count = album.itemCount {
                                        parts.append("\(count) Objects")
                                    }
                                    
                                    if let date = album.dateRange {
                                        parts.append(date)
                                    }
                                    
                                    return parts.joined(separator: " - ")
                                }()
                                
                                if !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
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
