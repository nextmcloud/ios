//
//  AlbumsRootView.swift
//  Nextcloud
//
//  Created by A200118228 on 07/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI
import SVGKit

struct AlbumsListScreen: View {
    
    @StateObject private var viewModel: AlbumsListViewModel
    
    init(viewModel: AlbumsListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        Group {
            if viewModel.isLoading {
                ProgressView("Loading albums...")
            } else if let error = viewModel.errorMessage {
                Text(error)
            } else if viewModel.albums.isEmpty {
                NoAlbumsEmptyView(onNewAlbumCreationIntent: {
                    viewModel.onNewAlbumClick()
                })
            } else {
                AlbumsGridView(albums: viewModel.albums)
            }
        }
        .navigationTitle("Albums")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New") {
                    viewModel.onNewAlbumClick()
                }
                .foregroundColor(Color(NCBrandColor.shared.customer))
            }
        }
        .alert(
            "Create new Album",
            isPresented: $viewModel.isNewAlbumCreationPopupVisible
        ) {
            
            TextField("Album's name", text: $viewModel.newAlbumName)
            
            Button("Cancel", role: .cancel) {
                viewModel.onNewAlbumPopupCancel()
            }
            
            Button("Create") {
                viewModel.onNewAlbumPopupCreate()
            }
            .disabled(viewModel.newAlbumNameError != nil)
        } message: {
            Text("Please enter an album name between 3 and 30 characters.")
                .foregroundColor(.secondary)
        }
        .onAppear {
            viewModel.loadAlbums()
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
