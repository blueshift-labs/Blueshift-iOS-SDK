//
//  BlueShiftPushDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BlueShiftPushDelegate <NSObject>

@optional
/// This is a SDK hook/callback for the click event of carousel push notification
/// @param categoryName carousel push notification category name, carousel or carousel_animation.
/// @param index selected image index
/// @param details push notification payload
/// @note The index can be used to get the deep link and image from the carousel_elements object of push payload.
- (void)handleCarouselPushForCategory:(NSString *)categoryName clickedWithIndex:(NSInteger)index withDetails:(NSDictionary *)details;


/// This is a SDK hook/callback for the click event of custom action button for push notification .
/// @param payload push notification payload
/// @param identifier custom action button identifier.
/// @note The additional details related to clicked action can be found in the payload's `actions` array using the action identifier.
- (void)pushNotificationDidClick:(NSDictionary * _Nullable)payload forActionIdentifier:(NSString * _Nullable)identifier;

/// This is a SDK hook/callback for the push notification click event.
/// @param payload push notification payload
/// @discussion When SDK processes a push notification click/action, it invokes this callback method and shares the push notification payload.
- (void)pushNotificationDidClick:(NSDictionary * _Nullable)payload;
@end 

NS_ASSUME_NONNULL_END
