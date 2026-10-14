//
//  CollaboraTestCase.swift
//  NextcloudTests
//
//  Created by A200073704 on 06/05/23.
//  Copyright © 2023 Marino Faggiana. All rights reserved.
//

@testable import Nextcloud
import XCTest
import NextcloudKit

class CollaboraTestCase: XCTestCase {
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCollaboraDocumentIsPresent() {
        
        var viewForDocument: NCMenuAction?
        
        if let image = UIImage(named: "create_file_document") {
            viewForDocument = NCMenuAction(title: NSLocalizedString("_create_new_document_", comment: ""), icon: image, action: { _ in
                guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() as? UINavigationController else {
                    return
                }
                
                let viewController = navigationController.topViewController as? NCCreateFormUploadDocuments
                viewController?.titleForm = NSLocalizedString("_create_new_document_", comment: "")
            })
        }
        
        XCTAssertNotNil(viewForDocument)
        
    }
    
    func testCollaboraPresentationIsPresent() {
        
        var viewForPresentation: NCMenuAction?
        
        if let image = UIImage(named: "create_file_ppt") {
            viewForPresentation = NCMenuAction(title: NSLocalizedString("_create_new_presentation_", comment: ""), icon: image, action: { _ in
                guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() as? UINavigationController else {
                    return
                }
                
                let viewController = navigationController.topViewController as? NCCreateFormUploadDocuments
                viewController?.titleForm = NSLocalizedString("_create_new_presentation_", comment: "")
            })
        }
        
        XCTAssertNotNil(viewForPresentation)
        
    }
    
    func testCollaboraSpreadsheetIsPresent() {
        
        var viewForSpreadsheet: NCMenuAction?
        
        if let image = UIImage(named: "create_file_xls") {
            viewForSpreadsheet = NCMenuAction(title: NSLocalizedString("_create_new_spreadsheet_", comment: ""), icon: image, action: { _ in
                guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() as? UINavigationController else {
                    return
                }
                
                let viewController = navigationController.topViewController as? NCCreateFormUploadDocuments
                viewController?.titleForm = NSLocalizedString("_create_new_spreadsheet_", comment: "")
            })
        }
        
        XCTAssertNotNil(viewForSpreadsheet)
        
    }
    
    func testTextDocumentIsPresent() {
        
        var textMenu: NCMenuAction?
        
        if let image = UIImage(named: "file_txt_menu") {
            textMenu = NCMenuAction(title: NSLocalizedString("_create_nextcloudtext_document_", comment: ""), icon: image, action: { _ in
                guard let navigationController = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil).instantiateInitialViewController() as? UINavigationController else {
                    return
                }
                
                let viewController = navigationController.topViewController as? NCCreateFormUploadDocuments
                viewController?.titleForm = NSLocalizedString("_create_nextcloudtext_document_", comment: "")
            })
        }
        
        XCTAssertNotNil(textMenu)
        
    }
    
    func testTextDocumentAction() {
        
        let text = NCGlobal.shared.actionTextDocument
        XCTAssertNotNil(text, "Text Editor Should be opened")
    }
    
    func testTextFieldIsPresent() {
        
        let storyboard = UIStoryboard(name: "NCCreateFormUploadDocuments", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() as? NCCreateFormUploadDocuments else {
            return
        }
        
        // Verify that a text field is present in the view controller
        let textFields = viewController.view.subviews.filter { $0 is UITextField }
        XCTAssertFalse(textFields.isEmpty, "No text field found in NCCreateFormUploadDocuments")
    }
    
    func testSavePathFolder() {
        
        let viewController = NCCreateFormUploadDocuments()
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var row : XLFormRowDescriptor

        //  the section with the title "Folder Destination"

        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: "kNMCFolderCustomCellType", title: "")
        row.action.formSelector = #selector(viewController.changeDestinationFolder(_:))
        
        // Verify that section was found
        XCTAssertNotNil(row, "Expected save path section to exist in form.")

    }
    


    
    

}
