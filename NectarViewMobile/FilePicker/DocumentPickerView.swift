import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    private let supportedTypes: [UTType] = {
        var types: [UTType] = [
            .image,
            .pdf,
            .zip,
        ]
        // Archive types
        let archiveExtensions = ["rar", "7z", "tar", "gz", "bz2", "xz", "lha", "lzh", "cab", "cbz", "cbr"]
        for ext in archiveExtensions {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        return types
    }()

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }

            // Copy to app's temporary directory for persistent access.
            // Must complete copy before releasing security scope.
            let destURL = copyToTempDirectory(url)
            url.stopAccessingSecurityScopedResource()

            guard let destURL = destURL else {
                print("Failed to copy file from document picker")
                return
            }
            onPick(destURL)
        }

        private func copyToTempDirectory(_ url: URL) -> URL? {
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: url, to: dest)
                return dest
            } catch {
                print("Failed to copy file: \(error)")
                return nil
            }
        }
    }
}
