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
        
        let app = XCUIApplication()
        app.tabBars["Tab Bar"].buttons["More"].tap()
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Help"]/*[[".cells.staticTexts[\"Help\"]",".staticTexts[\"Help\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        
    }
    
    func testImprint() throws {
        
        app.tabBars["Tab Bar"].buttons["More"].tap()
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Settings"]/*[[".cells.staticTexts[\"Settings\"]",".staticTexts[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Imprint"]/*[[".cells.staticTexts[\"Imprint\"]",".staticTexts[\"Imprint\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
    }
}
