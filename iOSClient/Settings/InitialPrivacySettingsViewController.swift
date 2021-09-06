//
//  InitialPrivacySettingsViewController.swift
//  Nextcloud
//
//  Created by A107161739 on 09/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//

import Foundation


class InitialPrivacySettingsViewController: UIViewController {
    
    
    @IBOutlet weak var dataPrivacyImage: UIImageView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var privacySettingsHelpText: UITextView!
    @IBOutlet weak var privacySettingsTitle: UILabel!
    var privacyHelpText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        privacyHelpText = NSLocalizedString("_privacy_help_text_after_login_", comment: "")
        
        privacySettingsHelpText.text = privacyHelpText
        
        //UIImage(named: "cancel")!.image(color: NCBrandColor.shared.icon, size: 50)
        //let dataImage
        //dataPrivacyImage!.image(color: NCBrandColor.shared.icon, size: 60)
        dataPrivacyImage.image = UIImage(named: "dataPrivacy")!.image(color: NCBrandColor.shared.brand, size: 60)
        privacySettingsHelpText.delegate = self
        privacySettingsHelpText.textColor = NCBrandColor.shared.label
        privacySettingsHelpText.hyperLink(originalText: privacyHelpText,
                                         linkTextsAndTypes: [NSLocalizedString("_key_privacy_help_", comment: ""): LinkType.privacyPolicy.rawValue,
                                                             NSLocalizedString("_key_reject_help_", comment: ""): LinkType.reject.rawValue,
                                                             NSLocalizedString("_key_settings_help_", comment: ""): LinkType.settings.rawValue])
        
        acceptButton.backgroundColor = NCBrandColor.shared.brand
        acceptButton.tintColor = UIColor.white
        acceptButton.layer.cornerRadius = 5
        acceptButton.layer.borderWidth = 1
        acceptButton.layer.borderColor = NCBrandColor.shared.brand.cgColor
        self.navigationItem.leftBarButtonItem?.tintColor = NCBrandColor.shared.brand

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @IBAction func onAcceptButtonClicked(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "isInitialPrivacySettingsShowed")
        self.dismiss(animated: true, completion: nil)
    }
}
// MARK: - UITextViewDelegate
extension InitialPrivacySettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if let linkType = LinkType(rawValue: URL.absoluteString) {
            // TODO: handle linktype here with switch or similar.
            switch linkType {
            case LinkType.privacyPolicy:
                //let storyBoard: UIStoryboard = UIStoryboard(name: "NCSettings", bundle: nil)

               let privacyViewController = PrivacyPolicyViewController()
                self.navigationController?.pushViewController(privacyViewController, animated: true)
            case LinkType.reject:
                UserDefaults.standard.set(false, forKey: "isAnalysisDataCollectionSwitchOn")
                UserDefaults.standard.set(true, forKey: "isInitialPrivacySettingsShowed")
                self.dismiss(animated: true, completion: nil)
            case LinkType.settings:
                let privacySettingsViewController = PrivacySettingsViewController()
                UserDefaults.standard.set(true, forKey: "showSettingsButton")
                self.navigationController?.pushViewController(privacySettingsViewController, animated: true)
            }
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
        
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: NCBrandColor.shared.label, range: fullRange)
        for linkTextAndType in linkTextsAndTypes {
            let linkRange = attributedOriginalText.mutableString.range(of: linkTextAndType.key)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: linkTextAndType.value, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: NCBrandColor.shared.brand, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 10), range: fullRange)
        }
        
        self.linkTextAttributes = [
            kCTForegroundColorAttributeName: NCBrandColor.shared.label
        ] as [NSAttributedString.Key: Any]
        
        self.attributedText = attributedOriginalText
    }
}

enum LinkType: String {
        case reject
        case privacyPolicy
        case settings
}


