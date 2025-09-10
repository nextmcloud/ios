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
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        let sb = UIStoryboard(name: "NCMedia", bundle: nil)
        let media = sb.instantiateInitialViewController() as! NCMedia
        media.isInGeneralPhotosSelectionContext = true
        
        DispatchQueue.main.async {
            self.ncMedia = media
        }
        
        let nav = UINavigationController(rootViewController: media)
        nav.navigationBar.isHidden = true
        
        let tab = UITabBarController()
        tab.setViewControllers([nav], animated: false)
        tab.tabBar.isHidden = true
        tab.additionalSafeAreaInsets.bottom = 0
        
        return tab
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
