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
        
        // Try to instantiate the initial VC as NCMedia safely
        if let media = sb.instantiateInitialViewController() as? NCMedia {
            media.isInGeneralPhotosSelectionContext = true

            // Publish the media controller back to the binding on the next runloop turn
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
        } else {
            // Fallback: Provide an empty container to avoid crashing when NCMedia isn't available
            #if DEBUG
            print("Error: Could not instantiate NCMedia from storyboard 'NCMedia'. Falling back to empty container.")
            #endif

            // Ensure binding reflects the absence of a media controller
            DispatchQueue.main.async {
                self.ncMedia = nil
            }

            let empty = UIViewController()
            empty.view.backgroundColor = .systemBackground

            let nav = UINavigationController(rootViewController: empty)
            nav.navigationBar.isHidden = true

            let tab = UITabBarController()
            tab.setViewControllers([nav], animated: false)
            tab.tabBar.isHidden = true
            tab.additionalSafeAreaInsets.bottom = 0

            return tab
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
