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
            Spacer(minLength: 0)

            if let leftIndex = imageLoader.currentImages.0,
               let leftImage = imageLoader.getImage(for: imageLoader.images[leftIndex]) {
                bookPageView(
                    image: leftImage,
                    geometry: geometry,
                    isLeftPage: true
                )
            }

            if let rightIndex = imageLoader.currentImages.1,
               let rightImage = imageLoader.getImage(for: imageLoader.images[rightIndex]) {
                bookPageView(
                    image: rightImage,
                    geometry: geometry,
                    isLeftPage: false
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Book Page View (with realistic appearance)

    @ViewBuilder
    private func bookPageView(image: PlatformImage, geometry: GeometryProxy, isLeftPage: Bool) -> some View {
        let maxPageWidth = min(
            geometry.size.width / 2,
            geometry.size.height * (image.size.width / image.size.height)
        )

        if appSettings.useRealisticAppearance {
            Image(platformImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxPageWidth, maxHeight: geometry.size.height)
                .background(Color.white)
                .cornerRadius(3)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: isLeftPage ? 5 : -5, y: 5)
                .rotation3DEffect(.degrees(isLeftPage ? 5 : -5), axis: (x: 0, y: 1, z: 0))
                .padding(.horizontal, 10)
        } else {
            Image(platformImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxPageWidth, maxHeight: geometry.size.height)
        }
    }
}
