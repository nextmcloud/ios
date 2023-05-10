//
//  AutoUploadTestCase.swift
//  NextcloudTests
//
//  Created by A200073704 on 09/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit
import XLForm


class AutoUploadTestCase: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAutoUploadSectionIsAdded() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor

        //  the section with the title "Auto Upload"
        row = XLFormRowDescriptor(tag: "autoUpload", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_", comment: ""))
        section = XLFormSectionDescriptor.formSection(withTitle: "")
        section.footerTitle = NSLocalizedString("_autoupload_description_", comment: "");

        // Verify that section was found
        XCTAssertNotNil(row, "Expected 'AutoUpload' section to exist in form.")


    }
    
    func testAutoUploadDirectoryIsPresent() {
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        let image = UIImage(named: "foldersOnTop")
        
        row = XLFormRowDescriptor(tag: "autoUploadDirectory", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_autoupload_select_folder_", comment: ""))
        
        XCTAssertNotNil(image)
        
        XCTAssertNotNil(row , " Expected 'Autoupload' directory is present")
        
    }
    
    func testAutoUploadPhotoSectionIsPresent() {
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadImage", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_photos_", comment: ""))
        
        XCTAssertNotNil(row, " Expected 'Auto Upload Photos' is present")
        
        
    }
    
    func testAutoUploadVideoIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadVideo", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_videos_", comment: ""))
        
        XCTAssertNotNil(row, " Expected 'Auto Upload Videos' is present")
        
    }
    
    func testOnlyUseWifiConnectionIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadWWAnVideoo", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_wifi_only_", comment: ""))
        
        XCTAssertNotNil(row, " Expected 'Only use wifi connection' is present")
        
    }
    
    func testRemoveFromCameraRollIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "removePhotoCameraRoll", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_remove_photo_CameraRoll_", comment: ""))
        
        
        XCTAssertNotNil(row, " Expected 'Remove from camera roll' is present")
    }

    
    func testUploadWholeCameraRollIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadFull", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_fullphotos_", comment: ""))
        
        
        XCTAssertNotNil(row, " Expected 'Upload whole camera roll' is present")
    }
    
    func testUseSubFoldersIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadCreateSubfolder", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_create_subfolder_", comment: ""))
        
        
        XCTAssertNotNil(row, " Expected 'Use Subfolder' is present")
        
    }
    
    func testChangeFileNameMaskRowIsPresent() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        let section = XLFormSectionDescriptor.formSection()
        var row : XLFormRowDescriptor
        
        row = XLFormRowDescriptor(tag: "autoUploadFileName", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_filenamemask_", comment: ""))
        section.addFormRow(row)
        
        XCTAssertNotNil(row, " Expected 'Change filename mask' is present")
    }
    
    func testTapChangeFilenameMaskRow() {
        // Set up the form with the "Change Filename Mask" row
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        let section = XLFormSectionDescriptor.formSection()
        form.addFormSection(section)
        
        let row = XLFormRowDescriptor(tag: "autoUploadFileName", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_autoupload_filenamemask_", comment: ""))
        section.addFormRow(row)
        
        // Create a view controller with the form and add it to a navigation controller
        if let viewController = NCManageAutoUploadFileName(form: form) {
            let window = UIApplication.shared.windows.first { $0.isKeyWindow }
            let navigationController = UINavigationController(rootViewController: viewController)
            window?.rootViewController = navigationController
            
            viewController.loadViewIfNeeded()
            let indexPath = IndexPath(row: 0, section: 0)
            print("Calling didSelectRowAt for row at \(indexPath)")
            viewController.tableView.delegate?.tableView?(viewController.tableView, didSelectRowAt: indexPath)
            
            // Verify that the NCManageAutoUploadFileName class is opened
            XCTAssertTrue(navigationController.topViewController is NCManageAutoUploadFileName)
        }
        
       
    }

    

    
    

}
