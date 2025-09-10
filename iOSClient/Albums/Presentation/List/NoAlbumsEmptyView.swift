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
    
    private let contentPadding: CGFloat = 56.0
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ScrollView(.vertical) {
                
                ZStack(alignment: .top) {
                    
                    // Background image
                    Image("noAlbum")
                        .resizable()
                        .scaledToFill()
                        .frame(height: geometry.size.height * 0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Foreground content
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Spacer().frame(height: geometry.size.height * 0.4)
                        
                        Text("Create\nAlbums\nfor your\nPhotos")
                            .font(.system(size: 48, weight: .bold))
                            .padding(.horizontal, contentPadding)
                        
                        Text("You can organize all your photos in as many albums as you like. You haven't created an album yet.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, contentPadding)
                        
                        Button(action: onNewAlbumCreationIntent) {
                            Label("Create album", systemImage: "plus")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(NCBrandColor.shared.customer))
                        }
                        .padding(.horizontal, contentPadding)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, contentPadding)
                    .frame(minHeight: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
