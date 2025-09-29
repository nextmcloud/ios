//
//  AlbumDetailsViewModel.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import Foundation
import Combine
import NextcloudKit

class AlbumDetailsViewModel: ObservableObject {
    
    private let account: String
    private var album: Album
    
    @Published private(set) var screenTitle: String
    
    @Published private(set) var photos: [AlbumPhoto : tableMetadata?] = [:]
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    @Published var isLoadingPopupVisible: Bool = false
    
    @Published var isDeleteAlbumPopupVisible: Bool = false
    
    @Published var isRenameAlbumPopupVisible: Bool = false
    @Published var newAlbumName: String = ""
    @Published private(set) var newAlbumNameError: String? = nil
    
    @Published var isPhotoSelectionSheetVisible: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(account: String, album: Album) {
        self.account = account
        self.album = album
        self.screenTitle = album.name
        registerPublishers()
        loadAlbumPhotos()
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
    
    // MARK: - Popups
    // MARK: Delete Album
    func onDeleteAlbumIntent() {
        isDeleteAlbumPopupVisible = true
    }
    
    func onDeleteAlbumPopupCancel() {
        isDeleteAlbumPopupVisible = false
    }
    
    func onDeleteAlbumPopupConfirm() {
        isDeleteAlbumPopupVisible = false
        deleteAlbum()
    }
    
    // MARK: Rename Album
    func onRenameAlbumIntent() {
        isRenameAlbumPopupVisible = true
    }
    
    func onRenameAlbumPopupCancel() {
        newAlbumName = ""
        isRenameAlbumPopupVisible = false
    }
    
    func onRenameAlbumPopupConfirm() {
        isRenameAlbumPopupVisible = false
        renameAlbum()
    }
    
    // MARK: - APIs
    func onPulledToRefresh() {
        loadAlbumPhotos()
    }
    
    private func loadAlbumPhotos(
        doOnSuccess: (() -> Void)? = nil
    ) {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        NextcloudKit.shared.fetchAlbumPhotos(for: album.name, account: account) { [weak self] result in
            
            self?.isLoading = false
            
            switch result {
            case .success(let photos):
                self?.photos = Dictionary(uniqueKeysWithValues: photos.map { photo in
                    let meta = NCManageDatabase.shared.getMetadataFromFileId(photo.fileId)
                    return (photo.toAlbumPhoto(), meta)
                })
                doOnSuccess?()
                
            case .failure(let error):
                NCContentPresenter().showError(error: NKError(error: error))
                self?.errorMessage = NSLocalizedString("_albums_photos_error_msg_", comment: "")
            }
        }
    }
    
    func deleteAlbum() {
        
        guard !isLoadingPopupVisible else { return }
        
        isLoadingPopupVisible = true
        
        NextcloudKit.shared.deleteAlbum(
            albumName: album.name,
            account: account
        ) { [weak self] result in
            
            self?.isLoadingPopupVisible = false
            
            switch result {
            case .success():
                AlbumsManager.shared.syncAlbums()
                AlbumsNavigator.shared.pop()
                
            case .failure(let error):
                NCContentPresenter().showError(error: NKError(error: error))
            }
        }
    }
    
    func renameAlbum() {
        
        guard !isLoadingPopupVisible else { return }
        
        isLoadingPopupVisible = true
        
        NextcloudKit.shared.renameAlbum(account: account, from: album.name, to: newAlbumName) { [weak self] result in
            
            switch result {
            case .success():
                self?.reloadAlbumAfterRenaming(albumName: self?.newAlbumName ?? "")
                
            case .failure(let error):
                self?.isLoadingPopupVisible = false
                NCContentPresenter().showError(error: NKError(error: error))
            }
        }
    }
    
    private func reloadAlbumAfterRenaming(albumName: String) {
        
        AlbumsManager.shared.syncAlbums { [weak self] resultAlbums in
            
            self?.isLoadingPopupVisible = false
            
            if let newAlbum = resultAlbums.first(where: { $0.name == albumName }) {
                self?.album = newAlbum
                self?.loadAlbumPhotos {
                    self?.screenTitle = self?.album.name ?? ""
                    self?.newAlbumName = ""
                }
            }
        }
    }
    
    func onAddPhotosIntent() {
        isPhotoSelectionSheetVisible = true
    }
    
    func onPhotosSelected(selectedPhotos: [String]) {
        
        isPhotoSelectionSheetVisible = false
        
        if selectedPhotos.isEmpty {
            return
        }
        
        self.isLoadingPopupVisible = true
        
        for photo in selectedPhotos {
            
            let metadata: tableMetadata? = NCManageDatabase.shared.getMetadataFromOcId(photo)
            
            NextcloudKit.shared.copyPhotoToAlbum(
                account: account,
                sourcePath: metadata?.serveUrlFileName ?? photo,
                albumName: album.name,
                fileName: metadata?.fileName ?? photo
            ) { [weak self] result in
                
                self?.isLoadingPopupVisible = false
                
                switch result {
                case .success:
                    self?.loadAlbumPhotos()
                    AlbumsManager.shared.syncAlbums()
                    
                case .failure(let error):
                    NCContentPresenter().showError(error: NKError(error: error))
                }
            }
        }
    }
}
