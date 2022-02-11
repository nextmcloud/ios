//
//  NCUploadVoiceMemoUITests.swift
//  NextcloudUITests
//
//  Created by tsystems on 10/02/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCUploadVoiceMemoUITests: XCTestCase {

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
    
    func testStartButtonTitle() throws {
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["Add and upload"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Create voice memo"]/*[[".cells.staticTexts[\"Create voice memo\"]",".staticTexts[\"Create voice memo\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(5)
        let button = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        button.tap()
        XCTAssertEqual(app.staticTexts.element(boundBy: 2).label, "Tap to stop")
    }

    func testUploadPhotoVideoSaveScreen() throws {
        
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["Add and upload"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Create voice memo"]/*[[".cells.staticTexts[\"Create voice memo\"]",".staticTexts[\"Create voice memo\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let button = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        button.tap()
        button.tap()
        sleep(5)
        let saveScreen = app.otherElements["view_upload_voice_note"]
        let saveScreenShow = saveScreen.waitForExistence(timeout: 5)
        XCTAssert(saveScreenShow)
    }
}
