// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Iva Horn
// SPDX-FileCopyrightText: 2025 Milen Pivchev
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import WebKit
import NextcloudKit
import FloatingPanel

protocol NCLoginProviderDelegate: AnyObject {
    ///
    /// Called when the back button is tapped in the login provider view.
    ///
    func onBack()
}

///
/// View which presents the web view to login at a Nextcloud instance.
///
class NCLoginProvider: UIViewController {
    var webView: WKWebView?
    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    let utility = NCUtility()
    var titleView: String = ""
    var initialURLString = ""
    var uiColor: UIColor = .white
    weak var delegate: NCLoginProviderDelegate?
    var controller: NCMainTabBarController?

    ///
    /// A polling loop active in the background to check for the current status of the login flow.
    ///
    var pollingTask: Task<Void, any Error>?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        nkLog(debug: "Login provider view did load.")
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.customUserAgent = userAgent

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.navigationDelegate = self
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true

        self.webView = webView

        let navigationItemBack = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .done, target: self, action: #selector(goBack(_:)))
        navigationItemBack.tintColor = uiColor
        navigationItem.leftBarButtonItem = navigationItemBack
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nkLog(debug: "Login provider appeared.")

        guard let url = URL(string: initialURLString) else {
            let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_login_url_error_")
            NCContentPresenter().showError(error: error, priority: .max)
            return
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
        loadWebPage(url: url)
        self.title = titleView
        self.navigationController?.navigationBar.backgroundColor = NCBrandColor.shared.customer
    
        appDelegate.timerErrorNetworkingDisabled = true
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        // Stop timer error network
////        appDelegate.timerErrorNetworkingDisabled = true
//        if let account = NCManageDatabase.shared.getActiveTableAccount(), NCKeychain().getPassword(account: account.account).isEmpty {
//
//            let message = "\n" + NSLocalizedString("_password_not_present_", comment: "")
//            let alertController = UIAlertController(title: titleView, message: message, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
//            present(alertController, animated: true)
//        }
//    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        nkLog(debug: "Login provider view did disappear.")

        NCActivityIndicator.shared.stop()

//        guard pollingTask != nil else {
//            return
//        }
//
//        nkLog(debug: "Cancelling existing polling task because view did disappear...")
//        pollingTask?.cancel()
//        pollingTask = nil
//        appDelegate.timerErrorNetworkingDisabled = false
    }

    // MARK: - Navigation

    private func loadWebPage(url: URL) {
        let language = NSLocale.preferredLanguages[0] as String
        var request = URLRequest(url: url)

        request.addValue("true", forHTTPHeaderField: "OCS-APIRequest")
        request.addValue(language, forHTTPHeaderField: "Accept-Language")

        webView.load(request)
    }

    ///
    /// Dismiss the login web view from the hierarchy.
    ///
    @objc func goBack(_ sender: Any?) {
        delegate?.onBack()

        if isModal {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Polling

    ///
    /// Start checking the status of the login flow in the background periodally.
    ///
    func startPolling(loginFlowV2Token: String, loginFlowV2Endpoint: String, loginFlowV2Login: String) {
        nkLog(start: "Starting polling at \(loginFlowV2Endpoint) with token \(loginFlowV2Token)")
        pollingTask = createPollingTask(token: loginFlowV2Token, endpoint: loginFlowV2Endpoint)
        nkLog(debug: "Polling task created.")
    }

    ///
    /// Fetch the server response and process it.
    ///
    private func poll(token: String, endpoint: String, options: NKRequestOptions) async -> (urlBase: String, loginName: String, appPassword: String)? {
        await withCheckedContinuation { continuation in
            NextcloudKit.shared.getLoginFlowV2Poll(token: token, endpoint: endpoint, options: options) {server, loginName, appPassword, _, error in

                guard error == .success else {
                    nkLog(error: "Login poll result for token \"\(token)\" is not successful!")
                    continuation.resume(returning: nil)
                    return
                }

                guard let urlBase = server else {
                    nkLog(error: "Login poll response field for server for token \"\(token)\" is nil!")
                    continuation.resume(returning: nil)
                    return
                }

                guard let user = loginName else {
                    nkLog(error: "Login poll response field for user name for token \"\(token)\" is nil!")
                    continuation.resume(returning: nil)
                    return
                }

                guard let appPassword = appPassword else {
                    nkLog(error: "Login poll response field for app password for token \"\(token)\" is nil!")
                    continuation.resume(returning: nil)
                    return
                }

                nkLog(debug: "Returning login poll response for \"\(user)\" on \"\(urlBase)\" for token \"\(token)\".")
                continuation.resume(returning: (urlBase, user, appPassword))
            }
        }
    }

    ///
    /// Handle the values acquired by polling successfully.
    ///
    private func handleGrant(urlBase: String, loginName: String, appPassword: String) async {
        nkLog(debug: "Handling login grant values for \(loginName) on \(urlBase)")

        await withCheckedContinuation { continuation in
            if controller == nil {
                nkLog(debug: "View controller is still undefined, will resolve root view controller of first window.")
                controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
            }

            NCAccount().createAccount(viewController: self, urlBase: urlBase, user: loginName, password: appPassword, controller: controller) {
                nkLog(debug: "Account creation for \(loginName) on \(urlBase) completed based on login grant values.")
            continuation.resume()
            }
        }
    }

    ///
    /// Set up the `Task` which frequently checks the server.
    ///
    private func createPollingTask(token: String, endpoint: String) -> Task<Void, any Error> {
        let options = NKRequestOptions(customUserAgent: userAgent)
        var grantValues: (urlBase: String, loginName: String, appPassword: String)?

        return Task { @MainActor in
            repeat {
                try Task.checkCancellation()

                grantValues = await poll(token: token, endpoint: endpoint, options: options)
                try await Task.sleep(nanoseconds: 1_000_000_000) // .seconds() is not supported on iOS 15 yet.
            } while grantValues == nil

            guard let grantValues else {
                return
            }

            await handleGrant(urlBase: grantValues.urlBase, loginName: grantValues.loginName, appPassword: grantValues.appPassword)
            nkLog(debug: "Polling task completed.")
        }
    }
}

// MARK: - WKNavigationDelegate

extension NCLoginProvider: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        nkLog(debug: "Web view did receive server redirect for provisional navigation.")

        guard let currentWebViewURL = webView.url else {
            nkLog(error: "Web view does not have a URL after receiving a server redirect for provisional navigation!")
            return
        }

        let currentWebViewURLString: String = currentWebViewURL.absoluteString.lowercased()

        // Prevent HTTP redirects.
        if initialURLString.lowercased().hasPrefix("https://") && currentWebViewURLString.hasPrefix("http://") {
            nkLog(error: "Web view redirect degrades session from HTTPS to HTTP and must be cancelled!")

            let alertController = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: NSLocalizedString("_prevent_http_redirection_", comment: ""), preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in
                _ = self.navigationController?.popViewController(animated: true)
            }))

            self.present(alertController, animated: true)

            return
        }

        // Login via provider.
        if currentWebViewURLString.hasPrefix(NCBrandOptions.shared.webLoginAutenticationProtocol) && currentWebViewURLString.contains("login") {
            nkLog(debug: "Web view redirect to provider login URL detected.")

            var server: String = ""
            var user: String = ""
            var password: String = ""
            let keyValue = currentWebViewURL.path.components(separatedBy: "&")

            for value in keyValue {
                if value.contains("server:") { server = value }
                if value.contains("user:") { user = value }
                if value.contains("password:") { password = value }
            }

            if !server.isEmpty, !user.isEmpty, !password.isEmpty {
                let server: String = server.replacingOccurrences(of: "/server:", with: "")
                let username: String = user.replacingOccurrences(of: "user:", with: "").replacingOccurrences(of: "+", with: " ")
                let password: String = password.replacingOccurrences(of: "password:", with: "")

                if self.controller == nil {
                    self.controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
                }

                NCAccount().createAccount(viewController: self, urlBase: server, user: username, password: password, controller: controller)
            }
        }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        nkLog(debug: "Web view did receive authentication challenge.")

        DispatchQueue.global().async {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        nkLog(debug: "Web view will allow navigation to \(navigationAction.request.url?.absoluteString ?? "nil")")
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        nkLog(debug: "Web view did start provisional navigation.")
        NCActivityIndicator.shared.startActivity(backgroundView: self.view, style: .medium, blurEffect: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        nkLog(debug: "Web view did finish navigation to \(webView.url?.absoluteString ?? "nil")")
        NCActivityIndicator.shared.stop()
    }

    // MARK: -

//    func createAccount(server: String, username: String, password: String) {
//        var urlBase = server
//        if urlBase.last == "/" { urlBase = String(urlBase.dropLast()) }
//        let account: String = "\(username) \(urlBase)"
//        let user = username
//
//        NextcloudKit.shared.setup(account: account, user: user, userId: user, password: password, urlBase: urlBase)
//        NextcloudKit.shared.getUserProfile(account: account) { _, userProfile, _, error in
//            if error == .success, let userProfile {
//                NextcloudKit.shared.appendSession(account: account,
//                                                  urlBase: urlBase,
//                                                  user: user,
//                                                  userId: user,
//                                                  password: password,
//                                                  userAgent: userAgent,
//                                                  nextcloudVersion: NCCapabilities.shared.getCapabilities(account: account).capabilityServerVersionMajor,
//                                                  httpMaximumConnectionsPerHost: NCBrandOptions.shared.httpMaximumConnectionsPerHost,
//                                                  httpMaximumConnectionsPerHostInDownload: NCBrandOptions.shared.httpMaximumConnectionsPerHostInDownload,
//                                                  httpMaximumConnectionsPerHostInUpload: NCBrandOptions.shared.httpMaximumConnectionsPerHostInUpload,
//                                                  groupIdentifier: NCBrandOptions.shared.capabilitiesGroup)
//                NCSession.shared.appendSession(account: account, urlBase: urlBase, user: user, userId: userProfile.userId)
//                NCManageDatabase.shared.deleteAccount(account)
//                NCManageDatabase.shared.addAccount(account, urlBase: urlBase, user: user, userId: userProfile.userId, password: password)
//                self.appDelegate.changeAccount(account, userProfile: userProfile) { }
//                let window = UIApplication.shared.firstWindow
//                if window?.rootViewController is NCMainTabBarController {
//                    self.dismiss(animated: true)
//                } else {
//                    if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? NCMainTabBarController {
//                        controller.modalPresentationStyle = .fullScreen
//                        controller.view.alpha = 0
//
//                        window?.rootViewController = controller
//                        window?.makeKeyAndVisible()
//
//                        if let scene = window?.windowScene {
//                            SceneManager.shared.register(scene: scene, withRootViewController: controller)
//                        }
//
//                        UIView.animate(withDuration: 0.5) {
//                            controller.view.alpha = 1
//                        }
//                    }
//                }
//            } else {
//                let alertController = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: error.errorDescription, preferredStyle: .alert)
//                alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
//                self.present(alertController, animated: true)
//            }
//        }
//    }
}
