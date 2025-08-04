//
//  PhotosGridView.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct PhotosGridView: View {
    
    let photos: [AlbumPhoto]
    
    var body: some View {
        content()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button(action: {
                            // Regular add action
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        // Overflow menu
                        Menu {
                            Button("Rename", action: {
                                // Rename action
                            })
                            Button("Delete", role: .destructive, action: {
                                // Delete action
                            })
                        } label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                        }
                    }
                }
            }
    }
    
    @ViewBuilder
    private func content() -> some View {
        Color(.blue)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        PhotosGridView(photos: [])
            .navigationTitle("Album 2")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
