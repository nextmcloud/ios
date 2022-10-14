//
//  NextcloudTestForCommentSection.swift
//  NextcloudTestForCommentSection
//
//  Created by A200073704 on 11/10/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import XCTest
@testable import Nextcloud
class NextcloudTestForCommentSection: XCTestCase {

    var test: NCShare!
    
    override func setUpWithError() throws {
        
       try super.setUpWithError()
        test = NCShare()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        test = nil
       try super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testForShareSelected() throws {
 
        let share = test.isShareSelected
        XCTAssertTrue(share)
       
    }
    
    func testForCommentSelected() {
        
        let comment = !test.isShareSelected
        XCTAssertFalse(comment)
        
    }
    
    func testForDateTimeZone() {
        
       // let startOfToday = Calendar.startOfDay(for: Date())
        let date = Calendar.current.timeZone
        XCTAssertEqual(date, TimeZone.current)
        
        
    }
    
    func testForWeekDays() {
        
        let symbols = Calendar.current.shortWeekdaySymbols
        XCTAssertNotNil(symbols)
    }
    
    func testForSeconds() {
        
        let offsetFromGMT = Calendar.current.timeZone.secondsFromGMT()
        XCTAssertEqual(offsetFromGMT, 19800)
        
    }
    
    func testRegionIdentifier() {
        
        let identifier = Calendar.current.identifier
        XCTAssertEqual(identifier, identifier)
    }
    
    func testDates() {
    
        let date =  !test.sectionDates.isEmpty
        XCTAssertFalse(date)
    }
    
    
    
    func testForInCorrectDateFormat() {
        
        let date = CCUtility.getTitleSectionDate(Date())
        XCTAssertNotEqual(date, "1999-09-10", "Incorrect Date Format")
    }
    
    
  

}







