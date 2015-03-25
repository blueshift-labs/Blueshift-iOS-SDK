//
//  BlueShiftConfig.m
//  BlueShiftiOSSDK
//
//  Created by Arjun K P on 19/02/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "BlueShiftConfig.h"

@implementation BlueShiftConfig

- (id)init {
    self = [super init];
    if (self) {
        
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
