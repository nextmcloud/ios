// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import EasyTipView

extension NCCollectionViewCommon: EasyTipViewDelegate {
    func showTipAccounts() {
        guard !session.account.isEmpty,
              self is NCFiles,
              self.view.window != nil,
              !NCBrandOptions.shared.disable_multiaccount,
              self.serverUrl == utilityFileSystem.getHomeServer(session: session),
              let view = self.navigationItem.leftBarButtonItem?.customView,
              !database.tipExists(global.tipAccountRequest) else { return }
        var preferences = EasyTipView.Preferences()

        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .lightGray
        preferences.drawing.textAlignment = .left
        preferences.drawing.arrowPosition = .top
        preferences.drawing.cornerRadius = 10

        preferences.animating.dismissTransform = CGAffineTransform(translationX: 0, y: 100)
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 0, y: -100)
        preferences.animating.showInitialAlpha = 0
        preferences.animating.showDuration = 1.5
        preferences.animating.dismissDuration = 1.5

        if tipViewAccounts == nil {
            tipViewAccounts = EasyTipView(text: NSLocalizedString("_tip_accountrequest_", comment: ""), preferences: preferences, delegate: self, tip: global.tipAccountRequest)
            tipViewAccounts?.show(forView: view)
        }
    }

    func showTipAutoUpload() {
        guard !session.account.isEmpty,
              self.view.window != nil,
              self.serverUrl == utilityFileSystem.getHomeServer(session: session),
              !database.tipExists(global.tipAutoUpload) else { return }

        var preferences = EasyTipView.Preferences()

        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .lightGray
        preferences.drawing.textAlignment = .left
        preferences.drawing.arrowPosition = .top
        preferences.drawing.cornerRadius = 10
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.bottom

        preferences.animating.dismissTransform = CGAffineTransform(translationX: 0, y: 100)
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 0, y: -100)
        preferences.animating.showInitialAlpha = 0
        preferences.animating.showDuration = 1.5
        preferences.animating.dismissDuration = 1.5

        if tipViewAutoUpload == nil {
            tipViewAutoUpload = EasyTipView(text: NSLocalizedString("_tip_autoupload_", comment: ""), preferences: preferences, delegate: self, tip: global.tipAutoUpload)
            if  let item = controller?.tabBar.items?.first(where: { $0.tag == 104 }),
                let view = controller?.tabBar.viewForItem(item) {
                tipViewAutoUpload?.show(forView: view)
            }
        }
    }

    func easyTipViewDidTap(_ tipView: EasyTipView) {
        if tipView.tip == global.tipAccountRequest {
            database.addTip(global.tipAccountRequest)
        }
        if tipView.tip == global.tipAutoUpload {
            database.addTip(global.tipAutoUpload)
        }
    }

    func easyTipViewDidDismiss(_ tipView: EasyTipView) { }

    func dismissTip() {
        if !database.tipExists(global.tipAccountRequest) {
            database.addTip(global.tipAccountRequest)
        }
        if !database.tipExists(global.tipAutoUpload) {
            database.addTip(global.tipAutoUpload)
        }
        tipViewAccounts?.dismiss()
        tipViewAccounts = nil
        tipViewAutoUpload?.dismiss()
        tipViewAutoUpload = nil
    }
}
