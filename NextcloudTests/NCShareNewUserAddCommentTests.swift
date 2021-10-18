//
//  NCShareNewUserAddCommentTests.swift
//  NextcloudTests
//
//  Created by A118830248 on 18/10/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud

class NCShareNewUserAddCommentTests: XCTestCase {
    var sut: NCShareNewUserAddComment!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "NCShareNewUserAddComment") as? NCShareNewUserAddComment
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func testSetTitleForDefault() {
        sut.setTitle()
        XCTAssertEqual(sut.title, NSLocalizedString("_sharing_", comment: ""), "title should match")
    }
    
    func testSetTitleForUpdating() {
        sut.isUpdating = true
        let share = tableShare()
        share.shareWith = "John"
        sut.tableShare = share
        sut.setTitle()
        XCTAssertEqual(sut.title, "John", "title should match")
    }
    
    func testSetTitleForNew() {
        sut.isUpdating = false
        let sharee = NCCommunicationShareeMock()
        sharee.shareWith = "John"
        sut.sharee = sharee
        sut.setTitle()
        XCTAssertEqual(sut.title, "John", "title should match")
    }
}
