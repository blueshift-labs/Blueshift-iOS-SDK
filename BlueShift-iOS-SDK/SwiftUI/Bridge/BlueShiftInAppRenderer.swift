//
//  BlueShiftInAppRenderer.swift
//  BlueShift-iOS-SDK
//
//  Protocol for rendering in-app notifications
//  Allows both UIKit and SwiftUI implementations
//

import Foundation

/// Protocol that defines the interface for rendering in-app notifications
/// Both UIKit and SwiftUI renderers conform to this protocol
@objc public protocol BlueShiftInAppRenderer {
    
    /// Render an in-app notification
    /// - Parameters:
    ///   - notification: The notification to render
    ///   - onDismiss: Callback when notification is dismissed
    ///   - onAction: Callback when an action is triggered with optional URL
    @objc func renderInApp(notification: BlueShiftInAppNotification,
                          onDismiss: @escaping () -> Void,
                          onAction: @escaping (String?) -> Void)
}
