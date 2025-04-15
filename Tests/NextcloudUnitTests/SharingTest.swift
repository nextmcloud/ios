//
//  SharingTest.swift
//  NextcloudTests
//
//  Created by A200020526 on 07/06/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud
final class SharingTest: XCTestCase {

    var button: UIButton?
    var ncShare: NCShare?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        button = UIButton()
        ncShare = NCShare()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        button = nil
        ncShare = nil
        super.tearDown()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    //Date exntesion test case
    func testTomorrow() {
        let tomorrow = Date.tomorrow
        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(tomorrow.extendedIso8601String, expectedTomorrow.extendedIso8601String, "Tomorrow date should be correct.")
    }
    func testToday() {
        let today = Date.today
        let currentDate = Date()
        XCTAssertEqual(today.extendedIso8601String, currentDate.extendedIso8601String, "Today date should be correct.")
    }
    
    func testDayAfter() {
        let date = Date()
        let dayAfter = date.dayAfter
        let expectedDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        XCTAssertEqual(dayAfter.extendedIso8601String, expectedDayAfter.extendedIso8601String, "Day after date should be correct.")
    }
    
    //Date Formatter extension Test Case
    func testShareExpDate() {
        let dateFormatter = DateFormatter.shareExpDate
        
        XCTAssertEqual(dateFormatter.formatterBehavior, .behavior10_4, "Formatter behavior should be correct.")
        XCTAssertEqual(dateFormatter.dateStyle, .medium, "Date style should be correct.")
        XCTAssertEqual(dateFormatter.dateFormat, NCShareAdvancePermission.displayDateFormat, "Date format should be correct.")
    }
    
    //Button Extension test case
    func testSetBackgroundColor() {
            // Arrange
            let color = UIColor.red
            let state: UIControl.State = .normal
            
            // Act
            button?.setBackgroundColor(color, for: state)
            
            // Assert
            XCTAssertNotNil(button?.currentBackgroundImage, "Button background image not nil")
        }
        
        func testSetBackgroundColorForDifferentStates() {
            // Arrange

            let selectedColor = UIColor.green
            
            // Act
            button?.isSelected = true
            button?.setBackgroundColor(selectedColor, for: .selected)
            
            // Assert
            XCTAssertNotNil(button?.currentBackgroundImage, "Button background image not nil")
            button?.isSelected = false
            XCTAssertNil(button?.currentBackgroundImage,"Button background image will be nil")
            button?.isHighlighted = true
            XCTAssertNil(button?.currentBackgroundImage, "Button background image will be nil")
        }
    
    //UIView extension shadow test case
    func testAddShadowWithLocation() {
         // Create a UIView instance
         let view = UIView()
         
         // Set the shadow with bottom location
         view.addShadow(location: .bottom, height: 2, color: .red, opacity: 0.4, radius: 2)
         
         // Verify that the shadow offset is set correctly for the bottom location
         let bottomShadowOffset = view.layer.shadowOffset
         XCTAssertEqual(bottomShadowOffset, CGSize(width: 0, height: 2), "Shadow offset not set correctly for bottom location")
         
         // Verify that the shadow color is set correctly
         let shadowColor = view.layer.shadowColor
         XCTAssertEqual(shadowColor, UIColor.red.cgColor, "Shadow color not set correctly")
         
         // Verify that the shadow opacity is set correctly
         let shadowOpacity = view.layer.shadowOpacity
         XCTAssertEqual(shadowOpacity, 0.4, "Shadow opacity not set correctly")
         
         // Verify that the shadow radius is set correctly
         let shadowRadius = view.layer.shadowRadius
         XCTAssertEqual(shadowRadius, 2.0, "Shadow radius not set correctly")
     }
     
     func testAddShadowWithOffset() {
         // Create a UIView instance
         let view = UIView()
         
         // Set the shadow with a custom offset
         view.addShadow(offset: CGSize(width: 0, height: -4), color: .blue, opacity: 0.6, radius: 3)
         
         // Verify that the shadow offset is set correctly
         let shadowOffset = view.layer.shadowOffset
         XCTAssertEqual(shadowOffset, CGSize(width: 0, height: -4), "Shadow offset not set correctly")
         
         // Verify that the shadow color is set correctly
         let shadowColor = view.layer.shadowColor
         XCTAssertEqual(shadowColor, UIColor.blue.cgColor, "Shadow color not set correctly")
         
         // Verify that the shadow opacity is set correctly
         let shadowOpacity = view.layer.shadowOpacity
         XCTAssertEqual(shadowOpacity, 0.6, "Shadow opacity not set correctly")
         
         // Verify that the shadow radius is set correctly
         let shadowRadius = view.layer.shadowRadius
         XCTAssertEqual(shadowRadius, 3.0, "Shadow radius not set correctly")
     }
    
    func testAddShadowForLocation() {
            // Create a UIView instance
            let view = UIView()

            // Add shadow to the bottom
        view.addShadow(location: .bottom, color: UIColor.black)

            // Verify that the shadow properties are set correctly for the bottom location
            XCTAssertEqual(view.layer.shadowOffset, CGSize(width: 0, height: 2), "Shadow offset not set correctly for bottom location")
            XCTAssertEqual(view.layer.shadowColor, UIColor.black.cgColor, "Shadow color not set correctly for bottom location")
            XCTAssertEqual(view.layer.shadowOpacity, 0.4, "Shadow opacity not set correctly for bottom location")
            XCTAssertEqual(view.layer.shadowRadius, 2.0, "Shadow radius not set correctly for bottom location")

            // Add shadow to the top
            view.addShadow(location: .top)

            // Verify that the shadow properties are set correctly for the top location
            XCTAssertEqual(view.layer.shadowOffset, CGSize(width: 0, height: -2), "Shadow offset not set correctly for top location")
            XCTAssertEqual(view.layer.shadowColor, NCBrandColor.shared.customerDarkGrey.cgColor, "Shadow color not set correctly for top location")
            XCTAssertEqual(view.layer.shadowOpacity, 0.4, "Shadow opacity not set correctly for top location")
            XCTAssertEqual(view.layer.shadowRadius, 2.0, "Shadow radius not set correctly for top location")
        }

        func testAddShadowForOffset() {
            // Create a UIView instance
            let view = UIView()

            // Add shadow with custom offset
            view.addShadow(offset: CGSize(width: 2, height: 2))

            // Verify that the shadow properties are set correctly for the custom offset
            XCTAssertEqual(view.layer.shadowOffset, CGSize(width: 2, height: 2), "Shadow offset not set correctly for custom offset")
            XCTAssertEqual(view.layer.shadowColor, UIColor.black.cgColor, "Shadow color not set correctly for custom offset")
            XCTAssertEqual(view.layer.shadowOpacity, 0.5, "Shadow opacity not set correctly for custom offset")
            XCTAssertEqual(view.layer.shadowRadius, 5.0, "Shadow radius not set correctly for custom offset")
        }


        func testHasUploadPermission() {
            // Create an instance of NCShare
            let share = NCShare()

            // Define the input parameters
            let tableShareWithUploadPermission = tableShare()
            tableShareWithUploadPermission.permissions = NCGlobal.shared.permissionMaxFileShare

            let tableShareWithoutUploadPermission = tableShare()
            tableShareWithoutUploadPermission.permissions = NCGlobal.shared.permissionReadShare

            // Call the hasUploadPermission function
            let hasUploadPermission1 = share.hasUploadPermission(tableShare: tableShareWithUploadPermission)
            let hasUploadPermission2 = share.hasUploadPermission(tableShare: tableShareWithoutUploadPermission)

            // Verify the results
            XCTAssertTrue(hasUploadPermission1, "hasUploadPermission returned false for a tableShare with upload permission")
            XCTAssertFalse(hasUploadPermission2, "hasUploadPermission returned true for a tableShare without upload permission")
        }
    
    func testGetImageShareType() {
        let sut = NCShareCommon() // Replace with the actual class containing the getImageShareType function
        
        // Test case 1: SHARE_TYPE_USER
        let shareType1 = sut.SHARE_TYPE_USER
        let result1 = sut.getImageShareType(shareType: shareType1)
        XCTAssertEqual(result1, UIImage(named: "shareTypeEmail")?.imageColor(NCBrandColor.shared.label))
        
        // Test case 2: SHARE_TYPE_GROUP
        let shareType2 = sut.SHARE_TYPE_GROUP
        let result2 = sut.getImageShareType(shareType: shareType2)
        XCTAssertEqual(result2, UIImage(named: "shareTypeGroup")?.imageColor(NCBrandColor.shared.label))
        
        // Test case 3: SHARE_TYPE_LINK
        let shareType3 = sut.SHARE_TYPE_LINK
        let result3 = sut.getImageShareType(shareType: shareType3)
        XCTAssertEqual(result3, UIImage(named: "shareTypeLink")?.imageColor(NCBrandColor.shared.label))
        
        // Test case 4: SHARE_TYPE_EMAIL (with isDropDown=false)
        let shareType4 = sut.SHARE_TYPE_EMAIL
        let result4 = sut.getImageShareType(shareType: shareType4)
        XCTAssertEqual(result4, UIImage(named: "shareTypeUser")?.imageColor(NCBrandColor.shared.label))
        
        // Test case 5: SHARE_TYPE_EMAIL (with isDropDown=true)
        let shareType5 = sut.SHARE_TYPE_EMAIL
        let isDropDown5 = true
        let result5 = sut.getImageShareType(shareType: shareType5, isDropDown: isDropDown5)
        XCTAssertEqual(result5, UIImage(named: "email")?.imageColor(NCBrandColor.shared.label))
        }
}
