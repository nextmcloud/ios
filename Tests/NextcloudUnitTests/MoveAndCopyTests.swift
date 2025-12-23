//
//  MoveAndCopyTests.swift
//  NextcloudTests
//
//  Created by A200073704 on 05/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit


 class MoveAndCopyTests: XCTestCase {

     var view : NCSelectCommandView?
     var viewController : NCSelect?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let storyboard = UIStoryboard(name: "NCSelect", bundle: nil)
        if let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController {
            let viewController = navigationController.topViewController as? NCSelect
            
            let _ = viewController?.view
            viewController?.loadViewIfNeeded()
        }
        view = NCSelectCommandView()
       
    }
     
     override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("NCSelectCommandViewCopyMove", owner: nil, options: nil)
        view = nib?.first as? NCSelectCommandView
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        viewController = nil
        view = nil
        
    }
    
    func  testCreateFolderButton() {
        
        let image: Void? = view?.createFolderButton?.setImage(UIImage(named: "addFolder")?.withTintColor(UIColor.label), for: .normal)
        
        XCTAssertNotNil(image)
    }
    
    func testOverwriteSwitch() {

        let mySwitch = view?.overwriteSwitch
        
        XCTAssertNotNil(mySwitch)
        
    }
    
    func testCopyButton() {
        
        let copy = view?.copyButton
        
        XCTAssertNotNil(copy)
    }

     
     func testOverwriteSwitchAlwaysOn() {
         
         XCTAssertTrue(view?.overwriteSwitch?.isOn ?? false, "Overwrite Switch should always be on")
     }
     
     func testCopyButtonandMoveButtonCondition() {
         
         // Disable copy and move
         view?.copyButton?.isEnabled = false
         view?.moveButton?.isEnabled = false

         // Creating a test item
         let item = tableMetadata()
         item.serverUrl = "serverUrl" // Set the serverUrl property of the item

         let items: [tableMetadata] = [item]
        
         // Update the items in the view controller
         viewController?.items = items

         // Verify that the copy and move buttons are still disabled
         XCTAssertFalse(view?.copyButton?.isEnabled ?? true, "Copy Button should remain disabled when items.first matches the condition")
         XCTAssertFalse(view?.moveButton?.isEnabled ?? true, "Move Button should remain disabled when items.first matches the condition")

         // Enable copy and move
         view?.copyButton?.isEnabled = true
         view?.moveButton?.isEnabled = true

         // Update the items in the view controller
         viewController?.items = [] // Empty items

         // Verify that the copyButton is still enabled
         XCTAssertTrue(view?.copyButton?.isEnabled ?? false, "Copy Button should remain enabled when items.first doesn't match the condition")
         XCTAssertTrue(view?.moveButton?.isEnabled ?? false, "Move Button should remain enabled when items.first doesn't match the condition")
     }

}
