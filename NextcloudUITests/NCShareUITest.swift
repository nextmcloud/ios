//
//  NCShareUITest.swift
//  NextcloudUITests
//
//  Created by A200020526 on 17/01/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCShareUITest: XCTestCase {
    
    var app:XCUIApplication!
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testShareInfo() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let shareInfo = app.staticTexts.element(boundBy: 4).label
        let message =  "You can create links or send shares by mail. If you invite MagentaCLOUD users, you have more opportunities for collaboration."
        XCTAssertEqual(shareInfo, message, "Sharing message should be same")
    }
    
    
    func testCreateLink() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Create Link"].tap()
        app.tables.containing(.staticText, identifier: "Link to folder")
    }

}
