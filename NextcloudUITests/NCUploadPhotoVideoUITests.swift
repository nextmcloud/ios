//
//  NCUploadPhotoVideoUITests.swift
//  NextcloudUITests
//
//  Created by tsystems on 10/02/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCUploadPhotoVideoUITests: XCTestCase {

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
    
    func navigateToScreen() {
        app.tabBars["Tab Bar"].buttons["Add and upload"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Upload photos or videos"]/*[[".cells.staticTexts[\"Upload photos or videos\"]",".staticTexts[\"Upload photos or videos\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.children(matching: .cell).element(boundBy: 10).children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 8).children(matching: .other).element.children(matching: .other).element.tap()
        app.navigationBars.buttons["Done"].tap()
        sleep(5)
    }

    func testUploadPhotoVideoSaveScreen() throws {
        navigateToScreen()
        let saveScreen = app.otherElements["view_upload_assets_screen"]
        let saveScreenShow = saveScreen.waitForExistence(timeout: 5)
        XCTAssert(saveScreenShow)
    }
    
    func testUseAutoUploadEnable() throws {
        navigateToScreen()
        let autoUploadSwitch = app.switches.element(boundBy: 0)
        autoUploadSwitch.tap()
        XCTAssertTrue((autoUploadSwitch.value as! String) == "1")
    }
    
    func testUseSubfolderEnable() throws {
        navigateToScreen()
        let subfolderSwitch = app.switches.element(boundBy: 1)
        subfolderSwitch.tap()
        XCTAssertTrue((subfolderSwitch.value as! String) == "1")
    }
    
    func testOriginalFileNameEnable() throws {
        navigateToScreen()
        let orignalFileNameSwitch = app.switches.element(boundBy: 2)
        orignalFileNameSwitch.tap()
        XCTAssertTrue((orignalFileNameSwitch.value as! String) == "1")
    }

    func testSpecifyTypeFilenameEnable() throws {
        navigateToScreen()
        let fileNameSwitch = app.switches.element(boundBy: 3)
        fileNameSwitch.tap()
        XCTAssertTrue((fileNameSwitch.value as! String) == "1")
    }
    
    func testUploadPhotoVideoCancel() throws {
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["Add and upload"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Upload photos or videos"]/*[[".cells.staticTexts[\"Upload photos or videos\"]",".staticTexts[\"Upload photos or videos\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.children(matching: .cell).element(boundBy: 10).children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 8).children(matching: .other).element.children(matching: .other).element.tap()
        app.navigationBars.buttons["Done"].tap()
        app.navigationBars["Upload photos or videos"].buttons["Save"].tap()
        app.alerts["File conflict"].scrollViews.otherElements.buttons["Replace"].tap()
    }
}
