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
    
    // Style provider handles all styling logic
    private var styleProvider: BlueShiftModalStyleProvider {
        BlueShiftModalStyleProvider(viewModel: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content with close button overlay
            ZStack(alignment: .topTrailing) {
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
                    
                    // Action Buttons
                    if styleProvider.hasActionButtons {
                        actionButtonsView
                            .padding(.top, styleProvider.actionsPaddingTop)
                            .padding(.bottom, styleProvider.actionsPaddingBottom)
                            .padding(.leading, styleProvider.actionsPaddingLeft)
                            .padding(.trailing, styleProvider.actionsPaddingRight)
                    }

                }
                .frame(maxWidth: 340)
                .background(styleProvider.modalBackgroundColor)
                .cornerRadius(styleProvider.modalCornerRadius)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // Close button - overlay in top-right corner
                if styleProvider.shouldShowCloseButton {
                    Button(action: {
                        dismissModal()
                    }) {
                        Text(styleProvider.closeButtonText)
                            .font(.custom("FontAwesome5Free-Solid", size: styleProvider.closeButtonFontSize))
                            .foregroundColor(styleProvider.closeButtonTextColor)
                            .frame(width: 36, height: 36)
                            .background(styleProvider.closeButtonBackgroundColor)
                            .cornerRadius(styleProvider.closeButtonCornerRadius)
                    }
                    .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Load and register Font Awesome with Core Text if needed
            if UIFont(name: "FontAwesome5Free-Solid", size: 20) == nil {
                BlueShiftFontAwesomeHelper.loadFontAwesome { success in
                    self.fontLoaded = success
                }
            }
            animateIn()
        }
    }
    
    // MARK: - Action Buttons View
    
    /// Action buttons view with proper alignment
    @ViewBuilder
    private var actionButtonsView: some View {
        if styleProvider.isVerticalLayout {
            // Vertical layout - buttons stacked
            VStack(spacing: 10) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
            .padding(.horizontal, 0)
        } else {
            // Horizontal layout - buttons side by side
            HStack(spacing: 10) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
            .padding(.horizontal, 0)
        }
    }
    
    /// Create individual action button matching the UI design
    private func actionButton(for action: BlueShiftInAppNotificationButton, at index: Int) -> some View {
        Button(action: {
            handleActionButtonTap(action: action, at: index)
        }) {
            Text(action.text ?? "")
                .font(.system(size: CGFloat(action.textSize?.floatValue ?? 18), weight: .medium))
                .foregroundColor(action.buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(action.buttonBackgroundColor)
                .cornerRadius(CGFloat(action.backgroundRadius?.floatValue ?? 8))
        }
    }
    
    /// Handle action button tap
    private func handleActionButtonTap(action: BlueShiftInAppNotificationButton, at index: Int) {
        // Handle button action (navigate to link, dismiss, etc.)
        if let link = action.iosLink, !link.isEmpty {
            // Open the link
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }
        // Dismiss the modal after action
        dismissModal()
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
