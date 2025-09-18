//
//  AlbumsViewModel.swift
//  Nextcloud
//
//  Created by A200118228 on 08/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import Foundation
import Combine
import NextcloudKit

class AlbumsListViewModel: ObservableObject {
    
    private var account: String
    
    @Published private(set) var albums: [Album] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    @Published var isLoadingPopupVisible: Bool = false
    
    @Published var isNewAlbumCreationPopupVisible: Bool = false
    @Published var newAlbumName: String = ""
    @Published private(set) var newAlbumNameError: String? = nil
    
    @Published var isPhotoSelectionSheetVisible: Bool = false
    @Published var newlyCreatedAlbum: Album? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(account: String) {
        self.account = account
        observeAlbums()
        registerPublishers()
    }
    
    // MARK: - Subscriptions
    private func observeAlbums() {
        AlbumsManager.shared.albumsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle:
                    self?.isLoading = false
                case .loading:
                    self?.isLoading = true
                    self?.errorMessage = nil
                case .success(let albums):
                    self?.isLoading = false
                    self?.albums = albums
                case .failure:
                    self?.isLoading = false
                    self?.errorMessage = NSLocalizedString("_albums_list_error_msg_", comment: "")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Album name validation
    private func registerPublishers() {
        $newAlbumName
            .removeDuplicates()
            .sink { [weak self] name in
                guard let self = self else { return }
                self.newAlbumNameError = self.validateAlbumName(name).first
            }
            .store(in: &cancellables)
    }
    
    private func validateAlbumName(_ name: String) -> [String] {
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return [NSLocalizedString("_albums_list_album_name_validation_nonempty_", comment: "")]
        } else if trimmed.count < 3 {
            return [NSLocalizedString("_albums_list_album_name_validation_min_length_", comment: "")]
        } else if trimmed.count > 30 {
            return [NSLocalizedString("_albums_list_album_name_validation_max_length_", comment: "")]
        } else if trimmed.contains("/") || trimmed.contains("\\") {
            return [NSLocalizedString("_albums_list_album_name_validation_specials_", comment: "")]
        }
        
        return []
    }
    
    // MARK: - Events
    func onAlbumClicked(_ album: Album) {
        AlbumsNavigator.shared.push(.albumDetails(album: album))
    }
    
    // MARK: - Album name popup
    func onNewAlbumClick() {
        isNewAlbumCreationPopupVisible = true
    }
    
    func onNewAlbumPopupCancel() {
        newAlbumName = ""
        isNewAlbumCreationPopupVisible = false
    }
    
    func onNewAlbumPopupCreate() {
        
        //        let errors = validateAlbumName(newAlbumName)
        //        guard errors.isEmpty else {
        //            newAlbumNameError = errors.first
        //            return
        //        } // TODO: For more defensive coding
        
        
        isNewAlbumCreationPopupVisible = false
        createNewAlbum(for: newAlbumName)
        newAlbumName = ""
    }
    
    // MARK: - APIs
    func onPulledToRefresh() {
        AlbumsManager.shared.syncAlbums()
    }
    
    private func createNewAlbum(for name: String) {
        
        guard !isLoadingPopupVisible else { return }
        
        isLoadingPopupVisible = true
        
        NextcloudKit.shared.createNewAlbum(for: account, albumName: name) { [weak self] result in
            
            self?.isLoadingPopupVisible = false
            
            switch result {
            case .success(_):
                
                AlbumsManager.shared.syncAlbums { [weak self] resultAlbums in
                    if let newAlbum = resultAlbums.first(where: { $0.name == name }) {
                        self?.newlyCreatedAlbum = newAlbum
                        self?.isPhotoSelectionSheetVisible = true
                    }
                }
                
            case .failure(let error):
                NCContentPresenter().showError(error: NKError(error: error))
            }
        }
    }
    
    func onPhotosSelected(selectedPhotos: [String]) {
        
        isPhotoSelectionSheetVisible = false
        
        guard let album = newlyCreatedAlbum else { return }
        
        if selectedPhotos.isEmpty {
            AlbumsNavigator.shared.push(.albumDetails(album: album))
            return
        }
        
        for photo in selectedPhotos {
            
            let metadata: tableMetadata? = NCManageDatabase.shared.getMetadataFromOcId(photo)
            
            NextcloudKit.shared.copyPhotoToAlbum(
                account: account,
                sourcePath: metadata?.serveUrlFileName ?? photo,
                albumName: album.name,
                fileName: metadata?.fileName ?? photo,
            ) { result in
                
                switch result {
                case .success:
                    AlbumsNavigator.shared.push(.albumDetails(album: album))
                    AlbumsManager.shared.syncAlbums()
                    
                case .failure(let error):
                    NCContentPresenter().showError(error: NKError(error: error))
                }
            }
        }
    }
}
