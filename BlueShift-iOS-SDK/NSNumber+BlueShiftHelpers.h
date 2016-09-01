//
//  NSNumber+BlueShiftHelpers.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftHTTPMethod.h"

@interface NSNumber (BlueShiftHelpers)



// Method to return NSNumber instance from BlueShiftHTTPMethod ...

+ (NSNumber *)numberWithBlueShiftHTTPMethod:(BlueShiftHTTPMethod)blueShiftHTTPMethod;



// Method to return blueShiftHTTPMethodValue for the NSNumber ....

- (BlueShiftHTTPMethod)blueShiftHTTPMethodValue;

@end
