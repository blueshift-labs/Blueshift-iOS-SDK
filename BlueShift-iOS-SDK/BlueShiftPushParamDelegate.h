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
- (void)fetchProductID:(NSString *)productID;
- (void)handleCarouselPushDictionary:(NSDictionary *)pushDictionary withSelectedIndex:(NSInteger)index;

@end
