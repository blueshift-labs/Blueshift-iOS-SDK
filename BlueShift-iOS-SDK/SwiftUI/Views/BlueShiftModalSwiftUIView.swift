//
//  BlueShiftModalSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Simple modal view for in-app notifications (iOS 13+)
//

import SwiftUI
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

/// Simple modal view for in-app notifications - shows title and message
@available(iOS 13.0, *)
struct BlueShiftModalSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var fontLoaded: Bool = false
    /// Loader for background image — uses ImageLoader directly so we can render
    /// with .resizable().scaledToFill() for full-bleed, matching UIKit's
    /// setBackgroundImageFromURL: which sets imageView.contentMode = UIViewContentModeScaleAspectFill
    /// Uses @ObservedObject + init pattern (same as RemoteImageView) for iOS 13 compatibility.
    /// @StateObject is iOS 14+ only.
    @ObservedObject private var bgImageLoader: ImageLoader
    
    init(viewModel: BlueShiftInAppViewModel) {
        self.viewModel = viewModel
        // Pre-load background image from SDK cache synchronously in init,
        // matching UIKit's loadImageFromURL:forImageView: which reads from NSCache synchronously.
        let loader = ImageLoader()
        if let bgURLString = viewModel.notification.templateStyle.backgroundImage,
           !bgURLString.isEmpty,
           let bgURL = URL(string: bgURLString) {
            loader.loadFromCacheSync(url: bgURL)
        }
        self._bgImageLoader = ObservedObject(wrappedValue: loader)
    }
    
    // Style provider handles all styling logic
    private var styleProvider: BlueShiftModalStyleProvider {
        BlueShiftModalStyleProvider(viewModel: viewModel)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background dim — matches UIKit's setBackgroundDim which reads
                // templateStyle.backgroundDimAmount (default 0.5)
                // UIKit modal does NOT dismiss on background tap by default.
                // Only dismiss if enableBackgroundAction is true (matches UIKit's canTouchesPassThroughWindow).
                Color.black.opacity(styleProvider.backgroundDimAmount)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(opacity)
                    .onTapGesture {
                        if viewModel.notification.templateStyle.enableBackgroundAction {
                            viewModel.dismiss(key: "tap_outside")
                        }
                    }
                
                // Modal content with close button overlay
                ZStack(alignment: .topTrailing) {
                    // Content layer — compute frame using image-ratio logic when bg image present
                    // Matches UIKit's positionNotificationView + getAutoImageSizeForNotificationView
                    let frame = styleProvider.modalFrame(
                        screenWidth: geo.size.width,
                        screenHeight: geo.size.height,
                        imageSize: bgImageLoader.image?.size
                    )
                    let modalW = frame.width
                    let modalH = frame.height
                    
                    // Content VStack
                    VStack(spacing: 0) {
                        
                        // Title
                        if let title = viewModel.notification.notificationContent.title,
                           !title.isEmpty {
                            Text(title)
                                .font(styleProvider.titleFont)
                                .foregroundColor(styleProvider.titleColor)
                                .multilineTextAlignment(styleProvider.titleAlignment)
                                .frame(maxWidth: .infinity, alignment: styleProvider.titleFrameAlignment)
                                .background(styleProvider.titleBackgroundColor)
                                .padding(.top, styleProvider.titlePaddingTop)
                                .padding(.bottom, styleProvider.titlePaddingBottom)
                                .padding(.leading, styleProvider.titlePaddingLeft)
                                .padding(.trailing, styleProvider.titlePaddingRight)
                        }
                        
                        // Subtitle (if provided)
                        if let subtitle = viewModel.notification.notificationContent.subTitle,
                           !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.custom("HelveticaNeue-Medium", size: 16))
                                .foregroundColor(styleProvider.titleColor)
                                .multilineTextAlignment(styleProvider.titleAlignment)
                                .frame(maxWidth: .infinity, alignment: styleProvider.titleFrameAlignment)
                                .background(styleProvider.titleBackgroundColor)
                                .padding(.top, styleProvider.subTitlePaddingTop)
                                .padding(.bottom, styleProvider.subTitlePaddingBottom)
                                .padding(.leading, styleProvider.subTitlePaddingLeft)
                                .padding(.trailing, styleProvider.subTitlePaddingRight)
                        }
                        
                        if modalH != nil {
                            Spacer()
                        }
                        
                        // Message
                        if let message = viewModel.notification.notificationContent.message,
                           !message.isEmpty {
                            Text(message)
                                .font(styleProvider.messageFont)
                                .foregroundColor(styleProvider.messageColor)
                                .multilineTextAlignment(styleProvider.messageAlignment)
                                .frame(maxWidth: .infinity, alignment: styleProvider.messageFrameAlignment)
                                .background(styleProvider.messageBackgroundColor)
                                .padding(.top, styleProvider.messagePaddingTop)
                                .padding(.bottom, styleProvider.messagePaddingBottom)
                                .padding(.leading, styleProvider.messagePaddingLeft)
                                .padding(.trailing, styleProvider.messagePaddingRight)
                        }
                        
                        // When a fixed height is set, push buttons to the bottom.
                        // Matches UIKit's initializeButtonView which positions buttons
                        // at notificationView.frame.size.height - buttonHeight - yPadding
                        if modalH != nil {
                            Spacer()
                        }
                        
                        // Action Buttons
                        if styleProvider.hasActionButtons {
                            actionButtonsView
                                .padding(.top, styleProvider.actionsPaddingTop)
                                .padding(.bottom, styleProvider.actionsPaddingBottom)
                                .padding(.leading, styleProvider.actionsPaddingLeft)
                                .padding(.trailing, styleProvider.actionsPaddingRight)
                        }
                    }
                    // Apply payload-driven width — matches UIKit's positionNotificationView width logic
                    .frame(width: modalW)
                    // Apply payload-driven height only when set — nil means content-driven (UIKit auto-height)
                    .frame(height: modalH)
                    // Background image — matches UIKit's setBackgroundImageFromURL:
                    // imageView.frame = notificationView.bounds (fills entire modal)
                    // imageView.contentMode = UIViewContentModeScaleAspectFill
                    .background(
                        Group {
                            if styleProvider.backgroundImageURL != nil,
                               let bgImage = bgImageLoader.image {
                                Image(uiImage: bgImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                styleProvider.modalBackgroundColor
                            }
                        }
                    )
                    .clipped()
                    .cornerRadius(styleProvider.modalCornerRadius)
                    
                    // Close button - overlay in top-right corner
                    // Matches UIKit's createCloseButton: size = KInAppNotificationModalCloseButtonWidth/Height,
                    // margin = 5pt, cornerRadius = closeButton.backgroundRadius or 0.5*width
                    if styleProvider.shouldShowCloseButton {
                        Button(action: {
                            viewModel.dismiss(key: "btn_close")
                        }) {
                            Text(styleProvider.closeButtonText)
                                .font(.custom("FontAwesome5Free-Solid", size: styleProvider.closeButtonFontSize))
                                .foregroundColor(styleProvider.closeButtonTextColor)
                                .frame(width: styleProvider.closeButtonSize, height: styleProvider.closeButtonSize)
                                .background(styleProvider.closeButtonBackgroundColor)
                                .cornerRadius(styleProvider.closeButtonCornerRadius)
                        }
                        .padding(styleProvider.closeButtonMargin)
                    }
                }
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load and register Font Awesome with Core Text if needed
            if UIFont(name: "FontAwesome5Free-Solid", size: 20) == nil {
                BlueShiftFontAwesomeHelper.loadFontAwesome { success in
                    self.fontLoaded = success
                }
            }
            // Pre-load background image from SDK cache (matches UIKit's loadImageFromURL:forImageView:)
            if let bgURL = styleProvider.backgroundImageURL {
                bgImageLoader.loadFromCacheSync(url: bgURL)
                if bgImageLoader.image == nil {
                    bgImageLoader.loadAsync(url: bgURL)
                }
            }
            animateIn()
            // Notify shown — matches UIKit's inAppDidShow: → trackInAppNotificationShowingWithParameter: (a=open)
            viewModel.notifyDidShow()
        }
    }
    
    // MARK: - Action Buttons View
    
    /// Action buttons view with proper alignment
    /// Matches UIKit's initializeButtonView spacing:
    /// - Vertical: spacing = contentStyle.actionsPadding.bottom between buttons
    /// - Horizontal: spacing = contentStyle.actionsPadding.left between buttons
    @ViewBuilder
    private var actionButtonsView: some View {
        if styleProvider.isVerticalLayout {
            // Vertical layout - buttons stacked
            // UIKit uses actionsPadding.bottom as spacing between vertical buttons (line 400)
            VStack(spacing: styleProvider.actionsPaddingBottom) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
            .padding(.horizontal, 0)
        } else {
            // Horizontal layout - buttons side by side
            // UIKit uses actionsPadding.left as spacing between horizontal buttons (line 402)
            HStack(spacing: styleProvider.actionsPaddingLeft) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
            .padding(.horizontal, 0)
        }
    }
    
    /// Create individual action button matching UIKit's createActionButton:
    /// UIKit button height = 40.0 (initializeButtonView line 383)
    /// UIKit default corner radius = 0.0 (buttonDetails.backgroundRadius ?? 0.0, line 417-418)
    private func actionButton(for action: BlueShiftInAppNotificationButton, at index: Int) -> some View {
        Button(action: {
            handleActionButtonTap(action: action, at: index)
        }) {
            Text(action.text ?? "")
                .font(.system(size: CGFloat(action.textSize?.floatValue ?? 18), weight: .medium))
                .foregroundColor(action.buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(action.buttonBackgroundColor)
                .cornerRadius(CGFloat(action.backgroundRadius?.floatValue ?? 0))
        }
    }
    
    /// Handle action button tap
    /// Matches UIKit's handleInAppButtonAction: → processInAppActionForDeepLink:
    /// - Real URL → fires a=click via actionBlock in manager
    /// - nil/empty/dismiss URL → fires a=dismiss via actionBlock in manager
    private func handleActionButtonTap(action: BlueShiftInAppNotificationButton, at index: Int) {
        // Pass the URL to the action callback — the manager's actionBlock handles
        // tracking (a=click or a=dismiss) and URL opening, matching UIKit's flow
        viewModel.handleAction(url: action.iosLink)
    }
    
    // MARK: - Animation Methods
    
    private func animateIn() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeInOut(duration: 0.25)) {
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewModel.dismiss()
        }
    }
}
