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
    
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: AlbumDetailsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        ZStack {
            content()
            
            if viewModel.isLoadingPopupVisible {
                NCLoadingAlert()
            }
        }
        .navigationTitle(viewModel.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarContent()
            }
        }
        .onAppear {
            viewModel.loadAlbumPhotos()
        }
        .onReceive(viewModel.goBack) {
            dismiss()
        }
        .inputAlbumNameAlert(
            isPresented: $viewModel.isRenameAlbumPopupVisible,
            albumName: $viewModel.newAlbumName,
            error: viewModel.newAlbumNameError,
            isForRenamingAlbum: true,
            onCreate: {
                viewModel.onRenameAlbumPopupConfirm()
            },
            onCancel: {
                viewModel.onRenameAlbumPopupCancel()
            }
        )
        .alert(
            "Delete Album?",
            isPresented: $viewModel.isDeleteAlbumPopupVisible,
            actions: {
                Button("Delete", role: .destructive, action: viewModel.onDeleteAlbumPopupConfirm)
                Button("Cancel", role: .cancel, action: viewModel.onDeleteAlbumPopupCancel)
            },
            message: {
                Text("Are you sure you want to delete this album? This action cannot be undone.")
            }
        )
    }
    
    @ViewBuilder
    private func toolbarContent() -> some View {
        if viewModel.isLoading {
            EmptyView()
        } else {
            HStack {
                
                if viewModel.photos.isEmpty {
                    Button("Add", action: handleAddPhotosIntent)
                        .foregroundColor(Color(NCBrandColor.shared.customer))
                } else {
                    Button(action: handleAddPhotosIntent) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                
                Spacer()
                    .frame(width: 4)
                
                Menu {
                    Button("Rename Album") {
                        viewModel.onRenameAlbumIntent()
                    }
                    Button("Delete Album", role: .destructive) {
                        viewModel.onDeleteAlbumIntent()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundStyle(Color(NCBrandColor.shared.customer))
                }
            }
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
                onAddPhotosIntent: handleAddPhotosIntent
            )
        } else {
            PhotosGridView(
                photos: viewModel.photos,
                onAddPhotosIntent: handleAddPhotosIntent
            )
        }
    }
    
    private func handleAddPhotosIntent() {
        
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
