//
//  NSNumber+BlueShiftHelpers.m
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
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
