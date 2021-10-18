//
//  NCShareAdvancePermissionTests.swift
//  NextcloudTests
//
//  Created by A118830248 on 13/10/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud

class NCShareAdvancePermissionTests: XCTestCase {
    var sut: NCShareAdvancePermission!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func testSetTitleForNewUser() {
        sut.newUser = true
        sut.setTitle()
        XCTAssertEqual(sut.title, NSLocalizedString("_sharing_", comment: ""), "title should match")
        
        let sharee = NCCommunicationShareeMock()
        sharee.shareWith = "John"
        sut.sharee = sharee
        sut.setTitle()
        XCTAssertEqual(sut.title, "John", "title should match")
    }
    
    func testSetTitleForInternalExternalUser() {
        sut.setTitle()
        XCTAssertEqual(sut.title, NSLocalizedString("_sharing_", comment: ""), "title should match")
        
        let share = tableShare()
        share.shareType = 0
        sut.tableShare = share
        share.shareWith = "John"
        sut.setTitle()
        XCTAssertEqual(sut.title, "John", "title should match")
    }
    
    func testGetServerStyleDate() {
        let dateString = sut.getServerStyleDate(date: Date.init(timeIntervalSince1970: 0))
        XCTAssertEqual(dateString, "1970-01-01", "date format should match")
    }
    
    func testGetDisplayStyleDate() {
        let dateString = sut.getDisplayStyleDate(date: Date.init(timeIntervalSince1970: 0))
        XCTAssertEqual(dateString, "01-Jan-1970", "date format should match")
    }
    
    func testIsLinkShare() {
        sut.shareType = 3
        let value = sut.isLinkShare()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsExternalUserShare() {
        sut.shareType = 4
        let value = sut.isExternalUserShare()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsInternalUser() {
        sut.shareType = 0
        let value = sut.isInternalUser()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsFileDropOptionVisible() {
        sut.directory = true
        sut.shareType = 3
        let value = sut.isFileDropOptionVisible()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsCanReshareOptionVisible() {
        sut.shareType = 0
        let value = sut.isCanReshareOptionVisible()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsHideDownloadOptionVisible() {
        sut.shareType = 4
        let value = sut.isHideDownloadOptionVisible()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testIsPasswordOptionsVisible() {
        sut.shareType = 4
        let value = sut.isPasswordOptionsVisible()
        XCTAssertTrue(value, "value should be true")
    }
    
    func testViewDidLoad() {
        let metadata = tableMetadata()
        sut.metadata = metadata
        sut.viewDidLoad()
        XCTAssertNotNil(sut.title, "title should not be nil")
    }
    
    func testShareType() {
        sut.newUser = false
        let share = tableShare()
        share.shareType = 3
        sut.tableShare = share
        XCTAssertEqual(sut.shareType, 3, "Share type should be equal")
    }
    
    func testShareTypeForNewUser() {
        sut.newUser = true
        let sharee = NCCommunicationShareeMock()
        sharee.shareType = 3
        sut.sharee = sharee
        XCTAssertEqual(sut.shareType, 3, "Share type should be equal")
    }
    
}

class NCCommunicationShareeMock: NCCommunicationShareeProtocol {
    var circleInfo: String = ""
    var circleOwner: String = ""
    var label: String = ""
    var name: String = ""
    var shareType: Int = 0
    var shareWith: String = ""
    var uuid: String = ""
    var userClearAt: NSDate?
    var userIcon: String = ""
    var userMessage: String = ""
    var userStatus: String = ""
}
