//
//  NCManageE2EE.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 17/11/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import NextcloudKit
import TOPasscodeViewController
import LocalAuthentication

@objc class NCManageE2EEInterface: NSObject {

    @objc func makeShipDetailsUI(account: String) -> UIViewController {

        let details = NCViewE2EE(account: account)
        let vc = UIHostingController(rootView: details)
        vc.title = NSLocalizedString("_e2e_settings_", comment: "")
        return vc
    }
}

class NCManageE2EE: NSObject, ObservableObject, NCEndToEndInitializeDelegate, TOPasscodeViewControllerDelegate {

    let endToEndInitialize = NCEndToEndInitialize()
    let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    var passcodeType = ""

    @Published var isEndToEndEnabled: Bool = false
    @Published var statusOfService: String = NSLocalizedString("_status_in_progress_", comment: "")

    override init() {
        super.init()

        endToEndInitialize.delegate = self
        isEndToEndEnabled = NCKeychain().isEndToEndEnabled(account: appDelegate.account)
        if isEndToEndEnabled {
            statusOfService = NSLocalizedString("_status_e2ee_configured_", comment: "")
        } else {
            endToEndInitialize.statusOfService { error in
                if error == .success {
                    self.statusOfService = NSLocalizedString("_status_e2ee_on_server_", comment: "")
                } else {
                    self.statusOfService = NSLocalizedString("_status_e2ee_not_setup_", comment: "")
                }
            }
        }
    }

    // MARK: - Delegate

    func endToEndInitializeSuccess() {
        isEndToEndEnabled = true
    }

    // MARK: - Passcode

    @objc func requestPasscodeType(_ passcodeType: String) {

        let laContext = LAContext()
        var error: NSError?

        let passcodeViewController = TOPasscodeViewController(passcodeType: .sixDigits, allowCancel: true)
        passcodeViewController.delegate = self
        passcodeViewController.keypadButtonShowLettering = false
        if NCKeychain().touchFaceID, laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if error == nil {
                if laContext.biometryType == .faceID {
                    passcodeViewController.biometryType = .faceID
                    passcodeViewController.allowBiometricValidation = true
                } else if laContext.biometryType == .touchID {
                    passcodeViewController.biometryType = .touchID
                }
                passcodeViewController.allowBiometricValidation = true
                passcodeViewController.automaticallyPromptForBiometricValidation = true
            }
        }

        self.passcodeType = passcodeType
        appDelegate.window?.rootViewController?.present(passcodeViewController, animated: true)
    }

    @objc func correctPasscode() {

        switch self.passcodeType {
        case "startE2E":
            endToEndInitialize.initEndToEndEncryption()
        case "readPassphrase":
            if let e2ePassphrase = NCKeychain().getEndToEndPassphrase(account: appDelegate.account) {
                print("[INFO]Passphrase: " + e2ePassphrase)
                let message = "\n" + NSLocalizedString("_e2e_settings_the_passphrase_is_", comment: "") + "\n\n\n" + e2ePassphrase
                let alertController = UIAlertController(title: NSLocalizedString("_info_", comment: ""), message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { _ in }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("_copy_passphrase_", comment: ""), style: .default, handler: { _ in
                    UIPasteboard.general.string = e2ePassphrase
                }))
                appDelegate.window?.rootViewController?.present(alertController, animated: true)
            }
        case "removeLocallyEncryption":
            let alertController = UIAlertController(title: NSLocalizedString("_e2e_settings_remove_", comment: ""), message: NSLocalizedString("_e2e_settings_remove_message_", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_remove_", comment: ""), style: .default, handler: { _ in
                NCKeychain().clearAllKeysEndToEnd(account: self.appDelegate.account)
                self.isEndToEndEnabled = NCKeychain().isEndToEndEnabled(account: self.appDelegate.account)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default, handler: { _ in }))
            appDelegate.window?.rootViewController?.present(alertController, animated: true)
        default:
            break
        }
    }

    func passcodeViewController(_ passcodeViewController: TOPasscodeViewController, isCorrectCode code: String) -> Bool {

        if code == NCKeychain().passcode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.correctPasscode()
            }
            return true
        } else {
            return false
        }
    }

    func didPerformBiometricValidationRequest(in passcodeViewController: TOPasscodeViewController) {

        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NCBrandOptions.shared.brand) { success, _ in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    passcodeViewController.dismiss(animated: true)
                    self.correctPasscode()
                }
            }
        }
    }

    func didTapCancel(in passcodeViewController: TOPasscodeViewController) {
        passcodeViewController.dismiss(animated: true)
    }
}

// MARK: Views

struct NCViewE2EE: View {

    @ObservedObject var manageE2EE = NCManageE2EE()
    @State var account: String = ""

    @State private var showPasswordPrompt = false
    @State private var password = ""
    @State private var passwordCompletion: (@MainActor (String?) async -> Void)?

    var body: some View {

        VStack {

            if manageE2EE.isEndToEndEnabled {

                List {
                    Section(header: Text("").font(.headline),
                            footer: Text(model.statusOfService + "\n\n" + "End-to-End Encryption " + model.capabilities.e2EEApiVersion).font(.footnote)) {
                        Label {
                            Text(NSLocalizedString("_e2e_settings_activated_", comment: ""))
                                .cappedFont(.body, maxDynamicType: .accessibility2)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .cappedFont(.body, maxDynamicType: .accessibility2)
                                .fontWeight(.light)
                                .frame(width: 25, height: 25)
                                .foregroundColor(.green)
                        }
                    }

                    Section(header: Text(""), footer: Text(NSLocalizedString("_read_passphrase_description_", comment: ""))) {
                        Label {
                            Text(NSLocalizedString("_e2e_settings_read_passphrase_", comment: ""))
                                .cappedFont(.body, maxDynamicType: .accessibility2)

                        } icon: {
                            Image(systemName: "eye")
                                .resizable()
                                .scaledToFit()
                                .cappedFont(.body, maxDynamicType: .accessibility2)
                                .fontWeight(.light)
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(NCBrandColor.shared.iconImageColor))

                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if NCPreferences().passcode != nil {
                            model.requestPasscodeType("readPassphrase")
                        } else {
                            Task {
                                await showInfoBanner(windowScene: model.windowScene, text: "_e2e_settings_lock_not_active_")
                            }
                        }
                    }

                    let removeStrDesc1 = NSLocalizedString("_remove_passphrase_desc_1_", comment: "")
                    let removeStrDesc2 = NSLocalizedString("_remove_passphrase_desc_2_", comment: "")
                    let removeStrDesc = String(format: "%@\n\n%@", removeStrDesc1, removeStrDesc2)
                    Section(header: Text(""), footer: Text(removeStrDesc)) {
                        Label {
                            Text(NSLocalizedString("_e2e_settings_remove_", comment: ""))
                                .cappedFont(.body, maxDynamicType: .accessibility2)
                        } icon: {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .cappedFont(.body, maxDynamicType: .accessibility2)
                                .fontWeight(.light)
                                .frame(width: 25, height: 15)
                                .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if NCPreferences().passcode != nil {
                            model.requestPasscodeType("removeLocallyEncryption")
                        } else {
                            Task {
                                await showInfoBanner(windowScene: model.windowScene, text: "_e2e_settings_lock_not_active_")
                            }
                        }
                    }
#if DEBUG
                    if let certificateValidity = model.certificateValidity {
                        Section {
                            LabeledContent(
                                NSLocalizedString("_certificate_valid_from_", comment: ""),
                                value: certificateValidity.notBefore.formatted(
                                    date: .long,
                                    time: .standard
                                )
                            )
                            .cappedFont(.body, maxDynamicType: .accessibility2)

                            LabeledContent {
                                Text(
                                    certificateValidity.notAfter.formatted(
                                        date: .long,
                                        time: .standard
                                    )
                                )
                                .foregroundStyle(
                                    certificateExpirationColor(certificateValidity.notAfter)
                                )
                                .fontWeight(
                                    Date() >= (Calendar.current.date(
                                        byAdding: .month,
                                        value: -1,
                                        to: certificateValidity.notAfter
                                    ) ?? certificateValidity.notAfter) ? .semibold : .regular
                                )
                            } label: {
                                Text(NSLocalizedString("_certificate_valid_until_", comment: ""))
                            }
                            .cappedFont(.body, maxDynamicType: .accessibility2)

                            HStack {
                                Label {
                                    Text(NSLocalizedString("_certificate_renew_", comment: ""))
                                        .cappedFont(.body, maxDynamicType: .accessibility2)
                                } icon: {
                                    Image(systemName: "arrow.clockwise")
                                        .resizable()
                                        .scaledToFit()
                                        .cappedFont(.body, maxDynamicType: .accessibility2)
                                        .fontWeight(.light)
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color(NCBrandColor.shared.iconImageColor))
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                requestPassword { password in
                                    await model.renewCertificate(password: password)
                                }
                            }
                        } header: {
                            Text(NSLocalizedString("_certificate_", comment: ""))
                                .font(.headline)
                        }
                    }

                    deleteCerificateSection
#endif
                }
            } else {
                List {
                    Section(header: Text("").font(.headline),
                            footer: Text(model.statusOfService + "\n\n" + "End-to-End Encryption " + model.capabilities.e2EEApiVersion).font(.footnote)) {
                        HStack {
                            Label {
                                Text(NSLocalizedString("_e2e_settings_start_", comment: ""))
                                    .cappedFont(.body, maxDynamicType: .accessibility2)
                            } icon: {
                                Image(systemName: "play.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .cappedFont(.body, maxDynamicType: .accessibility2)
                                    .fontWeight(.light)
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if NCPreferences().passcode != nil {
                                model.requestPasscodeType("startE2E")
                            } else {
                                Task {
                                    await showInfoBanner(windowScene: model.windowScene, text: "_e2e_settings_lock_not_active_")
                                }
                            }
                        }
                    }
#if DEBUG
                    DeleteCerificateSection()
#endif
                }

            } else {

                List {
                    let startE2EDesc1 = NSLocalizedString("_start_e2e_encryption_1_", comment: "");
                    let startE2EDesc2 = NSLocalizedString("_start_e2e_encryption_2_", comment: "");
                    let startE2EDesc3 = NSLocalizedString("_start_e2e_encryption_3_", comment: "");
                    let startE2EDesc  = String(format: "%@\n\n%@\n\n%@",startE2EDesc1,startE2EDesc2,startE2EDesc3)
                    Section(header: Text(""), footer: Text(startE2EDesc)) {
                        HStack {
                            Label {
                                Text(NSLocalizedString("_e2e_settings_start_", comment: ""))
                            } icon: {
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let passcode = NCKeychain().passcode {
                                manageE2EE.requestPasscodeType("startE2E")
                            } else {
                                NCContentPresenter().showInfo(error: NKError(errorCode: 0, errorDescription: "_e2e_settings_lock_not_active_"))
                            }
                        }
                    }

#if DEBUG
                    DeleteCerificateSection()
#endif
                }
                .listStyle(GroupedListStyle())
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .defaultViewModifier(model)
        .onChange(of: model.navigateBack) { _, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .alert(NSLocalizedString("_password_", comment: ""), isPresented: $showPasswordPrompt) {
            SecureField(NSLocalizedString("_enter_password_", comment: ""), text: $password)

            Button(NSLocalizedString("_cancel_", comment: ""), role: .cancel) {
                password = ""
                passwordCompletion = nil
            }

            Button(NSLocalizedString("_confirm_", comment: "")) {
                guard let completion = passwordCompletion else { return }
                let submittedPassword = password.isEmpty ? nil : password

                password = ""
                passwordCompletion = nil

                Task {
                    await completion(submittedPassword)
                }
            }
        }
    }
}

struct DeleteCerificateSection: View {

    var body: some View {

    @ViewBuilder
    var deleteCerificateSection: some View {
        Section(header: Text("Delete Server keys").font(.headline),
                footer: Text("Available only in debug mode").font(.footnote)) {

            HStack {
                Label {
                    Text("Delete PublicKey")
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                        .fontWeight(.light)
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(UIColor.systemGray))
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                requestPassword { password in
                    let options = NCNetworkingE2EE().getOptions(account: model.session.account, capabilities: model.capabilities)
                    let results = await NextcloudKit.shared.deleteE2EEPublicKeyAsync(account: model.session.account, password: password, options: options)

                    if results.error == .success {
                        await showInfoBanner(windowScene: model.windowScene,
                                             text: "E2E delete publicKey")
                    } else {
                        await showErrorBanner(windowScene: model.windowScene,
                                              text: results.error.errorDescription,
                                              errorCode: results.error.errorCode)
                    }
                }
            }

            HStack {
                Label {
                    Text("Delete PrivateKey")
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                        .fontWeight(.light)
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(UIColor.systemGray))
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                requestPassword { password in
                    let options = NCNetworkingE2EE().getOptions(account: model.session.account, capabilities: model.capabilities)
                    let results = await NextcloudKit.shared.deleteE2EEPrivateKeyAsync(account: model.session.account, password: password ?? "", options: options)

                    if results.error == .success {
                        await showInfoBanner(windowScene: model.windowScene,
                                             text: "E2E delete privateKey")
                    } else {
                        await showErrorBanner(windowScene: model.windowScene,
                                              text: results.error.errorDescription,
                                              errorCode: results.error.errorCode)
                    }
                }
            }

            HStack {
                Label {
                    Text("Delete Keys and files")
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .cappedFont(.body, maxDynamicType: .accessibility2)
                        .fontWeight(.light)
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color(NCBrandColor.shared.textColor2))
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                requestPassword { password in
                    let options = NCNetworkingE2EE().getOptions(account: model.session.account, capabilities: model.capabilities)
                    let results = await NextcloudKit.shared.deleteE2EEKeysAsync(account: model.session.account, password: password ?? "", options: options)
                    if results.error == .success {
                        await showInfoBanner(windowScene: model.windowScene,
                                             text: "E2E delete Keys from FS")
                    } else {
                        await showErrorBanner(windowScene: model.windowScene,
                                              text: results.error.errorDescription,
                                              errorCode: results.error.errorCode)
                    }
                }
            }
        }
    }

    private func certificateExpirationColor(_ expirationDate: Date) -> Color {
        let warningDate = Calendar.current.date(
            byAdding: .month,
            value: -1,
            to: expirationDate
        ) ?? expirationDate

        return Date() >= warningDate ? .orange : .primary
    }

    private func requestPassword(action: @escaping @MainActor (String?) async -> Void) {
        password = ""
        passwordCompletion = action
        showPasswordPrompt = true
    }
}

// MARK: - Preview / Test

struct SectionView: View {

    @State var height: CGFloat = 0
    @State var text: String = ""

    var body: some View {
        HStack {
            Text(text)
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .bottomLeading)
    }
}

struct NCViewE2EETest: View {

    var body: some View {

        VStack {
            List {
                Section(header: SectionView(height: 50, text: "Section Header View")) {
                    Label {
                        Text(NSLocalizedString("_e2e_settings_activated_", comment: ""))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.green)
                    }
                }
                Section(header: SectionView(text: "Section Header View 42")) {
                    Label {
                        Text(NSLocalizedString("_e2e_settings_activated_", comment: ""))
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct NCViewE2EE_Previews: PreviewProvider {
    static var previews: some View {

        // swiftlint:disable force_cast
        let account = (UIApplication.shared.delegate as! AppDelegate).account
        NCViewE2EE(account: account)
        // swiftlint:enable force_cast
    }
}
