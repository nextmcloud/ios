//
//  UIButton+Extension.swift
//  Nextcloud
//
//  Created by A200020526 on 30/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit

extension UIButton {

  func setBackgroundColor(_ color: UIColor, for forState: UIControl.State) {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
    UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let colorImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    self.setBackgroundImage(colorImage, for: forState)
  }
}

//  Created by Milen Pivchev on 17.12.24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//

extension UIButton {
    func hideButtonAndShowSpinner(tint: UIColor = .white) {
        self.isHidden = true

        let spinnerTag = Int(bitPattern: Unmanaged.passUnretained(self).toOpaque())
        if self.superview?.subviews.first(where: { view -> Bool in
            return view.isKind(of: UIActivityIndicatorView.self) && view.tag == spinnerTag
        }) != nil {
            return
        }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.tag = spinnerTag
        spinner.color = tint
        spinner.startAnimating()
        spinner.center = self.center
        self.superview?.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    func hideSpinnerAndShowButton() {
       let spinnerTag = Int(bitPattern: Unmanaged.passUnretained(self).toOpaque())
       let spinner = self.superview?.subviews.first(where: { view -> Bool in
           return view.isKind(of: UIActivityIndicatorView.self) && view.tag == spinnerTag
       })

       spinner?.removeFromSuperview()
       self.isHidden = false
    }
    
    func setBackgroundColor(_ color: UIColor, for forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}
