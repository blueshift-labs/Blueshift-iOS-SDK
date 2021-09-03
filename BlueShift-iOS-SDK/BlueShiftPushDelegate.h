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
- (void)buyPushActionWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("Buy category is deprecated and will be removed in future. Use custom actionable push notifications instead.");
- (void)viewPushActionWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("View category is deprecated and will be removed in future. Use custom actionable push notifications instead.");
- (void)openCartPushActionWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("Open cart category is deprecated and will be removed in future. Use custom actionable push notifications instead.");
- (void)handlePushActionForIdentifier:(NSString *)identifier withDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in future. Use `pushNotificationDidClick:(NSDictionary *)payload forActionIdentifier:(NSString *)identifier` method instead.");

- (void)buyCategoryPushClickedWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("Buy category is deprecated and will be removed in future. Use custom actionable push notifications instead.");
- (void)cartViewCategoryPushClickedWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("Cart view category is deprecated and will be removed in future. Use custom actionable push notifications instead.");
- (void)promotionCategoryPushClickedWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("Promotion category is deprecated and will be removed in future. Use `pushNotificationDidClick:(NSDictionary *)payload` method instead.");
- (void)handleCustomCategory:(NSString *)categroyName clickedWithDetails:(NSDictionary *)details DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in future. Use `pushNotificationDidClick:(NSDictionary *)payload` method instead.");

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
