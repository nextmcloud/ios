//
//  NCViewerMediaPageWrapper.swift
//  Nextcloud
//
//  Created by Dhanesh on 04/09/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct NCViewerMediaPageWrapper: UIViewControllerRepresentable {
    
    let ocIds: [String]
    let metadatas: [tableMetadata]
    let currentIndex: Int
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        guard let viewerMediaPageContainer = UIStoryboard(
            name: "NCViewerMediaPage",
            bundle: nil
        ).instantiateInitialViewController() as? NCViewerMediaPage else {
            return UIViewController()
        }
        
        viewerMediaPageContainer.currentIndex = currentIndex
        viewerMediaPageContainer.ocIds = ocIds
        viewerMediaPageContainer.metadatas = metadatas
        
        return viewerMediaPageContainer
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
