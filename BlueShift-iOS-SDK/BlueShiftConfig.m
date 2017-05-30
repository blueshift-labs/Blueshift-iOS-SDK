//
//  BlueShiftConfig.m
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftConfig.h"

@implementation BlueShiftConfig

- (id)init {
    self = [super init];
    if (self) {
        self.disablePushNotification = NO;
        self.disableLocationAccess = NO;
        self.disableAnalytics = NO;
    }
    return self;
}

+ (BlueShiftConfig *)config {
    return [[BlueShiftConfig alloc] init];
}

- (BOOL)validateConfigDetails {
    BOOL status = YES;
    
    if (self.apiKey == NULL || self.apiKey == nil) {
        status = NO;
        NSLog(@"\n\n Cannot initialize the SDK. Need to set the API Key. \n\n");
    }
    
    return status;
}

@end
