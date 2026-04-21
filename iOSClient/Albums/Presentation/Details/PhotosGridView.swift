//
//  PhotosGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct PhotosGridView: View {
    let localAccount: String // Add this
    let photos: [AlbumPhoto : tableMetadata?]
    let onAddPhotosIntent: () -> Void
    let album: Album

    private var columns: [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)
        } else {
            return [GridItem(.adaptive(minimum: 100, maximum: 300), spacing: 1)]
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
                            album: album,
                            photo: photo,
                            isVideo: (metadata?.isVideo ?? false),
                            metadata: metadata,
                            iconSize: calculatedIconSize
                        )
                    }
                }
            }
        }
    }
    
    private func openPhotoViewer(photo: AlbumPhoto, metadata: tableMetadata?) {
        // 1. Try to use existing metadata, or find it in the DB, or create a stub
        var activeMetadata = metadata
        
        if activeMetadata == nil {
            // Attempt database lookup first to get full details
            activeMetadata = NCManageDatabase.shared.getMetadataFromOcId(photo.id)
        }
        
        if activeMetadata == nil {
            // Fallback: Manually create metadata from the AlbumPhoto object
            let stub = tableMetadata()
            stub.ocId = photo.id
            stub.fileId = photo.id
            stub.fileName = photo.fileName
            stub.account = self.localAccount
            // Combine album path with photo name if necessary
            stub.path = "\(album.href)/\(photo.fileName)"
            activeMetadata = stub
        }

        // 2. Safety check
        guard let finalMetadata = activeMetadata else { return }

        // 3. Navigation and Viewer Setup
        guard let navController = (UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })?.rootViewController as? NCMainTabBarController)?
            .selectedViewController as? UINavigationController else { return }
            
        guard let viewer = UIStoryboard(name: "NCViewerMediaPage", bundle: nil)
            .instantiateInitialViewController() as? NCViewerMediaPage else { return }
        
        // 4. Populate viewer with the new metadata
        // We filter out nils to ensure metadatas and ocIds arrays stay in sync
        let metadatas = photos.values.compactMap { $0 }
        let ocIds = metadatas.map { $0.ocId }

        viewer.ocIds = ocIds
        viewer.metadatas = metadatas
        viewer.currentIndex = metadatas.firstIndex(where: { $0.ocId == finalMetadata.ocId }) ?? 0
        viewer.albumName = album.name
        viewer.albumServerUrl = album.href
        viewer.albumPhoto = photo
        
        navController.pushViewController(viewer, animated: true)
    }
}
