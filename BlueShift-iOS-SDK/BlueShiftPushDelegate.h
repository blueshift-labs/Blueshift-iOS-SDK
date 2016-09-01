//
//  BlueShiftPushDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushDelegate <NSObject>

@optional
- (void) buyPushActionWithDetails:(NSDictionary *)details;
- (void) viewPushActionWithDetails:(NSDictionary *)details;
- (void) openCartPushActionWithDetails:(NSDictionary *)details;
- (void) handlePushActionForIdentifier:(NSString *)identifier withDetails:(NSDictionary *)details;

@end 