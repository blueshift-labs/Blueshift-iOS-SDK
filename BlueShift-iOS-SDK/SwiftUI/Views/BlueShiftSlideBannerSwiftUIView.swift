//
//  BlueShiftSlideBannerSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Banner view for in-app notifications (iOS 13+)
//

import SwiftUI

/// Slide-in banner view for in-app notifications
@available(iOS 13.0, *)
struct BlueShiftSlideBannerSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    @State private var offsetX: CGFloat = -UIScreen.main.bounds.width
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Tap outside to dismiss
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissBanner()
                }
            
            // Position banner based on templateStyle.position
            if position == "top" {
                VStack {
                    bannerContent
                        .offset(x: offsetX + dragOffset)
                        .gesture(swipeGesture)
                    Spacer()
                }
            } else if position == "bottom" {
                VStack {
                    Spacer()
                    bannerContent
                        .offset(x: offsetX + dragOffset)
                        .gesture(swipeGesture)
                }
            } else {
                // center
                bannerContent
                    .offset(x: offsetX + dragOffset)
                    .gesture(swipeGesture)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Banner Content
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            // Icon - matches UIKit logic (lines 220-227)
            iconView
            
            // Message
            if let message = viewModel.notification.notificationContent.message {
                Text(message)
                    .font(.system(size: CGFloat(messageSize)))
                    .foregroundColor(Color(hex: messageColor) ?? Color.black)
                    .lineLimit(3)
                
                Spacer()
            }
            
            // Close button
            // Button(action: { dismissBanner() }) {
            //     Image(systemName: "xmark")
            //         .foregroundColor(.gray)
            //         .padding(8)
            // }
        }
        // .padding()
        .background(Color(hex: backgroundColor) ?? Color.white)
        .cornerRadius(CGFloat(backgroundRadius))
        .shadow(radius: 5)
        // .padding(.horizontal)
    }
    
    // MARK: - Icon View (Matches UIKit logic exactly)
    
    @ViewBuilder
    private var iconView: some View {
        // Check icon field first (FontAwesome), then iconImage field (URL)
        if let icon = viewModel.notification.notificationContent.icon,
           !icon.isEmpty {
            // Show FontAwesome icon (matches UIKit createIconLabel)
            Text(icon)
                .font(.custom("FontAwesome5Free-Solid", size: iconFontSize))
                .foregroundColor(Color(hex: iconColor) ?? Color.white)
                .frame(width: 50, height: 50)
                .background(Color(hex: iconBackgroundColor) ?? Color.black)
                .cornerRadius(iconBackgroundRadius)
        } else if let iconImageURL = viewModel.iconImageURL {
            // Show image from URL (matches UIKit createIconViewWithHeight)
            RemoteImageView(url: iconImageURL, width: 50, height: 50) {
                AnyView(defaultIcon)
            }
        } else {
            // Default bell icon
            defaultIcon
        }
    }
    
    private var defaultIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: "bell.fill")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get position from templateStyle (top, center, or bottom)
    private var position: String {
        if let pos = viewModel.notification.templateStyle.position, !pos.isEmpty {
            return pos
        }
        return "top"
    }
    
    /// Banner background color
    private var backgroundColor: String {
        viewModel.notification.templateStyle.backgroundColor ?? "#ffffff"
    }
    
    /// Banner background radius
    private var backgroundRadius: Float {
        viewModel.notification.templateStyle.backgroundRadius?.floatValue ?? 0.0
    }
    
    /// Message text color
    private var messageColor: String {
        viewModel.notification.contentStyle.messageColor ?? "#000000"
    }
    
    /// Message font size
    private var messageSize: Float {
        viewModel.notification.contentStyle.messageSize?.floatValue ?? 14.0
    }
    
    /// Icon text color
    private var iconColor: String {
        viewModel.notification.contentStyle.iconColor ?? "#ffffff"
    }
    
    /// Icon font size
    private var iconFontSize: CGFloat {
        if let size = viewModel.notification.contentStyle.iconSize {
            return CGFloat(size.floatValue)
        }
        return 22.0
    }
    
    /// Icon background color
    private var iconBackgroundColor: String {
        viewModel.notification.contentStyle.iconBackgroundColor ?? "#000000"
    }
    
    /// Icon background radius
    private var iconBackgroundRadius: CGFloat {
        if let radius = viewModel.notification.contentStyle.iconBackgroundRadius {
            return CGFloat(radius.floatValue)
        }
        return 0.0
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let swipeThreshold: CGFloat = 100
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                if abs(value.translation.width) > swipeThreshold || abs(velocity) > 50 {
                    if value.translation.width < 0 {
                        dismissBanner(direction: .left)
                    } else {
                        dismissBanner(direction: .right)
                    }
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Animation Methods
    
    private func animateIn() {
        withAnimation(.easeInOut(duration: 1.0)) {
            offsetX = 0
        }
    }
    
    private enum SwipeDirection {
        case left, right
    }
    
    private func dismissBanner(direction: SwipeDirection = .left) {
        let targetOffset: CGFloat
        
        switch direction {
        case .left:
            targetOffset = -UIScreen.main.bounds.width * 2
        case .right:
            targetOffset = UIScreen.main.bounds.width * 2
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            offsetX = targetOffset
            dragOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewModel.dismiss()
        }
    }
}
