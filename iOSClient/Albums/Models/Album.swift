//
//  Album.swift
//  Nextcloud
//
//  Created by Dhanesh on 28/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

public struct Album: Identifiable {
    public let id = UUID()
    let name: String
    let lastPhotoId: String?
    let itemCount: Int?
    let location: String?
    let dateRange: String?
    let collaborators: String?
}
