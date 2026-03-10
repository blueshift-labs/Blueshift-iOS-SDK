//
//  BlueShiftFontAwesomeHelper.swift
//  BlueShift-iOS-SDK
//
//  Helper for Font Awesome support in SwiftUI
//

import Foundation
import UIKit
import SwiftUI

/// Helper class to manage Font Awesome font loading for SwiftUI views
@available(iOS 13.0, *)
public class BlueShiftFontAwesomeHelper {
    
    // Font Awesome constants
    private static let fontAwesomeName = "FontAwesome5Free-Solid"
    
    /// Check if Font Awesome is already loaded
    public static func isFontAwesomeLoaded() -> Bool {
        return UIFont(name: fontAwesomeName, size: 20) != nil
    }
    
    /// Load Font Awesome font (downloads if needed, registers if already downloaded)
    public static func loadFontAwesome(completion: @escaping (Bool) -> Void) {
        // Check if font is already loaded in memory
        if isFontAwesomeLoaded() {
            completion(true)
            return
        }
        
        // Download and register font using existing Objective-C helper
        BlueShiftInAppNotificationHelper.downloadFontAwesomeFile {
            // Font is downloaded and registered by Objective-C code
            // Just verify it's now available
            DispatchQueue.main.async {
                completion(self.isFontAwesomeLoaded())
            }
        }
    }
    
    /// Get Font Awesome font with specified size
    public static func fontAwesome(size: CGFloat) -> UIFont? {
        return UIFont(name: fontAwesomeName, size: size)
    }
}

/// SwiftUI View Modifier to ensure Font Awesome is loaded
@available(iOS 13.0, *)
struct FontAwesomeLoader: ViewModifier {
    @State private var isFontLoaded = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !BlueShiftFontAwesomeHelper.isFontAwesomeLoaded() {
                    BlueShiftFontAwesomeHelper.loadFontAwesome { success in
                        isFontLoaded = success
                    }
                } else {
                    isFontLoaded = true
                }
            }
    }
}

@available(iOS 13.0, *)
extension View {
    /// Ensures Font Awesome is loaded before displaying the view
    func loadFontAwesome() -> some View {
        self.modifier(FontAwesomeLoader())
    }
}
