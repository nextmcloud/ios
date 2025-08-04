//
//  Album.swift
//  Nextcloud
//
//  Created by Dhanesh on 28/07/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

public struct Album: Identifiable {
    public let id: String
    let href: String
    let name: String
    let lastPhotoId: String?
    let itemCount: Int?
    let location: String?
    let dateRange: String?
    let collaborators: String?
    
    init(
        href: String,
        lastPhotoId: String?,
        itemCount: Int?,
        location: String?,
        dateRange: String?,
        collaborators: String?
    ) {
        self.href = href
        
        if let lastComponent = href.split(separator: "/").last {
            self.name = lastComponent.removingPercentEncoding ?? String(lastComponent)
        } else {
            self.name = href
        }
        
        self.lastPhotoId = lastPhotoId
        self.itemCount = itemCount
        self.location = location
        self.dateRange = dateRange
        self.collaborators = collaborators
        self.id = href
    }
}
