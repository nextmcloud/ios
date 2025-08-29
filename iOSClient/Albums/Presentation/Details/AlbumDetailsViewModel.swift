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
    
    @Published private(set) var photos: [AlbumPhoto] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    @Published var isLoadingPopupVisible: Bool = false
    
    @Published var isDeleteAlbumPopupVisible: Bool = false
    
    @Published var isRenameAlbumPopupVisible: Bool = false
    @Published var newAlbumName: String = ""
    @Published private(set) var newAlbumNameError: String? = nil
    
    let goBack = PassthroughSubject<Void, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(account: String, album: Album) {
        self.account = account
        self.album = album
        self.screenTitle = album.name
        registerPublishers()
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
            return ["Album name cannot be empty."]
        } else if trimmed.count < 3 {
            return ["Album name must be at least 3 characters."]
        } else if trimmed.count > 30 {
            return ["Album name cannot be more than 30 characters."]
        } else if trimmed.contains("/") || trimmed.contains("\\") {
            return ["Album name cannot contain slashes."]
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
    func loadAlbumPhotos(
        doOnSuccess: (() -> Void)? = nil
    ) {
        
        guard !isLoading else { return } // Prevent double calls
        
        isLoading = true
        errorMessage = nil
        
        NextcloudKit.shared.fetchAlbumPhotos(for: album.name, account: account) { [weak self] result in
            
            self?.isLoading = false
            
            switch result {
            case .success(let photos):
                self?.photos = photos.toAlbumPhotos()
                if let callback = doOnSuccess {
                    callback()
                }
                
            case .failure(let error):
                NCContentPresenter().showError(error: NKError(error: error))
                self?.errorMessage = "Unable to load photos. Please try again later!"
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
                self?.goBack.send()
                
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
        
        NextcloudKit.shared.fetchAllAlbums(for: account) { [weak self] result in
            
            self?.isLoadingPopupVisible = false
            
            switch result {
            case .success(let albums):
                
                if let newAlbum = albums.toAlbums().first(where: { $0.name == albumName }) {
                    self?.album = newAlbum
                    self?.loadAlbumPhotos {
                        self?.screenTitle = self?.album.name ?? ""
                        self?.newAlbumName = ""
                    }
                }
                
            case .failure(let error):
                NCContentPresenter().showError(error: NKError(error: error))
                self?.isLoadingPopupVisible = false
            }
        }
    }
}
