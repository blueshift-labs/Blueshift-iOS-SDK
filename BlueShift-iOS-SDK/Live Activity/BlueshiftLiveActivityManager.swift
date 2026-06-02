//
//  BlueshiftLiveActivityManager.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 29/05/26.
//

import Foundation
@preconcurrency import ActivityKit

/// Manages Blueshift Live Activity token registration and lifecycle actions.
@available(iOS 16.1, *)
@objc public class BlueshiftLiveActivityManager: NSObject, @unchecked Sendable {

    // MARK: - Shared Instance
    
    /// Exposed to Objective-C cleanly without forcing global MainActor compliance on the whole class
    @objc public static let shared = BlueshiftLiveActivityManager()

    // MARK: - Private State Tracking Trees
    
    private let pushToStartTasks = ThreadSafeStorage<Task<Void, Never>>()
    private let lifecycleTasks = ThreadSafeStorage<Task<Void, Never>>()
    private let enablementTask = ThreadSafeStorage<Task<Void, Never>>()

    private override init() { super.init() }

    // MARK: - Public API

    @available(iOS 17.2, *)
    public func registerPushToStart<T: ActivityAttributes>(
        forType type: Activity<T>.Type,
        name: String
    ) {
        // Guard: SDK configuration verification
        guard BlueShift.sharedInstance()?.config?.enableLiveActivity == true else {
            BlueshiftLog.logInfo("Blueshift Live Activity: disabled in config. Skipping configuration for '\(name)'.", withDetails: nil, methodName: nil)
            return
        }

        // Guard: Local Device Settings check
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            BlueshiftLog.logInfo("Blueshift Live Activity: disabled in device Settings. Sending disabled action.", withDetails: nil, methodName: nil)
            
            // Fixed payload routing via MainActor context
            Task { @MainActor in
                Self.logPayload(Self.shared.buildActionPayload("disabled"), url: BlueshiftRoutes.getLiveActivityActionURL())
            }
            return
        }

        startEnablementObserver()

        let activityTypeName = name

        // 1. Safe Tracking Loop for Push-to-Start (PTS) Token Rotations
        let ptsTask = Task { [activityTypeName] in
            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { break }
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                
                var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                payload["activity_attributes_type"] = activityTypeName
                payload["push_to_start_token"] = token
                BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityPushToStartURL())
            }
        }
        
        // FIX 1: Wrap actor mutations inside a task block to safely await across threads
        Task {
            await pushToStartTasks.set(ptsTask, forKey: name)
        }

        // 2. Continuous Tracking Loop: Detects both launch activities AND background push-to-start activities
        let monitoringTask = Task { [activityTypeName] in
            for await activity in Activity<T>.activityUpdates {
                guard !Task.isCancelled else { break }
                // FIX 2: Safely read the non-isolated manager instance without crossing MainActor walls
                BlueshiftLiveActivityManager.shared.observeRunningActivity(activity, activityType: activityTypeName)
            }
        }
        
        Task {
            await lifecycleTasks.set(monitoringTask, forKey: name)
        }
    }

    // MARK: - Private: Observe Running Activity

    @available(iOS 17.2, *)
    private func observeRunningActivity<T: ActivityAttributes>(
        _ activity: Activity<T>,
        activityType: String
    ) {
        let activityId = activity.id
        let capturedActivityType = activityType
        let capturedActivityId = activityId

        Task { [capturedActivityType, capturedActivityId, weak activity] in
            guard let activity = activity else { return }

            if let tokenData = activity.pushToken {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                payload["activity_attributes_type"] = capturedActivityType
                payload["activity_id"] = capturedActivityId
                payload["instance_token"] = token
                BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityInstanceTokenURL())
            }

            async let watchTokens: Void = {
                for await tokenData in activity.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                    payload["activity_attributes_type"] = capturedActivityType
                    payload["activity_id"] = capturedActivityId
                    payload["instance_token"] = token
                    BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityInstanceTokenURL())
                }
            }()

            async let watchStates: Void = {
                for await state in activity.activityStateUpdates {
                    switch state {
                    case .dismissed:
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["activity_attributes_type"] = capturedActivityType
                        payload["activity_id"] = capturedActivityId
                        payload["action"] = "dismiss"
                        BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityActionURL())
                        return
                    case .ended:
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["activity_attributes_type"] = capturedActivityType
                        payload["activity_id"] = capturedActivityId
                        payload["action"] = "ended"
                        BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityActionURL())
                        return
                    case .active:
                        break
                    case .stale:
                        break
                    
                    @unknown default:
                        break
                    }
                }
            }()

            _ = await [watchTokens, watchStates]
        }
    }
    
    // MARK: - Private: Enablement Observer

    private func startEnablementObserver() {
        if #available(iOS 16.2, *) {
            Task {
                // Safely await reading from the concurrent storage actor context
                if await enablementTask.get(forKey: "global") != nil { return }
                
                let task = Task.detached { @Sendable in
                    for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                        guard !Task.isCancelled else { break }
                        if !enabled {
                            var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                            payload["action"] = "disabled"
                            BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityActionURL())
                            BlueshiftLog.logInfo("Blueshift Live Activity: disabled in device Settings.", withDetails: nil, methodName: nil)
                        }
                    }
                }
                await enablementTask.set(task, forKey: "global")
            }
        }
    }

    // MARK: - Private: Payload Helpers

    private static func buildBasePayloadStatic() -> [String: String] {
        var payload: [String: String] = [:]
        if let apiKey = BlueShift.sharedInstance()?.config?.apiKey {
            payload["api_key"] = apiKey
        }
        if let deviceId = BlueShiftDeviceData.current()?.deviceUUID {
            payload["device_id"] = deviceId
        }
        if let customerId = BlueShiftUserInfo.sharedInstance()?.retailerCustomerID {
            payload["customer_id"] = customerId
        }
        return payload
    }

    private func buildActionPayload(_ action: String) -> [String: String] {
        var payload = Self.buildBasePayloadStatic()
        payload["action"] = action
        return payload
    }

    private static func logPayload(_ payload: [String: String], url: String) {
        BlueshiftLog.logAPICallInfo(
            "Blueshift Live Activity — Would POST to: \(url)",
            withDetails: payload as [AnyHashable: Any],
            statusCode: 0
        )
    }
}

// MARK: - Thread-Safe Storage Companion Actor
// FIX 3: Explicit iOS 13 availability guard applied to the underlying Actor structure itself
@available(iOS 13.0.0, *)
fileprivate actor ThreadSafeStorage<Element: Sendable> {
    private var storage: [String: Element] = [:]
    
    func set(_ value: Element, forKey key: String) {
        storage[key] = value
    }
    
    func get(forKey key: String) -> Element? {
        return storage[key]
    }
    
    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
