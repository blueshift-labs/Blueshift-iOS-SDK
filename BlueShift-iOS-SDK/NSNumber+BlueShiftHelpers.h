//
//  NSNumber+BlueShiftHelpers.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftHTTPMethod.h"

@interface NSNumber (BlueShiftHelpers)

/// Return NSNumber instance from BlueShiftHTTPMethod
+ (NSNumber *)numberWithBlueShiftHTTPMethod:(BlueShiftHTTPMethod)blueShiftHTTPMethod;

/// Return blueShiftHTTPMethodValue for the NSNumber
- (BlueShiftHTTPMethod)blueShiftHTTPMethodValue;

@end
