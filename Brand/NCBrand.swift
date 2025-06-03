// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2017 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit

let userAgent: String = {
    let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    // Original Nextcloud useragent "Mozilla/5.0 (iOS) Nextcloud-iOS/\(appVersion)"
    return "Mozilla/5.0 (iOS) Magenta-iOS/\(appVersion)"
}()

 /*
 Codname Matheria

 Matheria represents a pivotal step forward in the evolution of our software. This release delivers substantial architectural enhancements, increased performance, and a robust foundation for future innovations.

 The codename embodies the concept of dynamic, living matter — reflecting our vision of a platform that is not only powerful and reliable, but also capable of continuous transformation and intelligent adaptation.
 */

//final class NCBrandOptions: @unchecked Sendable {
//    static let shared = NCBrandOptions()
@objc class NCBrandOptions: NSObject, @unchecked Sendable {
    @objc static let shared: NCBrandOptions = {
        let instance = NCBrandOptions()
        return instance
    }()

    var brand:                           String = "MagentaCLOUD"
    var textCopyrightNextcloudiOS:       String = "MagentaCLOUD for iOS %@"
    var textCopyrightNextcloudServer:    String = "MagentaCLOUD Server %@"
    var loginBaseUrl:                    String = "https://magentacloud.de"
    var pushNotificationServerProxy: String = "https://push-notifications.nextcloud.com"
    var linkLoginHost: String = "https://nextcloud.com/install"
    var linkloginPreferredProviders: String = "https://nextcloud.com/signup-ios"
    var webLoginAutenticationProtocol: String = "nc://"                                        // example "abc://"
    var privacy: String = "https://static.magentacloud.de/privacy/datenschutzhinweise_app.htm"
    var sourceCode: String = "https://github.com/nextcloud/ios"
    var mobileconfig: String = "/remote.php/dav/provisioning/apple-provisioning.mobileconfig"
    var appStoreUrl: String = "https://apps.apple.com/in/app/nextcloud/id1125420102"
    @objc public var brand:                           String = "MagentaCLOUD"
    @objc public var textCopyrightNextcloudiOS:       String = "MagentaCLOUD for iOS %@"
    @objc public var textCopyrightNextcloudServer:    String = "MagentaCLOUD Server %@"
    @objc public var loginBaseUrl:                    String = "https://magentacloud.de"
    @objc public var pushNotificationServerProxy: String = "https://push-notifications.nextcloud.com"
    @objc public var linkLoginHost: String = "https://nextcloud.com/install"
    @objc public var linkloginPreferredProviders: String = "https://nextcloud.com/signup-ios"
    @objc public var webLoginAutenticationProtocol: String = "nc://"                                                // example "abc://"
    @objc public var privacy: String = "https://nextcloud.com/privacy"
    @objc public var sourceCode: String = "https://github.com/nextcloud/ios"
    @objc public var mobileconfig: String = "/remote.php/dav/provisioning/apple-provisioning.mobileconfig"
    @objc public var appStoreUrl: String = "https://apps.apple.com/de/app/magentacloud-cloud-speicher/id312838242"

    // Personalized
    @objc public var webCloseViewProtocolPersonalized: String = ""                                                  // example "abc://change/plan"      Don't touch me !!
    @objc public var folderBrandAutoUpload: String = ""                                                             // example "_auto_upload_folder_"   Don't touch me !!

    // Auto Upload default folder
    @objc public var folderDefaultAutoUpload: String = Locale.current.languageCode == "de" ? "Kamera-Medien" : "Camera-Media"

    // Capabilities Group
    var capabilitiesGroup:              String = "group.de.magentacloud.next.dev2.client"
    var capabilitiesGroupApps:              String = "group.de.magentacloud.next.dev2.client.apps"

    // BRAND ONLY
    var use_AppConfig: Bool = false
    @objc public var capabilitiesGroup:              String = "group.de.telekom.Mediencenter"
    @objc public var capabilitiesGroupApps:              String = "group.de.telekom.Mediencenter"

    // BRAND ONLY
    // Set use_login_web_personalized to true for prod and false for configurable path
    @objc public var use_login_web_personalized: Bool = true                               // Don't touch me !!
    @objc public var use_AppConfig: Bool = false                                                // Don't touch me !!
    @objc public var use_GroupApps: Bool = true                                                 // Don't touch me !!

    // Options
    // Use server theming color
    var use_themingColor:                Bool = false

    var disable_intro:       Bool = true
    var disable_request_login_url: Bool = false
    var disable_multiaccount:            Bool = true
    var disable_more_external_site: Bool = false
    var disable_openin_file: Bool = false                                                       // Don't touch me !!
    var disable_crash_service:             Bool = true
    var disable_log: Bool = false
    var disable_mobileconfig: Bool = false
    var disable_show_more_nextcloud_apps_in_settings:         Bool = true
    var doNotAskPasscodeAtStartup: Bool = false
    var disable_source_code_in_settings: Bool = false
    var enforce_passcode_lock = false
    @objc public var use_default_auto_upload: Bool = false
    @objc public var use_themingColor: Bool = false
    @objc public var use_themingLogo: Bool = false
    @objc public var use_storeLocalAutoUploadAll: Bool = false
    @objc public var use_loginflowv2: Bool = false

    @objc var disable_intro:       Bool = false//true
    @objc var disable_request_login_url:       Bool = false//true
    @objc public var disable_multiaccount:            Bool = true
    @objc public var disable_manage_account:          Bool = false
    @objc var disable_more_external_site: Bool = false
    @objc var disable_openin_file: Bool = false                                          // Don't touch me !!
    @objc var disable_crash_service:             Bool = true
    @objc var disable_log: Bool = false
    @objc var disable_mobileconfig: Bool = false
    @objc var disable_show_more_nextcloud_apps_in_settings:         Bool = true
    @objc var doNotAskPasscodeAtStartup: Bool = false
    @objc var disable_source_code_in_settings: Bool = false
    @objc var enforce_passcode_lock = false
    @objc var use_in_app_browser_for_login = false

    // Example: (name: "Name 1", url: "https://cloud.nextcloud.com"),(name: "Name 2", url: "https://cloud.nextcloud.com")
    var enforce_servers: [(name: String, url: String)] = []

    // Internal option behaviour
    @objc var cleanUpDay: Int = 0                                                                     // Set default "Delete all cached files older than" possible days value are: 0, 1, 7, 30, 90, 180, 365

    // Max request/download/upload concurrent
    let httpMaximumConnectionsPerHost: Int = 6
    let httpMaximumConnectionsPerHostInDownload: Int = 6
    let httpMaximumConnectionsPerHostInUpload: Int = 6

    // Number of failed attempts after reset app
    @objc let resetAppPasscodeAttempts: Int = 10
    let passcodeSecondsFail: Int = 60

    // Info Paging
    enum NCInfoPagingTab: Int, CaseIterable {
        case activity, sharing
    }

    init() {
        // wrapper AppConfig
        if let configurationManaged = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed"), use_AppConfig {
            if let str = configurationManaged[NCGlobal.shared.configuration_brand] as? String {
                brand = str
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_intro] as? String {
                disable_intro = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_multiaccount] as? String {
                disable_multiaccount = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_crash_service] as? String {
                disable_crash_service = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_log] as? String {
                disable_log = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_manage_account] as? String {
                disable_manage_account = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_more_external_site] as? String {
                disable_more_external_site = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_disable_openin_file] as? String {
                disable_openin_file = (str as NSString).boolValue
            }
            if let str = configurationManaged[NCGlobal.shared.configuration_enforce_passcode_lock] as? String {
                enforce_passcode_lock = (str as NSString).boolValue
            }
        }

#if DEBUG
        pushNotificationServerProxy = "https://c0004.customerpush.nextcloud.com"
#endif
    }

    @objc func getUserAgent() -> String {
        return userAgent
    }
}

class NCBrandColor: NSObject, @unchecked Sendable  {
    static let shared: NCBrandColor = {
        let instance = NCBrandColor()
        return instance
    }()

    /// This is rewrited from customet theme, default is Nextcloud color
    ///
    let customer:              UIColor = UIColor(red: 226.0/255.0, green: 0.0/255.0, blue: 116.0/255.0, alpha: 1.0)
    var customerText:             UIColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    @objc let customer:              UIColor = UIColor(red: 226.0/255.0, green: 0.0/255.0, blue: 116.0/255.0, alpha: 1.0)
    @objc var customerText: UIColor = .white

    @objc var brand: UIColor                                                                                         // don't touch me
    @objc var brandElement: UIColor                                                                                  // don't touch me
    @objc var brandText:             UIColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)

    // INTERNAL DEFINE COLORS
    private var themingColor = ThreadSafeDictionary<String, UIColor>()
    private var themingColorElement = ThreadSafeDictionary<String, UIColor>()
    private var themingColorText = ThreadSafeDictionary<String, UIColor>()

    var userColors: [CGColor] = []
    let nextcloud: UIColor = UIColor(red: 0.0 / 255.0, green: 130.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)
    let yellowFavorite: UIColor = UIColor(red: 248.0 / 255.0, green: 205.0 / 255.0, blue: 70.0 / 255.0, alpha: 1.0)
    let iconImageColor: UIColor = .label
    let iconImageColor2: UIColor = .secondaryLabel
    let iconImageMultiColors: [UIColor] = [.secondaryLabel, .label]
    let textColor: UIColor = .label
    let textColor2: UIColor = .secondaryLabel

    @objc var systemMint: UIColor {
        get {
            return UIColor(red: 0.0 / 255.0, green: 199.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
        }
    }

    var documentIconColor: UIColor {
        get {
            return UIColor(hex: "#49abe9")!
        }
    }

    var spreadsheetIconColor: UIColor {
        get {
            return UIColor(hex: "#9abd4e")!
        }
    }

    var presentationIconColor: UIColor {
        get {
            return UIColor(hex: "#f0965f")!
        }
    }

    override init() {
        brand = customer
        brandElement = customer
        brandText = customerText
    }

    /**
     Generate colors from the official nextcloud color.
     You can provide how many colors you want (multiplied by 3).
     if `step` = 6,
     3 colors \* 6 will result in 18 generated colors
     */
    func createUserColors() {
        func generateColors(steps: Int = 6) -> [CGColor] {
            func stepCalc(steps: Int, color1: CGColor, color2: CGColor) -> [CGFloat] {
                var step = [CGFloat](repeating: 0, count: 3)

                step[0] = (color2.components![0] - color1.components![0]) / CGFloat(steps)
                step[1] = (color2.components![1] - color1.components![1]) / CGFloat(steps)
                step[2] = (color2.components![2] - color1.components![2]) / CGFloat(steps)
                return step
            }

            func mixPalette(steps: Int, color1: CGColor, color2: CGColor) -> [CGColor] {
                var palette = [color1]
                let step = stepCalc(steps: steps, color1: color1, color2: color2)
                let c1Components = color1.components!

                for i in 1 ..< steps {
                    let r = c1Components[0] + step[0] * CGFloat(i)
                    let g = c1Components[1] + step[1] * CGFloat(i)
                    let b = c1Components[2] + step[2] * CGFloat(i)

                    palette.append(UIColor(red: r, green: g, blue: b, alpha: 1).cgColor)
                }
                return palette
            }

            let red = UIColor(red: 182 / 255, green: 70 / 255, blue: 157 / 255, alpha: 1).cgColor
            let yellow = UIColor(red: 221 / 255, green: 203 / 255, blue: 85 / 255, alpha: 1).cgColor
            let blue = UIColor(red: 0 / 255, green: 130 / 255, blue: 201 / 255, alpha: 1).cgColor

            let palette1 = mixPalette(steps: steps, color1: red, color2: yellow)
            let palette2 = mixPalette(steps: steps, color1: yellow, color2: blue)
            let palette3 = mixPalette(steps: steps, color1: blue, color2: red)

            return palette1 + palette2 + palette3
        }

        userColors = generateColors()
    }

    @discardableResult
    func settingThemingColor(account: String) -> Bool {
        let darker: CGFloat = 30    // %
        let lighter: CGFloat = 30   // %
        var colorThemingColor: UIColor?
        var colorThemingColorElement: UIColor?
        var colorThemingColorText: UIColor?

        if NCBrandOptions.shared.use_themingColor {
            let themingColor = NCCapabilities.shared.getCapabilities(account: account).capabilityThemingColor
            let themingColorElement = NCCapabilities.shared.getCapabilities(account: account).capabilityThemingColorElement
            let themingColorText = NCCapabilities.shared.getCapabilities(account: account).capabilityThemingColorText

            // THEMING COLOR
            if themingColor.first == "#" {
                if let color = UIColor(hex: themingColor) {
                    colorThemingColor = color
                } else {
                    colorThemingColor = customer
                }
            } else {
                colorThemingColor = customer
            }

            // THEMING COLOR ELEMENT (control isTooLight / isTooDark)
            if themingColorElement.first == "#" {
                if let color = UIColor(hex: themingColorElement) {
                    if color.isTooLight() {
                        if let color = color.darker(by: darker) {
                            colorThemingColorElement = color
                        }
                    } else if color.isTooDark() {
                        if let color = color.lighter(by: lighter) {
                            colorThemingColorElement = color
                        }
                    } else {
                        colorThemingColorElement = color
                    }
                } else {
                    colorThemingColorElement = customer
                }
            } else {
                colorThemingColorElement = customer
            }

            // THEMING COLOR TEXT
            if themingColorText.first == "#" {
                if let color = UIColor(hex: themingColorText) {
                    colorThemingColorText = color
                } else {
                    colorThemingColorText = .white
                }
            } else {
                colorThemingColorText = .white
            }

        } else {

            // THEMING COLOR
            colorThemingColor = customer

            // THEMING COLOR ELEMENT (control isTooLight / isTooDark)
            if self.customer.isTooLight() {
                if let color = customer.darker(by: darker) {
                    colorThemingColorElement = color
                }
            } else if customer.isTooDark() {
                if let color = customer.lighter(by: lighter) {
                    colorThemingColorElement = color
                }
            } else {
                colorThemingColorElement = customer
            }

            // THEMING COLOR TEXT
            colorThemingColorText = customerText
        }

        if self.themingColor[account] != colorThemingColor || self.themingColorElement[account] != colorThemingColorElement || self.themingColorText[account] != colorThemingColorText {

            self.themingColor[account] = colorThemingColor
            self.themingColorElement[account] = colorThemingColorElement
            self.themingColorText[account] = colorThemingColorText

            return true
        }

        return false
    }

    public func getTheming(account: String?) -> UIColor {
        if let account, let color = self.themingColor[account] {
            return color
        }
        return customer
    }

    public func getElement(account: String?) -> UIColor {
        if let account, let color = self.themingColorElement[account] {
            return color
        }
        return customer
    }

    public func getText(account: String?) -> UIColor {
        if let account, let color = self.themingColorText[account] {
            return color
        }
        return .white
    }
    
    @objc public var iconColor: UIColor{
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return  UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            }else {
                return  UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
            }
        } else {
            return  UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
        }
    }
    
    @objc public var notificationAction: UIColor {
        return UIColor(red: 0/255.0, green: 153/255.0, blue: 255/255.0, alpha: 1.0)
    }

    @objc public var secondarySystemGroupedBackground: UIColor = UIColor.secondarySystemGroupedBackground
    @objc public var label: UIColor = UIColor.label
    @objc public var backgroundForm: UIColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    @objc public let graySoft: UIColor = UIColor(red: 162.0/255.0, green: 162.0/255.0, blue: 162.0/255.0, alpha: 0.5)
    @objc public let systemGray4: UIColor = UIColor.systemGray4
    @objc public let systemBackground: UIColor = UIColor.systemBackground
    @objc public let textInfo: UIColor = UIColor(red: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 1.0)
    @objc public let systemGray: UIColor = UIColor.systemGray
    @objc public let customerDarkGrey: UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    @objc public var fileFolderName: UIColor = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public let optionItem: UIColor = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    @objc public var singleTitleColorButton: UIColor = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
    @objc public var shareCellTitleColor: UIColor = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    @objc public var gray60: UIColor {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return  UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
        } else {
            return  UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
        }
    }
    @objc public var systemGray2: UIColor = UIColor.systemGray2
    @objc public var shareByEmailTextColor: UIColor = UIColor(displayP3Red: 13.0/255.0, green: 57.0/255.0, blue: 223.0/255.0, alpha: 1.0)
    @objc public var memoryConsuptionBackground: UIColor {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return  UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
        } else {
            return  UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    @objc public var nmcGray0: UIColor{
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return  UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        }else {
            return  UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
        }
    }
    @objc public var commonViewInfoText: UIColor =  UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public let progressColorGreen60: UIColor = UIColor(red: 115.0/255.0, green: 195.0/255.0, blue: 84.0/255.0, alpha: 1.0)
    @objc public var seperatorRename: UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    @objc public let gray: UIColor = UIColor(red: 104.0/255.0, green: 104.0/255.0, blue: 104.0/255.0, alpha: 1.0)
    @objc public var nmcIconSharedWithMe: UIColor = UIColor(displayP3Red: 0.0/255.0, green: 153.0/255.0, blue: 255.0/255.0, alpha: 1.0)
}
