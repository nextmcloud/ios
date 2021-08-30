//
//  NCBrandColor.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 24/04/17.
//  Copyright (c) 2017 Marino Faggiana. All rights reserved.
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

//MARK: - Configuration

@objc class NCBrandConfiguration: NSObject {
    @objc static let shared: NCBrandConfiguration = {
        let instance = NCBrandConfiguration()
        return instance
    }()
    
    @objc public let configuration_bundleId:            String = "it.twsweb.Nextcloud"
    @objc public let configuration_serverUrl:           String = "serverUrl"
    @objc public let configuration_username:            String = "username"
    @objc public let configuration_password:            String = "password"
}

//MARK: - Options

@objc class NCBrandOptions: NSObject {
    @objc static let shared: NCBrandOptions = {
        let instance = NCBrandOptions()
        return instance
    }()
    
    @objc public var brand:                             String = "MagentaCLOUD"//"Nextcloud"
    @objc public var brandCloud:                             String = "CLOUD"//"Nextcloud"
    @objc public var mailMe:                            String = "ios@nextcloud.com"
    @objc public var textCopyrightNextcloudiOS:         String = "Nextcloud Coherence for iOS %@ © 2021"
    @objc public var textCopyrightNextcloudServer:      String = "Nextcloud Server %@"
    @objc public var loginBaseUrl:                      String = "https://dev2.next.magentacloud.de/"

    @objc public var pushNotificationServerProxy:       String = "https://push-notifications.nextcloud.com"
    @objc public var linkLoginHost:                     String = "https://nextcloud.com/install"
    @objc public var linkloginPreferredProviders:       String = "https://nextcloud.com/signup-ios";
    @objc public var webLoginAutenticationProtocol:     String = "nc://"                                            // example "abc://"

    @objc public var privacy:                           String = "https://nextcloud.com/privacy"
    @objc public var sourceCode:                        String = "https://github.com/nextcloud/ios"

    // Personalized
    @objc public var webCloseViewProtocolPersonalized:  String = ""                                                 // example "abc://change/plan"      Don't touch me !!
    @objc public var folderBrandAutoUpload:             String = ""                                                 // example "_auto_upload_folder_"   Don't touch me !!
    
    // Auto Upload default folder
    @objc public var folderDefaultAutoUpload:           String = "Photos"
    
    // Capabilities Group

//    @objc public var capabilitiesGroups:                String = "group.in.t-systems.com"
    @objc public var capabilitiesGroups:                String = "group.com.t-systems.pu-ds.magentacloud.qa"

    
    // User Agent
    @objc public var userAgent:                         String = "Nextcloud-iOS"                                    // Don't touch me !!
    
    // Options
    @objc public var use_login_web_personalized:        Bool = false                                                // Don't touch me !!
    @objc public var use_default_auto_upload:           Bool = false
    @objc public var use_themingColor:                Bool = false
    //@objc public var use_themingBackground:           Bool = false
    @objc public var use_themingLogo:                   Bool = false
    @objc public var use_storeLocalAutoUploadAll:       Bool = false
    @objc public var use_configuration:                 Bool = false                                                // Don't touch me !!
    @objc public var use_loginflowv2:                   Bool = false                                                // Don't touch me !!

    @objc public var disable_intro:       Bool = true
    @objc public var disable_request_login_url:       Bool = true
    @objc public var disable_multiaccount:            Bool = true
    @objc public var disable_manage_account:          Bool = false
    @objc public var disable_more_external_site:        Bool = false
    @objc public var disable_openin_file:               Bool = false                                                // Don't touch me !!
    @objc public var disable_crash_service:             Bool = true
    @objc public var disable_request_account:           Bool = false

    @objc public var disable_log:                       Bool = false

    @objc public var disable_background_color:          Bool = true
    @objc public var disable_background_image:          Bool = true

    override init() {
        
        if folderBrandAutoUpload != "" {
            folderDefaultAutoUpload = folderBrandAutoUpload
        }
    }
}

//MARK: - Color

@objc class NCBrandColor: NSObject {
    @objc static let shared: NCBrandColor = {
        let instance = NCBrandColor()
        //instance.setDarkMode()
        instance.createImagesThemingColor()
        return instance
    }()
    
    struct cacheImages {
        static var file = UIImage()

        static var shared = UIImage()
        static var canShare = UIImage()
        static var shareByLink = UIImage()
        
        static var favorite = UIImage()
        static var comment = UIImage()
        static var livePhoto = UIImage()
        static var offlineFlag = UIImage()
        static var local = UIImage()

        static var folderEncrypted = UIImage()
        static var folderSharedWithMe = UIImage()
        static var folderPublic = UIImage()
        static var folderGroup = UIImage()
        static var folderExternal = UIImage()
        static var folderAutomaticUpload = UIImage()
        static var folder = UIImage()
        
        static var checkedYes = UIImage()
        static var checkedNo = UIImage()
        
        static var buttonMore = UIImage()
        static var buttonStop = UIImage()
    }

    // Color

    @objc public let customer:              UIColor = UIColor(red: 226.0/255.0, green: 0.0/255.0, blue: 116.0/255.0, alpha: 1.0) //UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)    // BLU NC : #0082c9
    @objc public let customerDefault:       UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)    // BLU NC : #0082c9
    @objc public let cellSelection:       UIColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 0.7)    // BLU NC : #0082c9
        static var buttonRestore = UIImage()

    @objc public var customerText:          UIColor = .white
    
    @objc public var brand:                 UIColor                                                                                 // don't touch me
    @objc public var brandElement:          UIColor                                                                                 // don't touch me
    @objc public var brandText:             UIColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)

    @objc public var connectionNo:          UIColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    @objc public var encrypted:             UIColor = .red
    @objc public var backgroundView:        UIColor = .white
    @objc public var backgroundForm:        UIColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    @objc public var textView:              UIColor = .black
    //@objc public var separator:             UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    @objc public var tabBar:                UIColor = .white
    @objc public let nextcloud:             UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    @objc public let nextcloudSoft:         UIColor = UIColor(red: 90.0/255.0, green: 160.0/255.0, blue: 210.0/255.0, alpha: 1.0)
    @objc public let gray:                  UIColor = UIColor(red: 104.0/255.0, green: 104.0/255.0, blue: 104.0/255.0, alpha: 1.0)
    @objc public var icon:                  UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    @objc public let optionItem:            UIColor = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    @objc public let graySoft:              UIColor = UIColor(red: 162.0/255.0, green: 162.0/255.0, blue: 162.0/255.0, alpha: 0.5)
    @objc public let yellowFavorite:        UIColor = UIColor(red: 248.0/255.0, green: 205.0/255.0, blue: 70.0/255.0, alpha: 1.0)
    @objc public let textInfo:              UIColor = UIColor(red: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 1.0)
    @objc public var select:                UIColor = .white
    @objc public var avatarBorder:          UIColor = .white
    @objc public let progressColorGreen60:              UIColor = UIColor(red: 115.0/255.0, green: 195.0/255.0, blue: 84.0/255.0, alpha: 1.0)
    @objc public let customerDarkGrey:              UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    @objc public var actionCellBackgroundColor:              UIColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
    @objc public var gray26AndGrayf2:              UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    @objc public var searchImageColor:              UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
    @objc public var memoryConsuptionBackground:        UIColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    @objc public var systemGrayAndGray66:        UIColor = .gray
    @objc public var commonViewInfoText:        UIColor = UIColor(displayP3Red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    @objc public var tileSelectionImageColor:        UIColor = .white
    @objc public var backgroundCell:        UIColor = .white
    @objc public var seperatorRename:             UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)



    
//    private func createImagesThemingColor() {
//
//        cacheImages.file = UIImage.init(named: "file")!
//
//        cacheImages.shared = UIImage(named: "share")!.image(color: graySoft, size: 50)
//        cacheImages.canShare = UIImage(named: "share")!.image(color: graySoft, size: 50)
//        cacheImages.shareByLink = UIImage(named: "sharebylink")!.image(color: graySoft, size: 50)
//
//        cacheImages.favorite = NCUtility.shared.loadImage(named: "star.fill", color: yellowFavorite)
//        cacheImages.comment = UIImage(named: "comment")!.image(color: graySoft, size: 50)
//        cacheImages.livePhoto = NCUtility.shared.loadImage(named: "livephoto", color: textView)
//
//    @objc public let nextcloud:             UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)
//    @objc public let gray:                  UIColor = UIColor(red: 104.0/255.0, green: 104.0/255.0, blue: 104.0/255.0, alpha: 1.0)
//    @objc public let lightGray:             UIColor = UIColor(red: 229.0/255.0, green: 229.0/229.0, blue: 104.0/255.0, alpha: 1.0)
//    @objc public let yellowFavorite:        UIColor = UIColor(red: 248.0/255.0, green: 205.0/255.0, blue: 70.0/255.0, alpha: 1.0)

    @objc public var systemBackground: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemBackground
            } else {
                return .white
            }
        }
    }
    
    @objc public var secondarySystemBackground: UIColor {
        get {
            if #available(iOS 13, *) {
                return .secondarySystemBackground
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            }
        }
    }
    
    @objc public var tertiarySystemBackground: UIColor {
        get {
            if #available(iOS 13, *) {
                return .tertiarySystemBackground
            } else {
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGroupedBackground: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGroupedBackground
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            }
        }
    }
    
    @objc public var secondarySystemGroupedBackground: UIColor {
        get {
            if #available(iOS 13, *) {
                return .secondarySystemGroupedBackground
            } else {
                return .white
            }
        }
    }
    
    @objc public var label: UIColor {
        get {
            if #available(iOS 13, *) {
                return .label
            } else {
                return .black
            }
        }
    }
    
    @objc public var separator: UIColor {
        get {
            if #available(iOS 13, *) {
                return .separator
            } else {
                return UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1.0)
            }
        }
    }
    
    @objc public var opaqueSeparator: UIColor {
        get {
            if #available(iOS 13, *) {
                return .opaqueSeparator
            } else {
                return UIColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray
            } else {
                return UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray2: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray2
            } else {
                return UIColor(red: 0.68, green: 0.68, blue: 0.7, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray3: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray3
            } else {
                return UIColor(red: 0.78, green: 0.78, blue: 0.8, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray4: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray4
            } else {
                return UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray5: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray5
            } else {
                return UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemGray6: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemGray6
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            }
        }
    }
    
    @objc public var systemFill: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemFill
            } else {
                return UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1.0)
            }
        }
    }
    override init() {
        self.brand = self.customer
//        self.brandElement = self.customer
        self.brandElement = self.customerDefault
        self.brandText = self.customerText
    }
    
//    override init() {
//        self.brand = self.customer
//        self.brandElement = self.customer
//        self.brandText = self.customerText
//    }
    
    public func createImagesThemingColor() {
        
        let gray: UIColor = UIColor(red: 162.0/255.0, green: 162.0/255.0, blue: 162.0/255.0, alpha: 0.5)

        cacheImages.file = UIImage.init(named: "file")!
        
        cacheImages.shared = UIImage(named: "share")!.image(color: gray, size: 50)
        cacheImages.canShare = UIImage(named: "share")!.image(color: gray, size: 50)
        cacheImages.shareByLink = UIImage(named: "sharebylink")!.image(color: gray, size: 50)
        
        cacheImages.favorite = NCUtility.shared.loadImage(named: "star.fill", color: yellowFavorite)
        cacheImages.comment = UIImage(named: "comment")!.image(color: gray, size: 50)
        cacheImages.livePhoto = NCUtility.shared.loadImage(named: "livephoto", color: label)
        cacheImages.offlineFlag = UIImage.init(named: "offlineFlag")!
        cacheImages.local = UIImage.init(named: "local")!
            
        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
        cacheImages.folderEncrypted = UIImage(named: "folderEncrypted")!.image(color: brandElement, size: folderWidth)
        cacheImages.folderSharedWithMe = UIImage(named: "folder_shared_with_me")!
        cacheImages.folderPublic = UIImage(named: "folder_public")!.image(color: customerDefault, size: folderWidth)
        cacheImages.folderGroup = UIImage(named: "folder_group")!.image(color: brandElement, size: folderWidth)
        cacheImages.folderExternal = UIImage(named: "folder_external")!.image(color: brandElement, size: folderWidth)
        cacheImages.folderAutomaticUpload = UIImage(named: "folderAutomaticUpload")!.image(color: brandElement, size: folderWidth)
        cacheImages.folder =  UIImage(named: "folder_nmcloud")!
        
        cacheImages.checkedYes = UIImage(named: "checkedYes")!
        cacheImages.checkedNo = NCUtility.shared.loadImage(named: "circle", color: graySoft)
        
        cacheImages.buttonMore = UIImage(named: "more")!.image(color: graySoft, size: 50)
        cacheImages.buttonStop = UIImage(named: "stop")!.image(color: graySoft, size: 50)
    }
    
//    @objc public func setDarkMode() {
//        let darkMode = CCUtility.getDarkMode()
//        if darkMode {
////            tabBar = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
//            tabBar = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
//            backgroundView = .black
//            backgroundCell = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
//            backgroundForm = .black
//            textView = .white
////            separator = UIColor(red: 60.0/255.0, green: 60.0/255.0, blue: 60.0/255.0, alpha: 1.0)
//            separator = UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
//            select = UIColor.white.withAlphaComponent(0.2)
//            avatarBorder = .black
//            icon = UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
//            actionCellBackgroundColor = UIColor(displayP3Red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
//            gray26AndGrayf2 = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
//            searchImageColor = icon
//            memoryConsuptionBackground = backgroundCell
//            systemGrayAndGray66 = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
//            tileSelectionImageColor = .black
//            seperatorRename = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
//        } else {
//            tabBar = .white
//            backgroundView = .white
//            backgroundCell = .white
//            backgroundForm = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
//            textView = .black
////            separator = UIColor(red: 208.0/255.0, green: 209.0/255.0, blue: 212.0/255.0, alpha: 1.0)
//            separator = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
//            select = self.brandElement.withAlphaComponent(0.1)
//            avatarBorder = .white
//            // reassign default color
//            icon = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
//            actionCellBackgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
//            gray26AndGrayf2 = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
//            searchImageColor = icon
//            memoryConsuptionBackground = backgroundCell
//            systemGrayAndGray66 = .gray
//            tileSelectionImageColor = .white
//            seperatorRename = UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
//        }
//    }
//
//#if !EXTENSION
//func cacheImages.folderSharedWithMe = UIImage(named: "folder_shared_with_me")!.image(color: brandElement, size: folderWidth)
//        cacheImages.folderPublic = UIImage(named: "folder_public")!.image(color: brandElement, size: folderWidth)
//        cacheImages.folderGroup = UIImage(named: "folder_group")!.image(color: brandElement, size: folderWidth)
//        cacheImages.folderExternal = UIImage(named: "folder_external")!.image(color: brandElement, size: folderWidth)
//        cacheImages.folderAutomaticUpload = UIImage(named: "folderAutomaticUpload")!.image(color: brandElement, size: folderWidth)
//        cacheImages.folder =  UIImage(named: "folder")!.image(color: brandElement, size: folderWidth)
//
//        cacheImages.checkedYes = NCUtility.shared.loadImage(named: "checkmark.circle.fill", color: .systemBlue)
//        cacheImages.checkedNo = NCUtility.shared.loadImage(named: "circle", color: gray)
//
//        cacheImages.buttonMore = UIImage(named: "more")!.image(color: gray, size: 50)
//        cacheImages.buttonStop = UIImage(named: "stop")!.image(color: gray, size: 50)
//        cacheImages.buttonRestore = UIImage(named: "restore")!.image(color: gray, size: 50)
//    }
    
    #if !EXTENSION
    public func settingThemingColor(account: String) {
        
        let darker: CGFloat = 30    // %
        let lighter: CGFloat = 30   // %

        if NCBrandOptions.shared.use_themingColor {
            
            let themingColor = NCManageDatabase.shared.getCapabilitiesServerString(account: account, elements: NCElementsJSON.shared.capabilitiesThemingColor)
            
            let themingColorElement = NCManageDatabase.shared.getCapabilitiesServerString(account: account, elements: NCElementsJSON.shared.capabilitiesThemingColorElement)
            
            let themingColorText = NCManageDatabase.shared.getCapabilitiesServerString(account: account, elements: NCElementsJSON.shared.capabilitiesThemingColorText)
            
            settingBrandColor(themingColor, themingColorElement: themingColorElement, themingColorText: themingColorText)
                        
            if NCBrandColor.shared.brandElement.isTooLight() {
                if let color = NCBrandColor.shared.brandElement.darker(by: darker) {
                    NCBrandColor.shared.brandElement = color
                }
            } else if NCBrandColor.shared.brandElement.isTooDark() {
                if let color = NCBrandColor.shared.brandElement.lighter(by: lighter) {
                    NCBrandColor.shared.brandElement = color
                }
            }           
            
        } else {
            
            if NCBrandColor.shared.customer.isTooLight() {
                if let color = NCBrandColor.shared.customer.darker(by: darker) {
                    NCBrandColor.shared.brandElement = color
                }
            } else if NCBrandColor.shared.customer.isTooDark() {
                if let color = NCBrandColor.shared.customer.lighter(by: lighter) {
                    NCBrandColor.shared.brandElement = color
                }
            } else {
                NCBrandColor.shared.brandElement = NCBrandColor.shared.customer
            }
            
            NCBrandColor.shared.brand = NCBrandColor.shared.customer
            NCBrandColor.shared.brandText = NCBrandColor.shared.customerText
        }
        setDarkMode()
        DispatchQueue.main.async {
            self.createImagesThemingColor()
            NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterChangeTheming)
        }
    }
#endif
    
    @objc func settingBrandColor(_ themingColor: String?, themingColorElement: String?, themingColorText: String?) {
                
        // COLOR
        if themingColor?.first == "#" {
            if let color = UIColor(hex: themingColor!) {
                NCBrandColor.shared.brand = color
            } else {
                NCBrandColor.shared.brand = NCBrandColor.shared.customer
            }
        } else {
            NCBrandColor.shared.brand = NCBrandColor.shared.customer
        }
        
        // COLOR TEXT
        if themingColorText?.first == "#" {
            if let color = UIColor(hex: themingColorText!) {
                NCBrandColor.shared.brandText = color
            } else {
                NCBrandColor.shared.brandText = NCBrandColor.shared.customerText
            }
        } else {
            NCBrandColor.shared.brandText = NCBrandColor.shared.customerText
        }
        
        // COLOR ELEMENT
        if themingColorElement?.first == "#" {
            if let color = UIColor(hex: themingColorElement!) {
                NCBrandColor.shared.brandElement = color
            } else {
                NCBrandColor.shared.brandElement = NCBrandColor.shared.brand
            }
        } else {
            NCBrandColor.shared.brandElement = NCBrandColor.shared.brand
        }
    }
}
        
//MARK: - Global

@objc class NCBrandGlobal: NSObject {
    @objc static let shared: NCBrandGlobal = {
        let instance = NCBrandGlobal()
        return instance
    }()

    // Directory on Group
    @objc let appDatabaseNextcloud                  = "Library/Application Support/Nextcloud"
    @objc let appApplicationSupport                 = "Library/Application Support"
    @objc let appUserData                           = "Library/Application Support/UserData"
    @objc let appCertificates                       = "Library/Application Support/Certificates"
    @objc let appScan                               = "Library/Application Support/Scan"
    @objc let directoryProviderStorage              = "File Provider Storage"

    // Service
    @objc let serviceShareKeyChain                  = "Crypto Cloud"
    @objc let metadataKeyedUnarchiver               = "it.twsweb.nextcloud.metadata"
    @objc let refreshTask                           = "com.nextcloud.refreshTask"
    @objc let processingTask                        = "com.nextcloud.processingTask"
    
    // Nextcloud version
    @objc let nextcloudVersion12: Int               =  12
    let nextcloudVersion15: Int                     =  15
    let nextcloudVersion17: Int                     =  17
    let nextcloudVersion18: Int                     =  18
    let nextcloudVersion20: Int                     =  20

    // Database Realm
    let databaseDefault                             = "nextcloud.realm"
    let databaseSchemaVersion: UInt64               = 161
    
    // Intro selector
    @objc let introLogin: Int                       = 0
    @objc let introSignup: Int                      = 1
    
    // Avatar & Preview
    let avatarSize: CGFloat                         = 512
    @objc let sizePreview: CGFloat                  = 1024
    @objc let sizeIcon: CGFloat                     = 1024
    
    // E2EE
    let e2eeMaxFileSize: UInt64                     = 524288000   // 500 MB
    let e2eePassphraseTest                          = "more over television factory tendency independence international intellectual impress interest sentence pony"
    @objc let e2eeVersion                           = "1.1"
    
    // Max Size Upload
    let uploadMaxFileSize: UInt64                   = 524288000   // 500 MB
    
    // Max Cache Proxy Video
    let maxHTTPCache: Int64                         = 10737418240 // 10 GB
    
    // NCSharePaging
    let indexPageActivity: Int                      = 0
    let indexPageComments: Int                      = 1
    let indexPageSharing: Int                       = 2
    
    // NCViewerProviderContextMenu
    let maxAutoDownload: UInt64                     = 104857600 // 100MB
    let maxAutoDownloadCellular: UInt64             = 10485760  // 10MB

    // Nextcloud unsupported
    let nextcloud_unsupported_version: Int          = 13
    
    // Layout
    let layoutList                                  = "typeLayoutList"
    let layoutGrid                                  = "typeLayoutGrid"
    
    let layoutViewMove                              = "LayoutMove"
    let layoutViewTrash                             = "LayoutTrash"
    let layoutViewOffline                           = "LayoutOffline"
    let layoutViewFavorite                          = "LayoutFavorite"
    let layoutViewFiles                             = "LayoutFiles"
    let layoutViewViewInFolder                      = "ViewInFolder"
    let layoutViewTransfers                         = "LayoutTransfers"
    let layoutViewRecent                            = "LayoutRecent"
    let layoutViewShares                            = "LayoutShares"
    
    // Button Type in Cell list/grid
    let buttonMoreMore                              = "more"
    let buttonMoreStop                              = "stop"
    
    // Text -  OnlyOffice - Collabora
    let editorText                                  = "text"
    let editorOnlyoffice                            = "onlyoffice"
    let editorCollabora                             = "collabora"

    let onlyofficeDocx                              = "onlyoffice_docx"
    let onlyofficeXlsx                              = "onlyoffice_xlsx"
    let onlyofficePptx                              = "onlyoffice_pptx"

    // Template
    let templateDocument                            = "document"
    let templateSpreadsheet                         = "spreadsheet"
    let templatePresentation                        = "presentation"
    
    // Rich Workspace
    let fileNameRichWorkspace                       = "Readme.md"
    
    @objc let dismissAfterSecond: TimeInterval      = 4
    @objc let dismissAfterSecondLong: TimeInterval  = 10
    
    // Error
    @objc let ErrorBadRequest: Int                  = 400
    @objc let ErrorResourceNotFound: Int            = 404
    @objc let ErrorConflict: Int                    = 409
    @objc let ErrorBadServerResponse: Int           = -1011
    @objc let ErrorInternalError: Int               = -99999
    @objc let ErrorFileNotSaved: Int                = -99998
    @objc let ErrorDecodeMetadata: Int              = -99997
    @objc let ErrorE2EENotEnabled: Int              = -99996
    @objc let ErrorOffline: Int                     = -99994
    @objc let ErrorCharactersForbidden: Int         = -99993
    @objc let ErrorCreationFile: Int                = -99992
    
    // Constants to identify the different permissions of a file
    @objc let permissionShared                      = "S"
    @objc let permissionCanShare                    = "R"
    @objc let permissionMounted                     = "M"
    @objc let permissionFileCanWrite                = "W"
    @objc let permissionCanCreateFile               = "C"
    @objc let permissionCanCreateFolder             = "K"
    @objc let permissionCanDelete                   = "D"
    @objc let permissionCanRename                   = "N"
    @objc let permissionCanMove                     = "V"
    
    //Share permission
    //permissions - (int) 1 = read; 2 = update; 4 = create; 8 = delete; 16 = share; 31 = all (default: 31, for public shares: 1)
    @objc let permissionReadShare: Int              = 1
    @objc let permissionUpdateShare: Int            = 2
    @objc let permissionCreateShare: Int            = 4
    @objc let permissionDeleteShare: Int            = 8
    @objc let permissionShareShare: Int             = 16
    
    @objc let permissionMinFileShare: Int           = 1
    @objc let permissionMaxFileShare: Int           = 19
    @objc let permissionMinFolderShare: Int         = 1
    @objc let permissionMaxFolderShare: Int         = 31
    @objc let permissionDefaultFileRemoteShareNoSupportShareOption: Int     = 3
    @objc let permissionDefaultFolderRemoteShareNoSupportShareOption: Int   = 15
    
    // Metadata : FileType
    @objc let metadataTypeFileAudio                 = "audio_file"
    @objc let metadataTypeFileCompress              = "compress"
    @objc let metadataTypeFileDirectory             = "directory"
    @objc let metadataTypeFileDocument              = "document"
    @objc let metadataTypeFileImage                 = "image"
    @objc let metadataTypeFileUnknown               = "unknow"
    @objc let metadataTypeFileVideo                 = "video"
    @objc let metadataTypeFileImagemeter            = "imagemeter"
    
    // Filename Mask and Type
    @objc let keyFileNameMask                       = "fileNameMask"
    @objc let keyFileNameType                       = "fileNameType"
    @objc let keyFileNameAutoUploadMask             = "fileNameAutoUploadMask"
    @objc let keyFileNameAutoUploadType             = "fileNameAutoUploadType"
    @objc let keyFileNameOriginal                   = "fileNameOriginal"
    @objc let keyFileNameOriginalAutoUpload         = "fileNameOriginalAutoUpload"
    @objc let keyFileNameOriginalAutoUploadPrefs    = "fileNameOriginalAutoUploadPrefs"


    // Selector
    @objc let selectorDownloadFile                  = "downloadFile"
    @objc let selectorDownloadAllFile               = "downloadAllFile"
    @objc let selectorReadFile                      = "readFile"
    @objc let selectorListingFavorite               = "listingFavorite"
    @objc let selectorLoadFileView                  = "loadFileView"
    @objc let selectorLoadFileQuickLook             = "loadFileQuickLook"
    @objc let selectorLoadCopy                      = "loadCopy"
    @objc let selectorLoadOffline                   = "loadOffline"
    @objc let selectorOpenIn                        = "openIn"
    @objc let selectorUploadAutoUpload              = "uploadAutoUpload"
    @objc let selectorUploadAutoUploadAll           = "uploadAutoUploadAll"
    @objc let selectorUploadFile                    = "uploadFile"
    @objc let selectorSaveAlbum                     = "saveAlbum"
    @objc let selectorSaveAlbumLivePhotoIMG         = "saveAlbumLivePhotoIMG"
    @objc let selectorSaveAlbumLivePhotoMOV         = "saveAlbumLivePhotoMOV"

    // Metadata : Status
    //
    // 1) wait download/upload
    // 2) in download/upload
    // 3) downloading/uploading
    // 4) done or error
    //
    @objc let metadataStatusNormal: Int             = 0

    @objc let metadataStatustypeDownload: Int       = 1

    @objc let metadataStatusWaitDownload: Int       = 2
    @objc let metadataStatusInDownload: Int         = 3
    @objc let metadataStatusDownloading: Int        = 4
    @objc let metadataStatusDownloadError: Int      = 5

    @objc let metadataStatusTypeUpload: Int         = 6

    @objc let metadataStatusWaitUpload: Int         = 7
    @objc let metadataStatusInUpload: Int           = 8
    @objc let metadataStatusUploading: Int          = 9
    @objc let metadataStatusUploadError: Int        = 10
    @objc let metadataStatusUploadForcedStart: Int  = 11
    
    // Notification Center

    @objc let notificationCenterApplicationDidEnterBackground   = "applicationDidEnterBackground"
    @objc let notificationCenterApplicationWillEnterForeground  = "applicationWillEnterForeground"

    @objc let notificationCenterInitializeMain                  = "initializeMain"
    @objc let notificationCenterChangeTheming                   = "changeTheming"
    @objc let notificationCenterChangeUserProfile               = "changeUserProfile"
    @objc let notificationCenterRichdocumentGrabFocus           = "richdocumentGrabFocus"
    @objc let notificationCenterReloadDataNCShare               = "reloadDataNCShare"
    @objc let notificationCenterCloseRichWorkspaceWebView       = "closeRichWorkspaceWebView"

    @objc let notificationCenterReloadDataSource                = "reloadDataSource"                 // userInfo: ocId?, serverUrl?
    @objc let notificationCenterReloadDataSourceNetworkForced   = "reloadDataSourceNetworkForced"    // userInfo: serverUrl?

    @objc let notificationCenterChangeStatusFolderE2EE          = "changeStatusFolderE2EE"           // userInfo: serverUrl

    @objc let notificationCenterDownloadStartFile               = "downloadStartFile"                // userInfo: ocId
    @objc let notificationCenterDownloadedFile                  = "downloadedFile"                   // userInfo: ocId, selector, errorCode, errorDescription
    @objc let notificationCenterDownloadCancelFile              = "downloadCancelFile"               // userInfo: ocId

    @objc let notificationCenterUploadStartFile                 = "uploadStartFile"                  // userInfo: ocId
    @objc let notificationCenterUploadedFile                    = "uploadedFile"                     // userInfo: ocId, ocIdTemp, errorCode, errorDescription
    @objc let notificationCenterUploadCancelFile                = "uploadCancelFile"                 // userInfo: ocId

    @objc let notificationCenterProgressTask                    = "progressTask"                     // userInfo: account, ocId, serverUrl, status, progress, totalBytes, totalBytesExpected
    
    @objc let notificationCenterCreateFolder                    = "createFolder"                     // userInfo: ocId
    @objc let notificationCenterDeleteFile                      = "deleteFile"                       // userInfo: ocId, fileNameView, typeFile, onlyLocal
    @objc let notificationCenterRenameFile                      = "renameFile"                       // userInfo: ocId, errorCode, errorDescription
    @objc let notificationCenterMoveFile                        = "moveFile"                         // userInfo: ocId, serverUrlTo
    @objc let notificationCenterCopyFile                        = "copyFile"                         // userInfo: ocId, serverUrlFrom
    @objc let notificationCenterFavoriteFile                    = "favoriteFile"                     // userInfo: ocId

    @objc let notificationCenterMenuSearchTextPDF               = "menuSearchTextPDF"
    @objc let notificationCenterMenuDetailClose                 = "menuDetailClose"
    
    @objc let notificationCenterChangedLocation                 = "changedLocation"
    @objc let notificationStatusAuthorizationChangedLocation    = "statusAuthorizationChangedLocation"
    @objc let notificationImagePreviewRotateImage    = "imagePreviewRotateImage"
}

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

//DispatchQueue.main.async
//DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
//DispatchQueue.global().async
//DispatchQueue.global(qos: .background).async

//#if targetEnvironment(simulator)
//#endif


//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//dispatch_async(dispatch_get_main_queue(), ^{
//dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {

//#if TARGET_OS_SIMULATOR
//#endif

