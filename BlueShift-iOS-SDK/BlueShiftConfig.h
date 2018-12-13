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

@property NSSet * _Nullable customCategories;

@property NSString * _Nullable appGroupID;

@property NSObject<UNUserNotificationCenterDelegate> * _Nonnull userNotificationDelegate;

@property NSString * _Nonnull blueShiftNotificationName;
@property NSString * _Nonnull isEnabledPushNotificationKey;

- (BOOL)validateConfigDetails;

+ (BlueShiftConfig * _Nonnull )config;
@end
