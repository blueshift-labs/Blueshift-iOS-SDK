//
//  BlueShiftSwiftUIBridge.swift
//  BlueShift-iOS-SDK
//
//  Bridge between Objective-C SDK and SwiftUI views
//  Handles rendering of in-app notifications using SwiftUI
//

import Foundation
import SwiftUI

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
    /// - Parameters:
    ///   - notification: The notification to render
    ///   - onDismiss: Callback when notification is dismissed
    ///   - onAction: Callback when an action is triggered
    @MainActor @objc public func renderInApp(notification: BlueShiftInAppNotification,
                                  onDismiss: @escaping () -> Void,
                                  onAction: @escaping (String?) -> Void) {
        presentSwiftUIView(notification: notification,
                           onDismiss: onDismiss,
                           onAction: onAction)
    }
    
    /// Present the SwiftUI view in a hosting controller
    @MainActor private func presentSwiftUIView(notification: BlueShiftInAppNotification,
                                    onDismiss: @escaping () -> Void,
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
        
        // Create view model
        let viewModel = BlueShiftInAppViewModel(
            notification: notification,
            onDismiss: { [weak self] in
                self?.currentHostingController?.dismiss(animated: true) {
                    onDismiss()
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

