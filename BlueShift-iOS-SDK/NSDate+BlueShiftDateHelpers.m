//
//  NSDate+BlueShiftDateHelpers.m
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 11/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "NSDate+BlueShiftDateHelpers.h"

@implementation NSDate (BlueShiftDateHelpers)

- (instancetype)dateByAddingMinutes:(NSInteger)minutes
{
    NSTimeInterval seconds = minutes * 60;
    NSDate *currentDate = [NSDate date];
    return [currentDate dateByAddingTimeInterval:seconds];
}

@end
