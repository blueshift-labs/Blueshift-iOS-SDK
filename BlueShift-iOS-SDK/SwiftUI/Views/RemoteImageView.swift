//
//  RemoteImageView.swift
//  BlueShift-iOS-SDK
//
//  Custom image loader for iOS 13+ (no ProgressView, no StateObject)
//

import SwiftUI
import Combine

/// Simple remote image loader for iOS 13+
@available(iOS 13.0, *)
struct RemoteImageView: View {
    let url: URL?
    let placeholder: AnyView
    let width: CGFloat
    let height: CGFloat
    
    @ObservedObject private var loader: ImageLoader
    
    init(url: URL?, 
         width: CGFloat = 50, 
         height: CGFloat = 50,
         @ViewBuilder placeholder: () -> AnyView) {
        self.url = url
        self.width = width
        self.height = height
        self.placeholder = placeholder()
        self.loader = ImageLoader()
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
            if let url = url {
                loader.load(url: url)
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

/// Image loader class
@available(iOS 13.0, *)
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var cancellable: AnyCancellable?
    private static let cache = NSCache<NSURL, UIImage>()
    
    func load(url: URL) {
        // Check cache first
        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                self?.isLoading = false
                if let loadedImage = loadedImage {
                    Self.cache.setObject(loadedImage, forKey: url as NSURL)
                    self?.image = loadedImage
                }
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
