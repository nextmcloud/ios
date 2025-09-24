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
    
    init(account: String, album: Album) {
        _viewModel = StateObject(
            wrappedValue: AlbumDetailsViewModel(account: account, album: album)
        )
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
        .sheet(
            isPresented: $viewModel.isPhotoSelectionSheetVisible
        ) {
            PhotoSelectionSheet(
                onPhotosSelected: viewModel.onPhotosSelected
            )
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
            NSLocalizedString("_albums_delete_album_popup_title_", comment: ""),
            isPresented: $viewModel.isDeleteAlbumPopupVisible,
            actions: {
                Button(
                    NSLocalizedString("_albums_delete_album_popup_positive_btn_", comment: ""),
                    role: .destructive,
                    action: viewModel.onDeleteAlbumPopupConfirm
                )
                Button(
                    NSLocalizedString("_albums_delete_album_popup_negative_btn_", comment: ""),
                    role: .cancel,
                    action: viewModel.onDeleteAlbumPopupCancel
                )
            },
            message: {
                Text(NSLocalizedString("_albums_delete_album_popup_desc_", comment: ""))
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
                    Button(
                        NSLocalizedString("_albums_photos_add_photos_btn_", comment: ""),
                        action: handleAddPhotosIntent
                    ).foregroundColor(Color(NCBrandColor.shared.customer))
                } else {
                    Button(action: handleAddPhotosIntent) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                
                Spacer()
                    .frame(width: 4)
                
                Menu {
                    Button(NSLocalizedString("_albums_photos_rename_album_btn_", comment: "")) {
                        viewModel.onRenameAlbumIntent()
                    }
                    Button(
                        NSLocalizedString("_albums_photos_delete_album_btn_", comment: ""),
                        role: .destructive
                    ) {
                        viewModel.onDeleteAlbumIntent()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color(NCBrandColor.shared.customer))
                }
            }
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        if viewModel.isLoading {
            ProgressView(NSLocalizedString("_albums_photos_loading_msg_", comment: ""))
        } else if let error = viewModel.errorMessage {
            Text(error)
                .refreshable {
                    viewModel.onPulledToRefresh()
                }
        } else if viewModel.photos.isEmpty {
            NoPhotosEmptyView(
                onAddPhotosIntent: handleAddPhotosIntent
            )
            .refreshable {
                viewModel.onPulledToRefresh()
            }
        } else {
            PhotosGridView(
                photos: viewModel.photos,
                onAddPhotosIntent: handleAddPhotosIntent
            )
            .refreshable {
                viewModel.onPulledToRefresh()
            }
        }
    }
    
    private func handleAddPhotosIntent() {
        viewModel.onAddPhotosIntent()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AlbumDetailsScreen(
            account: "120049010000000000682377",
            album: Album(
                href: "/Urlaub",
                lastPhotoId: "mountain",
                itemCount: 42,
                location: "Alps",
                dateRange: nil,
                collaborators: nil
            )
        )
    }
}
#endif
