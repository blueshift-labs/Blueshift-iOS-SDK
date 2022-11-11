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
/// This is a SDK hook/callback for the click event of carousel push notification. This method will be called when user clicks on any of the carousel push notification images.
/// This delegate method will not be called for carousel push notification when user clicks on push notification tile before expanding it or clicks on the `go to app` button.
/// @param categoryName carousel push notification category name, carousel or carousel_animation.
/// @param index clicked image index
/// @param details push notification payload
/// @note The index can be used to get the deep link and image from the carousel_elements object of push payload.
- (void)handleCarouselPushForCategory:(NSString *)categoryName clickedWithIndex:(NSInteger)index withDetails:(NSDictionary *)details;


/// This is a SDK hook/callback for the click event of custom action button for push notification .
/// @param payload push notification payload
/// @param identifier custom action button identifier.
/// @note The additional details related to clicked action can be found in the payload's `actions` array using the action identifier.
- (void)pushNotificationDidClick:(NSDictionary * _Nullable)payload forActionIdentifier:(NSString * _Nullable)identifier;

/// This is a SDK hook/callback for the push notification click event.
/// This delegate method will be called for title + content, image, GIF, Video push notification click. This method will be called also for carousel push notification  or custom action type push notification click on the tile before expanding it and for the carousel `go to app` button click.
/// @param payload push notification payload
/// @discussion When SDK processes a push notification click/action, it invokes this callback method and shares the push notification payload.
- (void)pushNotificationDidClick:(NSDictionary * _Nullable)payload;
@end 

NS_ASSUME_NONNULL_END
