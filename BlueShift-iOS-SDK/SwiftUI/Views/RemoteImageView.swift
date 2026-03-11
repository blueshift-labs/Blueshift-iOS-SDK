//
//  RemoteImageView.swift
//  BlueShift-iOS-SDK
//
//  Image view that loads from SDK cache first, then downloads as fallback.
//  Matches UIKit's loadImageFromURL:forImageView: flow.
//

import SwiftUI
import UIKit

/// Remote image view that loads images from SDK cache (iOS 13+).
///
/// **Flow (matches UIKit in-app):**
/// 1. Images are pre-downloaded and cached by `BlueShiftSwiftUIBridge.renderInApp`
///    (or `BlueShiftInAppNotificationManager` for UIKit) into
///    `BlueShiftRequestOperationManager.sdkCachedData` (NSCache).
/// 2. This view first checks the cache synchronously via `getCachedDataForURL:`.
/// 3. If cache miss (edge case), it downloads the image as a fallback.
@available(iOS 13.0, *)
struct RemoteImageView: View {
    let url: URL?
    let placeholder: AnyView
    let width: CGFloat
    let height: CGFloat

    /// Holds the loaded image state.
    @ObservedObject private var loader: ImageLoader

    init(url: URL?,
         width: CGFloat = 50,
         height: CGFloat = 50,
         @ViewBuilder placeholder: () -> AnyView) {
        self.url = url
        self.width = width
        self.height = height
        self.placeholder = placeholder()
        // Create loader and immediately try to load from cache synchronously
        let newLoader = ImageLoader()
        if let url = url {
            newLoader.loadFromCacheSync(url: url)
        }
        self.loader = newLoader
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
            } else if loader.isLoading {
                // Simple loading indicator for iOS 13+
                ZStack {
                    placeholder
                        .frame(width: width, height: height)
                        .opacity(0.5)

                    LoadingSpinner()
                }
            } else {
                placeholder
                    .frame(width: width, height: height)
            }
        }
        .onAppear {
            // If image was not loaded from cache in init, try async download
            if loader.image == nil, let url = url {
                loader.loadAsync(url: url)
            }
        }
    }
}

/// Simple loading spinner for iOS 13+
@available(iOS 13.0, *)
struct LoadingSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: 20, height: 20)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                isAnimating = true
            }
    }
}

/// Image loader that mirrors UIKit's `loadImageFromURL:forImageView:` flow.
///
/// **UIKit reference** (`BlueShiftNotificationViewController.m` line 149-152):
/// ```objc
/// - (void)loadImageFromURL:(NSString *)imageURL forImageView:(UIImageView *)imageView {
///     UIImage *image = [[UIImage alloc] initWithData:
///         [BlueShiftRequestOperationManager.sharedRequestOperationManager getCachedDataForURL:imageURL]];
///     imageView.image = image;
/// }
/// ```
///
/// The UIKit flow is fully synchronous — it reads from `sdkCachedData` (NSCache)
/// because images were pre-downloaded before the view was presented.
/// This loader replicates that: first try cache sync, then fallback to async download.
@available(iOS 13.0, *)
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    private var hasAttemptedLoad = false

    /// Load image synchronously from SDK cache.
    /// This matches UIKit's `loadImageFromURL:forImageView:` which calls
    /// `getCachedDataForURL:` synchronously.
    func loadFromCacheSync(url: URL) {
        let manager = BlueShiftRequestOperationManager.shared()
        if let data = manager.getCachedData(forURL: url.absoluteString),
           let loadedImage = UIImage(data: data) {
            self.image = loadedImage
            self.hasAttemptedLoad = true
        }
    }

    /// Async fallback: download the image if it wasn't in cache.
    /// This handles edge cases where the pre-download in the bridge didn't complete
    /// or the cache was evicted.
    func loadAsync(url: URL) {
        guard image == nil, !isLoading, !hasAttemptedLoad else { return }
        hasAttemptedLoad = true
        isLoading = true

        // First try cache again (it may have been populated between init and onAppear)
        let manager = BlueShiftRequestOperationManager.shared()
        if let data = manager.getCachedData(forURL: url.absoluteString),
           let loadedImage = UIImage(data: data) {
            self.image = loadedImage
            self.isLoading = false
            return
        }

        // Cache miss — download using the same SDK method that UIKit uses for pre-caching
        // (BlueShiftRequestOperationManager.downloadDataForURL:shouldCache:handler:)
        manager.downloadData(for: url, shouldCache: true) { [weak self] success, data, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if success, let data = data, let loadedImage = UIImage(data: data) {
                    self.image = loadedImage
                }
                self.isLoading = false
            }
        }
    }
}
