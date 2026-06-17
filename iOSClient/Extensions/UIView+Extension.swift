// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

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

    func addBlur(style: UIBlurEffect.Style, alpha: CGFloat = 1.0) {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = alpha
        blurView.layer.masksToBounds = true
        insertSubview(blurView, at: 0)
    }

    func addBlurBackground(style: UIBlurEffect.Style, alpha: CGFloat = 1) {
        let blur = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.isUserInteractionEnabled = false
        blurView.alpha = alpha
        blurView.layer.masksToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
