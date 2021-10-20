//
//  NCShareTests.swift
//  NextcloudTests
//
//  Created by A118830248 on 20/10/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud

class NCShareTests: XCTestCase {
    var sut: NCShare!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "NCShare", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "sharing") as? NCShare
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
}
