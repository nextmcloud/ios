import SwiftUI
import UIKit

struct NCMediaViewRepresentable: UIViewControllerRepresentable {

    let photos: [AlbumPhoto]

    func makeUIViewController(context: Context) -> UIViewController {
        
        // 1) Instantiate NCMedia the same way the app does
                //    If it’s storyboard-based, use that; else, call the designated init.
                let mediaVC: UIViewController = {
                    let sb = UIStoryboard(name: "NCMedia", bundle: nil)
                    // Identifier must match your storyboard scene
                    return sb.instantiateInitialViewController() as! NCMedia
                }()

                // 2) Put it inside a UINavigationController (some flows assume navigationController exists)
                let nav = UINavigationController(rootViewController: mediaVC)
                nav.navigationBar.isHidden = true

                // 3) Put the nav inside a UITabBarController (some flows assume tabBarController exists)
                let tab = UITabBarController()
                tab.setViewControllers([nav], animated: false)

                // 4) Hide the visible tab bar so your UI looks clean
                tab.tabBar.isHidden = true
                tab.additionalSafeAreaInsets.bottom = 0

                return tab
        
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller if needed
    }
}
