import SwiftUI
import NectarCore

struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader
    let onOpenFile: () -> Void

    var body: some View {
        List(selection: Binding(
            get: { imageLoader.currentIndex },
            set: { newValue in
                if let value = newValue {
                    imageLoader.updateSafeCurrentIndex(value)
                }
            }
        )) {
            ForEach(Array(imageLoader.images.enumerated()), id: \.offset) { index, url in
                HStack {
                    ThumbnailView(imageLoader: imageLoader, index: index)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading) {
                        Text(imageLoader.getDisplayName(for: url, at: index))
                            .font(.caption)
                            .lineLimit(2)
                    }

                    Spacer()

                    if imageLoader.bookmarks.contains(index) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .tag(index)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(NSLocalizedString("Pages", comment: ""))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onOpenFile()
                } label: {
                    Image(systemName: "folder")
                }
            }
        }
        .overlay {
            if imageLoader.images.isEmpty {
                ContentUnavailableView {
                    Label(NSLocalizedString("NoImagesLoaded", comment: ""), systemImage: "photo")
                } description: {
                    Text(NSLocalizedString("OpenFilePrompt", comment: ""))
                } actions: {
                    Button(NSLocalizedString("Open", comment: "")) {
                        onOpenFile()
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail

struct ThumbnailView: View {
    @ObservedObject var imageLoader: ImageLoader
    let index: Int

    var body: some View {
        Group {
            if index < imageLoader.images.count,
               let image = imageLoader.getImage(for: imageLoader.images[index]) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }
}
