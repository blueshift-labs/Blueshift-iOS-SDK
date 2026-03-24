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
    
    /// Reference to the pass-through window used for unobtrusive slide-in banners
    /// Matches UIKit's BlueShiftNotificationWindow which passes touches through to the app
    private var passThroughWindow: UIWindow?
    
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
        dismissCurrentNotification()
        
        // Eagerly register Font Awesome with Core Text before presenting
        // This ensures the font is available for close buttons and icons in all view types
        // Mirrors UIKit's createFontFile: in BlueShiftNotificationViewController.m
        BlueShiftFontAwesomeHelper.loadFontAwesome { _ in }
        
        // Check if this is an unobtrusive slide-in banner
        // Matches UIKit's createWindow (line 97): uses BlueShiftNotificationWindow for pass-through
        let isUnobtrusive = notification.templateStyle.enableBackgroundAction &&
                            notification.inAppType.rawValue == 2 // BlueShiftNotificationSlideBanner
        
        // Create view model with appropriate dismiss/action handlers
        let viewModel = BlueShiftInAppViewModel(
            notification: notification,
            onShow: onShow,
            onDismiss: { [weak self] key in
                self?.dismissCurrentNotification {
                    onDismiss(key)
                }
            },
            onAction: { [weak self] url in
                self?.dismissCurrentNotification {
                    onAction(url)
                }
            }
        )
        
        // Create SwiftUI view
        let swiftUIView = BlueShiftInAppSwiftUIView(viewModel: viewModel)
        
        // Wrap in AnyView for type erasure
        let anyView = AnyView(swiftUIView)
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: anyView)
        hostingController.view.backgroundColor = .clear
        
        // Store reference
        currentHostingController = hostingController
        
        if isUnobtrusive {
            // Unobtrusive: present via pass-through window so touches pass through to app
            // Matches UIKit's createWindow (line 97) + BlueShiftNotificationWindow.hitTest
            // + BlueShiftNotificationView.hitTest (loadNotificationView uses pass-through view)
            let notificationWindow = BlueShiftPassThroughWindow()
            notificationWindow.windowScene = windowScene
            notificationWindow.frame = window.frame
            notificationWindow.backgroundColor = .clear
            notificationWindow.windowLevel = .normal
            
            // Use a pass-through view as the container (matches BlueShiftNotificationView)
            let passThroughView = BlueShiftPassThroughView(frame: window.frame)
            passThroughView.backgroundColor = .clear
            
            // Add hosting controller's view with Auto Layout constraints
            // Pin to top or bottom edge only (not full screen) so the hosting view
            // only covers the banner area. This ensures hitTest returns nil for
            // areas outside the banner, allowing touches to pass through.
            let hostingView = hostingController.view!
            hostingView.backgroundColor = .clear
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            passThroughView.addSubview(hostingView)
            
            // Determine position for constraints
            let bannerPosition = notification.templateStyle.position ?? "top"
            
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: passThroughView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: passThroughView.trailingAnchor),
            ])
            
            if bannerPosition == "bottom" {
                NSLayoutConstraint.activate([
                    hostingView.bottomAnchor.constraint(equalTo: passThroughView.bottomAnchor),
                ])
            } else {
                // top or center — pin to top
                NSLayoutConstraint.activate([
                    hostingView.topAnchor.constraint(equalTo: passThroughView.topAnchor),
                ])
            }
            
            let containerVC = UIViewController()
            containerVC.view = passThroughView
            containerVC.addChild(hostingController)
            hostingController.didMove(toParent: containerVC)
            
            notificationWindow.rootViewController = containerVC
            notificationWindow.isHidden = false
            
            self.passThroughWindow = notificationWindow
        } else {
            // Obtrusive: present modally (covers full screen, blocks touches)
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.modalTransitionStyle = .crossDissolve
            
            var presenter = rootViewController
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            
            presenter.present(hostingController, animated: true, completion: nil)
        }
    }
    
    /// Dismiss the currently presented notification (handles both modal and window-based presentation)
    @MainActor private func dismissCurrentNotification(completion: (() -> Void)? = nil) {
        if let window = passThroughWindow {
            // Window-based (unobtrusive) — hide and remove
            window.isHidden = true
            window.rootViewController = nil
            passThroughWindow = nil
            currentHostingController = nil
            completion?()
        } else if let hosting = currentHostingController {
            // Modal-based (obtrusive) — dismiss
            hosting.dismiss(animated: true) {
                completion?()
            }
            currentHostingController = nil
        } else {
            completion?()
        }
    }
}

// MARK: - Pass-Through Window for Unobtrusive Banners

/// A UIWindow subclass that passes touches through to the app when the touch
/// doesn't hit any subview. Mirrors the Objective-C BlueShiftNotificationWindow
/// (BlueShiftNotificationWindow.m) which is not exposed in public headers.
@available(iOS 13.0, *)
private class BlueShiftPassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // If the touch hits the window itself (not a subview), return nil
        // so the touch passes through to the app underneath
        return view === self ? nil : view
    }
}

// MARK: - Pass-Through View for Unobtrusive Banners

/// A UIView subclass that passes touches through to the app when the touch
/// doesn't hit any subview. Mirrors the Objective-C BlueShiftNotificationView
/// (BlueShiftNotificationView.m) which overrides hitTest the same way.
/// Used as the container view for the hosting controller in unobtrusive mode.
@available(iOS 13.0, *)
private class BlueShiftPassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view === self ? nil : view
    }
}

