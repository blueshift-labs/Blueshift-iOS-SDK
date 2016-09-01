//
//  NSNumber+BlueShiftHelpers.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "NSNumber+BlueShiftHelpers.h"

@implementation NSNumber (BlueShiftHelpers)



// Method to return NSNumber instance from BlueShiftHTTPMethod ...

+ (NSNumber *)numberWithBlueShiftHTTPMethod:(BlueShiftHTTPMethod)blueShiftHTTPMethod {
    return [NSNumber numberWithInt:blueShiftHTTPMethod];
}



// Method to return blueShiftHTTPMethodValue for the NSNumber ....

- (BlueShiftHTTPMethod)blueShiftHTTPMethodValue {
    return [self intValue];
}

@end
