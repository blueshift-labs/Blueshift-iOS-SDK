//
//  BlueShiftConfig.h
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "BlueShiftDeepLink.h"
#import "BlueShiftUserInfo.h"
#import "BlueShiftPushDelegate.h"
#import "BlueShiftInAppNotificationDelegate.h"
#import "BlueshiftUniversalLinksDelegate.h"
#import "BlueshiftDeviceIdSource.h"

typedef NS_ENUM (NSUInteger,BlueshiftRegion) {
    BlueshiftRegionUS,
    BlueshiftRegionEU
} ;

@class BlueShiftInAppNotificationDelegate;

@interface BlueShiftConfig : NSObject

@property NSString * _Nonnull apiKey;
@property BlueshiftRegion region;
@property NSDictionary * _Nonnull applicationLaunchOptions;

@property NSURL * _Nullable productPageURL DEPRECATED_MSG_ATTRIBUTE("productPageURL deeplinking is deprecated and will be removed in future. Use push notification deep links instead.");
@property NSURL * _Nullable cartPageURL DEPRECATED_MSG_ATTRIBUTE("cartPageURL deeplinking is deprecated and will be removed in future. Use push notification deep links instead.");
@property NSURL * _Nullable offerPageURL DEPRECATED_MSG_ATTRIBUTE("offerPageURL deeplinking is deprecated and will be removed in future. Use push notification deep links instead.");

/// Set this property to false in order to stop SDK from registering for silent(background) push notifications.
/// @discussion SDK registers for silent push notifications in order to receive the in-app notifications when user has not asked for push permission
/// or has denied the push permission or turned off push notifications manually from the app setting.
/// @note By default this property is set to true.
@property BOOL enableSilentPushNotification;

/// Set this property to false in order to delay the push permission dialog.
/// @discussion When enablePushNotification is set to true during the SDK initialisation, the SDK will register for push notifications immediately after SDK initialisation and it will show user push notification permission dialogue.
/// @discussion If you want to delay showing push permission dialog, set this property to false and register for push notification explicitly from your app using SDK as below.
/// @code
/// BlueShift.sharedInstance()?.appDelegate?.registerForNotification()
/// @endcode
/// @note By default this property is set to true.
@property BOOL enablePushNotification;

@property BOOL enableLocationAccess;

/// From SDK v2.1.13, the automatic app_open tracking will be disabled by default. In order to track the app_open set this flag to true.
/// @discussion You can set the time interval for automatic app_open events using config.automaticAppOpenTimeInterval to throttle them. Default value for automaticAppOpenTimeInterval is once in 24 hours.
/// @note Default value for enableAppOpenTrackEvent is set to false.
@property BOOL enableAppOpenTrackEvent;

@property BOOL enableInAppNotification;
@property BOOL inAppManualTriggerEnabled;
@property BOOL inAppBackgroundFetchEnabled;
@property BOOL debug;

/// Set custom push notification categories. The SDK will merge the given categories with default SDK categories and register them to UNUserNotificationCenter while registering for push notifications
@property NSSet<UNNotificationCategory *> * _Nullable customCategories API_AVAILABLE(ios(10.0));

/// Set custom push notification authorization options. The SDK will override the default SDK authorization options with given options while registering for push notifications
@property UNAuthorizationOptions customAuthorizationOptions API_AVAILABLE(ios(10.0));

@property NSString * _Nullable appGroupID;

/// Set this propery to true if the app has SceneDelegate configuration enabled.
/// @note Default value is set to false.
@property BOOL isSceneDelegateConfiguration API_AVAILABLE(ios(13.0)) DEPRECATED_MSG_ATTRIBUTE("From SDK v2.2.5, SDK will not use this property, instead it will check for scene delegate configuration dynamically if needed.");

/// Set this property to false to stop the SDK from collectiong IDFA.
/// @discussion With enableIDFACollection set as true, SDK will not ask user the device IDFA permission, but if the host app has asked for IDFA permission, and user has accepted it, then SDK collects it and sends to server.
/// @note Default value is set to true.
@property BOOL enableIDFACollection;

/// Custom device id provision for DeviceIDSourceCUSTOM
@property NSString * _Nullable customDeviceId;

/// Set this value in seconds in order to throttle the automatic app_open events getting fired from the SDK.
/// @discussion Setting this value will make sure that only one app_open event will get fired during given time interval.
/// @note Default value is set to 24Hours(60*60*24 seconds), and it will fire an app_open event once in a day.
/// To fire it every time on app launch set the value to 0
@property double automaticAppOpenTimeInterval;

@property NSObject<UNUserNotificationCenterDelegate> * _Nullable userNotificationDelegate API_AVAILABLE(ios(10.0));
@property id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;
@property id<BlueShiftInAppNotificationDelegate> _Nullable inAppNotificationDelegate;
@property id<BlueshiftUniversalLinksDelegate> _Nullable blueshiftUniversalLinksDelegate;

@property(nonatomic) double BlueshiftInAppNotificationTimeInterval;
@property (nonatomic, assign) BlueshiftDeviceIdSource blueshiftDeviceIdSource;

- (BOOL)validateConfigDetails;
- (NSString* _Nullable)getConfigStringToLog;

+ (BlueShiftConfig * _Nonnull)config;
@end
