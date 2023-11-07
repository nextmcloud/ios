//
//  HelpViewController.swift
//  Nextcloud
//
//  Created by A200073704 on 11/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import UIKit
import WebKit

class HelpViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = NSLocalizedString("_help_", comment: "")
        let myWebView:WKWebView = WKWebView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height))
        myWebView.uiDelegate = self
        myWebView.navigationDelegate = self
        myWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(myWebView)
        
        
        //1. Load web site into my web view
        let myURL = URL(string: "https://cloud.telekom-dienste.de/hilfe")
        let myURLRequest:URLRequest = URLRequest(url: myURL!)
        NCActivityIndicator.shared.start()
        myWebView.load(myURLRequest)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NCActivityIndicator.shared.stop()
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

