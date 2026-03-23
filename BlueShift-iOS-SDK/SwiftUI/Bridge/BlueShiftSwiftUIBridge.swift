//
//  BlueShiftSwiftUIBridge.swift
//  BlueShift-iOS-SDK
//
//  Bridge between Objective-C SDK and SwiftUI views
//  Handles rendering of in-app notifications using SwiftUI
//

import Foundation
import SwiftUI
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

/// Bridge class that connects Objective-C SDK to SwiftUI rendering
/// This class is the main entry point for SwiftUI-based in-app notifications
@available(iOS 13.0, *)
@objc(BlueShiftSwiftUIBridge)
@objcMembers
@MainActor
public class BlueShiftSwiftUIBridge: NSObject {
    
    /// Shared singleton instance
    @objc public static let shared = BlueShiftSwiftUIBridge()
    
    /// Reference to the currently presented hosting controller
    private weak var currentHostingController: UIHostingController<AnyView>?
    
    private override init() {
        super.init()
    }
    
    /// Render an in-app notification using SwiftUI
    ///
    /// **Image pre-download flow (matches UIKit):**
    /// Before presenting the SwiftUI view, this method downloads all required images
    /// into `BlueShiftRequestOperationManager.sdkCachedData` (NSCache).
    /// This mirrors the UIKit flow in `BlueShiftInAppNotificationManager.m`:
    /// - `processSlideInBannerNotification:` (lines 258-288)
    /// - `processModalNotification:` (lines 290-319)
    ///
    /// **HTML type exception:**
    /// For HTML in-app notifications (BlueShiftInAppTypeHTML, rawValue 0),
    /// image pre-download is skipped — matching UIKit's `processHTMLNotification:`
    /// which does NOT pre-download images. The WKWebView handles its own resource loading.
    ///
    /// Once cached, `RemoteImageView` reads from cache synchronously via
    /// `getCachedDataForURL:`, matching UIKit's `loadImageFromURL:forImageView:`.
    ///
    /// - Parameters:
    ///   - notification: The notification to render
    ///   - onShow: Callback when notification is shown — matches UIKit's inAppDidShow: delegate
    ///   - onDismiss: Callback when notification is dismissed
    ///   - onAction: Callback when an action is triggered
    @MainActor @objc public func renderInApp(notification: BlueShiftInAppNotification,
                                  onShow: @escaping () -> Void,
                                  onDismiss: @escaping (String?) -> Void,
                                  onAction: @escaping (String?) -> Void) {
        
        // For HTML type (rawValue 0), skip image pre-download and present immediately
        // This matches UIKit's processHTMLNotification: which does NOT pre-download images
        // The WKWebView handles its own resource loading internally
        if notification.inAppType.rawValue == 0 { // BlueShiftInAppTypeHTML
            presentSwiftUIView(notification: notification,
                               onShow: onShow,
                               onDismiss: onDismiss,
                               onAction: onAction)
            return
        }
        
        // Pre-download images before presenting (matches UIKit implementation)
        // See BlueShiftInAppNotificationManager.m lines 264-287
        let hasIconImage = notification.notificationContent.iconImage != nil &&
                          !notification.notificationContent.iconImage!.isEmpty
        let hasBackgroundImage = notification.templateStyle.backgroundImage != nil &&
                                !notification.templateStyle.backgroundImage!.isEmpty
        let hasBannerImage = notification.notificationContent.banner != nil &&
                            !notification.notificationContent.banner!.isEmpty
        
        let manager = BlueShiftRequestOperationManager.shared()
        
        if hasIconImage || hasBackgroundImage || hasBannerImage {
            let group = DispatchGroup()
            
            // Download icon image if present (slide-in banner)
            if hasIconImage, let iconURLString = notification.notificationContent.iconImage,
               let iconURL = URL(string: iconURLString) {
                group.enter()
                manager.downloadData(for: iconURL, shouldCache: true) { success, data, error in
                    group.leave()
                }
            }
            
            // Download background image if present
            if hasBackgroundImage, let bgURLString = notification.templateStyle.backgroundImage,
               let bgURL = URL(string: bgURLString) {
                group.enter()
                manager.downloadData(for: bgURL, shouldCache: true) { success, data, error in
                    group.leave()
                }
            }
            
            // Download banner image if present (modal)
            if hasBannerImage, let bannerURLString = notification.notificationContent.banner,
               let bannerURL = URL(string: bannerURLString) {
                group.enter()
                manager.downloadData(for: bannerURL, shouldCache: true) { success, data, error in
                    group.leave()
                }
            }
            
            // Present after all downloads complete
            group.notify(queue: .main) { [weak self] in
                self?.presentSwiftUIView(notification: notification,
                                        onShow: onShow,
                                        onDismiss: onDismiss,
                                        onAction: onAction)
            }
        } else {
            // No images to download, present immediately
            presentSwiftUIView(notification: notification,
                               onShow: onShow,
                               onDismiss: onDismiss,
                               onAction: onAction)
        }
    }
    
    /// Present the SwiftUI view in a hosting controller
    @MainActor private func presentSwiftUIView(notification: BlueShiftInAppNotification,
                                    onShow: @escaping () -> Void,
                                    onDismiss: @escaping (String?) -> Void,
                                    onAction: @escaping (String?) -> Void) {
        
        // Get the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("[Blueshift SwiftUI] Unable to find window or root view controller")
            return
        }
        
        // Dismiss any existing notification
        if let existing = currentHostingController {
            existing.dismiss(animated: false, completion: nil)
        }
        
        // Eagerly register Font Awesome with Core Text before presenting
        // This ensures the font is available for close buttons and icons in all view types
        // Mirrors UIKit's createFontFile: in BlueShiftNotificationViewController.m
        BlueShiftFontAwesomeHelper.loadFontAwesome { _ in }
        
        // Create view model
        let viewModel = BlueShiftInAppViewModel(
            notification: notification,
            onShow: onShow,
            onDismiss: { [weak self] key in
                self?.currentHostingController?.dismiss(animated: true) {
                    onDismiss(key)
                }
                self?.currentHostingController = nil
            },
            onAction: { [weak self] url in
                self?.currentHostingController?.dismiss(animated: true) {
                    onAction(url)
                }
                self?.currentHostingController = nil
            }
        )
        
        // Create SwiftUI view
        let swiftUIView = BlueShiftInAppSwiftUIView(viewModel: viewModel)
        
        // Wrap in AnyView for type erasure
        let anyView = AnyView(swiftUIView)
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: anyView)
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        
        // Store reference
        currentHostingController = hostingController
        
        // Present
        var presenter = rootViewController
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        
        presenter.present(hostingController, animated: true, completion: nil)
    }
}
