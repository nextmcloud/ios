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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("_privacy_policy_", comment: "")
        
        // Do any additional setup after loading the view, typically from a nib.
        
        let myWebView:WKWebView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        self.view.addSubview(myWebView)
        
        
        //1. Load web site into my web view
        let myURL = URL(string: "https://static.magentacloud.de/privacy/datenschutzhinweise_app.htm")
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
}
