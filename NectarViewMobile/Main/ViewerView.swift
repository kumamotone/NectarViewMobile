import SwiftUI
import NectarCore

struct ViewerView: View {
    @ObservedObject var imageLoader: ImageLoader
    @EnvironmentObject var appSettings: AppSettings

    let onOpenFile: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void

    @State private var isToolbarVisible = true
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Auto scroll
    @State private var isAutoScrolling = false
    @State private var autoScrollInterval: Double = 3.0
    @State private var autoScrollTimer: Timer?

    var body: some View {
        ZStack {
            appSettings.backgroundColor.ignoresSafeArea()

            if imageLoader.images.isEmpty && imageLoader.isInitialLoad {
                dropZoneView
            } else {
                imageContent
            }

            if isToolbarVisible && !imageLoader.images.isEmpty {
                overlayControls
            }
        }
        .statusBarHidden(!isToolbarVisible)
        .animation(.easeInOut(duration: 0.2), value: isToolbarVisible)
    }

    // MARK: - Drop Zone (initial state)

    private var dropZoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(NSLocalizedString("OpenFilePrompt", comment: "Tap to open a file"))
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                onOpenFile()
            } label: {
                Label(NSLocalizedString("Open", comment: ""), systemImage: "folder")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Image Content

    private var imageContent: some View {
        ImageDisplayView(imageLoader: imageLoader, appSettings: appSettings)
            .scaleEffect(scale)
            .offset(offset)
            .rotationEffect(appSettings.isSpreadViewEnabled ? .zero : imageLoader.currentRotation)
            .gesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1.1 {
                        scale = 1.0
                        offset = .zero
                        lastScale = 1.0
                        lastOffset = .zero
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
            .onTapGesture(count: 1) {
                withAnimation {
                    isToolbarVisible.toggle()
                }
            }
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1.0, min(lastScale * value, 8.0))
            }
            .onEnded { _ in
                lastScale = scale
                if scale < 1.1 {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                        lastScale = 1.0
                        lastOffset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if scale > 1.1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { value in
                if scale > 1.1 {
                    lastOffset = offset
                    return
                }

                let threshold: CGFloat = 50
                let horizontal = value.translation.width

                guard abs(horizontal) > abs(value.translation.height),
                      abs(horizontal) > threshold else { return }

                withAnimation(.easeInOut(duration: 0.2)) {
                    if horizontal < 0 {
                        imageLoader.showNextImage()
                    } else {
                        imageLoader.showPreviousImage()
                    }
                }
            }
    }

    // MARK: - Overlay Controls

    private var overlayControls: some View {
        VStack {
            topBar
            Spacer()
            bottomBar
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button { onOpenFile() } label: {
                Image(systemName: "folder")
            }

            Spacer()

            // Auto scroll
            Button {
                toggleAutoScroll()
            } label: {
                Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
            }

            // Bookmark
            Button {
                imageLoader.toggleBookmark()
            } label: {
                Image(systemName: imageLoader.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark")
            }

            // View mode
            Menu {
                Button(NSLocalizedString("Single Page View", comment: "")) {
                    appSettings.isSpreadViewEnabled = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                Button(NSLocalizedString("Spread View (Right to Left)", comment: "")) {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = true
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
                Button(NSLocalizedString("Spread View (Left to Right)", comment: "")) {
                    appSettings.isSpreadViewEnabled = true
                    appSettings.isRightToLeftReading = false
                    imageLoader.updateViewMode(appSettings: appSettings)
                }
            } label: {
                Image(systemName: appSettings.isSpreadViewEnabled ? "book.pages" : "doc")
            }

            // Filter
            Menu {
                ForEach(ImageFilter.allCases, id: \.self) { filter in
                    Button {
                        imageLoader.updateFilter(filter)
                    } label: {
                        HStack {
                            Text(NSLocalizedString(filter.rawValue, comment: ""))
                            if imageLoader.currentFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "camera.filters")
            }

            // More
            Menu {
                Button { onOpenBookmarks() } label: {
                    Label(NSLocalizedString("Bookmarks", comment: ""), systemImage: "bookmark.circle")
                }
                Button {
                    imageLoader.rotateImage(by: 90)
                } label: {
                    Label(NSLocalizedString("Rotate 90 Degrees", comment: ""), systemImage: "rotate.right")
                }
                Button { onOpenSettings() } label: {
                    Label(NSLocalizedString("Settings", comment: ""), systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .font(.title3)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if !imageLoader.images.isEmpty {
                Slider(
                    value: Binding(
                        get: { Double(imageLoader.currentIndex) },
                        set: { imageLoader.updateSafeCurrentIndex(Int($0)) }
                    ),
                    in: 0...max(Double(imageLoader.images.count - 1), 1),
                    step: 1
                )
                .padding(.horizontal)

                Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Auto Scroll

    private func toggleAutoScroll() {
        isAutoScrolling.toggle()
        if isAutoScrolling {
            autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { _ in
                DispatchQueue.main.async {
                    if imageLoader.currentIndex < imageLoader.images.count - 1 {
                        imageLoader.showNextImage()
                    } else {
                        stopAutoScroll()
                    }
                }
            }
        } else {
            stopAutoScroll()
        }
    }

    private func stopAutoScroll() {
        isAutoScrolling = false
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}
