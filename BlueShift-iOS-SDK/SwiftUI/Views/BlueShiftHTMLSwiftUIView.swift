//
//  BlueShiftHTMLSwiftUIView.swift
//  BlueShift-iOS-SDK
//
//  SwiftUI view for HTML in-app notifications.
//  Mirrors the UIKit implementation in BlueShiftNotificationWebViewController.m
//
//  Key behaviors replicated from UIKit:
//  - WKWebView with viewport meta header for HTML content
//  - URL loading or raw HTML string loading
//  - Auto-sizing based on content dimensions (resizeWebViewAsPerContent)
//  - Positioning: top/center/bottom with margins
//  - Close button overlay
//  - Background dim
//  - Link interception for deep link handling
//  - Deferred presentation after web content loads
//

import SwiftUI
#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

/// SwiftUI view for HTML in-app notifications
///
/// **UIKit reference:** `BlueShiftNotificationWebViewController`
///
/// This view replicates the complete UIKit HTML in-app notification flow:
/// 1. Shows a background dim overlay (matches `setBackgroundDim`)
/// 2. Positions a WKWebView based on templateStyle (matches `positionWebView`)
/// 3. Auto-sizes based on content after load (matches `resizeWebViewAsPerContent`)
/// 4. Shows close button overlay (matches `createCloseButton`)
/// 5. Intercepts link taps for deep link handling (matches `decidePolicyForNavigationAction`)
@available(iOS 13.0, *)
struct BlueShiftHTMLSwiftUIView: View {
    
    @ObservedObject var viewModel: BlueShiftInAppViewModel
    
    /// Whether the web content has finished loading
    /// Matches UIKit's deferred presentation via `showInAppOnWebViewLoad`
    @State private var isContentLoaded: Bool = false
    
    /// Content size reported by the web view after loading
    /// Used for auto-sizing, matches UIKit's `setHeightWidthAsPerHTMLContentWidth:height:`
    @State private var contentSize: CGSize = .zero
    
    /// Opacity for fade-in animation
    @State private var opacity: Double = 0.0
    
    /// Whether auto-width is enabled (no explicit width in templateStyle)
    /// Matches UIKit's `isAutoWidth` flag in `setAutomaticScale`
    private var isAutoWidth: Bool {
        return viewModel.notification.templateStyle.width <= 0
    }
    
    /// Whether auto-height is enabled (no explicit height in templateStyle)
    /// Matches UIKit's `isAutoHeight` flag in `setAutomaticScale`
    private var isAutoHeight: Bool {
        return viewModel.notification.templateStyle.height <= 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dim - matches UIKit's setBackgroundDim
                Color.black.opacity(backgroundDimAmount)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(opacity)
                    .onTapGesture {
                        // Tap outside to dismiss if background action is enabled
                        if viewModel.notification.templateStyle.enableBackgroundAction {
                            dismissHTML()
                        }
                    }
                
                // Web view content with close button overlay
                // IMPORTANT: The web view must always be in the view hierarchy so it can
                // load content. We control visibility via opacity instead of conditional rendering.
                // This avoids the deadlock where the web view can't load because it's not in
                // the hierarchy, and it can't be added because content hasn't loaded yet.
                webViewWithCloseButton(in: geometry)
                    .opacity(isContentLoaded ? opacity : 0.0)
            }
        }
        .onAppear {
            // If content is URL-based, show immediately like UIKit
            // (UIKit's loadFromURL sets navigationDelegate to nil, meaning no deferred presentation)
            if viewModel.notification.notificationContent.url != nil {
                isContentLoaded = true
                animateIn()
            }
            // Notify shown — matches UIKit's inAppDidShow: → trackInAppNotificationShowingWithParameter: (a=open)
            viewModel.notifyDidShow()
        }
    }
    
    // MARK: - Web View with Close Button
    
    /// Web view positioned with close button overlay
    /// Matches UIKit's `initialiseWebView` which calls `positionWebView` + `createCloseButton`
    @ViewBuilder
    private func webViewWithCloseButton(in geometry: GeometryProxy) -> some View {
        let frame = calculateFrame(in: geometry)
        let position = effectivePosition
        
        VStack {
            if position == "bottom" || position == "center" {
                Spacer()
            }
            
            if position == "top" {
                // Top margin + close button space
                // Matches UIKit: frame.origin.y = 0.0f + extra + 20.0f
                let extra: CGFloat = shouldShowCloseButton ? 16.0 : 0.0
                Spacer().frame(height: 20.0 + extra + topMargin)
            }
            
            ZStack(alignment: .topTrailing) {
                // WKWebView
                BlueShiftHTMLWebView(
                    htmlContent: viewModel.notification.notificationContent.content,
                    url: viewModel.notification.notificationContent.url,
                    cornerRadius: backgroundRadius,
                    onLinkTap: { url in
                        handleLinkTap(url: url)
                    },
                    onContentLoaded: {
                        // Matches UIKit's showInAppOnWebViewLoad
                        if !isContentLoaded {
                            isContentLoaded = true
                            animateIn()
                        }
                    },
                    onContentSizeChange: { size in
                        // Matches UIKit's resizeWebViewAsPerContent
                        contentSize = size
                    }
                )
                .frame(width: frame.width, height: frame.height)
                .cornerRadius(backgroundRadius)
                
                // Close button - matches UIKit's createCloseButton
                // UIKit positions it with 5pt margin from top and right edges of the web view frame
                // CGRectMake(xPosition, frame.origin.y + margin, width, height)
                // where margin = 5
                if shouldShowCloseButton {
                    buildCloseButton()
                        .padding(.top, 5)
                        .padding(.trailing, 5)
                }
            }
            .frame(width: frame.width, height: frame.height)
            
            if position == "top" || position == "center" {
                Spacer()
            }
            
            if position == "bottom" {
                Spacer().frame(height: bottomMargin)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Close Button
    
    /// Build close button view - matches UIKit's `createCloseButton` logic
    /// Uses FontAwesome icon or default X button
    @ViewBuilder
    private func buildCloseButton() -> some View {
        Button(action: {
            dismissHTML()
        }) {
            let closeButton = viewModel.notification.templateStyle.closeButton
            if let text = closeButton.text, !text.isEmpty {
                // Custom close button with FontAwesome icon
                // Matches UIKit's custom close button branch
                let fontSize = closeButton.textSize?.floatValue ?? 22.0
                Text(text)
                    .font(.custom("FontAwesome5Free-Solid", size: CGFloat(fontSize)))
                    .foregroundColor(closeButtonTextColor)
                    .frame(width: 32, height: 32)
                    .background(closeButtonBackgroundColor)
                    .cornerRadius(closeButtonCornerRadius)
            } else {
                // Default close button (BlueShiftNotificationCloseButton equivalent)
                // Matches UIKit's default close button branch
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Frame Calculation
    
    /// Calculate the web view frame - matches UIKit's `positionWebView` method
    ///
    /// UIKit flow:
    /// 1. Determine width (auto or explicit)
    /// 2. Determine height (auto or explicit)
    /// 3. Apply margins
    /// 4. Convert percentage to points if needed
    /// 5. Cap to screen bounds
    private func calculateFrame(in geometry: GeometryProxy) -> CGSize {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        // Width calculation - matches UIKit's positionWebView width logic
        if isAutoWidth {
            // Auto width logic from UIKit:
            // iPad: cap at 470pt max width (kInAppNotificationMaximumWidthInPoints)
            // iPhone landscape: cap at 470pt
            // iPhone portrait: 90% of screen (kInAppNotificationDefaultWidth)
            let maxWidthPoints: CGFloat = 470.0
            let defaultWidthPercent: CGFloat = 90.0
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad - use max width as percentage of screen
                width = min(maxWidthPoints, screenWidth * (defaultWidthPercent / 100.0))
            } else {
                let deviceWidth = screenWidth * (defaultWidthPercent / 100.0)
                if deviceWidth > maxWidthPoints {
                    width = maxWidthPoints
                } else {
                    width = deviceWidth
                }
            }
        } else {
            width = CGFloat(viewModel.notification.templateStyle.width)
        }
        
        // Height calculation - matches UIKit's positionWebView height logic
        if isAutoHeight {
            // Auto height: use content size if available, otherwise minimum
            let minHeight: CGFloat = 25.0 // kHTMLInAppNotificationMinimumHeight
            if contentSize.height > 0 {
                height = min(contentSize.height, screenHeight)
            } else {
                height = minHeight
            }
        } else {
            height = CGFloat(viewModel.notification.templateStyle.height)
        }
        
        // Apply dimension type conversion - matches UIKit's percentage/points logic
        let dimensionType = viewModel.notification.dimensionType ?? ""
        
        if dimensionType == "percentage" {
            let convertedWidth = screenWidth * (width / 100.0)
            let convertedHeight = screenHeight * (height / 100.0)
            
            var finalWidth = convertedWidth
            var finalHeight = convertedHeight
            
            if width == 100 {
                finalWidth = convertedWidth - (leftMargin + rightMargin)
            }
            if height == 100 {
                finalHeight = convertedHeight - (topMargin + bottomMargin)
            }
            
            width = finalWidth
            height = finalHeight
        } else if dimensionType == "points" {
            // Cap to screen bounds
            width = min(width, screenWidth)
            height = min(height, screenHeight)
        }
        
        // Auto-size adjustments based on content
        // Matches UIKit's setHeightWidthAsPerHTMLContentWidth:height:
        if (isAutoWidth || isAutoHeight) && contentSize.width > 0 && contentSize.height > 0 {
            if isAutoWidth {
                let maxWidth = screenWidth * 0.9 // 90% default
                width = min(contentSize.width, maxWidth)
            }
            if isAutoHeight {
                height = min(contentSize.height, screenHeight)
            }
        }
        
        // Ensure minimum dimensions
        width = max(width, 0)
        height = max(height, 25.0)
        
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Computed Properties
    
    /// Effective position - matches UIKit's position resolution
    /// UIKit: `(self.notification.templateStyle && self.notification.templateStyle.position) ? self.notification.templateStyle.position : self.notification.position`
    private var effectivePosition: String {
        if let pos = viewModel.notification.templateStyle.position, !pos.isEmpty {
            return pos
        }
        let pos = viewModel.notification.position as String
        return pos.isEmpty ? "center" : pos
    }
    
    /// Background dim amount - matches UIKit's setBackgroundDim
    /// Default 0.5, reads from templateStyle.backgroundDimAmount
    private var backgroundDimAmount: Double {
        if let dimAmount = viewModel.notification.templateStyle.backgroundDimAmount,
           dimAmount.floatValue > 0 {
            return Double(dimAmount.floatValue)
        }
        return 0.5
    }
    
    /// Background corner radius - matches UIKit's setBackgroundRadius
    private var backgroundRadius: CGFloat {
        if let radius = viewModel.notification.templateStyle.backgroundRadius,
           radius.floatValue > 0 {
            return CGFloat(radius.floatValue)
        }
        return 0.0
    }
    
    /// Whether to show close button - matches UIKit's shouldShowCloseButton
    /// For HTML type, default is YES (matches checkDefaultCloseButtonStatusForInApp)
    private var shouldShowCloseButton: Bool {
        if let enableCloseButton = viewModel.notification.templateStyle.enableCloseButton {
            return enableCloseButton.boolValue
        }
        // Default for HTML type is YES
        return true
    }
    
    // MARK: - Margin Properties
    
    /// Top margin from templateStyle.margin
    private var topMargin: CGFloat {
        let margin = viewModel.notification.templateStyle.margin
        return margin.top > 0 ? CGFloat(margin.top) : 0
    }
    
    /// Bottom margin from templateStyle.margin
    private var bottomMargin: CGFloat {
        let margin = viewModel.notification.templateStyle.margin
        return margin.bottom > 0 ? CGFloat(margin.bottom) : 0
    }
    
    /// Left margin from templateStyle.margin
    private var leftMargin: CGFloat {
        let margin = viewModel.notification.templateStyle.margin
        return margin.left > 0 ? CGFloat(margin.left) : 0
    }
    
    /// Right margin from templateStyle.margin
    private var rightMargin: CGFloat {
        let margin = viewModel.notification.templateStyle.margin
        return margin.right > 0 ? CGFloat(margin.right) : 0
    }
    
    // MARK: - Close Button Styling
    
    private var closeButtonTextColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let textColor = closeButton.textColor {
            return Color(hex: textColor) ?? .white
        }
        return .white
    }
    
    private var closeButtonBackgroundColor: Color {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let bgColor = closeButton.backgroundColor {
            return Color(hex: bgColor) ?? .black
        }
        return .black
    }
    
    private var closeButtonCornerRadius: CGFloat {
        let closeButton = viewModel.notification.templateStyle.closeButton
        if let radius = closeButton.backgroundRadius,
           radius.floatValue > 0 {
            return CGFloat(radius.floatValue)
        }
        return 16.0 // Default circular
    }
    
    // MARK: - Actions
    
    /// Handle link tap from the web view
    /// Matches UIKit's `handleInAppWebViewActionForURL:`
    private func handleLinkTap(url: URL) {
        viewModel.handleAction(url: url.absoluteString)
    }
    
    /// Dismiss the HTML notification
    private func dismissHTML() {
        withAnimation(.easeInOut(duration: 0.25)) {
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewModel.dismiss()
        }
    }
    
    /// Animate in - matches UIKit's showFromWindow animated fade-in
    private func animateIn() {
        withAnimation(.easeInOut(duration: 0.25)) {
            opacity = 1.0
        }
    }
}
