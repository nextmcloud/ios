//
//  PrivacySettingsView.swift
//  Nextcloud
//
//  Created by A106551118 on 28/08/25.
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct PrivacySettingsView: View {
    @AppStorage("isAnalysisDataCollectionSwitchOn") private var isAnalysisDataCollectionSwitchOn: Bool = false
    @AppStorage("showSettingsButton") private var isShowSettingsButton: Bool = false
    @State private var requiredDataCollection: Bool = true

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                Form {
                    Section(footer:
                        Text(NSLocalizedString("_privacy_settings_help_text_", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    ) {
                        EmptyView()
                    }

                    // --- Required Data Collection
                    Section(footer:
                        Text(NSLocalizedString("_required_data_collection_help_text_", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    ) {
                        Toggle(isOn: $requiredDataCollection) {
                            Text(NSLocalizedString("_required_data_collection_", comment: ""))
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: NCBrandColor.shared.brand)))
                    }

                    // --- Analysis Data Collection
                    Section(footer:
                        Text(NSLocalizedString("_analysis_data_acqusition_help_text_", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    ) {
                        Toggle(isOn: $isAnalysisDataCollectionSwitchOn) {
                            Text(NSLocalizedString("_analysis_data_acqusition_", comment: ""))
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: NCBrandColor.shared.brand)))
                        .onChange(of: isAnalysisDataCollectionSwitchOn) { newValue in
                            handleAnalysisDataCollectionSwitchChanged(newValue)
                        }
                    }

                    // --- Save Button (styled like SaveSettingsCustomButtonCell)
                    if isShowSettingsButton {
                        Section {
                            Button(action: saveSettings) {
                                Text(NSLocalizedString("_save_settings_", comment: ""))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(uiColor: NCBrandColor.shared.brand))
                                    .cornerRadius(5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color(uiColor: NCBrandColor.shared.brand), lineWidth: 1)
                                    )
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                } // Form
                .background(Color(.systemGroupedBackground))
            } // ZStack
            .navigationBarTitle(Text(NSLocalizedString("_privacy_settings_title_", comment: "")), displayMode: .inline)
        } // NavigationView
    } // body

    // MARK: - Actions

    private func saveSettings() {
        print("save settings clicked")
        presentationMode.wrappedValue.dismiss()
    }

    private func handleAnalysisDataCollectionSwitchChanged(_ isOn: Bool) {
        if isOn {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    if status == .denied {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:])
                        }
                    }
                }
            }
        }
        UserDefaults.standard.set(isOn, forKey: "isAnalysisDataCollectionSwitchOn")
    }
}

#if DEBUG
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
    }
}
#endif
