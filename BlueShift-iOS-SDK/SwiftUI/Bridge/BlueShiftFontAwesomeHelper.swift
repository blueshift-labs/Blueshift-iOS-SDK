//
//  BlueShiftFontAwesomeHelper.swift
//  BlueShift-iOS-SDK
//
//  Helper for Font Awesome support in SwiftUI
//

import Foundation
import UIKit
import SwiftUI
import CoreText

/// Helper class to manage Font Awesome font loading for SwiftUI views
@available(iOS 13.0, *)
public class BlueShiftFontAwesomeHelper {
    
    // Font Awesome constants
    private static let fontAwesomeName = "FontAwesome5Free-Solid"
    private static let fontFileDownloadURL = "https://cdn.getblueshift.com/inapp/Font+Awesome+5+Free-Solid-900.otf"
    
    /// Check if Font Awesome is already loaded
    public static func isFontAwesomeLoaded() -> Bool {
        return UIFont(name: fontAwesomeName, size: 20) != nil
    }
    
    /// Load Font Awesome font (downloads if needed, registers with Core Text)
    /// Mirrors UIKit's `createFontFile:` in BlueShiftNotificationViewController.m
    public static func loadFontAwesome(completion: @escaping @Sendable (Bool) -> Void) {
        // Check if font is already registered in memory
        if isFontAwesomeLoaded() {
            completion(true)
            return
        }
        
        // Try to register from disk first (file may already be downloaded by SDK init)
        if registerFontFromDisk() {
            DispatchQueue.main.async {
                completion(self.isFontAwesomeLoaded())
            }
            return
        }
        
        // Download the font file, then register it with Core Text
        BlueShiftInAppNotificationHelper.downloadFontAwesomeFile {
            // After download completes, register the font with Core Text
            // downloadFontAwesomeFile only saves to disk — it does NOT register
            let registered = self.registerFontFromDisk()
            DispatchQueue.main.async {
                completion(registered && self.isFontAwesomeLoaded())
            }
        }
    }
    
    /// Register the Font Awesome font from disk with Core Text
    /// Mirrors UIKit's `createFontFile:` in BlueShiftNotificationViewController.m (lines 524-546)
    /// which reads the .otf file from disk and calls CTFontManagerRegisterGraphicsFont
    @discardableResult
    private static func registerFontFromDisk() -> Bool {
        let fontFileName = BlueShiftInAppNotificationHelper.createFileName(fromURL: fontFileDownloadURL)
        
        guard BlueShiftInAppNotificationHelper.hasFileExist(fontFileName) else {
            return false
        }
        
        let fontFilePath = BlueShiftInAppNotificationHelper.getLocalDirectory(fontFileName)
        guard let fontData = NSData(contentsOfFile: fontFilePath) as CFData?,
              let provider = CGDataProvider(data: fontData),
              let font = CGFont(provider) else {
            return false
        }
        
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(font, &error)
        if !success {
            // Font may already be registered (not an error)
            if let cfError = error?.takeRetainedValue() {
                let nsError = cfError as Error as NSError
                // kCTFontManagerErrorAlreadyRegistered = 105
                if nsError.code == 105 {
                    return true
                }
                print("[Blueshift] Failed to register FontAwesome: \(cfError)")
            }
            return false
        }
        return true
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
