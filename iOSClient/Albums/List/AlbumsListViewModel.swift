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
    
    @Published var isNewAlbumCreationPopupVisible: Bool = false
    @Published var newAlbumName: String = ""
    @Published private(set) var newAlbumNameError: String? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(account: String) {
        self.account = account
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
    func loadAlbums() {
        
        guard !isLoading else { return } // Prevent double calls
        
        isLoading = true
        errorMessage = nil
        
        NextcloudKit.shared.fetchAllAlbums(for: account) { result in
            
            self.isLoading = false
            
            switch result {
            case .success(let albums):
                self.albums = albums
            case .failure(let error):
                //                self.errorMessage = error.localizedDescription
                self.errorMessage = "Unable to load albums. Please try again later!"
            }
        }
    }
    
    private func createNewAlbum(for name: String) {
        
    }
}
