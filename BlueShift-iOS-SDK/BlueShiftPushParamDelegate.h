//
//  BlueShiftPushParamDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 04/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushParamDelegate <NSObject>

@optional
- (void)handlePushDictionary:(NSDictionary *)pushDictionary;

@end
