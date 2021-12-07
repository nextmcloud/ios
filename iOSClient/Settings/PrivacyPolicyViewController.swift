//
//  PrivacyPolicyViewController.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation

import UIKit
import WebKit
class PrivacyPolicyViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var myWebView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("_privacy_policy_", comment: "")
        
        // Do any additional setup after loading the view, typically from a nib.
        
        myWebView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        myWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(myWebView)
        
        
        //1. Load web site into my web view
        let myURL = URL(string: "https://static.magentacloud.de/privacy/datenschutzhinweise_app.htm")
        let myURLRequest:URLRequest = URLRequest(url: myURL!)
        NCUtility.shared.startActivityIndicator(backgroundView: self.view, blurEffect: false)
        myWebView.load(myURLRequest)
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.brand

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        myWebView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NCUtility.shared.stopActivityIndicator()
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
