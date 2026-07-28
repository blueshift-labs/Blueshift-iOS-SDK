//
//  BlueShiftAppData.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 27/12/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftAppData : NSObject

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *sdkVersion;
@property (nonatomic, strong) NSString *appBuildNumber;
@property (nonatomic, strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSNumber *currentUNAuthorizationStatus;

/// Set this flag to false to disable push notifications explicitly. You will need to fire the identify call after changing the value of flag.
/// To enable push notification later, you will need to set it to true and fire identify call.
/// The default value for the enablePush is set to true
@property (nonatomic) BOOL enablePush;

/// Set this flag to false to disable in-app notifications explicitly. You will need to fire the identify call after changing the value of flag.
/// To enable in-app notifications later, you will need to set it to true and fire identify call.
/// The default value for the enableInApp is set to true
@property (nonatomic) BOOL enableInApp;

/// Returns BOOL by taking Logical AND of `enableInApp` and `config.enableInAppNotification` to check the current status of inApp notifications.
/// This value will be sent to Blueshift server under key `enable_inapp` as part of every event and also it will be checked before displaying in-app notifications.
- (BOOL)getCurrentInAppNotificationStatus;

/// Returns BOOL indicating whether Live Activity is currently enabled — checks both `config.enableLiveActivity`
/// and the device-level Live Activity authorization status. This value will be sent to Blueshift server under
/// key `enable_live_activity` as part of every event and status API call.
/// The actual authorization check is delegated to BlueshiftLiveActivityManager (LiveActivity subspec) via
/// ObjC runtime to avoid a compile-time dependency on ActivityKit in the Core SDK.
- (BOOL)getCurrentLiveActivityStatus API_AVAILABLE(ios(16.1));

+ (instancetype) currentAppData;

- (NSDictionary *)toDictionary;

@end
