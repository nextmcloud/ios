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
import SVGKit

class AlbumsListViewModel: ObservableObject {
    
    private var account: String
    
    init(account: String) {
        self.account = account
    }
    
    @Published var albums: [Album] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadAlbums() {
        
        isLoading = true
        errorMessage = nil
        
        NextcloudKit.shared.fetchAllAlbums(for: account) { result in
            
            self.isLoading = false
            
            switch result {
            case .success(let albums):
                self.albums = albums
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
