//
//  AlbumDetailsScreen.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AlbumDetailsScreen: View {
    
    @StateObject private var viewModel: AlbumDetailsViewModel
    
    init(viewModel: AlbumDetailsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        content()
            .navigationTitle(viewModel.album.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadAlbumPhotos()
            }
    }
    
    @ViewBuilder
    private func content() -> some View {
        if viewModel.isLoading {
            ProgressView("Loading photos...")
        } else if let error = viewModel.errorMessage {
            Text(error)
        } else if viewModel.photos.isEmpty {
            NoPhotosEmptyView(
                onAddPhotosIntent: {
                    
                }
            )
        } else {
            PhotosGridView(photos: viewModel.photos)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AlbumDetailsScreen(
            viewModel: .init(
                account: "123",
                album: Album(
                    href: "/Urlaub",
                    lastPhotoId: "mountain",
                    itemCount: 42,
                    location: "Alps",
                    dateRange: nil,
                    collaborators: nil
                )
            )
        )
    }
}
#endif
