//
//  ImprintViewController.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//


import UIKit
import WebKit

class ImprintViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = NSLocalizedString("_imprint_", comment: "")

        let myWebView:WKWebView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        myWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(myWebView)
        
        
        //1. Load web site into my web view
        let myURL = URL(string: "https://www.telekom.de/impressum")
        let myURLRequest:URLRequest = URLRequest(url: myURL!)
        NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: false)
        myWebView.load(myURLRequest)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NCUtility.shared.stopActivityIndicator()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        }
        if UIDevice.current.orientation.isFlat {
            print("Flat")
        } else {
            print("Portrait")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated  {
                if let url = navigationAction.request.url,
                    UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
    }
}
