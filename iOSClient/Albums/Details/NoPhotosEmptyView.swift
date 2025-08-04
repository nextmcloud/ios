//
//  NoPhotosEmptyView.swift
//  Nextcloud
//
//  Created by Dhanesh on 29/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct NoPhotosEmptyView: View {
    
    let onAddPhotosIntent: () -> Void
    
    private let contentPadding: CGFloat = 56.0
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ScrollView(.vertical) {
                
                ZStack(alignment: .top) {
                    
                    // Background image
                    Image("emptyAlbum")
                        .resizable()
                        .scaledToFill()
                        .frame(height: geometry.size.height * 0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Foreground content
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Spacer().frame(height: geometry.size.height * 0.4)
                        
                        Text("All that's\nmissing are\nyour photos")
                            .font(.system(size: 48, weight: .bold))
                            .padding(.horizontal, contentPadding)
                        
                        Text("You can add as many photos as you like. A photo can also belong to more than one album.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, contentPadding)
                        
                        Button(action: onAddPhotosIntent) {
                            Label("Add photos", systemImage: "plus")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", action: onAddPhotosIntent)
                    .foregroundColor(Color(NCBrandColor.shared.customer))
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        NoPhotosEmptyView(onAddPhotosIntent: {})
            .navigationTitle("Album")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
