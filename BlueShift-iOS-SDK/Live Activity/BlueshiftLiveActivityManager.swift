//
//  BlueshiftLiveActivityManager.swift
//  BlueShift-iOS-SDK
//
//  Created by Vedant Patle on 29/05/26.
//

import Foundation

#if canImport(BlueShift_iOS_SDK)
import BlueShift_iOS_SDK
#endif

#if os(iOS)
import ActivityKit

/// Manages Blueshift Live Activity token registration and lifecycle actions.
///
/// Supports remote push-to-start only. The client registers each activity type once
/// on app launch — the SDK handles all token observation and action reporting automatically.
///
/// The SDK will:
/// - Observe `pushToStartTokenUpdates` and report each new PTS token to Blueshift
/// - Scan already-running activities of this type and observe their instance tokens
/// - Automatically report dismiss/end actions when activities end
/// - Automatically report the disabled action if the user turns off Live Activities in Settings
///
/// ## Usage
/// ```swift
/// // In AppDelegate.application(_:didFinishLaunchingWithOptions:)
/// if #available(iOS 17.2, *) {
///     BlueshiftLiveActivityManager.shared.registerPushToStart(
///         forType: Activity<SportsActivityAttributes>.self,
///         name: "SportsActivityAttributes"
///     )
/// }
/// ```
@available(iOS 16.2, *)
@objc public class BlueshiftLiveActivityManager: NSObject, @unchecked Sendable {

    @objc public static let shared = BlueshiftLiveActivityManager()

    // MARK: - Private State

    /// PTS token observation tasks, keyed by activity type name.
    /// Prevents duplicate observers if registerPushToStart is called twice for the same type.
    private var pushToStartTasks: [String: Task<Void, Never>] = [:]

    /// Instance token + state observation tasks, keyed by ActivityKit activity.id.
    private var activityTasks: [String: [Task<Void, Never>]] = [:]

    /// Single shared enablement observer task — started once, monitors Settings changes.
    private var enablementTask: Task<Void, Never>?

    private override init() { super.init() }

    // MARK: - Public API

    /// Registers a Push-to-Start token observer for the given Live Activity type.
    ///
    /// Call once per activity type on every app launch. The SDK will automatically:
    /// - Observe `pushToStartTokenUpdates` and report each new PTS token to Blueshift
    /// - Scan already-running activities of this type and observe their instance tokens
    /// - Report dismiss/end actions when activities end
    /// - Report the disabled action if the user turns off Live Activities in Settings
    ///
    /// - Parameters:
    ///   - type: The `Activity<T>.Type` to observe (e.g. `Activity<DemoActivityAttributes>.self`)
    ///   - name: The string name of the `ActivityAttributes` type, sent as `activity_attributes_type`
    ///           to Blueshift (e.g. `"DemoActivityAttributes"`)
    
    @available(iOS 17.2, *)
    public func registerPushToStart<T: ActivityAttributes>(
        forType type: Activity<T>.Type,
        name: String
    ) {
        // Guard: SDK must have enableLiveActivity set to true in config
        guard BlueShift.sharedInstance()?.config?.enableLiveActivity == true else {
            BlueshiftLog.logInfo(
                "Blueshift Live Activity: disabled in config. Skipping registerPushToStart for '\(name)'.",
                withDetails: nil,
                methodName: nil
            )
            return
        }

        // Guard: Live Activities must be enabled in device Settings
        // If disabled, send the disabled action immediately and stop
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            BlueshiftLog.logInfo(
                "Blueshift Live Activity: disabled in device Settings. Sending disabled action.",
                withDetails: nil,
                methodName: nil
            )
            Self.logPayload(buildActionPayload("disabled"), url: BlueshiftRoutes.getLiveActivityActionURL())
            return
        }

        // Start the shared enablement observer (started once only across all types)
        startEnablementObserver()

        // Cancel any existing PTS observer for this type and start a fresh one
        pushToStartTasks[name]?.cancel()
        let activityTypeName = name
        pushToStartTasks[name] = Task.detached {
            BlueshiftLog.logInfo(
                "Blueshift Live Activity: Observing Push-to-Start token stream for '\(activityTypeName)'.",
                withDetails: nil,
                methodName: nil
            )
            for await tokenData in Activity<T>.pushToStartTokenUpdates {
                guard !Task.isCancelled else { break }
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                payload["activity_attributes_type"] = activityTypeName
                payload["push_to_start_token"] = token
                BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityPushToStartURL())
            }
        }

        // Re-attach to any already-running activities of this type
        // (e.g. activity was started by server push before this app launch)
        let running = Activity<T>.activities
        if !running.isEmpty {
            BlueshiftLog.logInfo(
                "Blueshift Live Activity: Found \(running.count) running activity(ies) for '\(name)'. Re-attaching.",
                withDetails: nil,
                methodName: nil
            )
            for activity in running {
                observeRunningActivity(activity, activityType: name)
            }
        }
    }

    // MARK: - Private: Observe Running Activity

    /// Observes push token updates and state changes for a running activity instance.
    /// Called automatically when re-attaching to already-running activities on app launch.
    @available(iOS 17.2, *)
        private func observeRunningActivity<T: ActivityAttributes>(
            _ activity: Activity<T>,
            activityType: String
        ) {
            let activityId = activity.id

            // Cancel any existing tasks for this activity id before re-attaching
            activityTasks[activityId]?.forEach { $0.cancel() }
            activityTasks[activityId] = []

            // Immediately read the current push token if already available (synchronous)
            if let tokenData = activity.pushToken {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                var payload = Self.buildBasePayloadStatic()
                payload["activity_attributes_type"] = activityType
                payload["activity_id"] = activityId
                payload["instance_token"] = token
                Self.logPayload(payload, url: BlueshiftRoutes.getLiveActivityInstanceTokenURL())
            }

            let capturedActivityType = activityType
            let capturedActivityId = activityId

            // FIX: Use standard Task instead of Task.detached to preserve context safety boundaries
            // Observe push token updates stream — fires when token rotates
            let tokenTask = Task { [capturedActivityType, capturedActivityId] in
                for await tokenData in activity.pushTokenUpdates {
                    guard !Task.isCancelled else { break }
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                    payload["activity_attributes_type"] = capturedActivityType
                    payload["activity_id"] = capturedActivityId
                    payload["instance_token"] = token
                    BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityInstanceTokenURL())
                }
            }

            // FIX: Use standard Task instead of Task.detached to eliminate crossing-context data races
            // Observe activity state updates — auto-send dismiss action on end/dismissed
            let stateTask = Task { [capturedActivityType, capturedActivityId] in
                for await state in activity.activityStateUpdates {
                    guard !Task.isCancelled else { break }
                    switch state {
                    case .dismissed, .ended:
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["activity_attributes_type"] = capturedActivityType
                        payload["activity_id"] = capturedActivityId
                        payload["action"] = "dismiss"
                        BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityActionURL())
                    case .active, .stale:
                        break
                    @unknown default:
                        break
                    }
                }
            }

            activityTasks[activityId] = [tokenTask, stateTask]
        }
    
    // MARK: - Private: Enablement Observer

    /// Starts a single shared observer for Live Activity enablement changes in iOS Settings.
    /// When the user disables Live Activities, the SDK automatically sends the disabled action.
    /// This observer is started once and shared across all registered activity types.
    private func startEnablementObserver() {
        guard enablementTask == nil else { return }
        
        if #available(iOS 16.2, *) {
            // Task.detached disconnects from the parent Actor environment context entirely
            enablementTask = Task.detached {
                // FIX: Lowercase 'a' on activityEnablementUpdates
                let authInfo = ActivityAuthorizationInfo()
                for await enabled in authInfo.activityEnablementUpdates {
                    guard !Task.isCancelled else { break }
                    
                    if !enabled {
                        // User disabled Live Activities in Settings
                        // Send disabled action — server clears ALL types for this device
                        var payload = BlueshiftLiveActivityManager.buildBasePayloadStatic()
                        payload["action"] = "disabled"
                        
                        // Route to static log/post handler
                        BlueshiftLiveActivityManager.logPayload(payload, url: BlueshiftRoutes.getLiveActivityActionURL())
                        
                        BlueshiftLog.logInfo(
                            "Blueshift Live Activity: disabled in device Settings. Sent disabled action.",
                            withDetails: nil,
                            methodName: nil
                        )
                    } else {
                        // User re-enabled Live Activities in Settings
                        // Log a message — client should call registerPushToStart again to resume
                        BlueshiftLog.logInfo(
                            "Blueshift Live Activity: re-enabled in device Settings. Call registerPushToStart to resume token registration.",
                            withDetails: nil,
                            methodName: nil
                        )
                    }
                }
            }
        }
    }
    // MARK: - Private: Payload Helpers

    /// Static builder — avoids capturing `self` inside `Task.detached` closures.
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

    /// Builds the base payload dictionary with common fields shared across all Live Activity API calls.
    private func buildBasePayload() -> [String: String] {
        Self.buildBasePayloadStatic()
    }

    /// Builds a base payload with an action field added.
    private func buildActionPayload(_ action: String) -> [String: String] {
        var payload = buildBasePayload()
        payload["action"] = action
        return payload
    }

    /// Logs the payload that would be POSTed to the given URL.
    /// Static so it can be called from `Task.detached` closures without capturing `self`.
    /// Replace the log call with a real API call once the endpoints are live.
    private static func logPayload(_ payload: [String: String], url: String) {
        BlueshiftLog.logAPICallInfo(
            "Blueshift Live Activity — Would POST to: \(url)",
            withDetails: payload as [AnyHashable: Any],
            statusCode: 0
        )
    }
}

#endif // os(iOS)

