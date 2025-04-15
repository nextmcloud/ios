//
//  E2EETests.swift
//  NextcloudTests
//
//  Created by A200020526 on 26/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import TOPasscodeViewController

final class E2EETests: XCTestCase {

    var manageE2EE: NCManageE2EE!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        manageE2EE = NCManageE2EE()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        manageE2EE = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // MARK: - Initialization

    func testInitialization() {
            XCTAssertTrue(manageE2EE.endToEndInitialize.delegate === manageE2EE)
            XCTAssertFalse(manageE2EE.isEndToEndEnabled)
            XCTAssertEqual(manageE2EE.statusOfService, NSLocalizedString("_status_in_progress_", comment: ""))
        }
    
    // MARK: - Delegate

        func testEndToEndInitializeSuccess() {
            manageE2EE.endToEndInitializeSuccess()
            XCTAssertTrue(manageE2EE.isEndToEndEnabled)
        }
    
    // MARK: - Passcode

        func testRequestPasscodeType() {
            // TODO: Implement this test case
        }

        func testCorrectPasscode_startE2E() {
            manageE2EE.passcodeType = "startE2E"
            manageE2EE.correctPasscode()
            // TODO: Add assertions for the expected behavior after entering the correct passcode for starting E2E
        }

        func testCorrectPasscode_readPassphrase() {
            manageE2EE.passcodeType = "readPassphrase"
            // TODO: Simulate entering the correct passcode and verify the expected behavior
        }

        func testCorrectPasscode_removeLocallyEncryption() {
            manageE2EE.passcodeType = "removeLocallyEncryption"
            // TODO: Simulate entering the correct passcode and verify the expected behavior
        }

        func testDidPerformBiometricValidationRequest() {
            let passcodeViewController = TOPasscodeViewController(passcodeType: .sixDigits, allowCancel: true)
            manageE2EE.didPerformBiometricValidationRequest(in: passcodeViewController)
            // TODO: Add assertions for the expected behavior after performing biometric validation
        }

        func testDidTapCancel() {
            let passcodeViewController = TOPasscodeViewController(passcodeType: .sixDigits, allowCancel: true)
            manageE2EE.didTapCancel(in: passcodeViewController)
            // TODO: Add assertions for the expected behavior after tapping cancel
        }
}
