//
//  NCCreateFormUploadScanDocumentTests.swift
//  NextcloudTests
//
//  Created by A200020526 on 20/04/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud

class NCCreateFormUploadScanDocumentTests: XCTestCase {
    var sut: NCCreateFormUploadScanDocument!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func setUp() {
        super.setUp()
        sut = NCCreateFormUploadScanDocument.init(serverUrl: appDelegate.activeServerUrl, arrayImages: [])
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func testChangeCompressionImage() {
        let image = sut.changeCompressionImage(UIImage(named: "directory")!)
        let newDataCount = image.pngData()?.count ?? 0
        let originalDataCount = UIImage(named: "directory")!.pngData()?.count ?? 0
        XCTAssertLessThan(newDataCount, originalDataCount, "new image should be less in size")
    }
}
