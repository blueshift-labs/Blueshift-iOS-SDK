//
//  BlueshiftLiveActivityAPIManager.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 09/06/26.
//

import Foundation

/// Networking layer for all three Live Activity API endpoints.
///
/// Design: Every call is routed through BlueShiftRequestQueue.addRequestOperation(_:)
/// which automatically:
///   - Executes immediately if the device is online
///   - Persists to Core Data and defers to batch queue if offline
///   - Retries up to 3 times with 5-minute intervals on failure
///
/// This means no token is ever silently dropped due to connectivity.
final class BlueshiftLiveActivityAPIManager {

    // MARK: - Endpoint 1: Register Push-to-Start Token
    //
    // POST /api/v1/live_activity/push_to_start_token
    // Called every time Activity<T>.pushToStartTokenUpdates emits a new token.
    // The PTS token rotates on every app launch, so this fires frequently.
    // Required payload keys: device_id, email/customer_id, activity_attributes_type, push_to_start_token
    //
    static func registerPushToStartToken(_ payload: [String: String]) {
        enqueue(
            payload: payload,
            url: BlueshiftRoutes.getLiveActivityPushToStartURL(),
            label: "PushToStartToken"
        )
    }

    // MARK: - Endpoint 2: Register Instance Token
    //
    // POST /api/v1/live_activity/instance_token
    // Called when a live activity is first observed (activity.pushToken exists)
    // and again whenever activity.pushTokenUpdates emits a new token.
    // Required payload keys: device_id, email/customer_id, activity_attributes_type, activity_id, instance_token
    //
    static func registerInstanceToken(_ payload: [String: String]) {
        enqueue(
            payload: payload,
            url: BlueshiftRoutes.getLiveActivityInstanceTokenURL(),
            label: "InstanceToken"
        )
    }

    // MARK: - Endpoint 3: User Action
    //
    // POST /api/v1/live_activity/action
    // Called for lifecycle state changes: start, dismiss, ended, disabled.
    // Required payload keys: device_id, email/customer_id, activity_attributes_type, activity_id, action
    //
    static func sendAction(_ payload: [String: String]) {
        let actionLabel = payload["activity_action"] ?? "unknown"
        enqueue(
            payload: payload,
            url: BlueshiftRoutes.getLiveActivityActionURL(),
            label: "Action[\(actionLabel)]"
        )
    }

    // MARK: - Private: Route through SDK's Core Data-backed queue
    //
    // BlueShiftRequestOperation wraps the URL + params + retry metadata.
    // BlueShiftRequestQueue.addRequestOperation(_:) then:
    //   1. Online  → inserts to Core Data as non-batch → immediately calls processRequestsInQueue
    //   2. Offline → inserts to Core Data as batch     → waits for next processRequestsInQueue trigger
    //   3. Failure → decrements retryAttemptsCount, sets nextRetryTimeStamp +5min, re-queues as batch
    //   4. After 3 failures (kRequestTryMaximumLimit) → drops the record
    //
    private static func enqueue(
        payload: [String: String],
        url: String,
        label: String
    ) {
        guard let operation = BlueShiftRequestOperation(
            requestURL: url,
            andHttpMethod: BlueShiftHTTPMethodPOST,
            andParameters: payload as [AnyHashable: Any],
            andRetryAttemptsCount: 3,
            andNextRetryTimeStamp: 0,
            andIsBatchEvent: false
        ) else { return }
        BlueShiftRequestQueue.add(operation)
        BlueshiftLog.logAPICallInfo(
            "Live Activity [\(label)] - Enqueued POST → \(url)",
            withDetails: payload as [AnyHashable: Any],
            statusCode: 0
        )
    }
}
