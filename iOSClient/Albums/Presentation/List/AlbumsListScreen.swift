//
//  AlbumsListScreen.swift
//  Nextcloud
//
//  Created by A200118228 on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AlbumsListScreen: View {
    
    @Environment(\.localAccount) var localAccount: String
    
    @StateObject private var viewModel: AlbumsListViewModel
    
    init(viewModel: AlbumsListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        ZStack {
            content()
            
            if viewModel.isLoadingPopupVisible {
                NCLoadingAlert()
            }
        }
        .navigationTitle(NSLocalizedString("_albums_list_nav_title_", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("_albums_list_new_album_btn_", comment: "")) {
                    viewModel.onNewAlbumClick()
                }
                .foregroundColor(Color(NCBrandColor.shared.customer))
            }
        }
        .sheet(
            isPresented: $viewModel.isPhotoSelectionSheetVisible,
            onDismiss: {
                viewModel.onPhotosSelected(selectedPhotos: [])
            }
        ) {
            PhotoSelectionSheet(
                onPhotosSelected: viewModel.onPhotosSelected
            )
        }
        .inputAlbumNameAlert(
            isPresented: $viewModel.isNewAlbumCreationPopupVisible,
            albumName: $viewModel.newAlbumName,
            error: viewModel.newAlbumNameError,
            onCreate: viewModel.onNewAlbumPopupCreate,
            onCancel: viewModel.onNewAlbumPopupCancel
        )
    }
    
    @ViewBuilder
    private func content() -> some View {
        if viewModel.isLoading {
            ProgressView(NSLocalizedString("_albums_list_loading_msg_", comment: ""))
        } else if let error = viewModel.errorMessage {
            ScrollView(.vertical) {
                VStack {
                    Spacer()
                    Text(error)
                    Spacer()
                }
            }
            .refreshable {
                viewModel.onPulledToRefresh()
            }
        } else if viewModel.albums.isEmpty {
            NoAlbumsEmptyView(onNewAlbumCreationIntent: viewModel.onNewAlbumClick)
                .refreshable {
                    viewModel.onPulledToRefresh()
                }
        } else {
            AlbumsGridView(
                albums: viewModel.albums,
                onAlbumClicked: viewModel.onAlbumClicked
            )
            .refreshable {
                viewModel.onPulledToRefresh()
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AlbumsListScreen(viewModel: .init(account: "123"))
    }.onAppear {
        UIView
            .appearance(
                whenContainedInInstancesOf: [UIAlertController.self]
            ).tintColor = NCBrandColor.shared.customer
    }
}
#endif
