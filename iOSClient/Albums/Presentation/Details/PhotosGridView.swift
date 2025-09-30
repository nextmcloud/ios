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
                    
                    Button {
                        openPhotoViewer(for: metadata)
                    } label: {
                        PhotoGridItemView(photo: photo, isVideo: (metadata?.isVideo ?? false))
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                }
            }
        }
    }
    
    private func openPhotoViewer(for metadata: tableMetadata?) {
        
        guard let metadata else { return }
        
        // AlbumsViewController acting as a UINavigationController
        guard let navController = (
            UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
        )?.selectedViewController as? UINavigationController else { return }
        
        // NCViewerMediaPage to be inflated
        guard let viewer = UIStoryboard(name: "NCViewerMediaPage", bundle: nil)
            .instantiateInitialViewController() as? NCViewerMediaPage else { return }
        
        let ocIds = photos.values.compactMap { $0?.ocId }
        let metadatas = photos.values.compactMap { $0 }
        
        viewer.ocIds = ocIds
        viewer.metadatas = metadatas
        viewer.currentIndex = metadatas.firstIndex(where: { $0.ocId == metadata.ocId }) ?? 0
        
        navController.pushViewController(viewer, animated: true)
    }
}
