//
//  BlueShiftPushDelegate.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueShiftPushDelegate <NSObject>

@optional
- (void) handlePushActionForIdentifier:(NSString *_Nullable)identifier withDetails:(NSDictionary * _Nullable)details;

- (void) promotionCategoryPushClickedWithDetails:(NSDictionary * _Nullable)details;

- (void) handleCustomCategory:(NSString * _Nullable)categroyName clickedWithDetails:(NSDictionary * _Nullable)details;

- (void) handleCarouselPushForCategory:(NSString * _Nullable)categoryName clickedWithIndex:(NSInteger)index withDetails:(NSDictionary * _Nullable)details;

/// This is a SDK hook/callback for the push notification click event.
/// @param payload push notification payload
/// @discussion When SDK processes a push notification click/action, it invokes this callback method and shares the push notification payload.
- (void) pushNotificationDidClick:(NSDictionary * _Nullable)payload;
@end 
