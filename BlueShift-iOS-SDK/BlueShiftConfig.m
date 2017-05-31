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
        self.enablePushNotification = YES;
        self.enableLocationAccess = YES;
        self.enableAnalytics = YES;
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
