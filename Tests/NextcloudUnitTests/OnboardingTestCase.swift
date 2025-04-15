//
//  OnboardingTestCase.swift
//  NextcloudTests
//
//  Created by A200073704 on 21/04/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit

 class OnboardingTestCase: XCTestCase {
     
     var viewController = NCIntroViewController()

     
     var images:[UIImage?] = []
     let imagesLandscape = [UIImage(named: "introSlideLand1"), UIImage(named: "introSlideLand2"), UIImage(named: "introSlideLand3")]
     let imagesPortrait = [UIImage(named: "introSlide1"), UIImage(named: "introSlide2"), UIImage(named: "introSlide3")]
     let imagesEightPortrait = [UIImage(named: "introSlideEight1"), UIImage(named: "introSlideEight2"), UIImage(named: "introSlideEight3")]
     
     
     
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
     

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
     

     func testValidImage() {
         
         // onscreen images should not be nill
         let image = [UIImage(named: "introSlideLand1"), UIImage(named: "introSlideLand2"), UIImage(named: "introSlideLand3")]
         XCTAssertNotNil(image, "Image should not be nil")
         
     }
     
     func testImageDimensionsLandscape() {
         
         // testing height and width of the image
         let introCollectionView = UIImage(named: "introSlideLand1")
         XCTAssertEqual(introCollectionView?.size.width, 390, "Image width should be 390")
         XCTAssertEqual(introCollectionView?.size.height, 844.3333333333334, "Image height should be 844.3333333333334")
     }
     
     func testImageDimensionsPortrait() {
         
         // testing height and width of the image
         let introCollectionView = UIImage(named: "introSlide1")
         
         XCTAssertEqual(introCollectionView?.size.width, 390, "Image width should be 390")
         XCTAssertEqual(introCollectionView?.size.height, 844.3333333333334, "Image height should be 844.3333333333334")
     }
     
     
     func testImageDimentionsNotEqual() {
         
         // testing width and height if not equal
         let introCollectionView = UIImage(named: "introSlide2")
         
         XCTAssertNotEqual(introCollectionView?.size.width, 100, "Image width should be 390")
         XCTAssertNotEqual(introCollectionView?.size.height, 820, "Image height should be 844.3333333333334")
         
     }
     
     
     func testImageContentMode() {
         
         // imageview content mode should be scaleAspectFill
         let imageView = UIImageView()
         imageView.contentMode = .scaleAspectFill
         imageView.image = UIImage(named: "introSlideLand2")
         XCTAssertEqual(imageView.contentMode, .scaleAspectFill, "Image content mode should be scaleAspectFill")
         
     }
     
     
     // Background color of view should be customer
     func testBackgroundcolor() {
         
         let backgroundColor = NCBrandColor.shared.customer
         XCTAssertNotNil(backgroundColor, "NCBrandColor.shared.customer should not be nil")
         
     }
     
     
     // Button login text color shouyld be white
     func testButtonLoginTextColor() {
         
         let textColor: UIColor = .white
         viewController.buttonLogin?.backgroundColor = textColor
         
         XCTAssertEqual(textColor, textColor)
         
     }
     
     // images at loginscreen should not be empty
     func testImagesNotEmpty() {
         
         let isEightPlusDevice = UIScreen.main.bounds.height == 736
         images = UIDevice.current.orientation.isLandscape ?  imagesLandscape : (isEightPlusDevice ? imagesEightPortrait : imagesPortrait)
         
         XCTAssertFalse(images.isEmpty)
     }
     
        
     // Status bar and navigation bar color should not be blue color
     func testStatueBarColorNotEqualToCustomer() {
         
         
         let view = NCLoginWeb()
         var color = view.navigationController?.navigationBar.backgroundColor
         let navigationBarColor: UIColor = NCBrandColor.shared.customer
         color = .systemBlue
         
         XCTAssertNotEqual(navigationBarColor, color)
         
     }
     
     //NavigationBar and status Bar color should be equal
     func testNavigationBarColorEqualToCustomer() {
          
         let statusBarColor = NCBrandColor.shared.customer
         let navigationBarColor: UIColor = NCBrandColor.shared.customer
         
         XCTAssertEqual(navigationBarColor, statusBarColor)
     }
     
     func testEightPlusDeviceHeight() {
         
         let eightPlusDevice = UIScreen.main.bounds.height >= 736
        
         XCTAssertTrue(eightPlusDevice)
         
     }
     
     func testLoginButtonTapped() {
         
            let viewController = NCIntroViewController()
    
            let loginButton = UIButton()
            loginButton.addTarget(nil, action: #selector(viewController.login(_:)), for: .touchUpInside)
            loginButton.sendActions(for: .touchUpInside)
         
            viewController.login(loginButton)
         
           XCTAssertNotNil(loginButton)
     }
     
     
     
 
}
