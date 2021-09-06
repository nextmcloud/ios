//
//  PrivacySettingsViewController.swift
//  Nextcloud
//
//  Created by A107161739 on 06/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class PrivacySettingsViewController: XLFormViewController{
    
   @objc public var isShowSettingsButton: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("_privacy_settings_", comment: "")

        NotificationCenter.default.addObserver(self, selector: #selector(changeTheming), name: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeTheming), object: nil)

        let nib = UINib(nibName: "CustomSectionHeader", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "customSectionHeader")
        isShowSettingsButton = UserDefaults.standard.bool(forKey: "showSettingsButton")
        self.navigationController?.navigationBar.tintColor = NCBrandColor.shared.brand
        changeTheming()
    }
    
    @objc func changeTheming() {
        tableView.backgroundColor = NCBrandColor.shared.systemGroupedBackground
        tableView.separatorColor = .none
        tableView.reloadData()
        initializeForm()
    }

    

    //MARK: XLForm

    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("", comment: "").uppercased())
        section.footerTitle = NSLocalizedString("_privacy_settings_help_text_", comment: "")
        form.addFormSection(section)
        
//
//        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
//        row.action.formSelector = #selector(changeDestinationFolder(_:))
//        row.cellConfig["backgroundColor"] = NCBrandColor.shared.backgroundForm
//
//        row.cellConfig["imageView.image"] =  UIImage(named: "folder")!.image(color: NCBrandColor.shared.brandElement, size: 25)
//
//        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
//        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["textLabel.textColor"] = NCBrandColor.shared.label
        
        
        //custom cell
        section = XLFormSectionDescriptor.formSection(withTitle: "")
        section.footerTitle = NSLocalizedString("_required_data_collection_help_text_", comment: "")
        form.addFormSection(section)

        
        XLFormViewController.cellClassesForRowDescriptorTypes()["RequiredDataCollectionCustomCellType"] = RequiredDataCollectionSwitch.self
        
        
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: "RequiredDataCollectionCustomCellType", title: "")
        row.cellConfig["requiredDataCollectionSwitchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label //photos
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_required_data_collection_", comment: "")
        section.addFormRow(row)
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("", comment: "").uppercased())
        section.footerTitle = NSLocalizedString("_analysis_data_acqusition_help_text_", comment: "")
        form.addFormSection(section)
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["AnalysisDataCollectionCustomCellType"] = AnalysisDataCollectionSwitch.self
        
        
        row = XLFormRowDescriptor(tag: "AnalysisDataCollectionSwitch", rowType: "AnalysisDataCollectionCustomCellType", title: "")
        row.cellConfig["analysisDataCollectionSwitchControl.onTintColor"] = NCBrandColor.shared.brand
        row.cellConfig["cellLabel.textAlignment"] = NSTextAlignment.left.rawValue
        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label //photos
        row.cellConfig["cellLabel.text"] = NSLocalizedString("_analysis_data_acqusition_", comment: "")
        if(UserDefaults.standard.bool(forKey: "isAnalysisDataCollectionSwitchOn")){
            row.cellConfigAtConfigure["analysisDataCollectionSwitchControl.on"] = 1
        }else {
            row.cellConfigAtConfigure["analysisDataCollectionSwitchControl.on"] = 0
        }
        
        section.addFormRow(row)
        
        
        XLFormViewController.cellClassesForRowDescriptorTypes()["SaveSettingsButton"] = SaveSettingsCustomButtonCell.self
        
        section = XLFormSectionDescriptor.formSection(withTitle: "")
        form.addFormSection(section)
        
        
        row = XLFormRowDescriptor(tag: "SaveSettingsButton", rowType: "SaveSettingsButton", title: "")
        row.cellConfig["backgroundColor"] = UIColor.clear

//        row.cellConfig["analysisDataCollectionSwitchControl.onTintColor"] = NCBrandColor.shared.brand
//        row.cellConfig["cellLabel.textAlignment"] = NSTextAlignment.left.rawValue
//        row.cellConfig["cellLabel.font"] = UIFont.systemFont(ofSize: 15.0)
//        row.cellConfig["cellLabel.textColor"] = NCBrandColor.shared.label //photos
//        row.cellConfig["cellLabel.text"] = NSLocalizedString("_analysis_data_acqusition_", comment: "")
        
        if(isShowSettingsButton){
            section.addFormRow(row)
        }
        

        self.form = form
    }
    
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "SaveSettingsButton" {
            print("save settings clicked")
            //TODO save button state and leave the page
            self.navigationController?.popViewController(animated: true)
            
        }
        if formRow.tag == "AnalysisDataCollectionSwitch"{
            UserDefaults.standard.set((formRow.value! as AnyObject).boolValue, forKey: "isAnalysisDataCollectionSwitchOn")

        }
    
    }
    
//
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView:UIView =  UIView()
//        if section == 4{
//            let headerView = UIView()
//                    let headerCell = tableView.dequeueReusableCell(withIdentifier: "CustomSectionHeader") as! SaveSettingsCustomButtonCell
//                    headerView.addSubview(headerCell)
//                    return headerView
//        }else{
//            return headerView
//        }
//
    //}
}
