import SwiftUI
import NectarCore
import UniformTypeIdentifiers

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
    @State private var showAutoScrollSettings = false

    // Help & Tip Jar
    @State private var isHelpPresented = false
    @State private var isTipJarPresented = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                appSettings.backgroundColor.ignoresSafeArea()

                if imageLoader.images.isEmpty && imageLoader.isInitialLoad {
                    dropZoneView
                } else {
                    imageContentWithTapZones(geometry: geometry)
                }

                if isToolbarVisible && !imageLoader.images.isEmpty {
                    overlayControls(geometry: geometry)
                }
            }
        }
        .statusBarHidden(!isToolbarVisible)
        .animation(.easeInOut(duration: 0.2), value: isToolbarVisible)
        .onDisappear {
            stopAutoScroll()
        }
        // Context menu (long press)
        .contextMenu {
            contextMenuContent
        }
        // Drag & drop
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            imageLoader.loadImages(from: url)
                        }
                    }
                }
                return true
            }
            return false
        }
        .sheet(isPresented: $isHelpPresented) {
            HelpView()
        }
        .sheet(isPresented: $isTipJarPresented) {
            TipJarView(isPresented: $isTipJarPresented)
        }
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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            imageLoader.loadImages(from: url)
                        }
                    }
                }
                return true
            }
            return false
        }
    }

    // MARK: - Image Content with Tap Zones

    private func imageContentWithTapZones(geometry: GeometryProxy) -> some View {
        ZStack {
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

            // Left/right tap zones for page navigation
            if scale <= 1.1 {
                HStack(spacing: 0) {
                    // Left tap zone
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geometry.size.width * 0.2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if imageLoader.viewMode == .spreadRightToLeft {
                                    imageLoader.showNextImage()
                                } else {
                                    imageLoader.showPreviousImage()
                                }
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.3))
                        )

                    Spacer()

                    // Right tap zone
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geometry.size.width * 0.2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if imageLoader.viewMode == .spreadRightToLeft {
                                    imageLoader.showPreviousImage()
                                } else {
                                    imageLoader.showNextImage()
                                }
                            }
                        }
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.3))
                        )
                }
                .allowsHitTesting(!isToolbarVisible)
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            onOpenFile()
        } label: {
            Label(NSLocalizedString("Open", comment: ""), systemImage: "folder")
        }

        Divider()

        Button {
            appSettings.isSpreadViewEnabled = false
            imageLoader.updateViewMode(appSettings: appSettings)
        } label: {
            Label(NSLocalizedString("Single Page View", comment: ""), systemImage: "doc.text")
        }

        Button {
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = true
            imageLoader.updateViewMode(appSettings: appSettings)
        } label: {
            Label(NSLocalizedString("Spread View (Right to Left)", comment: ""), systemImage: "book.closed")
        }

        Button {
            appSettings.isSpreadViewEnabled = true
            appSettings.isRightToLeftReading = false
            imageLoader.updateViewMode(appSettings: appSettings)
        } label: {
            Label(NSLocalizedString("Spread View (Left to Right)", comment: ""), systemImage: "book")
        }

        Divider()

        Button {
            imageLoader.toggleBookmark()
        } label: {
            Label(
                imageLoader.isCurrentPageBookmarked()
                    ? NSLocalizedString("Remove Bookmark", comment: "")
                    : NSLocalizedString("Add Bookmark", comment: ""),
                systemImage: imageLoader.isCurrentPageBookmarked() ? "bookmark.fill" : "bookmark"
            )
        }

        Button {
            imageLoader.goToNextBookmark()
        } label: {
            Label(NSLocalizedString("Next Bookmark", comment: ""), systemImage: "arrow.right.to.line")
        }

        Button {
            imageLoader.goToPreviousBookmark()
        } label: {
            Label(NSLocalizedString("Previous Bookmark", comment: ""), systemImage: "arrow.left.to.line")
        }

        Button {
            onOpenBookmarks()
        } label: {
            Label(NSLocalizedString("Show Bookmark List", comment: ""), systemImage: "list.bullet")
        }

        Divider()

        Button {
            imageLoader.rotateImage(by: 90)
        } label: {
            Label(NSLocalizedString("Rotate 90 Degrees", comment: ""), systemImage: "rotate.right")
        }

        Button {
            imageLoader.rotateImage(by: -90)
        } label: {
            Label(NSLocalizedString("Rotate 90 Degrees Counterclockwise", comment: ""), systemImage: "rotate.left")
        }

        Divider()

        Button {
            appSettings.zoomFactor *= 1.25
        } label: {
            Label(NSLocalizedString("Zoom In", comment: ""), systemImage: "plus.magnifyingglass")
        }

        Button {
            appSettings.zoomFactor *= 0.8
        } label: {
            Label(NSLocalizedString("Zoom Out", comment: ""), systemImage: "minus.magnifyingglass")
        }

        Button {
            appSettings.zoomFactor = 1.0
        } label: {
            Label(NSLocalizedString("Reset Zoom", comment: ""), systemImage: "1.magnifyingglass")
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

    private func overlayControls(geometry: GeometryProxy) -> some View {
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

            // Auto scroll with interval
            HStack(spacing: 8) {
                Button {
                    toggleAutoScroll()
                } label: {
                    Image(systemName: isAutoScrolling ? "pause.fill" : "play.fill")
                }

                Button {
                    showAutoScrollSettings.toggle()
                } label: {
                    Image(systemName: "timer")
                        .font(.caption)
                }
                .popover(isPresented: $showAutoScrollSettings) {
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("Auto Page Turn Settings", comment: ""))
                            .font(.headline)
                        Slider(value: $autoScrollInterval, in: 0.5...30.0, step: 0.5)
                            .frame(width: 200)
                        Text(String(format: NSLocalizedString("%.1f seconds", comment: ""), autoScrollInterval))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }
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

            // More menu
            Menu {
                Button { onOpenBookmarks() } label: {
                    Label(NSLocalizedString("Bookmarks", comment: ""), systemImage: "bookmark.circle")
                }
                Button {
                    imageLoader.rotateImage(by: 90)
                } label: {
                    Label(NSLocalizedString("Rotate 90 Degrees", comment: ""), systemImage: "rotate.right")
                }
                Divider()
                Button { isHelpPresented = true } label: {
                    Label(NSLocalizedString("NectarView Help", comment: ""), systemImage: "questionmark.circle")
                }
                Button { isTipJarPresented = true } label: {
                    Label(NSLocalizedString("Tip Jar…", comment: ""), systemImage: "heart.fill")
                }
                Divider()
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

                // Image info (navigation title equivalent)
                Text(imageLoader.currentImageInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal)
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
