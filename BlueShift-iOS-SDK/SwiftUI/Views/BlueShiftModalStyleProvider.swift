//
//  BlueShiftModalStyleProvider.swift
//  BlueShift-iOS-SDK
//
//  Created by Blueshift on 10/03/26.
//

import SwiftUI

/// Provides styling and configuration properties for modal in-app notifications
/// Follows Single Responsibility Principle - handles only styling logic
/// Extracts all styling logic from the view to keep it clean and maintainable
@available(iOS 13.0, *)
@MainActor
struct BlueShiftModalStyleProvider {
    let viewModel: BlueShiftInAppViewModel
    
    init(viewModel: BlueShiftInAppViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Modal Container Styling
    
    var modalBackgroundColor: Color {
        if let bgColor = viewModel.notification.templateStyle.backgroundColor {
            return Color(hex: bgColor) ?? .white
        }
        return .white
    }
    
    var modalCornerRadius: CGFloat {
        if let radius = viewModel.notification.templateStyle.backgroundRadius {
            return CGFloat(radius.floatValue)
        }
        return 16
    }
    
    // MARK: - Title Styling
    
    var titleFont: Font {
        let size = viewModel.notification.contentStyle.titleSize?.floatValue ?? 18.0
        return .custom("Helvetica-Bold", size: CGFloat(size))
    }
    
    var titleColor: Color {
        if let color = viewModel.notification.contentStyle.titleColor {
            return Color(hex: color) ?? .black
        }
        return .black
    }
    
    var titleBackgroundColor: Color {
        if let color = viewModel.notification.contentStyle.titleBackgroundColor {
            return Color(hex: color) ?? .clear
        }
        return .clear
    }
    
    var titleAlignment: TextAlignment {
        guard let gravity = viewModel.notification.contentStyle.titleGravity else {
            return .center
        }
        return textAlignment(from: gravity)
    }
    
    var titleFrameAlignment: Alignment {
        guard let gravity = viewModel.notification.contentStyle.titleGravity else {
            return .center
        }
        return frameAlignment(from: gravity)
    }
    
    var titlePaddingTop: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.titlePadding.top)
    }
    
    var titlePaddingBottom: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.titlePadding.bottom)
    }
    
    var titlePaddingLeft: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.titlePadding.left)
    }
    
    var titlePaddingRight: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.titlePadding.right)
    }
    
    // MARK: - Subtitle Styling
    
    var subTitlePaddingTop: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.subTitlePadding.top)
    }
    
    var subTitlePaddingBottom: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.subTitlePadding.bottom)
    }
    
    var subTitlePaddingLeft: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.subTitlePadding.left)
    }
    
    var subTitlePaddingRight: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.subTitlePadding.right)
    }
    
    // MARK: - Message Styling
    
    var messageFont: Font {
        let size = viewModel.notification.contentStyle.messageSize?.floatValue ?? 14.0
        return .custom("Helvetica", size: CGFloat(size))
    }
    
    var messageColor: Color {
        if let color = viewModel.notification.contentStyle.messageColor {
            return Color(hex: color) ?? .black
        }
        return .black
    }
    
    var messageBackgroundColor: Color {
        if let color = viewModel.notification.contentStyle.messageBackgroundColor {
            return Color(hex: color) ?? .clear
        }
        return .clear
    }
    
    var messageAlignment: TextAlignment {
        guard let gravity = viewModel.notification.contentStyle.messageGravity else {
            return .center
        }
        return textAlignment(from: gravity)
    }
    
    var messageFrameAlignment: Alignment {
        guard let gravity = viewModel.notification.contentStyle.messageGravity else {
            return .center
        }
        return frameAlignment(from: gravity)
    }
    
    var messagePaddingTop: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.messagePadding.top)
    }
    
    var messagePaddingBottom: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.messagePadding.bottom)
    }
    
    var messagePaddingLeft: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.messagePadding.left)
    }
    
    var messagePaddingRight: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.messagePadding.right)
    }
    
    // MARK: - Actions Styling
    
    var actionsPaddingTop: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.actionsPadding.top)
    }
    
    var actionsPaddingBottom: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.actionsPadding.bottom)
    }
    
    var actionsPaddingLeft: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.actionsPadding.left)
    }
    
    var actionsPaddingRight: CGFloat {
        return CGFloat(viewModel.notification.contentStyle.actionsPadding.right)
    }
    
    var isVerticalLayout: Bool {
        guard let orientation = viewModel.notification.contentStyle.actionsOrientation else {
            return false // Default to horizontal
        }
        return orientation.intValue > 0
    }
    
    var hasActionButtons: Bool {
        return viewModel.notification.notificationContent.actions.count > 0
    }
    
    // MARK: - Close Button Styling
    
    var shouldShowCloseButton: Bool {
        guard let enableCloseButton = viewModel.notification.templateStyle.enableCloseButton else {
            return true // Default to showing close button if not specified
        }
        return enableCloseButton.boolValue
    }
    
    var closeButtonText: String {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let text = closeButton.text, !text.isEmpty {
            return text
        }
        return "\u{f00d}" // Default Font Awesome close icon
    }
    
    var closeButtonTextColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let textColor = closeButton.textColor {
            return Color(hex: textColor) ?? .white
        }
        return .white // Default text color
    }
    
    var closeButtonBackgroundColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let backgroundColor = closeButton.backgroundColor {
            return Color(hex: backgroundColor) ?? .black
        }
        return .black // Default background color
    }
    
    var closeButtonFontSize: CGFloat {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let textSize = closeButton.textSize {
            return CGFloat(textSize.floatValue)
        }
        return 22 // Default font size
    }
    
    var closeButtonCornerRadius: CGFloat {
        return 18 // Fixed corner radius for circular button
    }
    
    // MARK: - Helper Methods
    
    private func textAlignment(from gravity: String) -> TextAlignment {
        switch gravity.lowercased() {
        case "left":
            return .leading
        case "right":
            return .trailing
        default:
            return .center
        }
    }
    
    private func frameAlignment(from gravity: String) -> Alignment {
        switch gravity.lowercased() {
        case "left":
            return .leading
        case "right":
            return .trailing
        default:
            return .center
        }
    }
}

