//
//  BlueshiftActivityAttributes.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 30/06/26.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// A protocol that clients conform to alongside ActivityAttributes
/// to enable Blueshift to read the blueshiftActivityId per activity instance.
///
/// Usage:
/// ```swift
/// struct MyOrderAttributes: ActivityAttributes, BlueshiftActivityAttributes {
///     var blueshiftActivityId: String?
///
///     struct ContentState: Codable, Hashable {
///         var status: String
///     }
/// }
/// ```
@available(iOS 16.1, *)
public protocol BlueshiftActivityAttributes: ActivityAttributes {
    /// Optional Blueshift campaign/activity identifier set by the client.
    /// When present, the SDK sends this as `activity_id` in all
    /// instance token and lifecycle action API calls.
    var blueshiftActivityId: String? { get }
}

#endif
