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
    
    var body: some View {
        
        NavigationView {
            AlbumsListScreen(
                viewModel: .init(account: localAccount)
            )
        }
    }
}
