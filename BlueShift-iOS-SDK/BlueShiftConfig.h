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

@class BlueShiftInAppNotificationDelegate;

@interface BlueShiftConfig : NSObject

@property NSString * _Nonnull apiKey;
@property NSDictionary * _Nonnull applicationLaunchOptions;

@property NSURL * _Nullable productPageURL;
@property NSURL * _Nullable cartPageURL;
@property NSURL * _Nullable offerPageURL;

/// Set this property to false in order to delay the push permission dialog.
/// @discussion When enablePushNotification is set to true during the SDK initialisation, the SDK will register for push notifications immediately after SDK initialisation and it will show user push notification permission dialogue.
/// @discussion If you want to delay showing push permission dialog, set this property to false and register for push notification explicitly from your app using SDK as below.
/// @code
/// BlueShift.sharedInstance()?.appDelegate?.registerForNotification()
/// @endcode
/// @note By default this property is set to true.
@property BOOL enablePushNotification;

@property BOOL enableLocationAccess;
@property BOOL enableAnalytics;
@property BOOL enableAppOpenTrackEvent;
@property BOOL enableInAppNotification;
@property BOOL inAppManualTriggerEnabled;
@property BOOL inAppBackgroundFetchEnabled;
@property BOOL debug;

@property NSSet * _Nullable customCategories;

@property NSString * _Nullable appGroupID;

/// Set this propery to true if the app has SceneDelegate configuration enabled.
/// @note Default value is set to false.
@property BOOL isSceneDelegateConfiguration API_AVAILABLE(ios(13.0));

/// Set this property to false to stop the SDK from collectiong IDFA.
/// @discussion With enableIDFACollection set as true, SDK will not ask user the device IDFA permission, but if the host app has asked for IDFA permission, and user has accepted it, then SDK collects it and sends to server.
/// @note Default value is set to true.
@property BOOL enableIDFACollection;

/// Custom device id provision for DeviceIDSourceCUSTOM
@property NSString * _Nullable customDeviceId;

/// Set this value in seconds in order to throttle the automatic app_open events getting fired from the SDK.
/// @discussion Setting this value will make sure that only one app_open event will get fired during given time interval.
/// @note Default value is set to zero, and it will fire an app_open every time when app is lauched form killed state.
@property double automaticAppOpenTimeInterval;

@property NSObject<UNUserNotificationCenterDelegate> * _Nonnull userNotificationDelegate API_AVAILABLE(ios(10.0));
@property id<BlueShiftPushDelegate> _Nullable blueShiftPushDelegate;
@property id<BlueShiftInAppNotificationDelegate> _Nonnull inAppNotificationDelegate;
@property id<BlueshiftUniversalLinksDelegate> _Nonnull blueshiftUniversalLinksDelegate;

@property(nonatomic) double BlueshiftInAppNotificationTimeInterval;
@property (nonatomic, assign) BlueshiftDeviceIdSource blueshiftDeviceIdSource;

- (BOOL)validateConfigDetails;
- (NSString*_Nullable)getConfigStringToLog;

+ (BlueShiftConfig * _Nonnull )config;
@end
