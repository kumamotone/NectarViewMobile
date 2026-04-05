import SwiftUI
import NectarCore

struct ImageDisplayView: View {
    @ObservedObject var imageLoader: ImageLoader
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        GeometryReader { geometry in
            Group {
                if appSettings.isSpreadViewEnabled {
                    spreadView(geometry: geometry)
                } else {
                    singlePageView(geometry: geometry)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Single Page

    @ViewBuilder
    private func singlePageView(geometry: GeometryProxy) -> some View {
        if let index = imageLoader.currentImages.0,
           let image = imageLoader.getImage(for: imageLoader.images[index]) {
            Image(platformImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Spread View

    @ViewBuilder
    private func spreadView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            if let leftIndex = imageLoader.currentImages.0,
               let leftImage = imageLoader.getImage(for: imageLoader.images[leftIndex]) {
                Image(platformImage: leftImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width / 2, maxHeight: geometry.size.height)
            }

            if let rightIndex = imageLoader.currentImages.1,
               let rightImage = imageLoader.getImage(for: imageLoader.images[rightIndex]) {
                Image(platformImage: rightImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width / 2, maxHeight: geometry.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
