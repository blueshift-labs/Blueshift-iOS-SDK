//
//  BlueShiftPushParamDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushParamDelegate <NSObject>

@optional
- (void)handlePushDictionary:(NSDictionary *)pushDictionary;

@end
