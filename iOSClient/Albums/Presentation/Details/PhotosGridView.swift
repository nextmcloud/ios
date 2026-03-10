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
    let album: Album

    private var columns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // IPAD: Fixed 4-column "Professional" grid
            // Using 4 instead of 3 looks much better on wide iPad screens
            return Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)
        } else {
            // IPHONE: Adaptive "Fluid" grid
            // Fits as many 100pt items as possible (usually 3 or 4 depending on model)
            return [
                GridItem(.adaptive(minimum: 100, maximum: 300), spacing: 1)
            ]
        }
    }
    
    private let calculatedIconSize: CGFloat = 30
    
    var body: some View {
        
        ScrollView {
            
            LazyVGrid(columns: columns, spacing: 1) {
                
                ForEach(Array(photos), id: \.key) { (photo, metadata) in
                    
                    Button {
                        openPhotoViewer(photo: photo, metadata: metadata)
                    } label: {
                        PhotoGridItemView(
                                photo: photo,
                                isVideo: (metadata?.isVideo ?? false),
                                metadata: metadata,
                                iconSize: calculatedIconSize
                            )
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    }
                }
            }
        }
    }
    
    private func openPhotoViewer(photo: AlbumPhoto, metadata: tableMetadata?) {
        
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
        viewer.albumName = album.name
        viewer.albumServerUrl = album.href
        viewer.albumPhoto = photo
        navController.pushViewController(viewer, animated: true)
    }
}
