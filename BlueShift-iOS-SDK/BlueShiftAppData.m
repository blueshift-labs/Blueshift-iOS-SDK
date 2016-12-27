//
//  BlueShiftAppData.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 27/12/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import "BlueShiftAppData.h"

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
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
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
        [appMutableDictionary setObject:self.appName forKey:@"app_name"];
    }
    
    if (self.appVersion) {
        [appMutableDictionary setObject:self.appVersion forKey:@"app_version"];
    }
    
    if (self.appBuildNumber) {
        [appMutableDictionary setObject:self.appBuildNumber forKey:@"build_number"];
    }
    
    if (self.bundleIdentifier) {
        [appMutableDictionary setObject:self.bundleIdentifier forKey:@"bundle_identifier"];
    }
    
    return [appMutableDictionary copy];
}



@end
