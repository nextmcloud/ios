//
//  UIView+Extension.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/12/2022.
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
import UIKit

enum VerticalLocation: String {
    case bottom
    case top
}

extension UIView {

    // Source
    // https://stackoverflow.com/questions/18680028/prevent-screen-capture-in-an-ios-app/67054892#67054892
    //
    // private weak var scrollView: UIScrollView! (it's an outlet)
    // self.view.preventScreenshot(for: self.scrollView)
    //
    func preventScreenshot(for view: UIView) {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        guard let hiddenView = textField.layer.sublayers?.first?.delegate as? UIView else {
            return
        }
        hiddenView.subviews.forEach { $0.removeFromSuperview() }
        hiddenView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(hiddenView)
        hiddenView.fillSuperview()
        hiddenView.addSubview(view)
    }

    func addBlur(style: UIBlurEffect.Style) {
        let blur = UIBlurEffect(style: style)
        let blurredEffectView = UIVisualEffectView(effect: blur)
        blurredEffectView.frame = self.bounds
        blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurredEffectView.isUserInteractionEnabled = false
        self.addSubview(blurredEffectView)
    }

    func insertBlur(style: UIBlurEffect.Style) {
        let blur = UIBlurEffect(style: style)
        let blurredEffectView = UIVisualEffectView(effect: blur)
        blurredEffectView.frame = self.bounds
        blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurredEffectView.isUserInteractionEnabled = false
        self.insertSubview(blurredEffectView, at: 0)
    }

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
