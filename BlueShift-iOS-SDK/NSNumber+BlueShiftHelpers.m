//
//  NSNumber+BlueShiftHelpers.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "NSNumber+BlueShiftHelpers.h"

@implementation NSNumber (BlueShiftHelpers)

+ (NSNumber *)numberWithBlueShiftHTTPMethod:(BlueShiftHTTPMethod)blueShiftHTTPMethod {
    return [NSNumber numberWithInt:blueShiftHTTPMethod];
}

- (BlueShiftHTTPMethod)blueShiftHTTPMethodValue {
    return [self intValue];
}

@end
