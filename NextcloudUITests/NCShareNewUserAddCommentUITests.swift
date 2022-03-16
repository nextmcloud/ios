//
//  NCShareNewUserAddCommentUITests.swift
//  NextcloudUITests
//
//  Created by A200020526 on 20/01/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCShareNewUserAddCommentUITests: XCTestCase {

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
    
    func navigateToScreen() {
        app.collectionViews.cells.otherElements.containing(.button, identifier:"share").children(matching: .button).element(boundBy: 0).tap()
        let elementsQuery = app.scrollViews.otherElements
        let emailAddressTextField = elementsQuery.textFields["Contact name or email address"]
        emailAddressTextField.tap()
        emailAddressTextField.typeText("amrut.waghmare@t-systems.com")
        app/*@START_MENU_TOKEN@*/.buttons["Return"]/*[[".keyboards",".buttons[\"return\"]",".buttons[\"Return\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.otherElements["drop_down"].tables.staticTexts["amrut.waghmare@t-systems.com"].tap()
        app.buttons["Next"].tap()
    }
    
    func testCurrentScreen() throws {
        navigateToScreen()
        let addCommentScreen = app.otherElements["view_new_user_add_comment_screen"]
        let addCommentScreenShow = addCommentScreen.waitForExistence(timeout: 5)
        XCTAssert(addCommentScreenShow)
    }

    func testSendShareButtonActionNavigation() throws {
        navigateToScreen()
        app.buttons["Send share"].tap()
        sleep(5)
        let sharingScreen = app.otherElements["view_sharing_screen"]
        let sharingScreenShow = sharingScreen.waitForExistence(timeout: 5)
        XCTAssert(sharingScreenShow)
    }
    
    func testTextboxText() throws {
        navigateToScreen()
        let textView = app.textViews.element(boundBy: 0)
        textView.tap()
        textView.typeText("Welcome")
        let textViewValue = textView.value
        XCTAssertEqual(textViewValue as! String, "Welcome", "Text View value should match")
    }
    
}
