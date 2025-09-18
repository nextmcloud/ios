//
//  NCMediaViewRepresentable.swift
//  Nextcloud
//
//  Created by Dhanesh on 05/09/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI
import UIKit

struct NCMediaViewRepresentable: UIViewControllerRepresentable {
    
    @Binding var ncMedia: NCMedia?
    
    let itemSelectionCountCallback: (Int) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        let sb = UIStoryboard(name: "NCMedia", bundle: nil)
        let media = sb.instantiateInitialViewController() as! NCMedia
        media.isInGeneralPhotosSelectionContext = true
        media.generalPhotosSelectionCountCallback = itemSelectionCountCallback
        
        DispatchQueue.main.async {
            self.ncMedia = media
        }
        
        let nav = UINavigationController(rootViewController: media)
        nav.navigationBar.isHidden = true
        
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
