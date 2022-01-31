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
    
    func testCurrentScreen() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let sharingScreen = app.otherElements["view_sharing_screen"]
        let sharingScreenShow = sharingScreen.waitForExistence(timeout: 5)
        XCTAssert(sharingScreenShow)
    }
    
    func testShareInfo() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let shareInfo = app.staticTexts.element(boundBy: 4).label
        let message =  "You can create links or send shares by mail. If you invite MagentaCLOUD users, you have more opportunities for collaboration."
        XCTAssertEqual(shareInfo, message, "Sharing message should be same")
    }
    
    func testEmailDescription() throws{
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailDescription = elementsQuery.staticTexts.element(boundBy: 0).label
        XCTAssertEqual(emailDescription, "Personal share by mail", "Email Description should match")
    }
    
    // Func link to folder
    func testCreateLink() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Create Link"].tap()
        let cell = app.tables.containing(.staticText, identifier: "Link to folder").element(boundBy: 0)
        XCTAssertTrue(cell.isHittable)
    }

    func testTestfieldMessage() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        let textFieldPlaceholder = emailAddressTextField.placeholderValue
        XCTAssertEqual(textFieldPlaceholder, "Contact name or email address", "Textfiled placeholder message should match")
    }
    
    func testCreateLinkButtonTitle() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let buttonTitle = elementsQuery.buttons.element(boundBy: 0).label
        XCTAssertEqual(buttonTitle, "Create Link", "Button Title should match")
    }
    
    func testTextFieldAction() throws {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(10)
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        let advancePermissionScreen = app.otherElements["view_advance_sharing_screen"]
        let advancePermissionScreenShow = advancePermissionScreen.waitForExistence(timeout: 5)
        XCTAssert(advancePermissionScreenShow)
    }
    
//    func testEmailFieldDescriptionColor() throws {
//        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
//        let elementsQuery = app.scrollViews.otherElements
//        let emailDescription = elementsQuery.staticTexts.element(boundBy: 0).label
//        XCTAssertEqual(emailDescription, "Personal share by mail", "Email Description should match")
//    }
}
