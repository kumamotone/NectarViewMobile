import SwiftUI
import NectarCore

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var isTipJarPresented = false

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

                // Tip Jar
                Section {
                    Button {
                        isTipJarPresented = true
                    } label: {
                        HStack {
                            Label("Tip Jar", systemImage: "heart.fill")
                                .foregroundStyle(.pink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
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
            .sheet(isPresented: $isTipJarPresented) {
                TipJarView(isPresented: $isTipJarPresented)
            }
        }
    }
}
