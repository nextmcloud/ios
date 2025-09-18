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
    
    @State private var selectedPhotosCount: Int = 0
    
    @State private var mediaVC: NCMedia?
    
    var body: some View {
        NavigationView {
            VStack {
                NCMediaViewRepresentable(
                    ncMedia: $mediaVC,
                    itemSelectionCountCallback: { count in
                        selectedPhotosCount = count
                    }
                ).frame(maxHeight: .infinity)
            }
            .navigationTitle(NSLocalizedString("_albums_photo_selection_sheet_title_", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("_albums_photo_selection_sheet_back_btn_", comment: "")) {
                        onPhotosSelected([])
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("_albums_photo_selection_sheet_done_btn_", comment: "")) {
                        onPhotosSelected(mediaVC?.fileSelect ?? [])
                    }
                    .foregroundColor(Color(NCBrandColor.shared.customer))
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    let quantifyingString = (selectedPhotosCount == 1)
                    ? NSLocalizedString("_albums_photo_selection_sheet_item_selected_", comment: "")
                    : NSLocalizedString("_albums_photo_selection_sheet_items_selected_", comment: "")
                    
                    Text("\(selectedPhotosCount) \(quantifyingString)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
