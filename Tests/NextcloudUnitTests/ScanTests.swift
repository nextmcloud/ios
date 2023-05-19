//
//  ScanTests.swift
//  NextcloudTests
//
//  Created by A200020526 on 18/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import XLForm

final class ScanTests: XCTestCase {
    
    var viewController :  NCCreateFormUploadScanDocument?
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        viewController = NCCreateFormUploadScanDocument()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewController = nil
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
    
    public func testImageColor() {
        // Create a test color
        let testColor = UIColor.red
        
        // Create a test image
        let testImage = UIImage(named: "activityTypeInfo") // Replace "your_image_name" with the name of your test image
        
        // Call the imageColor function with the test color
        let resultImage = testImage?.imageColor(testColor)
        
        // Assert that the result image is not nil
        XCTAssertNotNil(resultImage, "Result image should not be nil")
        
        // Assert that the result image has the same size as the test image
        XCTAssertEqual(resultImage?.size, testImage?.size, "Result image should have the same size as the test image")
    }
    
    func testIsAtleastOneFiletypeSelected() {
        // Set up the initial switch states
        viewController?.isPDFWithOCRSwitchOn = false
        viewController?.isPDFWithoutOCRSwitchOn = false
        viewController?.isTextFileSwitchOn = false
        viewController?.isPNGFormatSwitchOn = false
        viewController?.isJPGFormatSwitchOn = false
        
        // Call the function under test
        let result1 = viewController?.isAtleastOneFiletypeSelected() ?? false
        
        // Assert the initial result
        XCTAssertFalse(result1, "None of the file types are selected initially")
        
        // Update switch states
        viewController?.isPDFWithOCRSwitchOn = true
        
        // Call the function under test again
        let result2 = viewController?.isAtleastOneFiletypeSelected() ?? false
        
        // Assert the updated result
        XCTAssertTrue(result2, "At least one file type is selected")
    }
    
    func testBestFittingFont() {
        // Set up the initial values
        let text = "Hello, World!"
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        let fontDescriptor = UIFontDescriptor(name: "Helvetica", size: 20)
        let fontColor = UIColor.black
        
        // Call the function under test
        let attributes = viewController?.bestFittingFont(for: text, in: bounds, fontDescriptor: fontDescriptor, fontColor: fontColor)
        
        // Assert the results
        XCTAssertNotNil(attributes?[NSAttributedString.Key.font], "Font attribute should not be nil")
        XCTAssertNotNil(attributes?[NSAttributedString.Key.foregroundColor], "Font color attribute should not be nil")
        XCTAssertNotNil(attributes?[NSAttributedString.Key.kern], "Kern attribute should not be nil")
        
        XCTAssertEqual(attributes?[NSAttributedString.Key.foregroundColor] as? UIColor, fontColor, "Font color should match the input value")
        
        let font = attributes?[NSAttributedString.Key.font] as? UIFont
        XCTAssertNotNil(font, "Font should not be nil")
        XCTAssertEqual(font?.fontName, fontDescriptor.fontAttributes[.name] as? String, "Font name should match the input value")
    }
    
    func testChangeCompressionImage() {
        // Set up the initial values
        guard let image = UIImage(named: "activityTypeInfo") else {
            return
        }
        
        // Call the function under test
        let compressedImage = viewController?.changeCompressionImage(image)
        
        // Assert the results
        XCTAssertNotNil(compressedImage, "Compressed image should not be nil")
        if let width = compressedImage?.size.width, let height = compressedImage?.size.height {
            XCTAssertTrue(width <= 841.8, "Compressed image width should be less than or equal to the base width")
            XCTAssertTrue(height <= 595.2, "Compressed image height should be less than or equal to the base height")
        }
    }
}
