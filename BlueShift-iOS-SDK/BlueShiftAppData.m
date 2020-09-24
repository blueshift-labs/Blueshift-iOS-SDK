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

#define kEnablePush                             @"enable_push"
#define kEnableInApp                            @"enable_inapp"
#define kBundleIdentifier                       @"bundle_identifier"
#define kBuildNumber                            @"build_number"
#define kAppVersion                             @"app_version"
#define kAppName                                @"app_name"
#define kCFBundleShortVersionString             @"CFBundleShortVersionString"

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

- (NSDictionary *)toDictionary {
    NSMutableDictionary *appMutableDictionary = [NSMutableDictionary dictionary];
    if (self.appName) {
        [appMutableDictionary setObject:self.bundleIdentifier forKey:kAppName];
    }
    
    if (self.appVersion) {
        [appMutableDictionary setObject:self.appVersion forKey:kAppVersion];
    }
    
    if (self.appBuildNumber) {
        [appMutableDictionary setObject:self.appBuildNumber forKey:kBuildNumber];
    }
    
    if (self.bundleIdentifier) {
        [appMutableDictionary setObject:self.bundleIdentifier forKey:kBundleIdentifier];
    }
    
    if (@available(iOS 10.0, *)) {
        NSNumber *isPushEnabled = [NSNumber numberWithBool: self.isPushPermissionAccepted];
        [appMutableDictionary setObject: isPushEnabled  forKey:kEnablePush];
    }
    
    NSNumber *enableInApp = [NSNumber numberWithBool: [[[BlueShift sharedInstance] config] enableInAppNotification]];
    [appMutableDictionary setObject: enableInApp  forKey:kEnableInApp];

    return [appMutableDictionary copy];
}

@end
