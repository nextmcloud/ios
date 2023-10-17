// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Milen Pivchev
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import WebKit
import NextcloudKit
import FloatingPanel

class NCLoginProvider: UIViewController {
    var webView: WKWebView?
    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    let utility = NCUtility()
    var titleView: String = ""
    var urlBase = ""
    var uiColor: UIColor = .white
    weak var delegate: NCLoginProviderDelegate?
    var controller: NCMainTabBarController?

    var pollingTask: Task<Void, any Error>?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: CGRect.zero, configuration: WKWebViewConfiguration())
        if let webView {
            webView.navigationDelegate = self
            view.addSubview(webView)

            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            webView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }

        let navigationItemBack = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .done, target: self, action: #selector(goBack(_:)))
        navigationItemBack.tintColor = uiColor
        navigationItem.leftBarButtonItem = navigationItemBack
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let url = URL(string: urlBase),
           let webView {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: {
                    self.loadWebPage(webView: webView, url: url)
                })
            }
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stop timer error network
        appDelegate.timerErrorNetworkingDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NCActivityIndicator.shared.stop()
        appDelegate.timerErrorNetworkingDisabled = false
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

    @objc func goBack(_ sender: Any?) {
        delegate?.onBack()

        if isModal {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    func startPolling(loginFlowV2Token: String, loginFlowV2Endpoint: String, loginFlowV2Login: String) {
        pollingTask = poll(loginFlowV2Token: loginFlowV2Token, loginFlowV2Endpoint: loginFlowV2Endpoint, loginFlowV2Login: loginFlowV2Login)
    }

    private func getPollResponse(loginFlowV2Token: String, loginFlowV2Endpoint: String, loginOptions: NKRequestOptions) async -> (urlBase: String, loginName: String, appPassword: String)? {
        await withCheckedContinuation { continuation in
            NextcloudKit.shared.getLoginFlowV2Poll(token: loginFlowV2Token, endpoint: loginFlowV2Endpoint, options: loginOptions) { server, loginName, appPassword, _, error in
                if error == .success, let urlBase = server, let user = loginName, let appPassword {
                    continuation.resume(returning: (urlBase, user, appPassword))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func handleGrant(urlBase: String, loginName: String, appPassword: String) async {
        await withCheckedContinuation { continuation in
            if controller == nil {
                controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
            }

            NCAccount().createAccount(viewController: self, urlBase: urlBase, user: loginName, password: appPassword, controller: controller) {
                continuation.resume()
            }
        }
    }

    private func poll(loginFlowV2Token: String, loginFlowV2Endpoint: String, loginFlowV2Login: String) -> Task<Void, any Error> {
        let loginOptions = NKRequestOptions(customUserAgent: userAgent)
        var grantValues: (urlBase: String, loginName: String, appPassword: String)?

        return Task { @MainActor in
            repeat {
                grantValues = await getPollResponse(loginFlowV2Token: loginFlowV2Token, loginFlowV2Endpoint: loginFlowV2Endpoint, loginOptions: loginOptions)
                try await Task.sleep(nanoseconds: 1_000_000_000) // .seconds() is not supported on iOS 15 yet.
            } while grantValues == nil

            guard let grantValues else {
                return
            }

            await handleGrant(urlBase: grantValues.urlBase, loginName: grantValues.loginName, appPassword: grantValues.appPassword)
        }
    }
}

extension NCLoginProvider: WKNavigationDelegate {
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

        // Login via provider
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

                if self.controller == nil {
                    self.controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
                }

                NCAccount().createAccount(viewController: self, urlBase: server, user: username, password: password, controller: controller)
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

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NCActivityIndicator.shared.startActivity(backgroundView: self.view, style: .medium, blurEffect: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NCActivityIndicator.shared.stop()
    }

    // MARK: -

    func createAccount(server: String, username: String, password: String) {
        var urlBase = server
        if urlBase.last == "/" { urlBase = String(urlBase.dropLast()) }
        let account: String = "\(username) \(urlBase)"
        let user = username

        NextcloudKit.shared.setup(account: account, user: user, userId: user, password: password, urlBase: urlBase)
        NextcloudKit.shared.getUserProfile(account: account) { _, userProfile, _, error in
            if error == .success, let userProfile {
                NextcloudKit.shared.appendSession(account: account,
                                                  urlBase: urlBase,
                                                  user: user,
                                                  userId: user,
                                                  password: password,
                                                  userAgent: userAgent,
                                                  nextcloudVersion: NCCapabilities.shared.getCapabilities(account: account).capabilityServerVersionMajor,
                                                  httpMaximumConnectionsPerHost: NCBrandOptions.shared.httpMaximumConnectionsPerHost,
                                                  httpMaximumConnectionsPerHostInDownload: NCBrandOptions.shared.httpMaximumConnectionsPerHostInDownload,
                                                  httpMaximumConnectionsPerHostInUpload: NCBrandOptions.shared.httpMaximumConnectionsPerHostInUpload,
                                                  groupIdentifier: NCBrandOptions.shared.capabilitiesGroup)
                NCSession.shared.appendSession(account: account, urlBase: urlBase, user: user, userId: userProfile.userId)
                NCManageDatabase.shared.deleteAccount(account)
                NCManageDatabase.shared.addAccount(account, urlBase: urlBase, user: user, userId: userProfile.userId, password: password)
                self.appDelegate.changeAccount(account, userProfile: userProfile) { }
                let window = UIApplication.shared.firstWindow
                if window?.rootViewController is NCMainTabBarController {
                    self.dismiss(animated: true)
                } else {
                    if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? NCMainTabBarController {
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
