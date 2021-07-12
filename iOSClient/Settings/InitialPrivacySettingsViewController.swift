//
//  InitialPrivacySettingsViewController.swift
//  Nextcloud
//
//  Created by A107161739 on 09/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class InitialPrivacySettingsViewController: UIViewController {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var privacySettingsHelpText: UITextView!
    @IBOutlet weak var privacySettingsTitle: UILabel!
    var privacyHelpText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        privacyHelpText = NSLocalizedString("_privacy_help_text_after_login_", comment: "")
        
        privacySettingsHelpText.text = privacyHelpText
        
        privacySettingsHelpText.delegate = self
        privacySettingsHelpText.hyperLink(originalText: privacyHelpText,
                                         linkTextsAndTypes: [NSLocalizedString("_key_privacy_help_", comment: ""): LinkType.privacyPolicy.rawValue,
                                                             NSLocalizedString("_key_reject_help_", comment: ""): LinkType.reject.rawValue,
                                                             NSLocalizedString("_key_settings_help_", comment: ""): LinkType.settings.rawValue])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
}
// MARK: - UITextViewDelegate
extension InitialPrivacySettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if let linkType = LinkType(rawValue: URL.absoluteString) {
            // TODO: handle linktype here with switch or similar.
            
            print("handle link:: \(linkType)")
        }
        return false
    }
}

public extension UITextView {
    
    func hyperLink(originalText: String, linkTextsAndTypes: [String: String]) {
        
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        
        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        
        for linkTextAndType in linkTextsAndTypes {
            let linkRange = attributedOriginalText.mutableString.range(of: linkTextAndType.key)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: linkTextAndType.value, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: NCBrandColor.shared.brand, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: fullRange)
        }
        
        self.linkTextAttributes = [
            kCTForegroundColorAttributeName: UIColor.blue
        ] as [NSAttributedString.Key: Any]
        
        self.attributedText = attributedOriginalText
    }
}

enum LinkType: String {
        case reject
        case privacyPolicy
        case settings
}


