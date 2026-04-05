import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(NSLocalizedString("NectarView Help", comment: ""))
                        .font(.largeTitle)
                        .padding(.bottom)

                    HelpSection(
                        title: NSLocalizedString("Getting Started", comment: ""),
                        content: NSLocalizedString("Tap the folder icon to open image files, PDF files, or ZIP archives from the Files app. You can also drag and drop files onto the app.", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("Navigation", comment: ""),
                        content: NSLocalizedString("• Swipe left or right to switch between images.\n• Tap the left or right edge of the screen to change pages.\n• Double-tap to zoom in/out.\n• Pinch to zoom.\n• Single tap to show/hide controls.", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("View Modes", comment: ""),
                        content: NSLocalizedString("• Single Page View: Displays one page at a time.\n• Spread View (Right to Left): Displays two pages side by side, right page first (for manga).\n• Spread View (Left to Right): Displays two pages side by side, left page first.", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("Bookmarks", comment: ""),
                        content: NSLocalizedString("• Tap the bookmark icon to add/remove a bookmark.\n• Long press the image to access bookmark navigation.\n• View all bookmarks from the menu.", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("Auto Page Turn", comment: ""),
                        content: NSLocalizedString("Tap the play button to start auto page turn. Tap the timer icon to adjust the interval (0.5 to 30 seconds).", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("Customization", comment: ""),
                        content: NSLocalizedString("Access Settings from the menu to customize:\n• Background color\n• Control bar color\n• Reading direction\n• Realistic page appearance", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("Supported File Formats", comment: ""),
                        content: NSLocalizedString("NectarView supports the following file formats:\n• Images: PNG, JPEG, GIF, BMP, TIFF, WebP\n• Archives: ZIP\n• Documents: PDF", comment: "")
                    )

                    HelpSection(
                        title: NSLocalizedString("iPad Keyboard Shortcuts", comment: ""),
                        content: NSLocalizedString("When using a hardware keyboard:\n• Open File: Command+O\n• Single Page: Command+1\n• Spread (RTL): Command+2\n• Spread (LTR): Command+3\n• Zoom In/Out: Command+/Command-\n• Reset Zoom: Command+0\n• Rotate: Command+R / Command+L\n• Bookmark: Command+B", comment: "")
                    )
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("NectarView Help", comment: ""))
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

private struct HelpSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }
}
