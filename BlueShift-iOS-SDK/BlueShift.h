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
#import "BlueShiftPushNotificationSettings.h"
#import "BlueShiftUserNotificationSettings.h"
#import "BlueShiftUserNotificationCenterDelegate.h"
#import "BlueshiftEventAnalyticsHelper.h"
#import "BlueshiftInAppNotificationRequest.h"
#import "BlueShiftLiveContent.h"

NS_ASSUME_NONNULL_BEGIN

@class BlueShiftDeviceData;
@class BlueShiftAppDelegate;
@class BlueShiftUserNotificationCenterDelegate;
@class BlueShiftUserInfo;
@class BlueShiftConfig;
@interface BlueShift : NSObject

@property (nonatomic, strong)  BlueShiftConfig * _Nullable config;
@property (nonatomic, strong)  BlueShiftPushNotificationSettings * _Nullable pushNotification API_AVAILABLE(ios(8.0));
@property (nonatomic, strong)  BlueShiftUserNotificationSettings * _Nullable userNotification API_AVAILABLE(ios(10.0));
@property BlueShiftAppDelegate * _Nullable appDelegate;
@property BlueShiftUserNotificationCenterDelegate * _Nullable userNotificationDelegate;

+ (instancetype _Nullable)sharedInstance;

/// Initialise the SDK using BlueShiftConfig
/// @param config BlueShiftConfig object
+ (void) initWithConfiguration:(BlueShiftConfig *)config;

+ (void) autoIntegration;
- (void) setPushDelegate: (id) obj;
- (void) setPushParamDelegate: (id) obj;
- (NSString * _Nullable) getDeviceToken;
- (void) setDeviceToken;
- (void) handleSilentPushNotification:(NSDictionary *)dictionary forApplicationState:(UIApplicationState)applicationState;

/// Register for in-app notifications in order to show the in-app notifications on the view controller or screen. To register, call this method in the `viewDidAppear` lifecycle method of VC.
/// @param displayPage Name of screen or view controller
/// @warning If you don't register a VC or screen to receive in-app notification, SDK will not show the in-app notifications on that VC or screen.
- (void)registerForInAppMessage:(NSString *)displayPage;

/// Unregister a VC or screen in the `viewDidDisappear` lifecycle method of VC. This is required to be done before registering a new screen for in-app notifications.
- (void)unregisterForInAppMessage;

// track events functions
- (void)identifyUserWithDetails:(NSDictionary * _Nullable)details canBatchThisEvent:(BOOL)isBatchEvent;

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary * _Nullable)details canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID withParameter:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary * _Nullable)filters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary * _Nullable)filters andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListSubscriptionForEmail:(NSString *)email andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionPauseWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionPauseWithParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionUnpauseWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionUnpauseWithParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionCancelWithBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackSubscriptionCancelWithParamters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEventForEventName:(NSString *)eventName canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPushClickedWithParameters:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationDeliveredWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationShowingWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationButtonTappedWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationDismissWithParameter:(NSDictionary *)notificationPayload
                                 canBacthThisEvent:(BOOL)isBatchEvent;

- (void)performRequestQueue:(NSMutableDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent;

/// Calling this method will display single in-app notification if the current screen/VC is registered for displaying in-app notifications.
- (void)displayInAppNotification;

/// Calling this method will fetch in-app notifications manually from api and add them into the SDK database.
/// @param success block to perform action when api call is successful
/// @param failure block to perform action when api call is unsuccessful
- (void)fetchInAppNotificationFromAPI:(void (^)(void))success failure:(void (^)(NSError*))failure;

/// Check if the url is from Blueshift
/// @param url  url to check
/// @returns true or false based on if url is from Blueshift or not
- (BOOL)isBlueshiftUniversalLinkURL:(NSURL *)url;

/// Check if the push notification is from Blueshift
/// @param userInfo  userInfo dictionary from the push notification payload
/// @returns true or false based on if push notification is from Blueshift or not
- (BOOL)isBlueshiftPushNotification:(NSDictionary *)userInfo;

/// Calling this method with `isEnabled` as `false` will disable the SDK tracking to stop sending data to Blueshift server for custom events, push and in-app metrics.
/// It will also erase all the non synced events data from the SDK database while disabling the SDK and they will not be sent to Blueshift server.
/// To restart the tracking, call enableTracking(true).
/// @param isEnabled true or false in order to enable or disable SDK tracking
/// @note By default the tracking is enabled.
- (void)enableTracking:(BOOL)isEnabled;

/// Calling this method with `isEnabled` as `false` will disable the SDK tracking to stop sending data to Blueshift server for custom events, push and in-app metrics.
/// Based on the param `shouldEraseEventsData`, it will erase all the non synced events data form the SDK database while disabling the SDK and they will not be sent to Blueshift server.
/// @param isEnabled true or false in order to enable or disable SDK tracking
/// @param shouldEraseEventsData true or false in order to earase the non synced data from the SDK database while disabling the SDK
/// @note By default the tracking is enabled.
/// @warning If you disable the SDK and do not erase the data, the non synced events will be sent to the Blueshift server when the tracking is enabled next time. These delayed events may impact on the product recommendations and campaign execution. It is recommended to erase the data when you disable the SDK.
- (void)enableTracking:(BOOL)isEnabled andEraseNonSyncedData:(BOOL)shouldEraseEventsData;

/// Know current status of SDK tracking if it is enabled or not.
- (BOOL)isTrackingEnabled;

/// This method will help to add an in-app notification in the SDK database based on the provided dictionary data.
/// @param completionHandler The block will be called after adding the in-app into the SDK database with status true or false
- (void)handleInAppMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler;

/// This method will to get the required payload data to make an api call to the Blueshift In-app notifications api.
/// @param completionHandler  The block will be called with params dictionary which is required to make a fetch in-app api call
- (void)getInAppNotificationAPIPayloadWithCompletionHandler:(void (^)(NSDictionary * _Nullable))completionHandler;

@end

NS_ASSUME_NONNULL_END
