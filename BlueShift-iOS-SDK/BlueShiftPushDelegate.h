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

- (void) buyCategoryPushClickedWithDetails:(NSDictionary *)details;
- (void) cartViewCategoryPushClickedWithDetails:(NSDictionary *)details;
- (void) promotionCategoryPushClickedWithDetails:(NSDictionary *)details;
- (void) handleCustomCategory:(NSString *)categroyName clickedWithDetails:(NSDictionary *)details;
- (void) handleCarouselPushForCategory:(NSString *)categoryName clickedWithIndex:(NSInteger)index withDetails:(NSDictionary *)details;


/// This is a SDK hook/callback for the push notification click event.
/// @param payload push notification payload
/// @discussion When SDK processes a push notification click/action, it invokes this callback method and shares the push notification payload.
- (void) pushNotificationDidClick:(NSDictionary *)payload;
@end 
