//
//  NSNumber+BlueShiftHelpers.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftHTTPMethod.h"

@interface NSNumber (BlueShiftHelpers)



// Method to return NSNumber instance from BlueShiftHTTPMethod ...

+ (NSNumber *)numberWithBlueShiftHTTPMethod:(BlueShiftHTTPMethod)blueShiftHTTPMethod;



// Method to return blueShiftHTTPMethodValue for the NSNumber ....

- (BlueShiftHTTPMethod)blueShiftHTTPMethodValue;

@end
