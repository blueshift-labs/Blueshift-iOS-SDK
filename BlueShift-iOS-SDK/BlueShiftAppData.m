//
//  BlueShiftAppData.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 27/12/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import "BlueShiftAppData.h"
#import "BlueShift.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"
#import "InAppNotificationEntity.h"

static BlueShiftAppData *_currentAppData = nil;

@implementation BlueShiftAppData

+ (instancetype) currentAppData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentAppData = [[self alloc] init];
    });
    return _currentAppData;
}

- (NSString *)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];;
}

- (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleShortVersionString];
}

- (NSString *)appBuildNumber {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

- (NSString *)bundleIdentifier {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
}

- (BOOL)enablePush {
    NSString *val = [[NSUserDefaults standardUserDefaults] objectForKey:kBlueshiftEnablePush];
    BOOL enablePush = YES;
    if (val) {
        enablePush = [val isEqual:kYES] ? YES : NO;
    }
    return enablePush;
}

- (void)setEnablePush:(BOOL)enablePush {
    // Added try catch to avoid issues with App UI automation script execution
    @try {
        NSString *val = enablePush ? kYES : kNO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:val forKey:kBlueshiftEnablePush];
        [defaults synchronize];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (BOOL)getCurrentPushNotificationStatus {
    if (@available(iOS 10.0, *)) {
        if (self.enablePush && self.currentUNAuthorizationStatus) {
            return YES;
        } else {
            return NO;
        }
    } else {
        //send enablePush value to server for iOS 9 and below versions
        return self.enablePush;
    }
}

- (BOOL)enableInApp {
    NSString *val = [[NSUserDefaults standardUserDefaults] objectForKey:kBlueshiftEnableInApp];
    BOOL enableInApp = YES;
    if (val) {
        enableInApp = [val isEqual:kYES] ? YES : NO;
    }
    return enableInApp;
}

- (void)setEnableInApp:(BOOL)enableInApp {
    @try {
        NSString *val = enableInApp ? kYES : kNO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:val forKey:kBlueshiftEnableInApp];
        [defaults synchronize];
        if (enableInApp == NO) {
            [InAppNotificationEntity eraseEntityData];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (BOOL)getCurrentInAppNotificationStatus {
    if (self.enableInApp && [BlueShift sharedInstance].config.enableInAppNotification) {
        return  YES;
    }
    return NO;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *appMutableDictionary = [NSMutableDictionary dictionary];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kAppName value:self.bundleIdentifier];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kAppVersion value:self.appVersion];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kBuildNumber value:self.appBuildNumber];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kBundleIdentifier value:self.bundleIdentifier];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kEnablePush value:[NSNumber numberWithBool: [self getCurrentPushNotificationStatus]]];
    [BlueshiftEventAnalyticsHelper addToDictionary:appMutableDictionary key:kEnableInApp value:[NSNumber numberWithBool: [self getCurrentInAppNotificationStatus]]];
    return [appMutableDictionary copy];
}

@end
