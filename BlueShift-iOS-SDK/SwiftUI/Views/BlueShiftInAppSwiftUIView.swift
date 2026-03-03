//
//  BlueShiftInAppSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Simple banner view for all notification types
//

import SwiftUI

/// Main SwiftUI view - displays all notifications as banners
@available(iOS 13.0, *)
public struct BlueShiftInAppSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    
    public var body: some View {
        // Simple: Always show as banner, regardless of type
        BlueShiftSlideBannerSwiftUIView(viewModel: viewModel)
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
