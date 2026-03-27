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
                // Ensure mediaVC exists and is loaded even if Media tab wasn't opened yet
//                if mediaVC == nil {
//                    let newMedia = NCMedia()
//                    mediaVC = newMedia
//                    Task { await newMedia.loadDataSource() }
//                } else if let existing = mediaVC {
//                    // If already present, ensure its data source is loaded/refreshed
//                    Task { await existing.loadDataSource() }
//                    .onAppear {
//                        // Ensure NCMedia is preloaded and available even if Media tab wasn't opened yet
//                        NCMediaPreloader.shared.preloadIfNeeded()
//                        if let preloaded = NCMediaPreloader.shared.getPreloaded() {
//                            // Bind the preloaded controller to the sheet
//                            self.mediaVC = preloaded
//                            // Reset any filters to show all items in selection context
//                            preloaded.showOnlyImages = false
//                            preloaded.showOnlyVideos = false
//                            // Trigger a full refresh of data and UI content
//                            Task {
//                                await preloaded.loadDataSource()
//                                await preloaded.searchMediaUI(true)
//                            }
//                        }
//                    }
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
                
            }
            .onChange(of: mediaVC?.fileSelect ?? []) { newValue in
                selectedPhotosCount = newValue.count
            }
        }
    }
}
//
//#if DEBUG
//#Preview {
//    PhotoSelectionSheet(
//        onPhotosSelected: { _ in }
//    )
//}
//#endif

