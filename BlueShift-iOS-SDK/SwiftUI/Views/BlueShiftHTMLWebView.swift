//
//  BlueShiftHTMLWebView.swift
//  BlueShift-iOS-SDK
//
//  UIViewRepresentable wrapper for WKWebView to display HTML in-app notifications.
//  Mirrors the UIKit implementation in BlueShiftNotificationWebViewController.m
//

import SwiftUI
import WebKit

/// UIViewRepresentable wrapper around WKWebView for HTML in-app notifications.
///
/// **UIKit reference:** `BlueShiftNotificationWebViewController.m`
///
/// This view replicates the UIKit flow:
/// 1. Creates a WKWebView with inline media playback (matches `createWebView`)
/// 2. Loads content from URL or raw HTML string (matches `loadWebView`)
/// 3. Intercepts link taps via WKNavigationDelegate (matches `decidePolicyForNavigationAction`)
/// 4. Reports content size after load for auto-sizing (matches `resizeWebViewAsPerContent`)
/// 5. Reports when content finishes loading (matches `webView:didFinishNavigation:`)
@available(iOS 13.0, *)
struct BlueShiftHTMLWebView: UIViewRepresentable {
    
    /// Raw HTML content string (from notification.notificationContent.content)
    let htmlContent: String?
    
    /// URL to load (from notification.notificationContent.url)
    let url: String?
    
    /// Background corner radius (from templateStyle.backgroundRadius)
    let cornerRadius: CGFloat
    
    /// Callback when a link is tapped inside the HTML content
    /// Matches UIKit's `handleInAppWebViewActionForURL:`
    let onLinkTap: (URL) -> Void
    
    /// Callback when web content finishes loading
    /// Matches UIKit's `showInAppOnWebViewLoad` flow
    let onContentLoaded: () -> Void
    
    /// Callback reporting content size after load for auto-sizing
    /// Matches UIKit's `resizeWebViewAsPerContent` which evaluates
    /// document.body.scrollHeight and document.body.scrollWidth
    let onContentSizeChange: (CGSize) -> Void
    
    /// HTML header with viewport meta tag
    /// Matches UIKit's kInAppNotificationModalHTMLHeaderKey constant
    private static let htmlHeader = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // Matches UIKit's createWebView method
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.backgroundColor = .white
        webView.isOpaque = false
        webView.clipsToBounds = true
        webView.layer.cornerRadius = cornerRadius
        
        // Set delegates - matches UIKit's setWebViewDelegate
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        
        // Load content - matches UIKit's loadWebView
        loadContent(in: webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // No dynamic updates needed - content is loaded once in makeUIView
    }
    
    /// Load content into the web view
    /// Matches UIKit's `loadWebView` which checks for URL first, then falls back to HTML
    private func loadContent(in webView: WKWebView) {
        if let urlString = url, let contentURL = URL(string: urlString) {
            // URL mode - matches UIKit's loadFromURL
            let request = URLRequest(url: contentURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
            webView.load(request)
        } else if let html = htmlContent {
            // HTML mode - matches UIKit's loadFromHTML
            // Prepends viewport header just like UIKit does
            let fullHTML = Self.htmlHeader + html
            webView.loadHTMLString(fullHTML, baseURL: nil)
        }
    }
    
    // MARK: - Coordinator
    
    /// Coordinator handles WKNavigationDelegate and UIScrollViewDelegate
    /// Mirrors UIKit's BlueShiftNotificationWebViewController delegate methods
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        let parent: BlueShiftHTMLWebView
        
        init(_ parent: BlueShiftHTMLWebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        /// Intercept link taps - matches UIKit's `decidePolicyForNavigationAction`
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    parent.onLinkTap(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        /// Content finished loading - matches UIKit's `webView:didFinishNavigation:`
        /// UIKit evaluates document.readyState, then calls showInAppOnWebViewLoad after 1 sec delay
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.readyState") { [weak self] complete, error in
                guard let self = self else { return }
                if complete != nil {
                    // Content loaded successfully
                    // Match UIKit's 1-second delay before showing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.parent.onContentLoaded()
                        self.resizeWebViewAsPerContent(webView)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.parent.onContentLoaded()
                        self.resizeWebViewAsPerContent(webView)
                    }
                }
            }
        }
        
        /// Navigation failed - matches UIKit's `webView:didFailNavigation:withError:`
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.parent.onContentLoaded()
                self?.resizeWebViewAsPerContent(webView)
            }
        }
        
        /// Resize web view based on content dimensions
        /// Matches UIKit's `resizeWebViewAsPerContent` which evaluates
        /// document.body.scrollHeight and document.body.scrollWidth via JavaScript
        private func resizeWebViewAsPerContent(_ webView: WKWebView) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] height, _ in
                webView.evaluateJavaScript("document.body.scrollWidth") { [weak self] width, _ in
                    guard let self = self else { return }
                    let contentWidth = (width as? CGFloat) ?? webView.frame.width
                    let contentHeight = (height as? CGFloat) ?? webView.frame.height
                    DispatchQueue.main.async {
                        self.parent.onContentSizeChange(CGSize(width: contentWidth, height: contentHeight))
                    }
                }
            }
        }
        
        // MARK: - UIScrollViewDelegate
        
        /// Disable pinch zoom - matches UIKit's `scrollViewWillBeginZooming`
        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }
    }
}
