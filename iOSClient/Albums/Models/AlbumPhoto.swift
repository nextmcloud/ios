//
//  AlbumPhoto.swift
//  Nextcloud
//
//  Created by Dhanesh on 01/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

public struct AlbumPhoto: Identifiable {
    public let id: String
    let fileName: String
    let contentType: String
    let contentLength: Int
    let lastModified: Date
    let hasPreview: Bool
    let isHidden: Bool
    let isFavorite: Bool
    let permissions: String
    let originalDateTime: Date?
    let width: Int?
    let height: Int?
    
    init(
        fileId: String,
        fileName: String,
        contentType: String,
        contentLength: Int,
        lastModified: Date,
        hasPreview: Bool,
        isHidden: Bool,
        isFavorite: Bool,
        permissions: String,
        originalDateTime: Date?,
        width: Int?,
        height: Int?
    ) {
        self.id = fileId
        self.fileName = fileName
        self.contentType = contentType
        self.contentLength = contentLength
        self.lastModified = lastModified
        self.hasPreview = hasPreview
        self.isHidden = isHidden
        self.isFavorite = isFavorite
        self.permissions = permissions
        self.originalDateTime = originalDateTime
        self.width = width
        self.height = height
    }
}
