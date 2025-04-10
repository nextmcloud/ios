// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2024 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI
import NextcloudKit

@objc class NCManageE2EEInterface: NSObject {

    @objc func makeShipDetailsUI(account: String) -> UIViewController {

        let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
        let details = NCManageE2EEView(model: NCManageE2EE(controller: controller))
        let vc = UIHostingController(rootView: details)
        vc.title = NSLocalizedString("_e2e_settings_", comment: "")
        return vc
    }
}

struct NCManageE2EEView: View {
    @ObservedObject var model: NCManageE2EE
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            if model.isEndToEndEnabled {
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
                    deleteCerificateSection
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
                                model.requestPasscodeType("startE2E")
                            } else {
                                NCContentPresenter().showInfo(error: NKError(errorCode: 0, errorDescription: "_e2e_settings_lock_not_active_"))
                            }
                        }
                    }

#if DEBUG
                    deleteCerificateSection
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
    }

    @ViewBuilder
    var deleteCerificateSection: some View {
        Section(header: Text("Delete Server keys").font(.headline),
                footer: Text("Available only in debug mode").font(.footnote)) {
            HStack {
                Label {
                    Text("Delete Certificate")
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
                NextcloudKit.shared.deleteE2EECertificate(account: model.session.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: model.session.account,
                                                                                                    name: "deleteE2EECertificate")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                } completion: { _, _, error in
                    Task {
                        if error == .success {
                            await showInfoBanner(windowScene: model.windowScene,
                                                 text: "E2E delete certificate")
                        } else {
                            await showErrorBanner(windowScene: model.windowScene,
                                                  text: error.errorDescription,
                                                  errorCode: error.errorCode)
                        }
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
                NextcloudKit.shared.deleteE2EEPrivateKey(account: model.session.account) { task in
                    Task {
                        let identifier = await NCNetworking.shared.networkingTasks.createIdentifier(account: model.session.account,
                                                                                                    name: "deleteE2EEPrivateKey")
                        await NCNetworking.shared.networkingTasks.track(identifier: identifier, task: task)
                    }
                } completion: { _, _, error in
                    Task {
                        if error == .success {
                            await showInfoBanner(windowScene: model.windowScene,
                                                 text: "E2E delete privateKey")
                        } else {
                            await showErrorBanner(windowScene: model.windowScene,
                                                  text: error.errorDescription,
                                                  errorCode: error.errorCode)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
    NCManageE2EEView(model: NCManageE2EE(controller: controller))
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

struct NCManageE2EEViewTest: View {

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

struct NCManageE2EEView_Previews: PreviewProvider {
    static var previews: some View {

        // swiftlint:disable force_cast
        let controller = UIApplication.shared.firstWindow?.rootViewController as? NCMainTabBarController
        NCManageE2EEView(model: NCManageE2EE(controller: controller))
        // swiftlint:enable force_cast
    }
}
