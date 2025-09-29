//
//  AddToAlbumsListView.swift
//  Nextcloud
//
//  Created by Mangesh Murhe on 25/09/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AddToAlbumsListView: View {
    
    @StateObject private var viewModel: AlbumsListViewModel
    @State private var selectedAlbum: Album? = nil
    var localAccount: String
    var onFinish: (Album) -> Void
    var onDismiss: () -> Void
    var onCreateAlbum: () -> Void
    
    init(viewModel: AlbumsListViewModel, localAccount: String, onFinish: @escaping (Album) -> Void, onDismiss: @escaping () -> Void, onCreateAlbum: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.localAccount = localAccount
        self.onFinish = onFinish
        self.onDismiss = onDismiss
        self.onCreateAlbum = onCreateAlbum
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section(header: Text(NSLocalizedString("_albums_list_own_albums_heading_", comment: ""))) {
                        ForEach(viewModel.albums) { album in
                            AlbumRow(album: album, localAccount: localAccount)
                                .onTapGesture {
                                    selectedAlbum = album
                                }
                                .listRowBackground(
                                            selectedAlbum?.id == album.id
                                                ? Color.accentColor.opacity(0.2)  // light blue highlight (default iOS tint)
                                                : Color.clear
                                        )
                            
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle(NSLocalizedString("_add_to_album", comment: ""), displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onDismiss) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(NSLocalizedString("_albums_photo_selection_sheet_back_btn_", comment: ""))
                            }.foregroundColor(Color(NCBrandColor.shared.customer))
                        }
                        .foregroundColor(.pink)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("_albums_photo_selection_sheet_done_btn_", comment: "")) {
                            if let selected = selectedAlbum {
                                onFinish(selected)
                            }
                        }
                        .foregroundColor(Color(NCBrandColor.shared.customer))
                        .opacity(selectedAlbum == nil ? 0.4 : 1.0)
                        .disabled(selectedAlbum == nil)
                    }
                }
                content()
            }
            .onAppear {
                AlbumsManager.shared.setAccount(localAccount)
                AlbumsManager.shared.syncAlbums()
            }
        }
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
            NoAlbumsEmptyView(onNewAlbumCreationIntent: onCreateAlbum)
                .refreshable {
                    viewModel.onPulledToRefresh()
                }
        }
    }
}

struct AlbumRow: View {
    let album: Album
    private enum ImageState { case loading, empty, thumbnail(UIImage) }
    @State private var imageState: ImageState = .loading
    var localAccount: String
    
    var body: some View {
        HStack {
            thumbnailView()
                .frame(width: 70, height: 50)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let subtitle = makeSubtitle(for: album), !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.systemGray))
                        .lineLimit(1)
                }
            }
        }
        .task(id: album.lastPhotoId) {
            await loadThumbnail()
        }
    }
    
    private func makeSubtitle(for album: Album) -> String? {
        guard let count = album.itemCount else { return nil }
        
        var parts: [String] = ["\(count) \(NSLocalizedString("_albums_list_entities_", comment: ""))"]
        
        if count > 0, let end = album.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append(formatter.string(from: end))
        }
        
        return parts.joined(separator: " - ")
    }
    
    /// Renders the thumbnail image based on the current state
    @ViewBuilder
    private func thumbnailView() -> some View {
        switch imageState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        case .empty:
            Image("EmptyAlbum")
                .resizable()
                .scaledToFill()
                .foregroundColor(.gray)
                .background(Color.gray.opacity(0.1))
        case .thumbnail(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        }
    }
    
    private func loadThumbnail() async {
        if album.lastPhotoId == "-1" || (album.itemCount ?? 0) == 0 {
            imageState = .empty
            return
        }
        guard let photoId = album.lastPhotoId else {
            imageState = .empty
            return
        }
        
        let result = await NCNetworking.shared.downloadPreview(
            fileId: photoId,
            etag: "",
            account: localAccount
        )
        
        if let data = result.responseData?.data, let image = UIImage(data: data) {
            await MainActor.run { imageState = .thumbnail(image) }
        } else {
            await MainActor.run { imageState = .empty }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AddToAlbumsListView(viewModel: .init(account: "123"), localAccount: "", onFinish: { selectedAlbum in
            print("Album:\(selectedAlbum)")
        }, onDismiss: {
           
        }) {
            
        }
    }.onAppear {
        UIView
            .appearance(
                whenContainedInInstancesOf: [UIAlertController.self]
            ).tintColor = NCBrandColor.shared.customer
    }
}
#endif
