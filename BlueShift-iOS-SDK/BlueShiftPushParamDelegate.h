//
//  BlueShiftPushParamDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushParamDelegate <NSObject>

@optional
- (void)handlePushDictionary:(NSDictionary *)pushDictionary DEPRECATED_MSG_ATTRIBUTE("Use BlueShiftPushDelegate to get the push notification callbacks.");;
- (void)fetchProductID:(NSString *)productID DEPRECATED_MSG_ATTRIBUTE("Use BlueShiftPushDelegate to get the push notification callbacks.");;
- (void)handleCarouselPushDictionary:(NSDictionary *)pushDictionary withSelectedIndex:(NSInteger)index DEPRECATED_MSG_ATTRIBUTE("Use BlueShiftPushDelegate to get the push notification callbacks.");;

@end
