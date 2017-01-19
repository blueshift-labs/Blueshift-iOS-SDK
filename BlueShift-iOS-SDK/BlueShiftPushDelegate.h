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

@end 
