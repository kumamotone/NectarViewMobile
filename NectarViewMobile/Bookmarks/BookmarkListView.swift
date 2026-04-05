import SwiftUI
import NectarCore

struct BookmarkListView: View {
    @ObservedObject var imageLoader: ImageLoader
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                if imageLoader.bookmarks.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("NoBookmarks", comment: ""),
                        systemImage: "bookmark",
                        description: Text(NSLocalizedString("NoBookmarksDescription", comment: ""))
                    )
                } else {
                    ForEach(imageLoader.bookmarks, id: \.self) { index in
                        Button {
                            imageLoader.updateSafeCurrentIndex(index)
                            isPresented = false
                        } label: {
                            HStack {
                                if index < imageLoader.images.count,
                                   let image = imageLoader.getImage(for: imageLoader.images[index]) {
                                    Image(platformImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }

                                VStack(alignment: .leading) {
                                    Text(NSLocalizedString("Page", comment: "") + " \(index + 1)")
                                        .font(.headline)
                                    if index < imageLoader.images.count {
                                        Text(imageLoader.getDisplayName(for: imageLoader.images[index], at: index))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Bookmarks", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Close", comment: "")) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
