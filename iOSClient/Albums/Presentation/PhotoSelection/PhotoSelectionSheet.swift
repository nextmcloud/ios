//
//  PhotoSelectionSheet.swift
//  Nextcloud
//
//  Created by Dhanesh on 04/09/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct PhotoSelectionSheet: View {
    
    let onPhotosSelected: ([String]) -> Void
    
    @State private var selectedPhotosCount: Int = 0 // TODO: Figure out how to get this count from NCMedia
    
    @State private var mediaVC: NCMedia?
    
    var body: some View {
        NavigationView {
            VStack {
                NCMediaViewRepresentable(ncMedia: $mediaVC)
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("Select items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        onPhotosSelected([])
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onPhotosSelected(mediaVC?.fileSelect ?? [])
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                
                //                ToolbarItemGroup(placement: .bottomBar) {
                //                    Text("\(selectedPhotosCount) items selected")
                //                        .font(.subheadline)
                //                        .foregroundColor(.secondary)
                //                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PhotoSelectionSheet(
        onPhotosSelected: { _ in }
    )
}
#endif
