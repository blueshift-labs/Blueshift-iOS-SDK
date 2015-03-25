//
//  BlueShiftPushDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 19/02/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushDelegate <NSObject>

@optional
- (void) buyPushActionWithDetails:(NSDictionary *)details;
- (void) viewPushActionWithDetails:(NSDictionary *)details;
- (void) openCartPushActionWithDetails:(NSDictionary *)details;
- (void) handlePushActionForIdentifier:(NSString *)identifier withDetails:(NSDictionary *)details;

@end 