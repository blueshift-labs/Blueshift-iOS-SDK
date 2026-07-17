//
//  BlueshiftActivityAttributes.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 30/06/26.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
public protocol BlueshiftActivityAttributes: ActivityAttributes {
    /// Optional Blueshift campaign/activity identifier set by the client.
    /// When present, the SDK sends this as `activity_id` in all
    var bsftActivityId: String? { get }
}

#endif
