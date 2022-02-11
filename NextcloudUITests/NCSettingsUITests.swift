//
//  NCSettingsUITests.swift
//  NextcloudUITests
//
//  Created by tsystems on 08/02/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCSettingsUITests: XCTestCase {

    var app:XCUIApplication!
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testPrivacySettingsAnalysisDataEnable() throws {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Privacy Settings"]/*[[".cells.staticTexts[\"Privacy Settings\"]",".staticTexts[\"Privacy Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let analysisDataSwitch = app.switches.element(boundBy: 0)
        analysisDataSwitch.tap()
        XCTAssertTrue((analysisDataSwitch.value as! String) == "1")
    }
    
    func testHelp() throws {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Help"]/*[[".cells.staticTexts[\"Help\"]",".staticTexts[\"Help\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let webView = app.webViews.element(boundBy: 0)
        XCTAssertTrue(webView.staticTexts["Telekom"].firstMatch.exists)
    }
    
    func testImprint() throws {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Imprint"]/*[[".cells.staticTexts[\"Imprint\"]",".staticTexts[\"Imprint\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let webView = app.webViews.element(boundBy: 0)
        XCTAssertTrue(webView.staticTexts["Telekom"].firstMatch.exists)
    }
    
    func testOpenSourceSoftwareUsed() throws {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCUIApplication().tables/*@START_MENU_TOKEN@*/.staticTexts["OpenSource software used"]/*[[".cells.staticTexts[\"OpenSource software used\"]",".staticTexts[\"OpenSource software used\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let webView = app.webViews.element(boundBy: 0)
        XCTAssertTrue(webView.staticTexts["MIT"].firstMatch.exists)
    }
    
    func navigateToScreen() {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Auto upload"]/*[[".cells.staticTexts[\"Auto upload\"]",".staticTexts[\"Auto upload\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    func testAutoUploadEnable() throws {
        navigateToScreen()
        let autoUploadSwitch = app.switches.element(boundBy: 0)
        autoUploadSwitch.tap()
        XCTAssertTrue((autoUploadSwitch.value as! String) == "1")
    }
    
    func testAutoUploadPhotosEnable() throws {
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["OpenSource software used"]/*[[".cells.staticTexts[\"OpenSource software used\"]",".staticTexts[\"OpenSource software used\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Auto upload photos/videos"]/*[[".cells.staticTexts[\"Auto upload photos\/videos\"]",".staticTexts[\"Auto upload photos\/videos\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let autoUploadPhotoSwitch = app.switches.element(boundBy: 1)
        autoUploadPhotoSwitch.tap()
        XCTAssertTrue((autoUploadPhotoSwitch.value as! String) == "1")
    }
    
    func testOnlyUseWifiEnable() throws {
        navigateToScreen()
        let wifiSwitch = app.switches.element(boundBy: 2)
        wifiSwitch.tap()
        XCTAssertTrue((wifiSwitch.value as! String) == "1")
    }
    
    func testAutoUploadVideoEnable() throws {
        navigateToScreen()
        let videoEnableSwitch = app.switches.element(boundBy: 3)
        videoEnableSwitch.tap()
        XCTAssertTrue((videoEnableSwitch.value as! String) == "1")
    }
    
    func testOnlyUseWifiVideoEnable() throws {
        navigateToScreen()
        let wifiVideoSwitch = app.switches.element(boundBy: 4)
        wifiVideoSwitch.tap()
        XCTAssertTrue((wifiVideoSwitch.value as! String) == "1")
    }

    func testRemoveFromCameraRollEnable() throws {
        navigateToScreen()
        let removeCameraRollSwitch = app.switches.element(boundBy: 5)
        removeCameraRollSwitch.tap()
        XCTAssertTrue((removeCameraRollSwitch.value as! String) == "1")

    }

    func testAutoUploadBackgroundEnable() throws {
        navigateToScreen()
        let backgroundUploadSwitch = app.switches.element(boundBy: 6)
        backgroundUploadSwitch.tap()
        XCTAssertTrue((backgroundUploadSwitch.value as! String) == "1")
    }

    func testUploadWholeCameraRollEnable() throws {
        navigateToScreen()
        let cameraRollSwitch = app.switches.element(boundBy: 7)
        cameraRollSwitch.tap()
        XCTAssertTrue((cameraRollSwitch.value as! String) == "1")
    }

    func testUseSubfolderEnable() throws {
        navigateToScreen()
        let subfolderSwitch = app.switches.element(boundBy: 8)
        subfolderSwitch.tap()
        XCTAssertTrue((subfolderSwitch.value as! String) == "1")
    }

    
    func testOriginalFileNameEnable() throws {
        app.tabBars["Tab Bar"].buttons["More"].tap()
        let tablesQuery2 = app.tables
        let tablesQuery = tablesQuery2
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Auto upload"]/*[[".cells.staticTexts[\"Auto upload\"]",".staticTexts[\"Auto upload\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.tables.containing(.cell, identifier:"1").element/*[[".tables.containing(.other, identifier:\"This option requires the use of GPS to trigger the detection of new photos\/videos in the camera roll once the location changes significantly.\").element",".tables.containing(.other, identifier:\"After successful automatic uploads, a confirmation message will be displayed to delete the uploaded photos or videos from the camera roll. The deleted photos or videos will still be available in the iOS Photos Trash for 30 days.\").element",".tables.containing(.other, identifier:\"Currently selected folder: \/Camera-Media\").element",".tables.containing(.other, identifier:\"New photos\/videos will be automatically uploaded to your MagentaCLOUD.\").element",".tables.containing(.cell, identifier:\"0\").element",".tables.containing(.cell, identifier:\"1\").element"],[[[-1,5],[-1,4],[-1,3],[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.swipeUp()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Change filename mask"]/*[[".cells.staticTexts[\"Change filename mask\"]",".staticTexts[\"Change filename mask\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let originalFileSwitch = app.switches.element(boundBy: 0)
        originalFileSwitch.tap()
        XCTAssertTrue((originalFileSwitch.value as! String) == "1")
    }

    func testSpecifyTypeFilenameEnable() throws {
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["More"].tap()
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Auto upload"]/*[[".cells.staticTexts[\"Auto upload\"]",".staticTexts[\"Auto upload\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.tables.containing(.cell, identifier:"1").element/*[[".tables.containing(.other, identifier:\"This option requires the use of GPS to trigger the detection of new photos\/videos in the camera roll once the location changes significantly.\").element",".tables.containing(.other, identifier:\"After successful automatic uploads, a confirmation message will be displayed to delete the uploaded photos or videos from the camera roll. The deleted photos or videos will still be available in the iOS Photos Trash for 30 days.\").element",".tables.containing(.other, identifier:\"Currently selected folder: \/Camera-Media\").element",".tables.containing(.other, identifier:\"New photos\/videos will be automatically uploaded to your MagentaCLOUD.\").element",".tables.containing(.cell, identifier:\"0\").element",".tables.containing(.cell, identifier:\"1\").element"],[[[-1,5],[-1,4],[-1,3],[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.swipeUp()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Change filename mask"]/*[[".cells.staticTexts[\"Change filename mask\"]",".staticTexts[\"Change filename mask\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let fileNameSwitch = app.switches.element(boundBy: 1)
        fileNameSwitch.tap()
        XCTAssertTrue((fileNameSwitch.value as! String) == "1")
    }
}
