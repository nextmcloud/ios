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
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        Form {
            Section {
                Text(NSLocalizedString("_privacy_settings_help_text_", comment: ""))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // --- Required Data Collection (always ON, disabled)
            Section(footer:
                Text(NSLocalizedString("_required_data_collection_help_text_", comment: ""))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            ) {
                RequiredDataCollectionRow()
            }
            
            // --- Analysis Data Collection (toggle)
            Section(footer:
                Text(NSLocalizedString("_analysis_data_acqusition_help_text_", comment: ""))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            ) {
                Toggle(isOn: $isAnalysisDataCollectionSwitchOn) {
                    Text(NSLocalizedString("_analysis_data_acqusition_", comment: ""))
                        .font(.system(size: 15))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: NCBrandColor.shared.brand)))
                .onChange(of: isAnalysisDataCollectionSwitchOn) { newValue in
                    handleAnalysisDataCollectionSwitchChanged(newValue)
                }
            }
            
            // --- Save Button
            if isShowSettingsButton {
                Section {
                    SaveSettingsButton(action: saveSettings)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(NSLocalizedString("_privacy_settings_title_", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
    
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

#Preview {
    NavigationView {
        PrivacySettingsView()
    }
}

struct RequiredDataCollectionRow: View {
    @State private var isOn: Bool = true
    
    var body: some View {
        HStack {
            Text(NSLocalizedString("_required_data_collection_", comment: ""))
                .font(.system(size: 15))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(true) // not editable
                .tint(Color(uiColor: NCBrandColor.shared.brand))
        }
    }
}

struct SaveSettingsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
    }
}
