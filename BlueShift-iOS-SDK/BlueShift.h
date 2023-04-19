//
//  BlueShift.h
//  BlueShift
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BlueShiftConfig.h>
#import <BlueShiftDeviceData.h>
#import <BlueShiftAppDelegate.h>
#import <BlueShiftPushDelegate.h>
#import <BlueShiftPushParamDelegate.h>
#import <BlueShiftNetworkReachabilityManager.h>
#import <BlueShiftSubscriptionState.h>
#import <BlueShiftRequestOperation.h>
#import <BlueShiftRequestQueue.h>
#import <BlueshiftRoutes.h>
#import <BlueShiftUserInfo.h>
#import <BlueShiftTrackEvents.h>
#import <BlueShiftProduct.h>
#import <BlueShiftSubscription.h>
#import <BlueShiftHttpRequestBatchUpload.h>
#import <BlueShiftBatchUploadConfig.h>
#import <BlueShiftAppData.h>
#import <BlueShiftPushNotificationSettings.h>
#import <BlueShiftUserNotificationSettings.h>
#import <BlueShiftUserNotificationCenterDelegate.h>
#import <BlueshiftEventAnalyticsHelper.h>
#import <BlueShiftLiveContent.h>
#import <BlueshiftInboxMessage.h>

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

+ (void) autoIntegration DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be replaced by the auto-integration using method swizzling. This method will be removed in a future SDK version.");

- (void) setPushDelegate: (id) obj DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");
- (void) setPushParamDelegate: (id) obj DEPRECATED_MSG_ATTRIBUTE("This method is deprecated, and will be removed in a future SDK version.");
- (NSString * _Nullable) getDeviceToken;
- (void) setDeviceToken;
- (void) handleSilentPushNotification:(NSDictionary *)dictionary forApplicationState:(UIApplicationState)applicationState;

/// Returns Blueshift serial queue instance for executing tasks on the Blueshift queue.
- (dispatch_queue_t _Nullable) dispatch_get_blueshift_queue;

#pragma mark In App registration methods
/// Register for in-app notifications in order to show the in-app notifications on the view controller or screen. To register, call this method in the `viewDidAppear` lifecycle method of VC.
/// @param displayPage Name of screen or view controller
/// @warning If you don't register a VC or screen to receive in-app notification, SDK will not show the in-app notifications on that VC or screen.
- (void)registerForInAppMessage:(NSString *)displayPage;

/// Unregister a VC or screen in the `viewDidDisappear` lifecycle method of VC. This is required to be done before registering a new screen for in-app notifications.
- (void)unregisterForInAppMessage;

/// Get current registered screen name for the in app notifications.
- (NSString* _Nullable)getRegisteredForInAppScreenName;

#pragma mark track events

/// Send identify event to update user data and custom attributes on Blueshift.
/// @param details additional details to send as part of identify event.
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true. Identify event is recommended to send in realtime.
/// @discussion Identify event is responsible to update the data for the user profile on the Blueshift.
/// Whenever any user data gets changed, It is recommended to send an identify event to reflect those changes on the Blueshift.
- (void)identifyUserWithDetails:(NSDictionary * _Nullable)details canBatchThisEvent:(BOOL)isBatchEvent;

/// Send identify event to update data and custom attributes on Blueshift.
/// @param email email id of the user.
/// @param details additional details to send as part of identify event.
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true. Identify event is recommended to send in realtime.
/// @discussion Identify event is responsible to update the data for the user profile on the Blueshift.
/// Whenever any user data gets changed, It is recommended to send an identify event to reflect those changes on the Blueshift.
- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary * _Nullable)details canBatchThisEvent:(BOOL)isBatchEvent;


/// Send `pageload` event to track the screen visits.
/// @param viewController viewController which is visited by the user.
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
- (void)trackScreenViewedForViewController:(UIViewController *)viewController canBatchThisEvent:(BOOL)isBatchEvent;

/// Send `pageload` event to track the screen visits.
/// @param viewController viewController which is visited by the user.
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
/// @param parameters additional details to send as part of event.
- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

/// Send `pageload` event to track the screen visits.
/// @param screenName Name of screen which is visited by the user.
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
/// @param parameters additional details to send as part of event.
- (void)trackScreenViewedForScreenName:(NSString*)screenName withParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;

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

/// Send custom events based on the custom usecases.
/// @param eventName name of the event
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
- (void)trackEventForEventName:(NSString *)eventName canBatchThisEvent:(BOOL)isBatchEvent;

/// Send custom events based on the custom usecases.
/// @param eventName name of the event
/// @param parameters additional details related to the event
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary * _Nullable)parameters canBatchThisEvent:(BOOL)isBatchEvent;


/// Calling this method with will fire a click event for the received Blueshift push notification payload.
/// @param userInfo push notification payload
/// @param isBatchEvent send this event in realtime when value is false or in batch when value is true.
- (void)trackPushClickedWithParameters:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent;

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent DEPRECATED_MSG_ATTRIBUTE("The push delivered is now calculated using the APNS feedback, and App should not send the push delivered event to Blueshift using this method.");

- (void)trackInAppNotificationDeliveredWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationShowingWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationButtonTappedWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent;

- (void)trackInAppNotificationDismissWithParameter:(NSDictionary *)notificationPayload canBacthThisEvent:(BOOL)isBatchEvent;

- (void)addTrackingEventToQueueWithParams:(NSMutableDictionary *)parameters isBatch:(BOOL)isBatchEvent;

#pragma mark In app manual trigger and fetch methods
/// Calling this method will display single in-app notification if the current screen/VC is registered for displaying in-app notifications.
- (void)displayInAppNotification;

/// Calling this method will fetch in-app notifications manually from api and add them into the SDK database.
/// @param success block to perform action when api call is successful
/// @param failure block to perform action when api call is unsuccessful
- (void)fetchInAppNotificationFromAPI:(void (^)(void))success failure:(void (^)(NSError* _Nullable))failure;

#pragma mark Helper methods
/// Check if the url is from Blueshift
/// @param url  url to check
/// @returns true or false based on if url is from Blueshift or not
- (BOOL)isBlueshiftUniversalLinkURL:(NSURL *)url;

/// Check if the push notification is from Blueshift
/// @param userInfo  userInfo dictionary from the push notification payload
/// @returns true or false based on if push notification is from Blueshift or not
- (BOOL)isBlueshiftPushNotification:(NSDictionary *)userInfo;

/// Check if the received push notification response is of Blueshift custom action type.
/// @param response userInfo dictionary from the push notification p ayload.
/// @returns true or false based on if push notification is of Blueshift custom action type or not.
- (BOOL)isBlueshiftPushCustomActionResponse:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0));

#pragma mark SDK tracking methods
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

#pragma mark In-app notifications helper methods
/// This method will help to add an in-app notification in the SDK database based on the provided dictionary data.
/// @param completionHandler The block will be called after adding the in-app into the SDK database with status true or false
- (void)handleInAppMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler;

/// This method will to get the required payload data to make an api call to the Blueshift In-app notifications api.
/// @param completionHandler  The block will be called with params dictionary which is required to make a fetch in-app api call
- (void)getInAppNotificationAPIPayloadWithCompletionHandler:(void (^)(NSDictionary * _Nullable))completionHandler;

- (BOOL)createInAppNotificationForInboxMessage:(BlueshiftInboxMessage*)message;

#pragma mark Push and In App notifications Opt In methods
/// This utility method can be used to opt-in/opt-out for in-app notifications from Blueshift server.
/// @params isOptedIn BOOL flag to indicate the optIn status of the in-app notifications.
/// @discussion Calling this function will update the optIn status using the `enableInApp` flag of the `BlueshiftAppData` class. After changing the status,
/// SDK will automatically fire the identify call in order to update the status on the server. There is no need of firing the identify call manually.
- (void)optInForInAppNotifications:(BOOL)isOptedIn;

/// This utility method can be used to opt-in/opt-out for push notifications from Blueshift server.
/// @params isOptedIn BOOL flag to indicate the optIn status of the push notifications.
/// @discussion Calling this function will update the optIn status using the `enablePush` flag of the `BlueshiftAppData` class. After changing the status,
/// SDK will automatically fire the identify call in order to update the status on the server. There is no need of firing the identify call manually.
- (void)optInForPushNotifications:(BOOL)isOptedIn;

@end

NS_ASSUME_NONNULL_END
