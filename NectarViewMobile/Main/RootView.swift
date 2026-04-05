import SwiftUI
import NectarCore

struct RootView: View {
    @ObservedObject var imageLoader: ImageLoader
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var isDocumentPickerPresented = false
    @State private var isSettingsPresented = false
    @State private var isBookmarkListPresented = false
    @State private var passwordInput = ""

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPickerView { url in
                imageLoader.loadImages(from: url)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
                .environmentObject(appSettings)
        }
        .sheet(isPresented: $isBookmarkListPresented) {
            BookmarkListView(imageLoader: imageLoader, isPresented: $isBookmarkListPresented)
        }
        .alert(
            NSLocalizedString("PasswordRequired", comment: ""),
            isPresented: $imageLoader.needsPassword
        ) {
            SecureField(NSLocalizedString("EnterPassword", comment: ""), text: $passwordInput)
            Button(NSLocalizedString("OK", comment: "")) {
                imageLoader.retryWithPassword(passwordInput)
                passwordInput = ""
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                imageLoader.cancelPasswordEntry()
                passwordInput = ""
            }
        }
        .onAppear {
            imageLoader.updateViewMode(appSettings: appSettings)
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        NavigationSplitView {
            SidebarView(imageLoader: imageLoader, onOpenFile: {
                isDocumentPickerPresented = true
            })
        } detail: {
            ViewerView(
                imageLoader: imageLoader,
                onOpenFile: { isDocumentPickerPresented = true },
                onOpenSettings: { isSettingsPresented = true },
                onOpenBookmarks: { isBookmarkListPresented = true }
            )
            .environmentObject(appSettings)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        ViewerView(
            imageLoader: imageLoader,
            onOpenFile: { isDocumentPickerPresented = true },
            onOpenSettings: { isSettingsPresented = true },
            onOpenBookmarks: { isBookmarkListPresented = true }
        )
        .environmentObject(appSettings)
    }
}
