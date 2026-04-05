import SwiftUI
import NectarCore

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section(NSLocalizedString("Appearance", comment: "")) {
                    ColorPicker(
                        NSLocalizedString("Background Color", comment: ""),
                        selection: $appSettings.backgroundColor
                    )
                    ColorPicker(
                        NSLocalizedString("Control Bar Color", comment: ""),
                        selection: $appSettings.controlBarColor
                    )
                }

                // Reading
                Section(NSLocalizedString("Reading", comment: "")) {
                    Toggle(
                        NSLocalizedString("Spread View", comment: ""),
                        isOn: $appSettings.isSpreadViewEnabled
                    )
                    if appSettings.isSpreadViewEnabled {
                        Toggle(
                            NSLocalizedString("Right to Left Reading", comment: ""),
                            isOn: $appSettings.isRightToLeftReading
                        )
                        Toggle(
                            NSLocalizedString("Realistic Appearance", comment: ""),
                            isOn: $appSettings.useRealisticAppearance
                        )
                    }
                }

                // Reset
                Section {
                    Button(role: .destructive) {
                        appSettings.resetToDefaults()
                    } label: {
                        Text(NSLocalizedString("Reset to Defaults", comment: ""))
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
