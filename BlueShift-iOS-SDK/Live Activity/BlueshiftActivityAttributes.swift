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

    var bsftActivityId: String? { get }
    var bsftCustomerId: String? { get }
    var bsftEmail: String? { get }
}

// @available(iOS 16.1, *)
// public extension BlueshiftActivityAttributes {
//     var bsftCustomerId: String? { nil }
//     var bsftEmail: String? { nil }
// }

#endif
