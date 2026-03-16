//
//  BlueShiftInAppSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Main SwiftUI view that routes to appropriate notification type
//

import SwiftUI

/// Main SwiftUI view - routes to appropriate notification view based on type
@available(iOS 13.0, *)
public struct BlueShiftInAppSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    
    public var body: some View {
        Group {
            // Use raw values from BlueShiftInAppType enum
            // BlueShiftInAppTypeHTML = 0, BlueShiftInAppTypeModal = 1, BlueShiftNotificationSlideBanner = 2
            switch viewModel.notification.inAppType.rawValue {
            case 0: // BlueShiftInAppTypeHTML
                // Show HTML web view notification
                BlueShiftHTMLSwiftUIView(viewModel: viewModel)
                
            case 1: // BlueShiftInAppTypeModal
                // Show modal view
                BlueShiftModalSwiftUIView(viewModel: viewModel)
                
            case 2: // BlueShiftNotificationSlideBanner
                // Show slide banner view
                BlueShiftSlideBannerSwiftUIView(viewModel: viewModel)
                
            default:
                // Default to slide banner for other types
                BlueShiftSlideBannerSwiftUIView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Preview
@available(iOS 13.0, *)
struct BlueShiftInAppSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        let notification = BlueShiftInAppNotification()
        let viewModel = BlueShiftInAppViewModel(
            notification: notification,
            onDismiss: {},
            onAction: { _ in }
        )
        
        return BlueShiftInAppSwiftUIView(viewModel: viewModel)
    }
}
