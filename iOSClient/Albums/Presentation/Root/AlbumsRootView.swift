//
//  AlbumsRootView.swift
//  Nextcloud
//
//  Created by Dhanesh on 24/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct AlbumsRootView: View {
    
    @Environment(\.localAccount) var localAccount: String
    
    @StateObject private var navigator = AlbumsNavigator.shared
    
    var body: some View {
        
        // TODO: Switch to NavigationStack once we hit iOS 16 base line
        NavigationView {
            AlbumsListScreen(
                viewModel: .init(account: localAccount)
            )
            .background(
                NavigationLink(
                    isActive: Binding(
                        get: { navigator.current != nil },
                        set: { value in
                            if !value { navigator.pop() }
                        }
                    )
                ) {
                    switch navigator.current {
                    case .albumDetails(let album):
                        AlbumDetailsScreen(
                            account: localAccount,
                            album: album
                        )
                    case .none:
                        EmptyView()
                    }
                } label: {
                    EmptyView()
                }
            )
        }
    }
}
