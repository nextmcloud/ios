//
//  PhotosGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct PhotosGridView: View {
    
    let photos: [AlbumPhoto]
    
    let onAddPhotosIntent: () -> Void
    
    private let gridItems = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        
        //            NCMediaViewRepresentable(photos: photos)
        //                .edgesIgnoringSafeArea(.all)
        
        ScrollView {
            LazyVGrid(columns: gridItems, spacing: 1) {
                ForEach(photos) { photo in
                    NavigationLink(
                        destination: {
                            Color(.blue)
                                .edgesIgnoringSafeArea(.all)
                        }
                    ) {
                        PhotoGridItemView(photo: photo)
                    }
                }
            }
        }
    }
}
