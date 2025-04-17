//
//  NCLoginWeb.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 21/08/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
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

import UIKit
import WebKit
import NextcloudKit
import FloatingPanel

class NCLoginWeb: UIViewController {

    var webView: WKWebView?
    var newWebView: WKWebView?

    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    let utility = NCUtility()

    var titleView: String = ""

    var urlBase = ""
    var user: String?

    var configServerUrl: String?
    var configUsername: String?
    var configPassword: String?
    var configAppPassword: String?

    var loginFlowV2Available = false
    var loginFlowV2Token = ""
    var loginFlowV2Endpoint = ""
    var loginFlowV2Login = ""

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let accountCount = NCManageDatabase.shared.getAccounts()?.count ?? 0

        // load AppConfig
        if (NCBrandOptions.shared.disable_multiaccount == false) || (NCBrandOptions.shared.disable_multiaccount == true && accountCount == 0) {
            if let configurationManaged = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed"), NCBrandOptions.shared.use_AppConfig {

                if let serverUrl = configurationManaged[NCGlobal.shared.configuration_serverUrl] as? String {
                    self.configServerUrl = serverUrl
                }
                if let username = configurationManaged[NCGlobal.shared.configuration_username] as? String, !username.isEmpty, username.lowercased() != "username" {
                    self.configUsername = username
                }
                if let password = configurationManaged[NCGlobal.shared.configuration_password] as? String, !password.isEmpty, password.lowercased() != "password" {
                    self.configPassword = password
                }
                if let apppassword = configurationManaged[NCGlobal.shared.configuration_apppassword] as? String, !apppassword.isEmpty, apppassword.lowercased() != "apppassword" {
                    self.configAppPassword = apppassword
                }
            }
        }

        if (NCBrandOptions.shared.use_login_web_personalized || NCBrandOptions.shared.use_AppConfig) && accountCount > 0 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.closeView(sender:)))
        }

        if accountCount > 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "users")!.image(color: .label, size: 35), style: .plain, target: self, action: #selector(self.changeUser(sender:)))
        }

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView!.navigationDelegate = self
//        webView!.uiDelegate = self
        view.addSubview(webView!)

        webView!.translatesAutoresizingMaskIntoConstraints = false
        webView!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        webView!.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        webView!.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        webView!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true

        // AppConfig
        if let serverUrl = configServerUrl {
            if let username = self.configUsername, let password = configAppPassword {
                self.createAccount(urlBase: serverUrl, user: username, password: password)
                return
            } else if let username = self.configUsername, let password = configPassword {
                getAppPassword(urlBase: serverUrl, user: username, password: password)
                return
            } else {
                urlBase = serverUrl
            }
        }

        // ADD end point for Web Flow
        if urlBase != NCBrandOptions.shared.linkloginPreferredProviders {
            if loginFlowV2Available {
                urlBase = loginFlowV2Login
            } else {
                urlBase += "/index.php/login/flow"
                if let user = self.user {
                    urlBase += "?user=\(user)"
                }
            }
        }

        if let url = URL(string: urlBase) {
            loadWebPage(webView: webView!, url: url)
        } else {
            let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_login_url_error_")
            NCContentPresenter().showError(error: error, priority: .max)
        }

        if #available(iOS 13, *) {
            let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
            let statusBar = UIView(frame: (keyWindow?.windowScene?.statusBarManager?.statusBarFrame)!)
            statusBar.backgroundColor = NCBrandColor.shared.customer
            keyWindow?.addSubview(statusBar)
        } else {
            if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
                statusBar.backgroundColor = NCBrandColor.shared.customer
            }
        }
        self.navigationController?.navigationBar.backgroundColor = NCBrandColor.shared.customer
        self.edgesForExtendedLayout = [] // iphone 16, white gap between navigaiton and status bar.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Stop timer error network
        appDelegate.timerErrorNetworking?.invalidate()

        if let account = NCManageDatabase.shared.getActiveTableAccount(), NCKeychain().getPassword(account: account.account).isEmpty {

            let message = "\n" + NSLocalizedString("_password_not_present_", comment: "")
            let alertController = UIAlertController(title: titleView, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
            present(alertController, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NCActivityIndicator.shared.stop()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Start timer error network
        appDelegate.startTimerErrorNetworking()
    }

    func loadWebPage(webView: WKWebView, url: URL) {

        let language = NSLocale.preferredLanguages[0] as String
        var request = URLRequest(url: url)

        if let deviceName = "\(UIDevice.current.name) (\(NCBrandOptions.shared.brand) iOS)".cString(using: .utf8),
            let deviceUserAgent = String(cString: deviceName, encoding: .ascii) {
            webView.customUserAgent = deviceUserAgent
        } else {
            webView.customUserAgent = userAgent
        }

        request.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
        request.addValue(language, forHTTPHeaderField: "Accept-Language")

        webView.load(request)
    }

    func getAppPassword(urlBase: String, user: String, password: String) {
        
        NextcloudKit.shared.getAppPassword(url: urlBase, user: user, password: password) { token, _, error in
            if error == .success, let password = token {
                self.createAccount(urlBase: urlBase, user: user, password: password)
            } else {
                NCContentPresenter().showError(error: error)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc func closeView(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func changeUser(sender: UIBarButtonItem) {
//        toggleMenu()
    }
}

extension NCLoginWeb: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {

        guard let url = webView.url else { return }

        let urlString: String = url.absoluteString.lowercased()

        // prevent http redirection
        if urlBase.lowercased().hasPrefix("https://") && urlString.lowercased().hasPrefix("http://") {
            let alertController = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: NSLocalizedString("_prevent_http_redirection_", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in
                _ = self.navigationController?.popViewController(animated: true)
            }))
            self.present(alertController, animated: true)
            return
        }

        if urlString.hasPrefix(NCBrandOptions.shared.webLoginAutenticationProtocol) == true && urlString.contains("login") == true {

            var server: String = ""
            var user: String = ""
            var password: String = ""

            let keyValue = url.path.components(separatedBy: "&")
            for value in keyValue {
                if value.contains("server:") { server = value }
                if value.contains("user:") { user = value }
                if value.contains("password:") { password = value }
            }

            if !server.isEmpty, !user.isEmpty, !password.isEmpty {

                let server: String = server.replacingOccurrences(of: "/server:", with: "")
                let username: String = user.replacingOccurrences(of: "user:", with: "").replacingOccurrences(of: "+", with: " ")
                let password: String = password.replacingOccurrences(of: "password:", with: "")

                self.createAccount(urlBase: server, user: username, password: password)

            }
        }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        DispatchQueue.global().async {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 403 {
//                showAccessDeniedAlert()
                closeApp()
                decisionHandler(.cancel) // Stop loading the page
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    
    // Show an alert instead of closing the app
    private func showAccessDeniedAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Access Denied", message: "You are not authorized to view this page.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                // Optionally, redirect user
                self.webView?.load(URLRequest(url: URL(string: "https://www.google.com")!))
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NCActivityIndicator.shared.startActivity(style: .medium, blurEffect: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        NCActivityIndicator.shared.stop()

        if loginFlowV2Available {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NextcloudKit.shared.getLoginFlowV2Poll(token: self.loginFlowV2Token, endpoint: self.loginFlowV2Endpoint) { server, loginName, appPassword, _, error in
                    if error == .success && server != nil && loginName != nil && appPassword != nil {
                        self.createAccount(urlBase: server!, user: loginName!, password: appPassword!)
                    }
                }
            }
        }
    }
    

    private func closeApp() {
        // Exit the app immediately
        exit(0)
    }


    // MARK: -
    
    func createAccount(urlBase: String, user: String, password: String) {
        let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
        if let host = URL(string: urlBase)?.host {
            NCNetworking.shared.writeCertificate(host: host)
        }
        NCAccount().createAccount(urlBase: urlBase, user: user, password: password, controller: controller) { account, error in
            if error == .success {
                let window = UIApplication.shared.firstWindow
                if let controller = window?.rootViewController as? NCMainTabBarController {
                    controller.account = account
                    self.dismiss(animated: true)
                } else {
                    if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? NCMainTabBarController {
                        AnalyticsHelper.shared.trackUserData()
                        controller.account = account
                        controller.modalPresentationStyle = .fullScreen
                        controller.view.alpha = 0

                        window?.rootViewController = controller
                        window?.makeKeyAndVisible()

                        if let scene = window?.windowScene {
                            SceneManager.shared.register(scene: scene, withRootViewController: controller)
                        }

                        UIView.animate(withDuration: 0.5) {
                            controller.view.alpha = 1
                        }
                    }
                }
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: error.errorDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
                self.present(alertController, animated: true)
            }
        }
    }
    
}
