//
//  AlbumDetailsScreen.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AlbumDetailsScreen: View {
    
    private let album: Album
    @StateObject private var viewModel: AlbumDetailsViewModel
    @State private var showMedia = false
    @State private var mediaReady = false
    @State private var pendingSelection: [String] = []
    
    init(account: String, album: Album) {
        self.album = album
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !viewModel.isLoading {
                    Button(action: handleAddPhotosIntent) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .tint(Color(NCBrandColor.shared.iconImageColor))

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
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .tint(Color(NCBrandColor.shared.iconImageColor))
                }
            }
        }
        .sheet(isPresented: $showMedia) {
            NavigationView {
                NCMediaHost(
                    storyboardName: "NCMedia",
                    sceneIdentifier: "NCMedia.storyboard",
                    isSelectionContext: true,
                    onLoaded: {
                        mediaReady = true
                    },
                    onSelectionChange: { files in
                        pendingSelection = files
                    }
                )
                .navigationTitle(NSLocalizedString("_albums_photo_selection_sheet_title_", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("_albums_photo_selection_sheet_back_btn_", comment: "")) {
                            // Dismiss by toggling the sheet state
                            showMedia = false
                        }
                        .foregroundColor(Color(NCBrandColor.shared.customer))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("_albums_photo_selection_sheet_done_btn_", comment: "")) {
                            viewModel.onPhotosSelected(selectedPhotos: pendingSelection)
                            showMedia = false
                        }
                        .foregroundColor(Color(NCBrandColor.shared.customer))
                    }
                }
            }
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
                localAccount: viewModel.account,
                photos: viewModel.photos,
                onAddPhotosIntent: handleAddPhotosIntent,
                album: album
            )
            .refreshable {
                viewModel.onPulledToRefresh()
            }
        }
    }
    
    private func handleAddPhotosIntent() {
        viewModel.onAddPhotosIntent()
        showMedia = true
    }
}

//#if DEBUG
//#Preview {
//    NavigationView {
//        AlbumDetailsScreen(
//            account: "120049010000000000682377",
//            album: Album(
//                href: "/Urlaub",
//                lastPhotoId: "mountain",
//                itemCount: 42,
//                location: "Alps",
//                dateRange: nil,
//                collaborators: nil
//            )
//        )
//    }
//}
//#endif

