//
//  NCAlbumCreationAlert.swift
//  Nextcloud
//
//  Created by Dhanesh on 05/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

extension View {
    
    func inputAlbumNameAlert(
        isPresented: Binding<Bool>,
        albumName: Binding<String>,
        error: String?,
        isForRenamingAlbum: Bool = false,
        onCreate: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        self.modifier(
            NCInputAlbumNameAlertModifier(
                isPresented: isPresented,
                albumName: albumName,
                isForRenamingAlbum: isForRenamingAlbum,
                error: error,
                onCreate: onCreate,
                onCancel: onCancel
            )
        )
    }
}

private struct NCInputAlbumNameAlertModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    @Binding var albumName: String
    
    let isForRenamingAlbum: Bool
    
    var error: String?
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    private let title: String
    private let description: String
    private let textFieldHint: String
    private let positiveButtonText: String
    private let negativeButtonText: String
    
    init(
        isPresented: Binding<Bool>,
        albumName: Binding<String>,
        isForRenamingAlbum: Bool,
        error: String? = nil,
        onCreate: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self._albumName = albumName
        self.isForRenamingAlbum = isForRenamingAlbum
        self.error = error
        self.onCreate = onCreate
        self.onCancel = onCancel
        
        if isForRenamingAlbum {
            title = "Rename Album"
            description = "Please enter new album name between 3 and 30 characters."
            textFieldHint = "Album's new name"
            positiveButtonText = "Rename"
            negativeButtonText = "Cancel"
        } else {
            title = "Create new Album"
            description = "Please enter an album name between 3 and 30 characters."
            textFieldHint = "Album's name"
            positiveButtonText = "Create"
            negativeButtonText = "Cancel"
        }
    }
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                TextField(textFieldHint, text: $albumName)
                
                Button(negativeButtonText, role: .cancel) {
                    onCancel()
                }
                
                Button(positiveButtonText) {
                    onCreate()
                }
                .disabled(error != nil)
            } message: {
                Text(description)
                    .foregroundColor(.secondary)
            }
    }
}

#if DEBUG
#Preview("Create button enabled") {
    ZStack {}
        .inputAlbumNameAlert(
            isPresented: .constant(true),
            albumName: .constant("Album 1"),
            error: nil,
            onCreate: {},
            onCancel: {}
        )
}

#Preview("Create button disabled") {
    ZStack {}
        .inputAlbumNameAlert(
            isPresented: .constant(true),
            albumName: .constant("Album 1"),
            error: "Enter a valid name!",
            onCreate: {},
            onCancel: {}
        )
}

#Preview("Renaming album") {
    ZStack {}
        .inputAlbumNameAlert(
            isPresented: .constant(true),
            albumName: .constant("Album 1"),
            error: "Enter a valid name!",
            isForRenamingAlbum: true,
            onCreate: {},
            onCancel: {}
        )
}
#endif
