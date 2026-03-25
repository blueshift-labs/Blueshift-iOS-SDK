//
//  BlueShiftInAppViewModel.swift
//  BlueShift-iOS-SDK
//
//  Simple view model for in-app notifications
//

import Foundation
import SwiftUI
import Combine
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

/// ViewModel for in-app notifications (banner, modal, and HTML)
@available(iOS 13.0, *)
@MainActor
public class BlueShiftInAppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The notification data
    @Published public var notification: BlueShiftInAppNotification
    
    /// Whether the notification is currently presented
    @Published public var isPresented: Bool = true
    
    // MARK: - Callbacks
    
    /// Callback when notification is shown — matches UIKit's inAppDidShow: delegate
    let onShow: () -> Void
    
    /// Callback when notification is dismissed
    /// The String? parameter carries the dismiss key: "swipe", "tap_outside", or nil for close button
    let onDismiss: (String?) -> Void
    
    /// Callback when an action is triggered
    let onAction: (String?) -> Void
    
    // MARK: - Initialization
    
    public init(notification: BlueShiftInAppNotification,
                onShow: @escaping () -> Void,
                onDismiss: @escaping (String?) -> Void,
                onAction: @escaping (String?) -> Void) {
        self.notification = notification
        self.onShow = onShow
        self.onDismiss = onDismiss
        self.onAction = onAction
    }
    
    // MARK: - Actions
    
    /// Notify that the notification has been shown.
    /// Call from each view's .onAppear — matches UIKit's inAppDidShow: delegate which fires
    /// trackInAppNotificationShowingWithParameter: (a=open) and updateInAppNotificationAsDisplayed:
    public func notifyDidShow() {
        onShow()
    }
    
    /// Dismiss the notification
    /// - Parameter key: The dismiss reason key — "swipe", "tap_outside", or nil for close button.
    ///   Matches UIKit's kNotificationClickElementKey values used in sendActionEventAnalytics:
    public func dismiss(key: String? = nil) {
        let onDismiss = self.onDismiss
        withAnimation {
            isPresented = false
        }
        
        // Delay callback to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss(key)
        }
    }
    
    /// Handle action button tap
    /// Passes the URL to the actionBlock in the manager which handles:
    /// - a=click tracking (real URL) or a=dismiss tracking (nil/empty/dismiss URL)
    /// - URL opening
    /// - dismiss housekeeping (currentNotificationController = nil, timer restart)
    /// Does NOT call dismiss() to avoid double-firing dismissBlock (a=dismiss)
    public func handleAction(url: String?) {
        let onAction = self.onAction
        // Animate out the view
        withAnimation {
            isPresented = false
        }
        // Delay to allow animation, then fire actionBlock which handles everything
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAction(url)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get the title text
    public var title: String? {
        return notification.notificationContent.title
    }
    
    /// Get the message text
    public var message: String? {
        return notification.notificationContent.message
    }
    
    /// Get the icon URL
    public var iconURL: URL? {
        guard let iconString = notification.notificationContent.icon,
              !iconString.isEmpty else {
            return nil
        }
        return URL(string: iconString)
    }
    
    /// Get the banner image URL
    public var bannerURL: URL? {
        guard let bannerString = notification.notificationContent.banner,
              !bannerString.isEmpty else {
            return nil
        }
        return URL(string: bannerString)
    }
    
    /// Get icon image URL (alternative to icon)
    public var iconImageURL: URL? {
        guard let iconImageString = notification.notificationContent.iconImage,
              !iconImageString.isEmpty else {
            return nil
        }
        return URL(string: iconImageString)
    }
    
    // MARK: - HTML In-App Properties
    
    /// Whether this is an HTML type notification
    /// Matches UIKit's BlueShiftInAppTypeHTML (rawValue 0)
    public var isHTMLType: Bool {
        return notification.inAppType.rawValue == 0 // BlueShiftInAppTypeHTML
    }
    
    /// Get the raw HTML content string
    /// Used by BlueShiftHTMLSwiftUIView to load HTML content
    /// Matches UIKit's notification.notificationContent.content
    public var htmlContent: String? {
        return notification.notificationContent.content
    }
    
    /// Get the URL string for URL-based HTML notifications
    /// Used by BlueShiftHTMLSwiftUIView to load URL content
    /// Matches UIKit's notification.notificationContent.url
    public var htmlURL: String? {
        return notification.notificationContent.url
    }
    
    /// Whether the HTML notification has valid content to display
    /// Matches UIKit's check in `show:` method:
    /// `if (!self.notification.notificationContent.content) return;`
    public var hasHTMLContent: Bool {
        return (htmlContent != nil && !htmlContent!.isEmpty) || (htmlURL != nil && !htmlURL!.isEmpty)
    }
}
