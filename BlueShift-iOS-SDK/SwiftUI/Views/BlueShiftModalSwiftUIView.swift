//
//  BlueShiftModalSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  Simple modal view for in-app notifications (iOS 13+)
//

import SwiftUI

/// Simple modal view for in-app notifications - shows title and message
@available(iOS 13.0, *)
struct BlueShiftModalSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var fontLoaded: Bool = false
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            VStack(spacing: 16) {
                
                // Close button - only show if enabled in response
                if shouldShowCloseButton {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismissModal()
                        }) {
                            Text(closeButtonText)
                                .font(.custom("FontAwesome5Free-Solid", size: closeButtonFontSize))
                                .foregroundColor(closeButtonTextColor)
                                .frame(width: 44, height: 44)
                                .background(closeButtonBackgroundColor)
                                .clipShape(Circle())
                        }
                    }
                }

                // Title
                if let title = viewModel.notification.notificationContent.title,
                   !title.isEmpty {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                
                // Message
                if let message = viewModel.notification.notificationContent.message,
                   !message.isEmpty {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                
                // Action Buttons
                if hasActionButtons {
                    actionButtonsView
                        .padding(.top, 8)
                }

            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 10)
            .frame(maxWidth: 300)
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Trigger Font Awesome download using Objective-C helper
            if UIFont(name: "FontAwesome5Free-Solid", size: 20) == nil {
                BlueShiftInAppNotificationHelper.downloadFontAwesomeFile {
                    DispatchQueue.main.async {
                        self.fontLoaded = true
                    }
                }
            }
            animateIn()
        }
    }
    
    // MARK: - Close Button Properties
    
    /// Check if close button should be shown based on response
    private var shouldShowCloseButton: Bool {
        guard let enableCloseButton = viewModel.notification.templateStyle.enableCloseButton else {
            return true // Default to showing close button if not specified
        }
        return enableCloseButton.boolValue
    }
    
    /// Get close button text from response or use default
    private var closeButtonText: String {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let text = closeButton.text, !text.isEmpty {
            return text
        }
        return "\u{f00d}" // Default Font Awesome close icon
    }
    
    /// Get close button text color from response or use default
    private var closeButtonTextColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let textColor = closeButton.textColor {
            return Color(hex: textColor) ?? .white
        }
        return .white // Default text color
    }
    
    /// Get close button background color from response or use default
    private var closeButtonBackgroundColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let backgroundColor = closeButton.backgroundColor {
            return Color(hex: backgroundColor) ?? .black
        }
        return .black // Default background color
    }
    
    /// Get close button font size from response or use default
    private var closeButtonFontSize: CGFloat {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let textSize = closeButton.textSize {
            return CGFloat(textSize.floatValue)
        }
        return 22 // Default font size
    }
    
    // MARK: - Action Buttons
    
    /// Check if there are action buttons to display
    private var hasActionButtons: Bool {
        return viewModel.notification.notificationContent.actions.count > 0
    }
    
    /// Determine if buttons should be vertical or horizontal
    private var isVerticalLayout: Bool {
        guard let orientation = viewModel.notification.contentStyle.actionsOrientation else {
            return false // Default to horizontal
        }
        return orientation.intValue > 0
    }
    
    /// Action buttons view with proper alignment
    @ViewBuilder
    private var actionButtonsView: some View {
        if isVerticalLayout {
            // Vertical layout - buttons stacked
            VStack(spacing: 12) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
        } else {
            // Horizontal layout - buttons side by side
            HStack(spacing: 12) {
                ForEach(Array(viewModel.notification.notificationContent.actions.enumerated()), id: \.offset) { index, action in
                    actionButton(for: action as! BlueShiftInAppNotificationButton, at: index)
                }
            }
        }
    }
    
    /// Create individual action button
    private func actionButton(for action: BlueShiftInAppNotificationButton, at index: Int) -> some View {
        Button(action: {
            handleActionButtonTap(action: action, at: index)
        }) {
            Text(action.text ?? "")
                .font(.system(size: CGFloat(action.textSize?.floatValue ?? 16)))
                .foregroundColor(action.buttonTextColor)
                .frame(maxWidth: isVerticalLayout ? .infinity : nil)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(action.buttonBackgroundColor)
                .cornerRadius(action.cornerRadius)
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
