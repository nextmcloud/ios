//
//  NoAlbumsEmptyView.swift
//  Nextcloud
//
//  Created by Dhanesh on 24/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct NoAlbumsEmptyView: View {
    
    let onNewAlbumCreationIntent: () -> Void
    
    private let contentPadding: CGFloat = 32.0
    
    var body: some View {
        
        ScrollView(.vertical) {
            
            VStack {
                
                // Background image
                Image("noAlbum")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    Text(NSLocalizedString("_albums_list_empty_heading_", comment: ""))
                        .font(.system(size: 48, weight: .bold))
                        .padding(.horizontal, contentPadding)
                    
                    Text(NSLocalizedString("_albums_list_empty_subheading_", comment: ""))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, contentPadding)
                    
                    Button(action: onNewAlbumCreationIntent) {
                        Label(NSLocalizedString("_albums_list_empty_new_album_btn_", comment: ""), systemImage: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(NCBrandColor.shared.customer))
                    }
                    .padding(.horizontal, contentPadding)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, contentPadding)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        NoAlbumsEmptyView(onNewAlbumCreationIntent: {})
            .navigationTitle("Album")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
