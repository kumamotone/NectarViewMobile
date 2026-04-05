import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp"]

    private let supportedTypes: [UTType] = {
        var types: [UTType] = [
            .image,
            .pdf,
            .zip,
            .folder,
        ]
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

            let ext = url.pathExtension.lowercased()
            let isImage = DocumentPickerView.imageExtensions.contains(ext)

            if isImage {
                // Image file selected: copy all sibling images from the same folder
                // so the user can navigate between them
                let result = copySiblingImages(selectedURL: url)
                url.stopAccessingSecurityScopedResource()

                if let selectedFileURL = result {
                    onPick(selectedFileURL)
                }
            } else {
                // Archive, PDF, or folder: just copy the single file
                let destURL = copyToTempDirectory(url)
                url.stopAccessingSecurityScopedResource()

                guard let destURL = destURL else {
                    print("Failed to copy file from document picker")
                    return
                }
                onPick(destURL)
            }
        }

        /// Copies all image files from the selected image's parent folder
        /// into a temp subdirectory, then returns the URL of the selected file
        /// within that temp folder. ImageLoader.loadImagesFromFileOrFolder
        /// will discover all sibling images automatically.
        private func copySiblingImages(selectedURL: URL) -> URL? {
            let parentFolder = selectedURL.deletingLastPathComponent()

            // Try to access the parent folder
            let hasParentAccess = parentFolder.startAccessingSecurityScopedResource()
            defer {
                if hasParentAccess {
                    parentFolder.stopAccessingSecurityScopedResource()
                }
            }

            // Create a unique temp subfolder to hold the images
            let tempFolder = FileManager.default.temporaryDirectory
                .appendingPathComponent("NectarViewImages", isDirectory: true)
            try? FileManager.default.removeItem(at: tempFolder)
            try? FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)

            // Try to enumerate sibling images
            var copiedSelectedURL: URL?

            if let contents = try? FileManager.default.contentsOfDirectory(
                at: parentFolder,
                includingPropertiesForKeys: nil
            ) {
                let imageFiles = contents.filter {
                    DocumentPickerView.imageExtensions.contains($0.pathExtension.lowercased())
                }

                for imageURL in imageFiles {
                    let dest = tempFolder.appendingPathComponent(imageURL.lastPathComponent)
                    try? FileManager.default.copyItem(at: imageURL, to: dest)
                    if imageURL.lastPathComponent == selectedURL.lastPathComponent {
                        copiedSelectedURL = dest
                    }
                }
            }

            // If we couldn't read siblings (no permission), just copy the selected file
            if copiedSelectedURL == nil {
                let dest = tempFolder.appendingPathComponent(selectedURL.lastPathComponent)
                try? FileManager.default.copyItem(at: selectedURL, to: dest)
                copiedSelectedURL = dest
            }

            return copiedSelectedURL
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
