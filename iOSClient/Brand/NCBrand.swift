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

// MARK: - Configuration

@objc class NCBrandConfiguration: NSObject {
    @objc static let shared: NCBrandConfiguration = {
        let instance = NCBrandConfiguration()
        return instance
    }()

    @objc public let configuration_bundleId: String = "it.twsweb.Nextcloud"
    @objc public let configuration_serverUrl: String = "serverUrl"
    @objc public let configuration_username: String = "username"
    @objc public let configuration_password: String = "password"
}

// MARK: - Options

@objc class NCBrandOptions: NSObject {
    @objc static let shared: NCBrandOptions = {
        let instance = NCBrandOptions()
        return instance
    }()
    
    @objc public var brand:                             String = "MagentaCLOUD"//"Nextcloud"
    @objc public var brandCloud:                             String = "CLOUD"//"Nextcloud"
    // @objc public var mailMe:                            String = "ios@nextcloud.com"                              // Deprecated
    @objc public var textCopyrightNextcloudiOS:         String = "MagentaCLOUD for iOS %@ © 2021"
    @objc public var textCopyrightNextcloudServer:      String = "MagentaCLOUD Server %@"
    @objc public var loginBaseUrl:                      String = "https://dev1.next.magentacloud.de/"
    @objc public var pushNotificationServerProxy:       String = "https://push-notifications.nextcloud.com"
    @objc public var linkLoginHost:                     String = "https://nextcloud.com/install"
    @objc public var linkloginPreferredProviders:       String = "https://nextcloud.com/signup-ios";
    @objc public var webLoginAutenticationProtocol:     String = "nc://"                                            // example "abc://"

    @objc public var privacy:                           String = "https://nextcloud.com/privacy"
    @objc public var sourceCode:                        String = "https://github.com/nextcloud/ios"

    // Personalized
    @objc public var webCloseViewProtocolPersonalized: String = ""                                                 // example "abc://change/plan"      Don't touch me !!
    @objc public var folderBrandAutoUpload: String = ""                                                 // example "_auto_upload_folder_"   Don't touch me !!

    // Auto Upload default folder
   // @objc public var folderDefaultAutoUpload:           String = "Photos"

    // Capabilities Group
    @objc public var capabilitiesGroups:              String = "group.de.magentacloud.next.dev2.client"

    // User Agent
    @objc public var userAgent:                         String = "Magenta-iOS"                                    // Don't touch me !!
    
    // Options
    @objc public var use_login_web_personalized:        Bool = true                                                // Don't touch me !!
    @objc public var use_default_auto_upload:           Bool = false
    @objc public var use_themingColor:                Bool = false
    //@objc public var use_themingBackground:           Bool = false
    @objc public var use_themingLogo:                   Bool = false
    @objc public var use_storeLocalAutoUploadAll:       Bool = false
    @objc public var use_configuration:                 Bool = false                                                // Don't touch me !!
    @objc public var use_loginflowv2:                   Bool = false                                                // Don't touch me !!

    @objc public var disable_intro:       Bool = false
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

    @objc public var folderDefaultAutoUpload: String {
        get {
            if Locale.current.languageCode == "de" {
                return "Kamera-Medien"
            } else {
                return "Camera-Media"
            }
        }
    }
    
    override init() {

        if folderBrandAutoUpload != "" {
            //folderDefaultAutoUpload = folderBrandAutoUpload
        }
    }
    
    
}

//MARK: - Color
class NCBrandColor: NSObject {
    @objc static let shared: NCBrandColor = {
        let instance = NCBrandColor()
        //instance.setDarkMode()
        instance.createImagesThemingColor()
        instance.createUserColors()
        return instance
    }()

    struct cacheImages {
        static var file = UIImage()

        static var shared = UIImage()
        static var sharedWithMe = UIImage()
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
        static var buttonRestore = UIImage()
        
        static var imgShare = UIImage()
        static var imgMore = UIImage()
    }

    // Color
    public var userColors: [CGColor] = []
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
//    @objc public var backgroundView:        UIColor = NCBrandColor.shared.secondarySystemGroupedBackground
    @objc public var backgroundForm:        UIColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
    @objc public var textView:              UIColor = .black//label
//    @objc public var separator:             UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    @objc public var tabBar:                UIColor = .white
    @objc public let nextcloud:             UIColor = UIColor(red: 0.0/255.0, green: 130.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    @objc public let nextcloudSoft:         UIColor = UIColor(red: 90.0/255.0, green: 160.0/255.0, blue: 210.0/255.0, alpha: 1.0)
    @objc public let gray:                  UIColor = UIColor(red: 104.0/255.0, green: 104.0/255.0, blue: 104.0/255.0, alpha: 1.0)
    @objc public var icon:                  UIColor = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)//iconColor
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
    
    @objc public var memoryConsuptionBackground: UIColor {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return  UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
                } else {
                    return  UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
                }
            } else {
                return  UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    @objc public var gray60: UIColor {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return  UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
            } else {
                return  UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
            }
        } else {
            return  UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
        }
    }
    
    @objc public var commonViewInfoText: UIColor =  UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public var tileSelectionImageColor:        UIColor = .white
    //@objc public var backgroundCell:        UIColor = .white
    @objc public var seperatorRename:             UIColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)

    @objc public var fileFolderName:          UIColor = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public var searchFieldPlaceHolder:          UIColor = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public var singleTitleColorButton:          UIColor = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
    @objc public var quickStatusTextColor:          UIColor = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    @objc public var shareCellTitleColor:    UIColor = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    @objc public var shareByEmailTextColor:    UIColor = UIColor(displayP3Red: 13.0/255.0, green: 57.0/255.0, blue: 223.0/255.0, alpha: 1.0)
    //@objc public var dotMenuGray: UIColor = UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1.0)
    @objc public var sublineGray: UIColor = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    @objc public let nmcYellowFavorite:        UIColor = UIColor(red: 254.0/255.0, green: 203.0/255.0, blue: 0/255.0, alpha: 1.0)
    @objc public let nmcGray30:        UIColor = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    @objc public let nmcGray70:        UIColor = UIColor(red: 254.0/255.0, green: 203.0/255.0, blue: 0/255.0, alpha: 1.0)
    
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
        
    @objc public var nmcGray1: UIColor{
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return  UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
                }else {
                    return  UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1.0)
                }
            } else {
                return  UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1.0)
        }
       
    }
    
    @objc public var nmcSeparator: UIColor{
        return  UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
    }
    
    @objc public var nmcCommonViewInfoText: UIColor{
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return  UIColor(displayP3Red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
                }else {
                    return  UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1.0)
                }
            }else{
                return  UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1.0)
        }
       
    }
    
    @objc public var notificationAction: UIColor {
        return UIColor(red: 0/255.0, green: 153/255.0, blue: 255/255.0, alpha: 1.0)
    }
    
    @objc public var nmcGray0: UIColor{
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return  UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
                }else {
                    return  UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
                }
            }else{
           return  UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
        }
    }
    
    @objc public var nmcGray70CellSelection: UIColor{
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return  UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
                }else {
                    return  UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
                }
            }else{
           return  UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        }
    }

    @objc public var nmcIconSharedWithMe: UIColor{
        return  UIColor(displayP3Red: 0.0/255.0, green: 153.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    @objc public var nmcGray80: UIColor {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return  UIColor(displayP3Red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
            }else {
                return  UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
            }
        }else{
            return  UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
        }
    }
    
    @objc public var nmcGray80TabBar: UIColor {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return  UIColor(displayP3Red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
            } else {
                return .white
            }
        } else {
            return .white
        }
    }
    
    override init() {
        self.brand = self.customer
//        self.brandElement = self.customer
        self.brandElement = self.customerDefault
        self.brandText = self.customerText
    }
    
    public func createImagesThemingColor() {
        
        let gray: UIColor = UIColor(red: 162.0/255.0, green: 162.0/255.0, blue: 162.0/255.0, alpha: 0.5)

        cacheImages.file = UIImage.init(named: "file")!
        
        cacheImages.shared = UIImage(named: "share")!.image(color: gray60, size: 50)
        cacheImages.sharedWithMe = UIImage.init(named: "cloudUpload")!.image(color: nmcIconSharedWithMe, size: 50)
        cacheImages.canShare = UIImage(named: "share")!.image(color: gray60, size: 50)
        cacheImages.shareByLink = UIImage(named: "sharebylink")!.image(color: nmcGray1, size: 50)
        
        cacheImages.favorite = NCUtility.shared.loadImage(named: "star.fill", color: yellowFavorite)
        cacheImages.comment = UIImage(named: "comment")!.image(color: gray, size: 50)
        cacheImages.livePhoto = NCUtility.shared.loadImage(named: "livephoto", color: label)
        cacheImages.offlineFlag = UIImage.init(named: "offlineFlag")!
        cacheImages.local = UIImage.init(named: "local")!
            
        let folderWidth: CGFloat = UIScreen.main.bounds.width / 3
        cacheImages.folderEncrypted = UIImage(named: "folderEncrypted")!
        cacheImages.folderSharedWithMe = UIImage(named: "folder_shared_with_me")!
        cacheImages.folderPublic = UIImage(named: "folder_public")!
        cacheImages.folderGroup = UIImage(named: "folder_group")!
        cacheImages.folderExternal = UIImage(named: "folder_external")!
        //cacheImages.folderAutomaticUpload = UIImage(named: "folderAutomaticUpload")!.image(color: brandElement, size: folderWidth)
        cacheImages.folderAutomaticUpload = UIImage(named: "folderAutomaticUpload")!

        cacheImages.folder =  UIImage(named: "folder_nmcloud")!
        
        cacheImages.checkedYes = UIImage(named: "checkedYes")!
        cacheImages.checkedNo = NCUtility.shared.loadImage(named: "circle", color: graySoft)
        
        cacheImages.buttonMore = UIImage(named: "more")!.image(color: gray60, size: 50)
        cacheImages.buttonStop = UIImage(named: "stop")!.image(color: iconColor, size: 50)
        cacheImages.imgShare = UIImage(named: "share")!
        cacheImages.imgMore = UIImage(named: "more")!
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
//            fileFolderName = .white
//            tileSelectionImageColor = .black
//            seperatorRename = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
//            quickStatusTextColor = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
//            shareCellTitleColor = UIColor(displayP3Red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
//        } else {
//            tabBar = .white
//            backgroundView = .white
//            backgroundCell = .white
//            backgroundForm = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
//            textView = .black
////            separator = UIColor(red: 208.0/255.0, green: 209.0/255.0, blue: 212.0/255.0, alpha: 1.0)
////            separator = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
//            select = self.brandElement.withAlphaComponent(0.1)
//            avatarBorder = .white
//            // reassign default color
//            icon = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
//            actionCellBackgroundColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 1.0)
//            gray26AndGrayf2 = UIColor(red: 38.0/255.0, green: 38.0/255.0, blue: 38.0/255.0, alpha: 1.0)
//            fileFolderName = UIColor(displayP3Red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1.0)
//            searchImageColor = icon
//            memoryConsuptionBackground = backgroundCell
//            systemGrayAndGray66 = .gray
//            tileSelectionImageColor = .white
//            seperatorRename = UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1.0)
//            quickStatusTextColor = UIColor(red: 178.0/255.0, green: 178.0/255.0, blue: 178.0/255.0, alpha: 1.0)
//            shareCellTitleColor = UIColor(red: 25.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1.0)
//        }
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
    
    private func stepCalc(steps: Int, color1: CGColor, color2: CGColor) -> [CGFloat] {
        var step = [CGFloat](repeating: 0, count: 3)
        step[0] = (color2.components![0] - color1.components![0]) / CGFloat(steps)
        step[1] = (color2.components![1] - color1.components![1]) / CGFloat(steps)
        step[2] = (color2.components![2] - color1.components![2]) / CGFloat(steps)
        return step
    }

    private func mixPalette(steps: Int, color1: CGColor, color2: CGColor) -> [CGColor] {
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

    /**
     Generate colors from the official nextcloud color.
     You can provide how many colors you want (multiplied by 3).
     if `step` = 6,
     3 colors \* 6 will result in 18 generated colors
     */
    func generateColors(steps: Int = 6) -> [CGColor] {
        let red = UIColor(red: 182/255, green: 70/255, blue: 157/255, alpha: 1).cgColor
        let yellow = UIColor(red: 221/255, green: 203/255, blue: 85/255, alpha: 1).cgColor
        let blue = UIColor(red: 0/255, green: 130/255, blue: 201/255, alpha: 1).cgColor

        let palette1 = mixPalette(steps: steps, color1: red, color2: yellow)
        let palette2 = mixPalette(steps: steps, color1: yellow, color2: blue)
        let palette3 = mixPalette(steps: steps, color1: blue, color2: red)
        return palette1 + palette2 + palette3
    }

    private func stepCalc(steps: Int, color1: CGColor, color2: CGColor) -> [CGFloat] {
        var step = [CGFloat](repeating: 0, count: 3)
        step[0] = (color2.components![0] - color1.components![0]) / CGFloat(steps)
        step[1] = (color2.components![1] - color1.components![1]) / CGFloat(steps)
        step[2] = (color2.components![2] - color1.components![2]) / CGFloat(steps)
        return step
    }

    private func mixPalette(steps: Int, color1: CGColor, color2: CGColor) -> [CGColor] {
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

    /**
     Generate colors from the official nextcloud color.
     You can provide how many colors you want (multiplied by 3).
     if `step` = 6,
     3 colors \* 6 will result in 18 generated colors
     */
    func generateColors(steps: Int = 6) -> [CGColor] {
        let red = UIColor(red: 182/255, green: 70/255, blue: 157/255, alpha: 1).cgColor
        let yellow = UIColor(red: 221/255, green: 203/255, blue: 85/255, alpha: 1).cgColor
        let blue = UIColor(red: 0/255, green: 130/255, blue: 201/255, alpha: 1).cgColor

        let palette1 = mixPalette(steps: steps, color1: red, color2: yellow)
        let palette2 = mixPalette(steps: steps, color1: yellow, color2: blue)
        let palette3 = mixPalette(steps: steps, color1: blue, color2: red)
        return palette1 + palette2 + palette3
    }
}
