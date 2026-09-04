//
//  BlueshiftLiveActivityManager.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 29/05/26.
//

import Foundation
@preconcurrency import ActivityKit
import BlueShift_iOS_SDK

/// Manages Blueshift Live Activity token registration and lifecycle actions.
@available(iOS 16.1, *)
@objc(BlueshiftLiveActivityManager)
public class BlueshiftLiveActivityManager: NSObject, @unchecked Sendable {

    // MARK: - Shared Instance

    /// Exposed to Objective-C cleanly without forcing global MainActor compliance on the whole class
    @objc public static let shared = BlueshiftLiveActivityManager()

    /// Returns true if Live Activity is enabled in SDK config AND enabled in device Settings.
    @objc public static func getLiveActivityStatus() -> Bool {
        guard BlueShift.sharedInstance()?.config?.enableLiveActivity == true else {
            return false
        }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Private State Tracking Trees

    private let pushToStartTasks = ThreadSafeStorage<Task<Void, Never>>()
    private let lifecycleTasks = ThreadSafeStorage<Task<Void, Never>>()
    private let enablementTask = ThreadSafeStorage<Task<Void, Never>>()

    private let registeredAssociations = AssociationCache()

    // Tracks the structural types the developer registered, allowing automatic recovery
    private let registeredTypes = ThreadSafeStorage<@Sendable () -> Void>()

    private override init() { super.init() }

    // MARK: - Public API

    @available(iOS 17.2, *)
    public func registerPushToStart<T: BlueshiftActivityAttributes>(
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

            return
        }

        startEnablementObserver()

        let activityTypeName = name

        // 1. Safe Tracking Loop for Push-to-Start (PTS) Token Rotations
        let ptsTask = Task { [activityTypeName] in
            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { break }
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                BlueshiftLiveActivityManager.shared.registerPushToStartTokenIfNeeded(token, activityTypeName: activityTypeName)
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

    // MARK: - Identity Lifecycle Hooks (called via ObjC runtime from Core SDK)

    @objc(handleIdentityChangeWithEmail:customerId:)
    public static func handleIdentityChange(email: String?, customerId: String?) {
        guard BlueShift.sharedInstance()?.config?.enableLiveActivity == true else { return }

        for (activityType, association) in shared.registeredAssociations.allEntries() {
            guard association.email != email || association.customerId != customerId else { continue }

            let deviceId = BlueShiftDeviceData.current()?.deviceUUID
            var payload: [String: String] = [
                "activity_attributes_type": activityType,
                "push_to_start_token": association.token
            ]
            if let deviceId = deviceId { payload["device_id"] = deviceId }
            if let email = email { payload["email"] = email }
            if let customerId = customerId { payload["customer_id"] = customerId }
            BlueshiftLiveActivityAPIManager.registerPushToStartToken(payload)

            shared.registeredAssociations.set(
                RegisteredAssociation(token: association.token, deviceId: deviceId, customerId: customerId, email: email),
                forKey: activityType
            )
        }
    }

    // MARK: - Public API - Explicit Associate/Dissociate

    @objc public static func associateAllPushToStartTokens() {
        guard BlueShift.sharedInstance()?.config?.enableLiveActivity == true else { return }

        let currentEmail = BlueShiftUserInfo.sharedInstance()?.email
        let currentCustomerId = BlueShiftUserInfo.sharedInstance()?.retailerCustomerID
        let currentDeviceId = BlueShiftDeviceData.current()?.deviceUUID

        for (activityType, association) in shared.registeredAssociations.allEntries() {
            var payload: [String: String] = [
                "activity_attributes_type": activityType,
                "push_to_start_token": association.token
            ]
            if let currentDeviceId = currentDeviceId { payload["device_id"] = currentDeviceId }
            if let currentEmail = currentEmail { payload["email"] = currentEmail }
            if let currentCustomerId = currentCustomerId { payload["customer_id"] = currentCustomerId }
            BlueshiftLiveActivityAPIManager.registerPushToStartToken(payload)

            shared.registeredAssociations.set(
                RegisteredAssociation(token: association.token, deviceId: currentDeviceId, customerId: currentCustomerId, email: currentEmail),
                forKey: activityType
            )
        }
    }

    @objc public static func dissociateAllPushToStartTokens() {
        guard let config = BlueShift.sharedInstance()?.config, config.enableLiveActivity else { return }
        guard !shared.registeredAssociations.allEntries().isEmpty else { return }

        BlueshiftLog.logInfo("Blueshift Live Activity: dissociating push-to-start token(s) for the currently identified customer/device.", withDetails: nil, methodName: nil)

        config.enableLiveActivity = false
        BlueShift.sharedInstance()?.identifyUser(withDetails: nil, canBatchThisEvent: false)
        config.enableLiveActivity = true

        shared.registeredAssociations.clearIdentity()
    }

    // MARK: - Private: Push-to-Start Registration

    @available(iOS 17.2, *)
    private func registerPushToStartTokenIfNeeded(_ token: String, activityTypeName: String) {
        let currentEmail = BlueShiftUserInfo.sharedInstance()?.email
        let currentCustomerId = BlueShiftUserInfo.sharedInstance()?.retailerCustomerID
        let currentDeviceId = BlueShiftDeviceData.current()?.deviceUUID

        // Skip only if this is a true duplicate: same token AND same identity we already sent it
        // under. A genuine OS token rotation, or an identity change picked up here because this
        // loop happened to fire around the same time as one, must still go out - this is why the
        // check compares the full (token, email, customerId) triple rather than just the token,
        // unlike the single-token dedupe this replaced.
        if let last = registeredAssociations.get(forKey: activityTypeName),
           last.token == token, last.email == currentEmail, last.customerId == currentCustomerId {
            return
        }

        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
        payload["activity_attributes_type"] = activityTypeName
        payload["push_to_start_token"] = token
        BlueshiftLiveActivityAPIManager.registerPushToStartToken(payload)

        registeredAssociations.set(
            RegisteredAssociation(token: token, deviceId: currentDeviceId, customerId: currentCustomerId, email: currentEmail),
            forKey: activityTypeName
        )
    }

    // MARK: - Private: Observe Running Activity

    @available(iOS 17.2, *)
    private func observeRunningActivity<T: BlueshiftActivityAttributes>(
        _ activity: Activity<T>,
        activityType: String
    ) {

        let capturedActivityType = activityType

        let capturedActivityId: String = activity.attributes.bsftActivityId ?? activity.id

        Task { [capturedActivityType, capturedActivityId, weak activity] in
            guard let activity = activity else { return }

            if let tokenData = activity.pushToken {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                payload["activity_attributes_type"] = capturedActivityType
                payload["bsft_activity_id"] = capturedActivityId
                payload["instance_token"] = token
                BlueshiftLiveActivityAPIManager.registerInstanceToken(payload)
            }

            async let watchTokens: Void = {
                for await tokenData in activity.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                    payload["activity_attributes_type"] = capturedActivityType
                    payload["bsft_activity_id"] = capturedActivityId
                    payload["instance_token"] = token
                    BlueshiftLiveActivityAPIManager.registerInstanceToken(payload)
                }
            }()

            async let watchStates: Void = {
                for await state in activity.activityStateUpdates {
                    switch state {
                    case .dismissed:
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["activity_attributes_type"] = capturedActivityType
                        payload["bsft_activity_id"] = capturedActivityId
                        payload["activity_action"] = "dismiss"
                        BlueshiftLiveActivityAPIManager.sendAction(payload)
                        return
                    case .ended:
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["activity_attributes_type"] = capturedActivityType
                        payload["bsft_activity_id"] = capturedActivityId
                        payload["activity_action"] = "ended"
                        BlueshiftLiveActivityAPIManager.sendAction(payload)
                        return
                    case .active:
                        break
                    case .stale:
                        break
                    case .pending:
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
                    if await enablementTask.get(forKey: "global") != nil { return }

                    let task = Task.detached { @Sendable in
                        for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                            guard !Task.isCancelled else { break }

                            if !enabled {
                                // Case 1: User toggled LA off
                                // Use high-priority task to ensure the log/API call completes
                                // before iOS suspends the background thread.
                                // var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                                // payload["activity_action"] = "disabled"
                                // Task(priority: .high) {
                                //     BlueshiftLiveActivityAPIManager.sendAction(payload)
                                //     BlueshiftLog.logInfo("Blueshift Live Activity: disabled in device Settings.", withDetails: nil, methodName: nil)
                                // }
                            } else {
                                // Case 2 (Scenario A Fix!): User toggled LA back ON while app was running
                                BlueshiftLog.logInfo("Blueshift Live Activity: Enabled/Re-enabled in device Settings. Re-triggering PTS token loops.", withDetails: nil, methodName: nil)

                                // Ask our safe actor for all saved registrations and run them
                                Task {
                                    let blocks = await BlueshiftLiveActivityManager.shared.registeredTypes.getAllValues()
                                    for executeRegistrationBlock in blocks {
                                        executeRegistrationBlock()
                                    }
                                }
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
        if let email = BlueShiftUserInfo.sharedInstance()?.email {
            payload["email"] = email
        }
        if let deviceId = BlueShiftDeviceData.current()?.deviceUUID {
            payload["device_id"] = deviceId
        }
        if let customerId = BlueShiftUserInfo.sharedInstance()?.retailerCustomerID {
            payload["customer_id"] = customerId
        }
        return payload
    }

}

// MARK: - Registered Association Tracking

/// What we last actually told the server for one activity type's push-to-start token.
private struct RegisteredAssociation {
    let token: String
    let deviceId: String?
    let customerId: String?
    let email: String?
}

/// Synchronous, lock-protected cache of the last registered association per activity type.
private final class AssociationCache: @unchecked Sendable {
    private var storage: [String: RegisteredAssociation] = [:]
    private let lock = NSLock()

    func set(_ value: RegisteredAssociation, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }

    func get(forKey key: String) -> RegisteredAssociation? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func allEntries() -> [(activityType: String, association: RegisteredAssociation)] {
        lock.lock(); defer { lock.unlock() }
        return storage.map { ($0.key, $0.value) }
    }

    /// Keeps each cached token/deviceId, but blanks the customer/email half - so the very next
    /// identify (even for the same customer signing back in) is treated as a change instead of
    /// matching a customer the server no longer has this token registered under.
    func clearIdentity() {
        lock.lock(); defer { lock.unlock() }
        for (key, existing) in storage {
            storage[key] = RegisteredAssociation(token: existing.token, deviceId: existing.deviceId, customerId: nil, email: nil)
        }
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

    func getAllValues() -> [Element] {
        return Array(storage.values)
    }
}
