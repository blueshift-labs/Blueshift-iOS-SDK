//
//  BlueShiftSlideBannerSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Banner view for in-app notifications (iOS 13+)
//

import SwiftUI
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

/// Slide-in banner view for in-app notifications
@available(iOS 13.0, *)
struct BlueShiftSlideBannerSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    @State private var offsetX: CGFloat = -UIScreen.main.bounds.width
    @State private var dragOffset: CGFloat = 0
    
    /// Whether this is an unobtrusive banner (touches pass through to app)
    private var isUnobtrusive: Bool {
        viewModel.notification.templateStyle.enableBackgroundAction
    }
    
    var body: some View {
        if isUnobtrusive {
            // Unobtrusive: NO full-screen overlay, NO Spacer filling the screen.
            // The hosting view is pinned to top/bottom edge by the bridge (Auto Layout),
            // so we only render the banner content with its natural height.
            // Combined with BlueShiftPassThroughWindow + BlueShiftPassThroughView,
            // touches outside the banner pass through to the app.
            // Matches UIKit: loadView (line 32-36) uses BlueShiftNotificationView (pass-through)
            // and does NOT add tap gesture (line 40-42).
            bannerContent
                .padding(.top, position == "top" ? marginTop : 0)
                .padding(.bottom, position == "bottom" ? marginBottom : 0)
                .padding(.leading, marginLeft)
                .padding(.trailing, marginRight)
                .offset(x: offsetX + dragOffset)
                .gesture(swipeGesture)
                .onAppear {
                    animateIn()
                    viewModel.notifyDidShow()
                }
        } else {
            // Obtrusive: full-screen overlay catches taps to dismiss.
            // Matches UIKit: loadView (line 34-41) uses super.loadView + setTapGestureForView
            ZStack {
                Color.clear
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissBanner(key: "tap_outside")
                    }
                
                // Position banner based on templateStyle.position
                if position == "top" {
                    VStack {
                        bannerContent
                            .padding(.top, marginTop)
                            .padding(.leading, marginLeft)
                            .padding(.trailing, marginRight)
                            .offset(x: offsetX + dragOffset)
                            .gesture(swipeGesture)
                        Spacer()
                    }
                } else if position == "bottom" {
                    VStack {
                        Spacer()
                        bannerContent
                            .padding(.bottom, marginBottom)
                            .padding(.leading, marginLeft)
                            .padding(.trailing, marginRight)
                            .offset(x: offsetX + dragOffset)
                            .gesture(swipeGesture)
                    }
                } else {
                    // center
                    bannerContent
                        .padding(.leading, marginLeft)
                        .padding(.trailing, marginRight)
                        .offset(x: offsetX + dragOffset)
                        .gesture(swipeGesture)
                }
            }
            .onAppear {
                animateIn()
                viewModel.notifyDidShow()
            }
        }
    }
    
    // MARK: - Banner Content
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            // Icon - matches UIKit logic (lines 220-227)
            // Background color is handled inside iconView per icon type:
            // - FontAwesome icon: uses iconBackgroundColor (contentStyle.iconBackgroundColor)
            // - Icon image: uses iconImageBackgroundColor (contentStyle.iconImageBackgroundColor)
            // - Default: no background
            VStack{
                iconView
            }
            .frame(height: bannerMinHeight, alignment: .center)
            
            // Message with padding
            if let message = viewModel.notification.notificationContent.message {
                Text(message)
                    .font(.system(size: CGFloat(messageSize)))
                    .foregroundColor(Color(hex: messageColor) ?? Color.black)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, CGFloat(messagePaddingTop))
                    .padding(.bottom, CGFloat(messagePaddingBottom))
                    .padding(.leading, CGFloat(messagePaddingLeft))
                    .padding(.trailing, CGFloat(messagePaddingRight))
                
                Spacer()
            }
            
            // Close button
            // Button(action: { dismissBanner() }) {
            //     Image(systemName: "xmark")
            //         .foregroundColor(.gray)
            //         .padding(8)
            // }
        }
        .frame(minHeight: bannerMinHeight)
        .background(Color(hex: backgroundColor) ?? Color.white)
        .cornerRadius(CGFloat(backgroundRadius))
        .shadow(radius: 5)
        .onTapGesture {
            handleBannerTap()
        }
    }
    
    // MARK: - Icon View (Matches UIKit logic exactly)
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = viewModel.notification.notificationContent.icon, !icon.isEmpty {
            // Show FontAwesome icon (matches UIKit createIconLabel)
            // Container fills full height, icon centered inside
            ZStack {
                Color(hex: iconBackgroundColor) ?? Color.clear
                
                Text(icon)
                    .font(.custom("FontAwesome5Free-Solid", size: iconFontSize))
                    .foregroundColor(Color(hex: iconColor) ?? Color.white)
                    .frame(width: 50, height: 50)
                    .cornerRadius(iconBackgroundRadius)
            }
            .frame(width: 50 + CGFloat(iconPaddingLeft) + CGFloat(iconPaddingRight))
            .padding(.leading, CGFloat(iconPaddingLeft))
            .padding(.trailing, CGFloat(iconPaddingRight))
        } else if let iconImage = viewModel.notification.notificationContent.iconImage, !iconImage.isEmpty, let iconImageURL = viewModel.iconImageURL {
            // Show image from URL (matches UIKit createIconViewWithHeight lines 236-275)
            // Image is pre-downloaded and cached by BlueShiftSwiftUIBridge.renderInApp
            // before this view is presented. RemoteImageView reads from cache synchronously.
            // Image size = 50 - padding (UIKit lines 243-244)
            let imgWidth: CGFloat = 50 - CGFloat(iconImagePaddingLeft) - CGFloat(iconImagePaddingRight)
            let imgHeight: CGFloat = 50 - CGFloat(iconImagePaddingTop) - CGFloat(iconImagePaddingBottom)
            ZStack {
                // Container background color (UIKit lines 267-270: only set if not null/empty, else clear)
                Color(hex: iconImageBackgroundColor) ?? Color.clear
                
                // Image centered in container (UIKit line 257: imageView.center = iconView.center)
                RemoteImageView(url: iconImageURL, width: imgWidth, height: imgHeight) {
                    AnyView(defaultIcon)
                }
                // Corner radius on image (UIKit line 261-262: iconImageBackgroundRadius)
                // clipsToBounds = YES (UIKit line 263)
                .clipShape(RoundedRectangle(cornerRadius: iconImageBackgroundRadius))
            }
            // Container is always 50pt wide (UIKit line 248: kInAppNotificationModalIconWidth)
            .frame(width: 50)
        } else {
            // No icon — matches UIKit which only adds icon if icon/iconImage is valid string
            // (initializeNotificationView lines 155-165)
            EmptyView()
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
    /// UIKit default: clear/transparent (UILabel default nil background)
    /// Background is only applied if iconBackgroundColor is non-null and non-empty
    private var iconBackgroundColor: String {
        viewModel.notification.contentStyle.iconBackgroundColor ?? ""
    }
    
    /// Icon background radius
    private var iconBackgroundRadius: CGFloat {
        if let radius = viewModel.notification.contentStyle.iconBackgroundRadius {
            return CGFloat(radius.floatValue)
        }
        return 0.0
    }
    
    // MARK: - Icon Image Properties (for URL-based icon, separate from FontAwesome icon)
    // Matches UIKit's createIconViewWithHeight: (BlueShiftNotificationSlideBannerViewController.m lines 236-275)
    
    /// Icon image background color (contentStyle.iconImageBackgroundColor, UIKit line 267-270)
    /// UIKit only sets background if not null/empty, otherwise container stays clear
    private var iconImageBackgroundColor: String {
        viewModel.notification.contentStyle.iconImageBackgroundColor ?? ""
    }
    
    /// Icon image background radius applied to the image (contentStyle.iconImageBackgroundRadius, UIKit line 261)
    private var iconImageBackgroundRadius: CGFloat {
        if let radius = viewModel.notification.contentStyle.iconImageBackgroundRadius {
            return CGFloat(radius.floatValue)
        }
        return 0.0
    }
    
    /// Icon image padding - top (contentStyle.iconImagePadding.top, UIKit line 239)
    private var iconImagePaddingTop: Float {
        viewModel.notification.contentStyle.iconImagePadding.top
    }
    
    /// Icon image padding - bottom (contentStyle.iconImagePadding.bottom, UIKit line 241)
    private var iconImagePaddingBottom: Float {
        viewModel.notification.contentStyle.iconImagePadding.bottom
    }
    
    /// Icon image padding - left (contentStyle.iconImagePadding.left, UIKit line 238)
    private var iconImagePaddingLeft: Float {
        viewModel.notification.contentStyle.iconImagePadding.left
    }
    
    /// Icon image padding - right (contentStyle.iconImagePadding.right, UIKit line 240)
    private var iconImagePaddingRight: Float {
        viewModel.notification.contentStyle.iconImagePadding.right
    }
    
    // MARK: - Dynamic Height Calculation
    
    /// Calculate banner minimum height
    /// Matches UIKit logic from BlueShiftNotificationSlideBannerViewController.m lines 192-218
    private var bannerMinHeight: CGFloat {
        // If templateStyle.height is explicitly set and > 0, use it as fixed height
        if viewModel.notification.templateStyle.height > 0 {
            return CGFloat(viewModel.notification.templateStyle.height)
        }
        
        // Otherwise, use minimum height
        // Minimum height constant from UIKit: kSlideInInAppNotificationMinimumHeight = 50.0
        let minimumHeight: CGFloat = 50.0
        let iconHeight: CGFloat = 50.0 // kInAppNotificationModalIconHeight
        
        // Check if we have an icon (FontAwesome or image)
        let hasIcon = (viewModel.notification.notificationContent.icon != nil &&
                      !viewModel.notification.notificationContent.icon!.isEmpty) ||
                     viewModel.iconImageURL != nil
        
        if hasIcon {
            return max(iconHeight + CGFloat(iconPaddingTop) + CGFloat(iconPaddingBottom), minimumHeight)
        } else {
            return minimumHeight
        }
    }
    
    // MARK: - Padding Properties
    
    /// Icon padding - top
    private var iconPaddingTop: Float {
        viewModel.notification.contentStyle.iconPadding.top
    }
    
    /// Icon padding - bottom
    private var iconPaddingBottom: Float {
        viewModel.notification.contentStyle.iconPadding.bottom
    }
    
    /// Icon padding - left
    private var iconPaddingLeft: Float {
        viewModel.notification.contentStyle.iconPadding.left
    }
    
    /// Icon padding - right
    private var iconPaddingRight: Float {
        viewModel.notification.contentStyle.iconPadding.right
    }
    
    /// Message padding - top
    private var messagePaddingTop: Float {
        viewModel.notification.contentStyle.messagePadding.top
    }
    
    /// Message padding - bottom
    private var messagePaddingBottom: Float {
        viewModel.notification.contentStyle.messagePadding.bottom
    }
    
    /// Message padding - left
    private var messagePaddingLeft: Float {
        viewModel.notification.contentStyle.messagePadding.left
    }
    
    /// Message padding - right
    private var messagePaddingRight: Float {
        viewModel.notification.contentStyle.messagePadding.right
    }
    
    // MARK: - Margin Properties (from templateStyle.margin)
    // Matches UIKit's positionNotificationView (BlueShiftNotificationSlideBannerViewController.m lines 442-455)
    
    /// Top margin from templateStyle.margin
    private var marginTop: CGFloat {
        let top = viewModel.notification.templateStyle.margin.top
        return top > 0 ? CGFloat(top) : 0
    }
    
    /// Bottom margin from templateStyle.margin
    private var marginBottom: CGFloat {
        let bottom = viewModel.notification.templateStyle.margin.bottom
        return bottom > 0 ? CGFloat(bottom) : 0
    }
    
    /// Left margin from templateStyle.margin
    private var marginLeft: CGFloat {
        let left = viewModel.notification.templateStyle.margin.left
        return left > 0 ? CGFloat(left) : 0
    }
    
    /// Right margin from templateStyle.margin
    private var marginRight: CGFloat {
        let right = viewModel.notification.templateStyle.margin.right
        return right > 0 ? CGFloat(right) : 0
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
                        dismissBanner(direction: .left, key: "swipe")
                    } else {
                        dismissBanner(direction: .right, key: "swipe")
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
    
    private func dismissBanner(direction: SwipeDirection = .left, key: String? = nil) {
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
            viewModel.dismiss(key: key)
        }
    }
    
    /// Handle tap on banner content
    /// Matches UIKit's handleSlideInTap (BlueShiftNotificationSlideBannerViewController.m line 404)
    /// - If action exists: triggers the action (fires click/dismiss event based on URL, opens URL)
    /// - If no action: just dismisses the banner
    private func handleBannerTap() {
        // Check if first action exists (matches UIKit lines 405-407)
        // In Obj-C bridge, `actions` may be bridged as NSMutableArray, which can be non-optional.
        // Avoid optional binding on non-optional types; instead, check count and then safely read first element.
        let actionsAny = viewModel.notification.notificationContent.actions

        // Handle both optional and non-optional arrays defensively
        if let optionalActions = actionsAny as AnyObject?,
           let array = optionalActions as? NSArray,
           array.count > 0,
           let first = array[0] as? BlueShiftInAppNotificationButton {
            // Has action → trigger it via handleAction
            viewModel.handleAction(url: first.iosLink)
        } else if let array = actionsAny as? NSArray,
                  array.count > 0,
                  let first = array[0] as? BlueShiftInAppNotificationButton {
            // Bridged path where actions is already an NSArray
            viewModel.handleAction(url: first.iosLink)
        } else {
            // No action → just dismiss (matches UIKit's hideAnimated line 410)
            viewModel.dismiss(key: nil)
        }
    }
}

