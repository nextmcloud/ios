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
    
    func testQuickStatus() {
        let metadata = tableMetadata()
        metadata.directory = true
        metadata.typeFile = "directory"
        metadata.ext = ""
        sut.metadata = metadata
        let share = tableShare()
        share.shareType = 4
        share.permissions = 19
        
        sut.quickStatus(with: share, sender: UIButton())
        XCTAssertEqual(sut.quickStatusTableShare.permissions, 19, "permission should be equal")
    }
    
    func testQuickStatusLink() {
        let metadata = tableMetadata()
        metadata.directory = true
        metadata.typeFile = "directory"
        metadata.ext = ""
        sut.metadata = metadata
        let share = tableShare()
        share.shareType = 3
        
        sut.quickStatusLink(with: share, sender: UIButton())
        XCTAssertEqual(sut.quickStatusTableShare.shareType, 3, "permission should be equal")
    }
}

class NCShareCommonTests: XCTestCase {
    var sut: NCShareCommon!
    
    override func setUp() {
        super.setUp()
        sut = NCShareCommon.shared
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func testIsLinkShare() {
        XCTAssertTrue(sut.isLinkShare(shareType: 3), "value should be true")
        XCTAssertFalse(sut.isLinkShare(shareType: 1), "value should be false")
    }
    
    func testIsExternalUserShare() {
        XCTAssertTrue(sut.isExternalUserShare(shareType: 4), "value should be true")
        XCTAssertFalse(sut.isExternalUserShare(shareType: 1), "value should be false")
    }
    
    func testInternalUser() {
        XCTAssertTrue(sut.isInternalUser(shareType: 0), "value should be true")
        XCTAssertFalse(sut.isInternalUser(shareType: 1), "value should be false")
    }
    
    func testIsFileTypeAllowedForEditing() {
        XCTAssertTrue(sut.isFileTypeAllowedForEditing(fileExtension: "md", shareType: 4), "value should be true")
        XCTAssertTrue(sut.isFileTypeAllowedForEditing(fileExtension: "txt", shareType: 4), "value should be true")
        XCTAssertTrue(sut.isFileTypeAllowedForEditing(fileExtension: "png", shareType: 0), "value should be true")
        XCTAssertFalse(sut.isFileTypeAllowedForEditing(fileExtension: "png", shareType: 4), "value should be false")
    }
    
    func testIsEditingEnabled() {
        XCTAssertTrue(sut.isEditingEnabled(isDirectory: true, fileExtension: "", shareType: 0), "value should be true")
        XCTAssertTrue(sut.isEditingEnabled(isDirectory: false, fileExtension: "md", shareType: 0), "value should be true")
        XCTAssertTrue(sut.isEditingEnabled(isDirectory: false, fileExtension: "", shareType: 0), "value should be true")
        XCTAssertFalse(sut.isEditingEnabled(isDirectory: false, fileExtension: "", shareType: 4), "value should be false")
    }
    
    func testisFileDropOptionVisible() {
        XCTAssertTrue(sut.isFileDropOptionVisible(isDirectory: true, shareType: 3), "value should be true")
        XCTAssertTrue(sut.isFileDropOptionVisible(isDirectory: true, shareType: 4), "value should be true")
        XCTAssertFalse(sut.isFileDropOptionVisible(isDirectory: true, shareType: 1), "value should be false")
        XCTAssertFalse(sut.isFileDropOptionVisible(isDirectory: false, shareType: 4), "value should be false")
    }
    
    func testCanReshare() {
        XCTAssertTrue(sut.canReshare(withPermission: "RGDNV"), "value should be true")
        XCTAssertFalse(sut.canReshare(withPermission: "DNVCK"), "value should be false")
    }
}

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
