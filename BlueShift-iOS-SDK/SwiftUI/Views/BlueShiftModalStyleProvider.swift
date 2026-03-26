//
//  BlueShiftModalStyleProvider.swift
//  BlueShift-iOS-SDK
//
//  Created by Blueshift on 10/03/26.
//

import SwiftUI
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

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
    
    /// Corner radius from templateStyle.backgroundRadius.
    /// Matches UIKit's setBackgroundRadius: which defaults to 0.0 when not set.
    var modalCornerRadius: CGFloat {
        if let radius = viewModel.notification.templateStyle.backgroundRadius,
           radius.floatValue > 0 {
            return CGFloat(radius.floatValue)
        }
        return 0  // UIKit default: no rounding (notificationView.layer.cornerRadius = 0.0)
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
    
    // MARK: - Dimensions
    
    /// Whether this is a background image modal.
    /// Matches UIKit's isBackgroundImagePresentForNotification:
    var isBackgroundImageModal: Bool {
        return backgroundImageURL != nil
    }
    
    /// Background image URL from templateStyle.backgroundImage
    /// Matches UIKit's setBackgroundImageFromURL: which uses templateStyle.backgroundImage
    var backgroundImageURL: URL? {
        guard let urlString = viewModel.notification.templateStyle.backgroundImage,
              !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    /// Compute modal frame (width, height) matching UIKit's positionNotificationView.
    ///
    /// When a background image is present, UIKit computes dimensions from the image's
    /// aspect ratio via getAutoImageSizeForNotificationView, using templateStyle.width/height
    /// as max bounds (not direct dimensions). This method replicates that logic.
    ///
    /// - Parameters:
    ///   - screenWidth: Available screen width from GeometryReader
    ///   - screenHeight: Available screen height from GeometryReader
    ///   - imageSize: Actual loaded background image dimensions (nil if not loaded yet)
    /// - Returns: (width, height?) — height is nil when content-driven
    func modalFrame(screenWidth: CGFloat, screenHeight: CGFloat, imageSize: CGSize?) -> (width: CGFloat, height: CGFloat?) {
        // CASE 1: Background image present and loaded → image-ratio-based sizing
        // Matches UIKit's positionNotificationView which calls getAutoImageSizeForNotificationView
        // and uses image-derived dimensions when isBackgroundImageModal && imageSize > 0
        if isBackgroundImageModal, let imgSize = imageSize, imgSize.width > 0, imgSize.height > 0 {
            let autoSize = autoImageSize(imageSize: imgSize, screenWidth: screenWidth, screenHeight: screenHeight)
            if autoSize.width > 0 && autoSize.height > 0 {
                return (autoSize.width, autoSize.height)
            }
        }
        
        // CASE 2: No background image (or image not loaded) → use payload dimensions
        let width = modalWidth(in: screenWidth)
        let height = modalHeight(in: screenHeight)
        return (width, height)
    }
    
    /// Compute image-based auto size matching UIKit's getAutoImageSizeForNotificationView.
    ///
    /// UIKit loads the cached background image, gets its pixel dimensions, and computes
    /// the modal frame based on the image's aspect ratio while respecting max bounds
    /// derived from templateStyle.width/height or defaults.
    ///
    /// Three cases:
    /// - Case A: Both auto width + auto height, image fits within max bounds → use image size directly
    /// - Case B: Auto width + Fixed height → derive width from height using aspect ratio
    /// - Case C: Fixed width + Auto height (or both fixed, or auto+auto but image too large)
    ///           → derive height from width using aspect ratio
    private func autoImageSize(imageSize: CGSize, screenWidth: CGFloat, screenHeight: CGFloat) -> CGSize {
        let templateWidth = viewModel.notification.templateStyle.width
        let templateHeight = viewModel.notification.templateStyle.height
        
        let isAutoWidth = templateWidth <= 0
        let isAutoHeight = templateHeight <= 0
        
        // Convert template percentage to points (UIKit uses percentage → points conversion)
        let templateWidthInPoints: CGFloat = isAutoWidth ? 0 : screenWidth * CGFloat(templateWidth) / 100.0
        let templateHeightInPoints: CGFloat = isAutoHeight ? 0 : screenHeight * CGFloat(templateHeight) / 100.0
        
        // Max width: templateWidth in points if set, else 90% of screen (kInAppNotificationDefaultWidth)
        let maxWidthInPoints: CGFloat = templateWidthInPoints > 0 ? templateWidthInPoints : screenWidth * 0.9
        
        // Max height: special case — if auto-width AND fixed-height, use fixed height as max
        // Otherwise use 90% of screen (kInAppNotificationDefaultHeight)
        let maxHeightInPoints: CGFloat = (isAutoWidth && templateHeightInPoints > 0)
            ? templateHeightInPoints
            : screenHeight * 0.9
        
        let ratio = imageSize.height / imageSize.width
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        // Case A: Both auto width + auto height, AND image fits within max bounds
        if isAutoWidth && isAutoHeight
            && imageSize.width < maxWidthInPoints
            && imageSize.height < maxHeightInPoints {
            width = imageSize.width
            height = imageSize.height
        }
        // Case B: Auto width + Fixed height
        else if isAutoWidth && !isAutoHeight {
            height = maxHeightInPoints
            width = maxHeightInPoints / ratio
            if width > maxWidthInPoints {
                width = maxWidthInPoints
                height = maxWidthInPoints * ratio
            }
        }
        // Case C: Fixed width + Auto height (or both fixed, or auto+auto but image too large)
        else {
            width = maxWidthInPoints
            height = maxWidthInPoints * ratio
            if height > maxHeightInPoints {
                height = maxHeightInPoints
                width = maxHeightInPoints / ratio
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    /// Compute modal width in points from payload (non-image case).
    /// Matches UIKit's positionNotificationView width fallback.
    ///
    /// UIKit priority:
    /// 1. templateStyle.width > 0 → use it (percentage or points based on dimensionType)
    /// 2. notification.width > 0  → use it (always percentage, root-level payload field)
    /// 3. Default: 90% of screen (kInAppNotificationDefaultWidth = 90.0)
    private func modalWidth(in screenWidth: CGFloat) -> CGFloat {
        let isPoints = viewModel.notification.dimensionType == "points"
        let templateWidth = viewModel.notification.templateStyle.width
        if templateWidth > 0 {
            return isPoints ? CGFloat(templateWidth) : screenWidth * CGFloat(templateWidth) / 100.0
        }
        let notifWidth = viewModel.notification.width
        if notifWidth > 0 {
            return screenWidth * CGFloat(notifWidth) / 100.0
        }
        // Default: kInAppNotificationDefaultWidth = 90%
        return screenWidth * 0.9
    }
    
    /// Compute modal height in points from payload (non-image case).
    /// Returns nil when height is not set → content-driven height (SwiftUI default).
    ///
    /// NOTE: We only check templateStyle.height, NOT notification.height (root-level).
    /// notification.height defaults to 90.0 in setDataUsingPayload: and would always
    /// produce a fixed height, but UIKit does NOT use it — it falls back to content-driven.
    private func modalHeight(in screenHeight: CGFloat) -> CGFloat? {
        let isPoints = viewModel.notification.dimensionType == "points"
        let templateHeight = viewModel.notification.templateStyle.height
        if templateHeight > 0 {
            return isPoints ? CGFloat(templateHeight) : screenHeight * CGFloat(templateHeight) / 100.0
        }
        return nil  // content-driven
    }
    
    // MARK: - Close Button Styling
    
    var shouldShowCloseButton: Bool {
        // If explicitly set in payload, use that value
        if let enableCloseButton = viewModel.notification.templateStyle.enableCloseButton {
            return enableCloseButton.boolValue
        }
        // Match UIKit's checkDefaultCloseButtonStatusForInApp:
        // Modal with NO action buttons → show close button by default
        // Modal WITH action buttons → hide close button by default
        let hasActions = viewModel.notification.notificationContent.actions.count > 0
        return !hasActions
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
    
    /// Close button corner radius — matches UIKit's createCloseButton:
    /// UIKit: closeButton.backgroundRadius if set, else 0.5 * bounds.width (circular)
    var closeButtonCornerRadius: CGFloat {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let radius = closeButton.backgroundRadius, radius.floatValue > 0 {
            return CGFloat(radius.floatValue)
        }
        // UIKit default: 0.5 * KInAppNotificationModalCloseButtonWidth = 0.5 * 32 = 16
        return closeButtonSize * 0.5
    }
    
    /// Close button size — matches UIKit's KInAppNotificationModalCloseButtonWidth/Height = 32.0
    var closeButtonSize: CGFloat {
        return 32.0
    }
    
    /// Close button margin from modal edge — UIKit uses 5pt margin in createCloseButton:
    var closeButtonMargin: CGFloat {
        return 5
    }
    
    // MARK: - Background Dim
    
    /// Background dim opacity from payload, matching UIKit's setBackgroundDim
    /// UIKit reads templateStyle.backgroundDimAmount, defaults to 0.5
    var backgroundDimAmount: Double {
        if let dimAmount = viewModel.notification.templateStyle.backgroundDimAmount,
           dimAmount.floatValue > 0 {
            return Double(dimAmount.floatValue)
        }
        return 0.5
    }
    
    // MARK: - Helper Methods
    
    /// Text alignment matching UIKit's getTextAlignement:
    /// UIKit handles "left"/"start" → left, "right"/"end" → right, else → center
    private func textAlignment(from gravity: String) -> TextAlignment {
        switch gravity.lowercased() {
        case "left", "start":
            return .leading
        case "right", "end":
            return .trailing
        default:
            return .center
        }
    }
    
    /// Frame alignment matching UIKit's getTextAlignement:
    private func frameAlignment(from gravity: String) -> Alignment {
        switch gravity.lowercased() {
        case "left", "start":
            return .leading
        case "right", "end":
            return .trailing
        default:
            return .center
        }
    }
}

