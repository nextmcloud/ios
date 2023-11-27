// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

enum VerticalLocation: String {
    case bottom
    case top
}

extension UIView {
    func makeCircularBackground(withColor backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = self.frame.size.width / 2
        self.layer.masksToBounds = true
    }

    /// Splits a filename into base name + extension across two labels to prevent
    /// Unicode bidi override attacks from visually disguising the real file extension.
    func setBidiSafeFilename(
        _ filename: String,
        isDirectory: Bool,
        titleLabel: UILabel?,
        extensionLabel: UILabel?
    ) {
        let nsName = filename as NSString
        let ext = nsName.pathExtension
        let base = nsName.deletingPathExtension

        if isDirectory || ext.isEmpty || base.isEmpty {
            titleLabel?.text = filename
            extensionLabel?.text = ""
            extensionLabel?.isHidden = true
        } else {
            titleLabel?.text = base
            extensionLabel?.text = "." + ext
            extensionLabel?.isHidden = false
        }
    }

    var parentTabBarController: UITabBarController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let tabBarController = nextResponder as? UITabBarController {
                return tabBarController
            }
            responder = nextResponder
        }
        return nil
    }
    
    func addShadow(location: VerticalLocation, height: CGFloat = 2, color: UIColor = NCBrandColor.shared.customerDarkGrey, opacity: Float = 0.4, radius: CGFloat = 2) {
        switch location {
        case .bottom:
             addShadow(offset: CGSize(width: 0, height: height), color: color, opacity: opacity, radius: radius)
        case .top:
            addShadow(offset: CGSize(width: 0, height: -height), color: color, opacity: opacity, radius: radius)
        }
    }

    func addShadow(offset: CGSize, color: UIColor = .black, opacity: Float = 0.5, radius: CGFloat = 5.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
    }
}
