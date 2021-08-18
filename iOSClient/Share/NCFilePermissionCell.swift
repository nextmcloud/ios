//
//  NCFilePermissionCell.swift
//  Nextcloud
//
//  Created by T-systems on 17/08/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import UIKit

class NCFilePermissionCell: XLFormButtonCell {
    
    @IBOutlet weak var seperator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageCheck: UIImageView!
    @IBOutlet weak var seperatorBelow: UIView!
    @IBOutlet weak var seperatorBelowFull: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        //        autoUploadSwitchControl.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
        
    }
    
    override func configure() {
        super.configure()
    }
    
    override func update() {
        super.update()
        
        if rowDescriptor.tag == "NCFilePermissionCellSharing" || rowDescriptor.tag == "NCFilePermissionCellAdvanceTxt" {
            self.seperator.isHidden = true
            self.seperatorBelowFull.isHidden = false
            self.titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        }
        if rowDescriptor.tag == "kNMCFilePermissionCellEditing" {
            self.seperator.isHidden = true
//            self.seperatorBelowFull.isHidden = true
        }
        
        if  rowDescriptor.tag == "NCFilePermissionCellFileDrop" {
            self.seperator.isHidden = true
            self.seperatorBelow.isHidden = true
//            self.seperatorBelowFull.isHidden = false
        }
        
        if  rowDescriptor.tag == "kNMCFilePermissionEditCellEditingCanShare" {
            self.seperatorBelowFull.isHidden = false
        }
    }
    
    @objc func switchChanged(mySwitch: UISwitch) {
        let value = mySwitch.isOn
        if value {
            //on
            self.rowDescriptor.value = value
        }else{
            self.rowDescriptor.value = value
        }
    }
    
    override func formDescriptorCellDidSelected(withForm controller: XLFormViewController!) {
        self.selectionStyle = .none
    }
    
    
}
