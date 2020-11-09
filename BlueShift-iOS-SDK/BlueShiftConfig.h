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
@property BOOL isSceneDelegateConfiguration;

//Custom device id provision for DeviceIDSourceCUSTOM
@property NSString * _Nullable customDeviceId;

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
