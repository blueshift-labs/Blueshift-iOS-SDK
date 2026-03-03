//
//  BlueShiftInAppNotification+SwiftUI.swift
//  BlueShift-iOS-SDK
//
//  Swift extensions for BlueShiftInAppNotification
//

import Foundation
import SwiftUI

// Simple extensions without enum references
@available(iOS 13.0, *)
extension BlueShiftInAppNotification {
    
    /// Get the background color as a SwiftUI Color
    var backgroundColor: Color {
        if let colorString = templateStyle.backgroundColor {
            return Color(hex: colorString) ?? .white
        }
        return .white
    }
    
    /// Check if background action is enabled
    var canDismissOnBackgroundTap: Bool {
        return templateStyle.enableBackgroundAction
    }
    
    /// Get the background dim amount
    var backgroundDimOpacity: Double {
        if let dimAmount = templateStyle.backgroundDimAmount {
            return min(max(dimAmount.doubleValue, 0.0), 1.0)
        }
        return 0.5
    }
}

@available(iOS 13.0, *)
extension BlueShiftInAppNotificationButton {
    
    /// Get button background color as SwiftUI Color
    var buttonBackgroundColor: Color {
        if let colorString = backgroundColor {
            return Color(hex: colorString) ?? .blue
        }
        return .blue
    }
    
    /// Get button text color as SwiftUI Color
    var buttonTextColor: Color {
        if let colorString = textColor {
            return Color(hex: colorString) ?? .white
        }
        return .white
    }
    
    /// Get corner radius
    var cornerRadius: CGFloat {
        return CGFloat(backgroundRadius?.floatValue ?? 8.0)
    }
}

// MARK: - Color Extension for Hex Support
@available(iOS 13.0, *)
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
