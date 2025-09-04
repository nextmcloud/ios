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
    
    @State private var selectedPhotos: [String] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Your photo grid goes here
                Text("Photo grid here")
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("Objekte hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zurück") {
                        // dismiss action
                    }
                    .foregroundColor(.pink)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        onPhotosSelected(selectedPhotos)
                    }
                    .foregroundColor(.pink)
                }
                
                // ✅ Bottom bar toolbar group
                ToolbarItemGroup(placement: .bottomBar) {
                    Text("\(selectedPhotos.count) Objekte ausgewählt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Hinzufügen") {
                        onPhotosSelected(selectedPhotos)
                    }
                    .disabled(selectedPhotos.isEmpty)
                    .foregroundColor(.pink)
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
