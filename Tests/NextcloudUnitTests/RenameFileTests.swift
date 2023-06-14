//
//  RenameFileTests.swift
//  NextcloudTests
//
//  Created by A200073704 on 14/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit

class RenameFileTests: XCTestCase {
    
    
    override func setUpWithError() throws {
     // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testStoryboardPresence() {
        
         let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
         XCTAssertNotNil(storyboard, "Storyboard 'NCRenameFile' should be present")
        
     }
    
    func testRenameButtonPresence() {
        let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCRenameFile else {
            XCTFail("Failed to instantiate view controller from storyboard")
            return
        }
        
        _ = viewController.view // Load the view
        
        let renameButton = viewController.renameButton
        XCTAssertNotNil(renameButton, "Rename button should be present")
    }
    
    func testRenameButtonBackgroundColor() {
        
        let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCRenameFile else {
            XCTFail("Failed to instantiate view controller from storyboard")
            return
        }
        
        _ = viewController.view // Load the view
        
        let color = NCBrandColor.shared.brand.cgColor
        let renameButton = viewController.renameButton.layer.backgroundColor
        
        XCTAssertEqual(renameButton,color, "Rename Button Bcakground Color should be brand")
    }
    
    func testCancelButtonPresence() {
        let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCRenameFile else {
            XCTFail("Failed to instantiate view controller from storyboard")
            return
        }
        
        _ = viewController.view // Load the view
        
        let cancelButton = viewController.cancelButton
        XCTAssertNotNil(cancelButton, "Cancel button should be present")
    }
    
    func testImageViewPresence() {
        
        let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCRenameFile else {
            XCTFail("Failed to instantiate view controller from storyboard")
            return
        }
        
        _ = viewController.view // Load the view
        
        let imageView = viewController.previewFile
        XCTAssertNotNil(imageView, "UIImageView should be present on the storyboard")
    }
    
    func testTextFiledPresence() {
        
        let storyboard = UIStoryboard(name: "NCRenameFile", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCRenameFile else {
            XCTFail("Failed to instantiate view controller from storyboard")
            return
        }
        
        _ = viewController.view // Load the view
        
        let textField = viewController.fileNameNoExtension
        let textFieldExt = viewController.ext
        
        XCTAssertNotNil(textField, "FileNameNoExtention TextFiled should be present on the storyboard")
        XCTAssertNotNil(textFieldExt, "Extension TextFiled should be present on the storyboard")
        
    }

    
 
}
