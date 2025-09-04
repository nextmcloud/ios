//
//  PhotosGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct PhotosGridView: View {
    
    let photos: [AlbumPhoto : tableMetadata?]
    let onAddPhotosIntent: () -> Void
    
    private let columns = [
        GridItem(
            .adaptive(
                minimum: 100,
                maximum: 300
            ),
            spacing: 1
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1) {
                
                ForEach(Array(photos), id: \.key) { (photo, metadata) in
                    
                    NavigationLink {
                        
                        if let metadata {
                            
                            NCViewerMediaPageWrapper(
                                ocIds: [metadata.ocId],
                                metadatas: [metadata],
                                currentIndex: 0
                            )
                        }
                    } label: {
                        PhotoGridItemView(photo: photo)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                }
            }
        }
    }
}
