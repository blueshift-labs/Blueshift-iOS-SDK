//
//  BlueShift.h
//  BlueShift
//
//  Copyright (c) Blueshift. All rights reserved.
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
#import "BlueShiftHttpRequestBatchUpload.h"
#import "BlueShiftBatchUploadConfig.h"
#import "BlueShiftAppData.h"
#import "SDKVersion.h"
#import "BlueShiftLiveContent.h"
#import "BlueShiftPushNotificationSettings.h"

@class BlueShiftDeviceData;
@class BlueShiftAppDelegate;
@interface BlueShift : NSObject

@property (nonatomic, strong) BlueShiftConfig *config;
@property BlueShiftDeviceData *deviceData;
@property BlueShiftAppData *appData;
@property (nonatomic, strong) BlueShiftUserInfo *userInfo;
@property (nonatomic, strong) BlueShiftPushNotificationSettings *pushNotification;
@property NSString *deviceToken;

+ (instancetype)sharedInstance;
+ (void) initWithConfiguration:(BlueShiftConfig *)config;
+ (void) autoIntegration;
- (void) setPushDelegate: (id) obj;
- (void) setPushParamDelegate: (id) obj;
- (NSString *) getDeviceToken;
- (void) setDeviceToken;
@property BlueShiftAppDelegate *appDelegate;


// track events functions ...
- (void)identifyUserWithDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent;

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID withParameter:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionPauseWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionPauseWithParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionUnpauseWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionUnpauseWithParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionCancelWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionCancelWithParamters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEventForEventName:(NSString *)eventName canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPushClickedWithParameters:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent;

@end
