//
//  BlueShiftConfig.h
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftDeepLink.h"
#import "BlueShiftUserInfo.h"

@interface BlueShiftConfig : NSObject

@property NSString *apiKey;
@property NSDictionary *applicationLaunchOptions;

@property NSURL *productPageURL;
@property NSURL *cartPageURL;
@property NSURL *offerPageURL;

@property BOOL disablePushNotification;
@property BOOL disableLocationAccess;
@property BOOL disableAnalytics;

@property NSString *appGroupID;

- (BOOL)validateConfigDetails;

+ (BlueShiftConfig *)config;
@end
