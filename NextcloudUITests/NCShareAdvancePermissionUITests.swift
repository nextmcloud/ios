//
//  NCShareAdvancePermissionUITests.swift
//  NextcloudUITests
//
//  Created by A200020526 on 19/01/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCShareAdvancePermissionUITests: XCTestCase {

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

    func testLaunchShareAdvancePermissionScreen() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let advancePermissionScreen = app.otherElements["view_advance_sharing_screen"]
        let advancePermissionScreenShow = advancePermissionScreen.waitForExistence(timeout: 5)
        XCTAssert(advancePermissionScreenShow)
    }

    func testPermissionTypeRow() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let readOnlyLabel = app.staticTexts.element(boundBy: 8).label
        let allowEditingLabel = app.staticTexts.element(boundBy: 11).label
        XCTAssertEqual(readOnlyLabel, "Read only", "Read only label should match")
        XCTAssertEqual(allowEditingLabel, "Allow editing", "Read only label should match")
    }
    
    func testPasswordSwitch() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let passwordSwitch = app.switches.element(boundBy: 1)
        passwordSwitch.tap()
        let title = passwordSwitch.label
        XCTAssertTrue((passwordSwitch.value as! String) == "1")
        XCTAssertEqual(title, "Set password", "Password title should match")
    }
    
    func testPreventDownloadSwitch() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let preventDownloadSwitch = app.switches.element(boundBy: 0)
        preventDownloadSwitch.tap()
        let title = preventDownloadSwitch.label
        XCTAssertTrue((preventDownloadSwitch.value as! String) == "1")
        XCTAssertEqual(title, "Prevent download", "Prevent Download title should match")
    }
    
    func testSetExpirationSwitch() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let setExpirationSwitch = app.switches.element(boundBy: 2)
        setExpirationSwitch.tap()
        let title = setExpirationSwitch.label
        XCTAssertTrue((setExpirationSwitch.value as! String) == "1")
        XCTAssertEqual(title, "Set expiration date", "Set expiration date title should match")
    }
}
