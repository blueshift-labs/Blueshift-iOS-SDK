//
//  BlueShift.h
//  BlueShift
//
//  Created by Asif on 2/16/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueShiftConfig.h"
#import "BlueShiftDeviceData.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftPushDelegate.h"
#import "BlueShiftDeepLink.h"
#import "BlueShiftPushParamDelegate.h"
#import "BlueShiftNetworkReachabilityManager.h"
#import "BlueShiftSubscriptionState.h"
#import "BlueShiftRequestOperation.h"
#import "BlueShiftRequestQueue.h"
#import "BlueShiftRoutes.h"
#import "BlueShiftUserInfo.h"
#import "BlueShiftTrackEvents.h"
#import "BlueShiftProduct.h"
#import "BlueShiftSubscription.h"

@class BlueShiftDeviceData;
//@protocol BlueShiftPushDelegate;

@interface BlueShift : NSObject

@property (nonatomic, strong) BlueShiftConfig *config;
@property BlueShiftDeviceData *deviceData;
@property (nonatomic, strong) BlueShiftUserInfo *userInfo;
@property NSString *deviceToken;

+ (instancetype)sharedInstance;
+ (void) initWithConfiguration:(BlueShiftConfig *)config;
- (void) setPushDelegate: (id) obj;
- (void) setPushParamDelegate: (id) obj;
- (NSString *) getDeviceToken;


// track events functions ...
- (void)identifyUserWithDetails:(NSDictionary *)details;

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary *)details;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary *)parameters;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID withParameter:(NSDictionary *)parameters;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity andParameters:(NSDictionary *)parameters;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID andParameters:(NSDictionary *)parameters;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products andParameters:(NSDictionary *)parameters;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andParameters:(NSDictionary *)parameters;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters andParameters:(NSDictionary *)parameters;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate andParameters:(NSDictionary *)parameters;

- (void)trackSubscriptionPause;

- (void)trackSubscriptionPauseWithParameters:(NSDictionary *)parameters;

- (void)trackSubscriptionUnpause;

- (void)trackSubscriptionUnpauseWithParameters:(NSDictionary *)parameters;

- (void)trackSubscriptionCancel;

- (void)trackSubscriptionCancelWithParamters:(NSDictionary *)parameters;

- (void)trackEventForEventName:(NSString *)eventName;

- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary *)parameters;

@end
