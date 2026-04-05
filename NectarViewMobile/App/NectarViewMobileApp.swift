import SwiftUI
import StoreKit
import NectarCore

@main
struct NectarViewMobileApp: App {
    @Environment(\.requestReview) private var requestReview
    @StateObject private var appSettings = AppSettings()
    @StateObject private var imageLoader = ImageLoader()

    var body: some Scene {
        WindowGroup {
            RootView(imageLoader: imageLoader)
                .environmentObject(appSettings)
                .onReceive(NotificationCenter.default.publisher(for: .requestAppReview)) { _ in
                    requestReview()
                }
                .onOpenURL { url in
                    imageLoader.loadImages(from: url)
                }
        }
    }
}
