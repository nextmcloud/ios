//
//  SettingsTestCases.swift
//  NextcloudTests
//
//  Created by A200073704 on 12/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit
import XLForm

 class SettingsTestCases: XCTestCase {
     

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
     
     // MARK: - Settings
     
     func testAutoUploadSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

         var section : XLFormSectionDescriptor
         var row : XLFormRowDescriptor
         
         let image = UIImage(named: "autoUpload")
         row = XLFormRowDescriptor(tag: "autoUpload", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_settings_autoupload_", comment: ""));
         section = XLFormSectionDescriptor.formSection(withTitle: "")
         section.addFormRow(row)

         XCTAssertNotNil(image)
         // Verify that section was found
         XCTAssertNotNil(row, "Expected 'Auto Upload' section to exist in form.")


     }
     
     func testLockSectionIsPresent() {
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

         var section : XLFormSectionDescriptor
         var row : XLFormRowDescriptor
         
         let image = UIImage(named: "lock_open")
         row = XLFormRowDescriptor(tag: "bloccopasscode", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_lock_not_active_", comment: ""));
         section = XLFormSectionDescriptor.formSection(withTitle: "")
         section.addFormRow(row)
         
         XCTAssertNotNil(image)
         
         XCTAssertNotNil(row, "Expected 'Lock Active / Off ' section exists")

         
     }
     
     func testEnableTouchIDSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

         var section : XLFormSectionDescriptor
         var row : XLFormRowDescriptor
         
         row = XLFormRowDescriptor(tag: "enableTouchDaceID", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_enable_touch_face_id_", comment: ""));
         section = XLFormSectionDescriptor.formSection(withTitle: "")
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Enable/Disable touch ID' is present")
         
     }
     
     func testEndToEndEncryptionSectionIsPresent() {
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

         var section : XLFormSectionDescriptor
         var row : XLFormRowDescriptor
         
         row = XLFormRowDescriptor(tag: "e2eEncryption", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_e2e_settings_", comment: ""));
         section = XLFormSectionDescriptor.formSection(withTitle: "")
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'End to End encryption' section exists")
         
         
     }
     
     func testAdvancedSectionIsPresent() {
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

         var section : XLFormSectionDescriptor
         var row : XLFormRowDescriptor
         
         row = XLFormRowDescriptor(tag: "advanced", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_e2e_settings_", comment: ""));
         section = XLFormSectionDescriptor.formSection(withTitle: "")
         section.addFormRow(row)
         
         XCTAssertNotNil(row, " Expected 'Advanced' Section exists")
     }
     
     
         
     func testNavigatesToOpenSourceViewController() {
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "buttonLeftAligned", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_used_opensource_software_", comment: ""))
         section.addFormRow(row)
         
         // Create a view controller with the form and add it to a navigation controller
         let viewController = OpenSourceSoftwareViewController()
         let window = UIApplication.shared.windows.first { $0.isKeyWindow }
         let navigationController = UINavigationController(rootViewController: viewController)
         window?.rootViewController = navigationController
         
         viewController.loadViewIfNeeded()
         let indexPath = IndexPath(row: 0, section: 0)
         print("Calling didSelectRowAt for row at \(indexPath)")
         
         // Verify that the OpenSourceSoftwareViewController class is opened
         XCTAssertTrue(navigationController.topViewController is OpenSourceSoftwareViewController)
         
     }
     
     func testHelpSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "buttonLeftAligned", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_help_", comment: ""))
         section.addFormRow(row)
         
         // Create a view controller with the form and add it to a navigation controller
         let viewController = HelpViewController()
         let window = UIApplication.shared.windows.first { $0.isKeyWindow }
         let navigationController = UINavigationController(rootViewController: viewController)
         window?.rootViewController = navigationController
         
         viewController.loadViewIfNeeded()
         let indexPath = IndexPath(row: 0, section: 0)
         print("Calling didSelectRowAt for row at \(indexPath)")
         
         // Verify that the HelpViewController class is opened
         XCTAssertTrue(navigationController.topViewController is HelpViewController)
         
         XCTAssertNotNil(row, "Expected 'Help' Section is present")
         
     }
     
     func testImprintSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "buttonLeftAligned", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_imprint_", comment: ""))
         section.addFormRow(row)
         
         // Create a view controller with the form and add it to a navigation controller
         let viewController = ImprintViewController()
         let window = UIApplication.shared.windows.first { $0.isKeyWindow }
         let navigationController = UINavigationController(rootViewController: viewController)
         window?.rootViewController = navigationController
         
         viewController.loadViewIfNeeded()
         let indexPath = IndexPath(row: 0, section: 0)
         print("Calling didSelectRowAt for row at \(indexPath)")
         
         // Verify that the ImprintViewController class is opened
         XCTAssertTrue(navigationController.topViewController is ImprintViewController)
         
         XCTAssertNotNil(row, "Expected 'Imprint' Section is present")
     }
     
     func testMagentaCloudVersionSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "disablefilesapp", rowType: "kNMCCustomCellType", title: NSLocalizedString("_magentacloud_version_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'MagentaCloud Version' is present")
         
         
     }
     
     // MARK: - Advanced
     
     func testShowHiddenFilesSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "showHiddenFiles", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_show_hidden_files_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Show hidden files' section is present")
         
     }
     
     func testMostCompatibleSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "formatCompatibility", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_format_compatibility_", comment: ""))
         row.value = "1"
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Most Compatible' is present")
     }
     
     func testLivePhotoSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "livePhoto", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_upload_mov_livephoto_", comment: ""))
         if CCUtility.getLivePhoto() {
             row.value = "1"
         } else {
             row.value = "0"
         }
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Live Photo' section is present")
         
     }
     
     func testImageResolutionSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "automaticDownloadImage", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_automatic_Download_Image_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Use images in full resolution' section is present")
     }
     
     func testAppIntegrationSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "disablefilesapp", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_disable_files_app_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Disable Files App Integration' section is present")
     }
     
     func testDeleteFilesSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let row = XLFormRowDescriptor(tag: "deleteoldfiles", rowType: XLFormRowDescriptorTypeSelectorPush, title: NSLocalizedString("_delete_old_files_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(row, "Expected 'Delete all files older than..' section is present")
     }
     
     func testClearCacheSectionIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let image = UIImage(named: "trash")
         
         let row = XLFormRowDescriptor(tag: "azzeracache", rowType:XLFormRowDescriptorTypeButton, title: NSLocalizedString("_clear_cache_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(image)
         
         XCTAssertNotNil(row, "Expected 'Clear Cache' section is present")
         
     }
     
     func testLogoutButtonIsPresent() {
         
         let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
         form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
         let section = XLFormSectionDescriptor.formSection()
         form.addFormSection(section)
         
         let image = UIImage(named: "xmark")
         
         let row = XLFormRowDescriptor(tag: "esci", rowType: XLFormRowDescriptorTypeButton, title: NSLocalizedString("_exit_", comment: ""))
         section.addFormRow(row)
         
         XCTAssertNotNil(image)
         
         XCTAssertNotNil(row, "Expected 'Logout' Button is present")
         
         
     }
     



     

     
     

    

}
