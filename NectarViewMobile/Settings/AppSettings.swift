import SwiftUI
import NectarCore

final class AppSettings: ObservableObject, AppSettingsProtocol {
    @AppStorage("backgroundColor") var backgroundColor: Color = .black
    @AppStorage("controlBarColor") var controlBarColor: Color = Color.black.opacity(0.6)
    @AppStorage("isSpreadViewEnabled") var isSpreadViewEnabled: Bool = false
    @AppStorage("isRightToLeftReading") var isRightToLeftReading: Bool = false
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"
    @AppStorage("useRealisticAppearance") var useRealisticAppearance: Bool = false
    @Published var zoomFactor: CGFloat = 1.0

    func resetToDefaults() {
        backgroundColor = .black
        controlBarColor = Color.black.opacity(0.6)
        isSpreadViewEnabled = false
        isRightToLeftReading = false
        zoomFactor = 1.0
        selectedLanguage = "system"
        useRealisticAppearance = false
    }
}
