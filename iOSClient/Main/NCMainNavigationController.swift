//
//  NCMainNavigationController.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 17/10/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class NCMainNavigationController: UINavigationController {
    
    var isPushing = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCBrandGlobal.shared.notificationCenterChangeTheming), object: nil)
        
        changeTheming()
    }

    /*
    // https://stackoverflow.com/questions/37829721/pushing-view-controller-twice
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if !isPushing {
            isPushing = true
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.isPushing = false
            }
            super.pushViewController(viewController, animated: animated)
            CATransaction.commit()
        }
    }
    */
    
    @objc func changeTheming() {
                  
        if #available(iOS 13.0, *) {
            
            var navBarAppearance = UINavigationBarAppearance()
            
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : NCBrandColor.shared.textView]
            navBarAppearance.backgroundColor = NCBrandColor.shared.backgroundView
            
            navBarAppearance = UINavigationBarAppearance()
            
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : NCBrandColor.shared.textView]
//            let attributedText = NSMutableAttributedString(string: heading, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20)])
//
//            attributedText.append(NSAttributedString(string: content, attributes: [NSAttributedStringKey.font: UIFont.SystemFont(ofSize: 15), NSAttributedStringKey.foregroundColor: UIColor.blue]))
//
//            navBarAppearance.titleTextAttributes.attributedText = attributedText
            
            navBarAppearance.backgroundColor = NCBrandColor.shared.tabBar

            navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationBar.standardAppearance = navBarAppearance
            
        } else {
            
            navigationBar.barStyle = .default
            navigationBar.barTintColor = NCBrandColor.shared.backgroundView
            navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:NCBrandColor.shared.textView]
            navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:NCBrandColor.shared.textView]
        }
        
        navigationBar.tintColor = NCBrandColor.shared.brandElement
        navigationBar.setNeedsLayout()
    }
}
