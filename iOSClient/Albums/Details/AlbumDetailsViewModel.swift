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
    let album: Album
    
    @Published private(set) var photos: [AlbumPhoto] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(account: String, album: Album) {
        self.account = account
        self.album = album
        //registerPublishers()
    }
    
    // MARK: - APIs
    func loadAlbumPhotos() {
        
        guard !isLoading else { return } // Prevent double calls
        
        isLoading = true
        errorMessage = nil
        
        NextcloudKit.shared.fetchAlbumPhotos(for: album.name, account: account) { result in
            
            self.isLoading = false
            
            switch result {
            case .success(let photos):
                self.photos = photos
            case .failure(let error):
                //                self.errorMessage = error.localizedDescription
                self.errorMessage = "Unable to load photos. Please try again later!"
            }
        }
    }
}
