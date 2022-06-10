//
//  NCCreateFormUploadScanDocumentUITests.swift
//  NextcloudUITests
//
//  Created by A200020526 on 20/04/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest

class NCCreateFormUploadScanDocumentUITests: XCTestCase {
    
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
        app.tabBars["Tab Bar"].buttons["Add and upload"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Scan document"]/*[[".cells.staticTexts[\"Scan document\"]",".staticTexts[\"Scan document\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(2)
    }
    
    func testFileNameTextField() throws {
        navigateToScreen()
        let fileNameTextField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(fileNameTextField.isEnabled, "File Name text field should be enabled")
    }
    
    func testPDFSwitch() throws {
        navigateToScreen()
        let pdfSwitch = app.switches.element(boundBy: 2)
        let title = pdfSwitch.label
        XCTAssertEqual(title, "PDF", "PDF switch title should match")
        pdfSwitch.tap()
        XCTAssertTrue((pdfSwitch.value as! String) == "1")
    }
    
    func testSetPasswordFieldActiveEnabledPDFSwitchOn() throws {
        navigateToScreen()
        let pdfSwitch = app.switches.element(boundBy: 2)
        let passwordSwitch = app.switches.element(boundBy: 5)
        XCTAssertFalse(passwordSwitch.isEnabled, "Password field switch should be disabled if PDF switch is not ON")
        pdfSwitch.tap()
        XCTAssertTrue(passwordSwitch.isEnabled, "Password field switch should be enabled if PDF switch is ON")
    }
    
    func testPDFOCRSwitch() throws {
        navigateToScreen()
        let pdfOCRSwitch = app.switches.element(boundBy: 0)
        let title = pdfOCRSwitch.label
        XCTAssertEqual(title, "PDF (OCR)", "PDF (OCR) switch title should match")
        pdfOCRSwitch.tap()
        XCTAssertTrue((pdfOCRSwitch.value as! String) == "1")
    }
    
    func testSetPasswordFieldActiveEnabledPDFOCRSwitchOn() throws {
        navigateToScreen()
        let pdfOCRSwitch = app.switches.element(boundBy: 0)
        let passwordSwitch = app.switches.element(boundBy: 5)
        XCTAssertFalse(passwordSwitch.isEnabled, "Password field switch should be disabled if PDF switch is not ON")
        pdfOCRSwitch.tap()
        XCTAssertTrue(passwordSwitch.isEnabled, "Password field switch should be enabled if PDF switch is ON")
    }
    
    func testTextFileSwitch() throws {
        navigateToScreen()
        let textFileSwitch = app.switches.element(boundBy: 1)
        let title = textFileSwitch.label
        XCTAssertEqual(title, "Textfile (txt)", "Textfile (txt) switch title should match")
        textFileSwitch.tap()
        XCTAssertTrue((textFileSwitch.value as! String) == "1")
    }
    func testJPGSwitch() throws {
        navigateToScreen()
        let jpgSwitch = app.switches.element(boundBy: 3)
        let title = jpgSwitch.label
        XCTAssertEqual(title, "JPG", "JPG switch title should match")
        jpgSwitch.tap()
        XCTAssertTrue((jpgSwitch.value as! String) == "1")
    }
    func testPNGSwitch() throws {
        navigateToScreen()
        let pngSwitch = app.switches.element(boundBy: 4)
        let title = pngSwitch.label
        XCTAssertEqual(title, "PNG", "PNG switch title should match")
        pngSwitch.tap()
        XCTAssertTrue((pngSwitch.value as! String) == "1")
    }
    func testSetPassworSwitch() throws {
        navigateToScreen()
        let setPasswordSwitch = app.switches.element(boundBy: 5)
        let title = setPasswordSwitch.label
        XCTAssertEqual(title, "Set password", "Set password switch title should match")
    }
}
