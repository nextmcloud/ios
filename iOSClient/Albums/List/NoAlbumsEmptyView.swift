//
//  NoAlbumsEmptyView.swift
//  Nextcloud
//
//  Created by Dhanesh on 24/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct NoAlbumsEmptyView: View {
    
    var onNewAlbumCreationIntent: () -> Void
    
    private let contentPadding: CGFloat = 64.0
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Image("noAlbum")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .accessibility(hidden: true)
                
                Text("Create\nAlbums\nfor your\nPhotos")
                    .font(.system(size: 58, weight: .bold))
                    .padding(.horizontal, contentPadding)
                
                Text("You can organize all your photos in as many albums as you like. You haven't created an album yet.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, contentPadding)
                
                Button(action: onNewAlbumCreationIntent) {
                    Label("Create album", systemImage: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                .padding(.horizontal, contentPadding)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NoAlbumsEmptyView(onNewAlbumCreationIntent: {})
}
#endif
