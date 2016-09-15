//
//  NSDate+BlueShiftDateHelpers.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
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
