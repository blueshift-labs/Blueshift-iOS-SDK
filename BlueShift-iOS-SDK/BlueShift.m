//
//  BlueShift.m
//  BlueShift
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShift.h"
#import <UserNotifications/UserNotifications.h>
#import "BlueShiftInAppNotificationManager.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueshiftInboxAPIManager.h"
#import "BlueshiftInboxMessage.h"
#import "InAppNotificationEntity.h"
#import "BlueshiftInboxManager.h"

BlueShiftInAppNotificationManager *_inAppNotificationMananger;
static BlueShift *_sharedBlueShiftInstance = nil;
static dispatch_queue_t blueshiftSerialQueue = nil;
static const void *const kBlueshiftQueue = &kBlueshiftQueue;

@implementation BlueShift

- (dispatch_queue_t _Nullable) dispatch_get_blueshift_queue {
    return blueshiftSerialQueue;
}

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBlueShiftInstance = [[self alloc] init];
    });
    return _sharedBlueShiftInstance;
}

#pragma mark SDK initialisation
+ (void) initWithConfiguration:(BlueShiftConfig *)config {
    if([NSThread isMainThread] == YES) {
        [[BlueShift sharedInstance] setupWithConfiguration:config];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[BlueShift sharedInstance] setupWithConfiguration:config];
        });
    }
}

+ (void) autoIntegration {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[BlueShift sharedInstance] setAppDelegate];
    });
}

- (void)setAppDelegate {
    [UIApplication sharedApplication].delegate = [BlueShift sharedInstance].appDelegate;
}

- (void)resetSDKConfig {
    // Reset the SDK data on SDK re-initialisation
    if (_sharedBlueShiftInstance.config) {
        [BlueshiftLog logInfo:@"Resetting SDK config for SDK re-initialization." withDetails:nil methodName:nil];
        
        // Stop batchupload
        [BlueShiftHttpRequestBatchUpload stopBatchUpload];

        _sharedBlueShiftInstance.config = nil;
        
        // Reset URL config on SDK re-initialisation to create new config with new API key.
        [BlueShiftRequestOperationManager.sharedRequestOperationManager resetURLSessionConfig];
        
        // Invalidate the in-app timer in case of SDK re-initialisation. New timer will be created on initialisation.
        if (_inAppNotificationMananger) {
            [_inAppNotificationMananger stopInAppMessageFetchTimer];
            // Close any active in-app
            if (_inAppNotificationMananger.currentNotificationController) {
                [_inAppNotificationMananger.currentNotificationController hide:YES];
            }
            _inAppNotificationMananger = nil;
        }
    }
}

- (void) setupWithConfiguration:(BlueShiftConfig *)config {
    @try {
        // Validate the API key
        if ([config validateConfigDetails] == NO) {
            return ;
        }
        
        [self resetSDKConfig];
        
        // Set config
        _sharedBlueShiftInstance.config = config;
        
        // Set up device id
        if (config.blueshiftDeviceIdSource) {
            [[BlueShiftDeviceData currentDeviceData] setBlueshiftDeviceIdSource:config.blueshiftDeviceIdSource];
            
            //Custom device id provision for DeviceIDSourceCUSTOM
            if (config.blueshiftDeviceIdSource == BlueshiftDeviceIdSourceCustom) {
                if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:config.customDeviceId]) {
                    [[BlueShiftDeviceData currentDeviceData] setCustomDeviceID:config.customDeviceId];
                    [BlueshiftLog logInfo: [NSString stringWithFormat:@"CUSTOM device id is set as - %@",config.customDeviceId] withDetails:nil methodName:nil];
                } else {
                    [BlueshiftLog logError:nil withDescription:@"ERROR: CUSTOM device id is not provided" methodName:nil];
                }
            }
        }
        
        // Set BlueshiftAppDelegate
        _sharedBlueShiftInstance.appDelegate = [[BlueShiftAppDelegate alloc] init];
        _sharedBlueShiftInstance.appDelegate.mainAppDelegate = [UIApplication sharedApplication].delegate;
        
        // Initialise Blueshift serial queue
        static dispatch_once_t s_done;
        dispatch_once(&s_done, ^{
            blueshiftSerialQueue = dispatch_queue_create(kBSSerialQueue, DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(blueshiftSerialQueue, kBlueshiftQueue, (__bridge void *)self, NULL);
        });
        
        // Initialise core data
        [_sharedBlueShiftInstance.appDelegate initializeCoreData];
        
        [self trackAppInstallOrUpdateEvent];
        
        // Set up Push notifications and delegates
        BlueShiftUserNotificationCenterDelegate *blueShiftUserNotificationCenterDelegate = [[BlueShiftUserNotificationCenterDelegate alloc] init];
        _sharedBlueShiftInstance.userNotificationDelegate = blueShiftUserNotificationCenterDelegate;
        
        
        if (@available(iOS 10.0, *)) {
            _sharedBlueShiftInstance.userNotification = [[BlueShiftUserNotificationSettings alloc] init];
            
            // Use this delegate while registering for push notifications
            if(config.userNotificationDelegate) {
                _sharedBlueShiftInstance.appDelegate.userNotificationDelegate = config.userNotificationDelegate;
            } else {
                _sharedBlueShiftInstance.appDelegate.userNotificationDelegate = blueShiftUserNotificationCenterDelegate;
            }
        } else {
            if (@available(iOS 8.0, *)) {
                _sharedBlueShiftInstance.pushNotification = [[BlueShiftPushNotificationSettings alloc] init];
            }
        }
        
        // Push notification callback delegate
        if(config.blueShiftPushDelegate) {
            _sharedBlueShiftInstance.appDelegate.blueShiftPushDelegate = config.blueShiftPushDelegate;
        } else {
            _sharedBlueShiftInstance.appDelegate.blueShiftPushDelegate = nil;
        }
        
        // Register for Push/Silent push notifications
        if (config.enablePushNotification == YES) {
            [_sharedBlueShiftInstance.appDelegate registerForNotification];
        } else if (config.enableSilentPushNotification == YES) {
            [_sharedBlueShiftInstance.appDelegate registerForSilentPushNotification];
        } else {
            [_sharedBlueShiftInstance.appDelegate checkUNAuthorizationStatus];
        }
        
        // Process app launch from push notification
        [_sharedBlueShiftInstance.appDelegate handleRemoteNotificationOnLaunchWithLaunchOptions:config.applicationLaunchOptions];
        
        // Download font awesome file
        [BlueShiftInAppNotificationHelper downloadFontAwesomeFile:^{}];
        
        // Set up Universal links delegate
        if (config.blueshiftUniversalLinksDelegate) {
            _sharedBlueShiftInstance.appDelegate.blueshiftUniversalLinksDelegate = config.blueshiftUniversalLinksDelegate;
        } else {
            _sharedBlueShiftInstance.appDelegate.blueshiftUniversalLinksDelegate = nil;
        }
        
        // Initialise timer for batch upload
        [BlueShiftHttpRequestBatchUpload startBatchUpload];
        
        // Initialize In App Manager
        _inAppNotificationMananger = [[BlueShiftInAppNotificationManager alloc] init];
        if (config.inAppNotificationDelegate) {
            _inAppNotificationMananger.inAppNotificationDelegate = config.inAppNotificationDelegate;
        } else {
            _inAppNotificationMananger.inAppNotificationDelegate = nil;
        }
        
        //Delete expired in-app notifications
        if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES || config.enableMobileInbox == YES) {
            [InAppNotificationEntity deleteExpiredMessagesFromDB];
        }
        
        //If mobile inbox is enabled, then force enable in-app notifications
        if (config.enableMobileInbox == YES) {
            config.enableInAppNotification = YES;
        }
        
        if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES) {
            if (config.inAppManualTriggerEnabled == NO) {
                _inAppNotificationMananger.inAppNotificationTimeInterval = config.BlueshiftInAppNotificationTimeInterval;
                [_inAppNotificationMananger load];
            }
            if (config.enableMobileInbox) {
                [BlueshiftInboxManager syncInboxMessages:^{}];
            } else {
                [self fetchInAppNotificationFromAPI:^(void) {
                } failure:^(NSError *error){
                }];
            }
        }
        
        [self runAfterSDKInitialisation];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:@"Failed to initialise SDK." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (void)runAfterSDKInitialisation {
    [self logSDKInitializationDetails];

    [self setupObservers];
    
    // Fire app open event
    [_sharedBlueShiftInstance.appDelegate trackAppOpenOnAppLaunch:nil];
    
    // Send any existing cached non batch/track events to Blueshift irrespecitive of SDK Tracking enabled status
    [BlueShiftRequestQueue processRequestsInQueue];
}

/// Print debug logs on SDK initialization
- (void)logSDKInitializationDetails {
    if (_sharedBlueShiftInstance.config.debug == YES) {
        [BlueshiftLog logInfo:@"SDK configured successfully. Below are the config details" withDetails:[_config getConfigStringToLog] methodName:nil];
        
        if ([[BlueShiftAppData currentAppData] enablePush] == YES) {
            [BlueshiftLog logInfo: @"EnablePush has been set to YES. If app push notification permission is accepted then app will start receiving push notifications from Blueshift." withDetails:nil methodName:nil];
        } else {
            [BlueshiftLog logInfo: @"EnablePush has been set to NO. The app will not receive any push notifications from Blueshift. To enable receiving push notifications, set enablePush to true and fire identify call from Blueshift SDK." withDetails:nil methodName:nil];
        }
        
        if ([[BlueShiftAppData currentAppData] enableInApp] == YES) {
            [BlueshiftLog logInfo: @"EnableInApp has been set to YES. If SDK is set up for receiving In-app, then app will start receiving in-app notifications from Blueshift." withDetails:nil methodName:nil];
        } else {
            [BlueshiftLog logInfo: @"EnableInApp has been set to NO. The app will not receive any in-app notifications from Blueshift. To enable receiving in-app notifications, set enableInApp to true and fire identify call from Blueshift SDK." withDetails:nil methodName:nil];
        }
        
        [BlueshiftLog logInfo: [NSString stringWithFormat: @"SDK tracking for custom events and push & in-app metrics is %@.",([self isTrackingEnabled] ? @"enabled" : @"disabled")] withDetails:nil methodName:nil];
    }
}

- (void)setupObservers {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BlueshiftLog logInfo:@"Adding obsevers for app enters foreground and background." withDetails:nil methodName:nil];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [self processWillEnterForground];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [self processDidEnterBackground];
        }];
    });
}

/// Check if the push permission status is changed when app enters foreground
/// Also upload one batch of the batched events to Blueshift.
- (void)processWillEnterForground {
    [BlueshiftLog logInfo:@"Processing will enter background" withDetails:nil methodName:nil];
    if ([BlueShift sharedInstance].isTrackingEnabled) {
        [[BlueShift sharedInstance].appDelegate checkUNAuthorizationStatus];
        // Send any pending non batch/track events to Blueshift
        [BlueShiftRequestQueue processRequestsInQueue];
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
}

/// Upload one batch of the batched events to Blueshift when app enters background.
- (void)processDidEnterBackground {
    [BlueshiftLog logInfo:@"Processing did enter background" withDetails:nil methodName:nil];
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        // Initiate background single batch upload
        @try {
            __block UIBackgroundTaskIdentifier background_task;
            background_task = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:^ {
                [UIApplication.sharedApplication endBackgroundTask: background_task];
                background_task = UIBackgroundTaskInvalid;
            }];
            
            //Send existing cached events to Blueshift irrespecitive of SDK Tracking enabled status
            [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
        } @catch (NSException *exception) {
        }
    }
}

- (void) setPushDelegate:(id)delegate {
    if (_sharedBlueShiftInstance.appDelegate != nil) {
        _sharedBlueShiftInstance.appDelegate.blueShiftPushDelegate = delegate;
    }
}

- (void) setPushParamDelegate:(id)delegate {
    if (_sharedBlueShiftInstance.appDelegate !=nil) {
        _sharedBlueShiftInstance.appDelegate.blueShiftPushParamDelegate = delegate;
    }
}

/// Returns true if the current thread Queue is Blueshift serial Queue.
- (BOOL)isBlueshiftQueue {
    @try {
        BlueShift *currentQueue = (__bridge id) dispatch_get_specific(kBlueshiftQueue);
        return currentQueue == self;
    } @catch (NSException *exception) {
        return NO;
    }
}

#pragma mark Update Application Badge
/// Calling this method will update the Application badge number to the number of pending notifications in the notification center.
/// The SDK calls this method to update the badge when 'auto update badge' type of push notficiation is receved/clicked/dismissed.
/// You may call this method on the app launch/ app enters foreground/ app enters background event to force refresh the badge.
/// - Note The SDK will only update badge if app has push notifications enabled from app setting and `enablePush` is set as true.
/// - Parameter completionHandler: handler to perform some task after badge update
- (void)refreshApplicationBadgeWithCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    if (BlueShiftAppData.currentAppData.enablePush) {
        
        [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIApplication.sharedApplication.applicationIconBadgeNumber = notifications.count;
                completionHandler();
            });
        }];
    } else {
        completionHandler();
    }
}

- (BOOL)isAutoUpdateBadgePushNotification:(UNNotificationRequest *)request {
    if([[request.content.userInfo objectForKey:kAutoUpdateBadge] boolValue] == YES) {
        return YES;
    }
    return NO;
}

#pragma mark Device token
- (void)setDeviceToken {
    if ([BlueShiftDeviceData currentDeviceData].deviceToken) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[BlueShiftDeviceData currentDeviceData].deviceToken forKey:kBlueshiftDeviceToken];
        [defaults synchronize];
    }
}

- (NSString * _Nullable) getDeviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* deviceToken = (NSString *)[defaults objectForKey:kBlueshiftDeviceToken];
    return deviceToken;
}

#pragma mark Identify events
- (void)identifyUserWithDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent {
    [self identifyUserWithEmail:[BlueShiftUserInfo sharedInstance].email andDetails:details canBatchThisEvent:isBatchEvent];
}

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    if (email) {
        [parameterMutableDictionary setObject:email forKey:kEmail];
    }
    
    if (details) {
        [parameterMutableDictionary addEntriesFromDictionary:details];
    }
    [self trackEventForEventName:kEventIdentify andParameters:parameterMutableDictionary canBatchThisEvent:isBatchEvent];
}

#pragma mark Track events
- (void)trackScreenViewedForViewController:(UIViewController *)viewController canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackScreenViewedForViewController:viewController withParameters:nil canBatchThisEvent:isBatchEvent];
}

- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSString* viewControllerString = NSStringFromClass([viewController class]);
    [self trackScreenViewedForScreenName:viewControllerString withParameters:parameters canBatchThisEvent:isBatchEvent];
}


- (void)trackScreenViewedForScreenName:(NSString*)screenName withParameters:(NSDictionary*)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    if (screenName) {
        [parameterMutableDictionary setObject:screenName forKey:kBSScreenViewed];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventPageLoad andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}

- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackProductViewedWithSKU:sku andCategoryID:categoryID withParameter:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID withParameter:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent {
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (sku) {
        [parameterMutableDictionary setObject:sku forKey:@"sku"];
    }
    
    if (categoryID) {
        [parameterMutableDictionary setObject:[NSNumber numberWithInteger:categoryID] forKey:@"category_id"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventProductViewed andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackAddToCartWithSKU:sku andQuantity:quantity andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (sku) {
        [parameterMutableDictionary setObject:sku forKey:@"sku"];
    }
    
    if (quantity) {
        [parameterMutableDictionary setObject:[NSNumber numberWithInteger:quantity] forKey:@"quantity"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventAddToCart andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackCheckOutCartWithProducts:products andRevenue:revenue andDiscount:discount andCoupon:coupon andParameters:nil canBatchThisEvent:isBatchEvent];
    
}


- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (products!=nil && products.count > 0) {
        NSMutableArray *productsDictionaryMutableArray = [BlueShiftProduct productsDictionaryMutableArrayForProductsArray:products];
        [parameterMutableDictionary setObject:productsDictionaryMutableArray forKey:@"products"];
    }
    
    if (revenue) {
        [parameterMutableDictionary setObject:[NSNumber numberWithFloat:revenue] forKey:@"revenue"];
    }
    
    if (discount) {
        [parameterMutableDictionary setObject:[NSNumber numberWithFloat:discount] forKey:@"discount"];
    }
    
    if (coupon) {
        [parameterMutableDictionary setObject:coupon forKey:@"coupon"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    
    [self trackEventForEventName:kEventCheckout andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackProductsPurchased:products withOrderID:orderID andRevenue:revenue andShippingCost:shippingCost andDiscount:discount andCoupon:coupon andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (products!=nil && products.count > 0) {
        NSMutableArray *productDictionaryMutableArray = [BlueShiftProduct productsDictionaryMutableArrayForProductsArray:products];
        [parameterMutableDictionary setObject:productDictionaryMutableArray forKey:@"products"];
    }
    
    if (orderID) {
        [parameterMutableDictionary setObject:orderID forKey:@"order_id"];
    }
    
    if (revenue) {
        [parameterMutableDictionary setObject:[NSNumber numberWithFloat:revenue] forKey:@"revenue"];
    }
    
    if (discount) {
        [parameterMutableDictionary setObject:[NSNumber numberWithFloat:discount] forKey:@"discount"];
    }
    
    if (coupon) {
        [parameterMutableDictionary setObject:coupon forKey:@"coupon"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventPurchase andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}

- (void)trackPurchaseCancelForOrderID:(NSString *)orderID canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackPurchaseCancelForOrderID:orderID andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackPurchaseCancelForOrderID:(NSString *)orderID andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (orderID) {
        [parameterMutableDictionary setObject:orderID forKey:@"order_id"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventCancel andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
    
}


- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackPurchaseReturnForOrderID:orderID andProducts:products andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (products!=nil && products.count > 0) {
        NSMutableArray *productsDictionaryMutableArray = [BlueShiftProduct productsDictionaryMutableArrayForProductsArray:products];
        [parameterMutableDictionary setObject:productsDictionaryMutableArray forKey:@"products"];
    }
    
    if (orderID) {
        [parameterMutableDictionary setObject:orderID forKey:@"order_id"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventReturn andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackProductSearchWithSkuArray:skuArray andNumberOfResults:numberOfResults andPageNumber:pageNumber andQuery:query andFilters:filters andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackProductSearchWithSkuArray:skuArray andNumberOfResults:numberOfResults andPageNumber:pageNumber andQuery:query andFilters:nil andParameters:parameters canBatchThisEvent:isBatchEvent];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (skuArray) {
        [parameterMutableDictionary setObject:skuArray forKey:@"skus"];
    }
    
    if (numberOfResults) {
        [parameterMutableDictionary setObject:[NSNumber numberWithInteger:numberOfResults] forKey:@"number_of_results"];
    }
    
    if (pageNumber) {
        [parameterMutableDictionary setObject:[NSNumber numberWithInteger:pageNumber] forKey:@"page_number"];
    }
    
    if (query) {
        [parameterMutableDictionary setObject:query forKey:@"query"];
    }
    
    if (filters) {
        [parameterMutableDictionary setObject:filters forKey:@"filters"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSearch andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
    
}


- (void)trackEmailListSubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackEmailListSubscriptionForEmail:email andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackEmailListSubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (email) {
        [parameterMutableDictionary setObject:email forKey:kEmail];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSubscribeMailing andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackEmailListUnsubscriptionForEmail:email andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (email) {
        [parameterMutableDictionary setObject:email forKey:kEmail];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventUnSubscribeMailing andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate canBatchThisEvent:(BOOL)isBatchEvent{
    
    [self trackSubscriptionInitializationForSubscriptionState:subscriptionState andCycleType:cycleType andCycleLength:cycleLength andSubscriptionType:subscriptionType andPrice:price andStartDate:startDate andParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    NSString *subscriptionEventName = @"";
    if (subscriptionState == BlueShiftSubscriptionStateStart || subscriptionState == BlueShiftSubscriptionStateUpgrade) {
        subscriptionEventName = kEventSubscriptionUpgrade;
    } else if (subscriptionState == BlueShiftSubscriptionStateDowngrade) {
        subscriptionEventName = kEventSubscriptionDowngrade;
    }
    
    BlueShiftSubscription *subscription = [[BlueShiftSubscription alloc] initWithSubscriptionState:subscriptionState andCycleType:cycleType andCycleLength:cycleLength andSubscriptionType:subscriptionType andPrice:price andStartDate:startDate];
    
    [subscription save];
    
    [parameterMutableDictionary addEntriesFromDictionary:[subscription toDictionary]];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:subscriptionEventName andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
    
}


- (void)trackSubscriptionPauseWithBatchThisEvent:(BOOL)isBatchEvent {
    [self trackSubscriptionPauseWithParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionPauseWithParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent {
    BlueShiftSubscription *subscription = [BlueShiftSubscription currentSubscription];
    
    if (subscription==nil) {
        [BlueshiftLog logError:nil withDescription:[NSString stringWithFormat:@"Could not pause subscription. Please initialize the subscription"] methodName:nil];

        return ;
    }
    
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    [parameterMutableDictionary addEntriesFromDictionary:[subscription toDictionary]];
    
    [parameterMutableDictionary setObject:@"paused" forKey:@"subscription_status"];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSubscriptionDowngrade andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionUnpauseWithBatchThisEvent:(BOOL)isBatchEvent {
    [self trackSubscriptionUnpauseWithParameters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionUnpauseWithParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    BlueShiftSubscription *subscription = [BlueShiftSubscription currentSubscription];
    
    if (subscription==nil) {
        [BlueshiftLog logError:nil withDescription:[NSString stringWithFormat:@"Could not unpause subscription. Please initialize the subscription"] methodName:nil];
        return ;
    }
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    [parameterMutableDictionary addEntriesFromDictionary:[subscription toDictionary]];
    
    [parameterMutableDictionary setObject:@"active" forKey:@"subscription_status"];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSubscriptionUpgrade andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionCancelWithBatchThisEvent:(BOOL)isBatchEvent {
    [self trackSubscriptionCancelWithParamters:nil canBatchThisEvent:isBatchEvent];
}


- (void)trackSubscriptionCancelWithParamters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    BlueShiftSubscription *subscription = [BlueShiftSubscription currentSubscription];
    
    if (subscription==nil) {
        [BlueshiftLog logError:nil withDescription:[NSString stringWithFormat:@"Could not cancel subscription. Please initialize the subscription"] methodName:nil];
        return ;
    }
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    [parameterMutableDictionary addEntriesFromDictionary:[subscription toDictionary]];
    
    [parameterMutableDictionary setObject:@"canceled" forKey:@"subscription_status"];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSubscriptionCancel andParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}


- (void)trackEventForEventName:(NSString *)eventName canBatchThisEvent:(BOOL)isBatchEvent{
    [self trackEventForEventName:eventName andParameters:nil canBatchThisEvent:isBatchEvent];
}

- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    // Event name should not get overriden by the additional params
    if (eventName) {
        [parameterMutableDictionary setObject:eventName forKey:kEventGeneric];
    }
    [self addCustomEventToQueueWithParams:[parameterMutableDictionary copy] isBatch:isBatchEvent];
}

#pragma mark Process custom and tracking events

/// Add event to event processing queue
/// @param requestParameters event parameters
/// @param isBatchEvent  BOOL to determine if the event needs to be batched or not.
- (void)addCustomEventToQueueWithParams:(NSDictionary *)requestParameters isBatch:(BOOL)isBatchEvent{
    @try {
        if([self validateSDKTrackingRequirements] == false) {
            return;
        }
        NSString *url = nil;
        if(isBatchEvent) {
            url = [BlueshiftRoutes getBulkEventsURL];
        } else {
            url = [BlueshiftRoutes getRealtimeEventsURL];
        }
        NSDictionary* eventParams = [self addDefaultParamsToDictionary:requestParameters];
        BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodPOST andParameters:[eventParams copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
        // Check if blueshiftSerialQueue is not nil
        if (blueshiftSerialQueue) {
            if([self isBlueshiftQueue]) { //check if the the current thread is of BlueShiftRequestQueue
                [BlueShiftRequestQueue addRequestOperation:requestOperation];
            } else {
                dispatch_async(blueshiftSerialQueue, ^{
                    [BlueShiftRequestQueue addRequestOperation:requestOperation];
                });
            }
        } else { // If blueshiftSerialQueue is not availble then execute it on same thread
            [BlueShiftRequestQueue addRequestOperation:requestOperation];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    
}

-(NSDictionary*)addDefaultParamsToDictionary:(NSDictionary*)requestParameters {
    NSMutableDictionary *requestMutableParameters = [[NSMutableDictionary alloc] init];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftAppData currentAppData].toDictionary];
    
    if ([BlueShiftUserInfo sharedInstance] == nil) {
        [BlueshiftLog logInfo:[NSString stringWithFormat:@"Please set BlueshiftUserInfo for sending the user attributes such as email id, customer id"] withDetails:nil methodName:nil];
    } else {
        NSString *email = [requestMutableParameters objectForKey:kEmail];
        NSMutableDictionary *blueShiftUserInfoMutableDictionary = [[BlueShiftUserInfo sharedInstance].toDictionary mutableCopy];
        // Remove the email id from userInfo if the email id is already exists.
        if (email && [blueShiftUserInfoMutableDictionary objectForKey:kEmail]) {
            [blueShiftUserInfoMutableDictionary removeObjectForKey:kEmail];
        }
        
        [requestMutableParameters addEntriesFromDictionary:[blueShiftUserInfoMutableDictionary copy]];
    }
    NSString* timestamp = [BlueshiftEventAnalyticsHelper getCurrentUTCTimestamp];
    if (timestamp) {
        [requestMutableParameters setObject:timestamp forKey:kInAppNotificationModalTimestampKey];
    }
    if(requestParameters) {
        [requestMutableParameters addEntriesFromDictionary:requestParameters];
    }
    return requestMutableParameters;
}

/// Add a tracking event to event processing queue. The track events could be delivered, open, click or dismiss.
/// @param parameters tracking parameters
/// @param isBatchEvent  BOOL to determine if the event needs to be batched or not.
- (void)addTrackingEventToQueueWithParams:(NSMutableDictionary *)parameters isBatch:(BOOL)isBatchEvent{
    @try {
        if([self validateSDKTrackingRequirements] == false) {
            return;
        }
        if (parameters) {
            NSMutableDictionary* mutableParams = [parameters mutableCopy];
            [mutableParams setValue:[BlueShiftDeviceData currentDeviceData].operatingSystem forKey:kBrowserPlatform];
            NSString *url = [BlueshiftRoutes getTrackURL];
            BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodGET andParameters:[mutableParams copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
            
            // Check if blueshiftSerialQueue is not nil
            if (blueshiftSerialQueue) {
                if([self isBlueshiftQueue]) { //check if the the current thread is of BlueShiftRequestQueue
                    [BlueShiftRequestQueue addRequestOperation:requestOperation];
                } else {
                    dispatch_async(blueshiftSerialQueue, ^{
                        [BlueShiftRequestQueue addRequestOperation:requestOperation];
                    });
                }
            } else { // If blueshiftSerialQueue is not availble then execute it on same thread
                [BlueShiftRequestQueue addRequestOperation:requestOperation];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (BOOL)validateSDKTrackingRequirements {
    if (![BlueShift sharedInstance].config.apiKey) {
        #ifdef DEBUG
            NSLog(@"[Blueshift] Error : SDK API key not found or SDK not initialised. Please set the API key in the config and initialise the SDK");
        #endif
        return false;
    }
    if ([[BlueShift sharedInstance] isTrackingEnabled] == NO) {
        [BlueshiftLog logInfo:@"The SDK Tracking is disabled and events will not be sent to Blueshift server. To start the SDK tracking, call BlueShift.sharedInstance()?.enableTracking(true)." withDetails:nil methodName:nil];
        return false;
    }
    return  true;
}

#pragma mark Track delivered, open and click events
- (void)trackPushClickedWithParameters:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSClick withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSDelivered withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackInAppNotificationDeliveredWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSDelivered withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationShowingWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSOpen withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationButtonTappedWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSClick withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationDismissWithParameter:(NSDictionary *)notificationPayload canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendTrackingAnalytics:kBSDismiss withParams: notificationPayload canBatchThisEvent: isBatchEvent];
}

- (void)sendTrackingAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics:userInfo]) {
        NSDictionary *trackingParams = [BlueshiftEventAnalyticsHelper getTrackingParamsForNotification: userInfo];
        NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
        
        if (trackingParams) {
            [mutableParams addEntriesFromDictionary:trackingParams];
        }
        if (type) {
            [mutableParams setObject:type forKey:kBSAction];
        }
        [self addTrackingEventToQueueWithParams:mutableParams isBatch:isBatchEvent];
    }
}

#pragma  mark In app messages
- (void)registerForInAppMessage:(NSString *)displayPage {
    if (_inAppNotificationMananger) {
        if (displayPage) {
            _inAppNotificationMananger.inAppNotificationDisplayOnPage = displayPage;
            [BlueshiftLog logInfo:@"Successfully registered for in-app for screen " withDetails:displayPage methodName:nil];
        }
        if (_config.inAppManualTriggerEnabled == NO) {
             [self fetchInAppNotificationFromDBforApplicationState:UIApplicationStateActive];
        }
    }
}

- (void)unregisterForInAppMessage {
    if (_inAppNotificationMananger) {
        [BlueshiftLog logInfo:@"Successfully unregistered for in-app for screen " withDetails:_inAppNotificationMananger.inAppNotificationDisplayOnPage methodName:nil];
        _inAppNotificationMananger.inAppNotificationDisplayOnPage = nil;
    }
}

- (NSString* _Nullable)getRegisteredForInAppScreenName {
    if (_inAppNotificationMananger) {
        return  _inAppNotificationMananger.inAppNotificationDisplayOnPage;
    }
    return nil;
}

- (void)displayInAppNotification {
    if (_inAppNotificationMananger) {
        [self fetchInAppNotificationFromDBforApplicationState:UIApplicationStateActive];
    }
}

- (void)handleSilentPushNotification:(NSDictionary *)dictionary forApplicationState:(UIApplicationState)applicationState {
    if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES) {
        if ([BlueshiftEventAnalyticsHelper isFetchInAppAction: dictionary]) {
            if (_config.enableMobileInbox) {
                [BlueshiftInboxManager syncInboxMessages:^{
                    if (self->_config.inAppManualTriggerEnabled == NO) {
                        [self fetchInAppNotificationFromDBforApplicationState:UIApplicationStateActive];
                    }
                }];
            } else {
                [self fetchInAppNotificationFromAPI:^() {
                    if (self->_config.inAppManualTriggerEnabled == NO) {
                        [self fetchInAppNotificationFromDBforApplicationState:applicationState];
                    }
                } failure:^(NSError *error){ }];
            }
        } else if (_config.inAppManualTriggerEnabled == NO){
            [self fetchInAppNotificationFromDBforApplicationState:applicationState];
        }
    }
}

/// Fetch in-app notification from db and display on the screen when app is in active state
- (void)fetchInAppNotificationFromDBforApplicationState:(UIApplicationState)applicationState {
    if (_inAppNotificationMananger && applicationState == UIApplicationStateActive) {
        [_inAppNotificationMananger fetchAndShowInAppNotification];
    }
}


- (void)fetchInAppNotificationFromAPI:(void (^_Nonnull)(void))success failure:(void (^)( NSError* _Nullable ))failure {
    if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES && _inAppNotificationMananger) {
        [BlueshiftInboxAPIManager fetchInAppNotificationWithSuccess:^(NSDictionary * apiResponse) {
            [self handleInAppMessageForAPIResponse:apiResponse withCompletionHandler:^(BOOL status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success();
                });
            }];
        } failure:^(NSError * error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }];
    } else {
        NSError *error = (NSError*)@"In-app is opted out, can not fetch in-app notifications from API.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

- (void)handleInAppMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler {
    [BlueshiftInboxManager processInboxMessagesForAPIResponse:apiResponse withCompletionHandler:^(BOOL status) {
        completionHandler(status);
    }];
}

- (void)getInAppNotificationAPIPayloadWithCompletionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    if (_inAppNotificationMananger) {
        [InAppNotificationEntity fetchLastReceivedMessageId:^(BOOL status, NSString * notificationID, NSString * lastTimestamp) {
            NSString *deviceID = [BlueShiftDeviceData currentDeviceData].deviceUUID.lowercaseString;
            NSString *email = [BlueShiftUserInfo sharedInstance].email;
            
            NSString *apiKey = @"";
            if([BlueShift sharedInstance].config.apiKey) {
                apiKey = [BlueShift sharedInstance].config.apiKey;
            } else {
                #ifdef DEBUG
                    NSLog(@"[Blueshift] Error : SDK API key not found or SDK not initialised. Please set the API key in the config and initialise the SDK");
                #endif
            }
            
            if ((deviceID && ![deviceID isEqualToString:@""]) || (email && ![email isEqualToString:@""])) {
                NSMutableDictionary *apiPayload = [@{
                    kInAppNotificationModalMessageUDIDKey : notificationID,
                    kAPIKey : apiKey,
                    kLastTimestamp : (lastTimestamp && ![lastTimestamp isEqualToString:@""]) ? lastTimestamp :@0
                } mutableCopy];
                [apiPayload addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];
                [apiPayload addEntriesFromDictionary:[BlueShiftAppData currentAppData].toDictionary];
                [apiPayload addEntriesFromDictionary:[[BlueShiftUserInfo sharedInstance].toDictionary mutableCopy]];
                if (deviceID && apiPayload[kDeviceID] == nil) {
                    [apiPayload setValue:deviceID forKey:kDeviceID];
                }
                if (email && [apiPayload objectForKey:kEmail] == nil) {
                    [apiPayload setValue:email forKey:kEmail];
                }
                completionHandler(apiPayload);
            } else {
                [BlueshiftLog logInfo:@"Unable to fetch in-app messages as device_id is missing." withDetails:nil methodName:nil];
                completionHandler(nil);
            }
        }];
    }
}

#pragma mark Enable/Disable events tracking
- (void)enableTracking:(BOOL)isEnabled {
    [self enableTracking:isEnabled andEraseNonSyncedData:!isEnabled];
}

- (void)enableTracking:(BOOL)isEnabled andEraseNonSyncedData:(BOOL)shouldEraseEventsData {
    @try {
        NSString *val = isEnabled ? kYES : kNO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:val forKey:kBlueshiftEnableTracking];
        [defaults synchronize];

        if (shouldEraseEventsData) {
            // Erase existing batched and non-batched events after disabling the tracking
            [HttpRequestOperationEntity eraseEntityData];
            [BatchEventEntity eraseEntityData];
        }
        
        if(isEnabled) {
            [BlueshiftLog logInfo:@"The SDK event tracking has been enabled. SDK will now send the events to the Blueshift server." withDetails:nil methodName:nil];
        } else {
            [BlueshiftLog logInfo:@"The SDK event tracking has been disabled. SDK will not send any events to the Blueshift server." withDetails:nil methodName:nil];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (BOOL)isTrackingEnabled {
    NSString *status = [[NSUserDefaults standardUserDefaults] stringForKey:kBlueshiftEnableTracking];
    if (status == nil) {
        return YES;
    }
    return [status isEqual:kYES] ? YES : NO;
}

#pragma mark Opt In in-app notifications
- (void)optInForInAppNotifications:(BOOL)isOptedIn {
    [BlueShiftAppData currentAppData].enableInApp = isOptedIn;
    [[BlueShift sharedInstance]identifyUserWithDetails:nil canBatchThisEvent:NO];
}

#pragma mark Opt In push notifications
- (void)optInForPushNotifications:(BOOL)isOptedIn {
    [BlueShiftAppData currentAppData].enablePush = isOptedIn;
    [[BlueShift sharedInstance]identifyUserWithDetails:nil canBatchThisEvent:NO];
}

#pragma mark IsBlueshift data
- (BOOL)isBlueshiftUniversalLinkURL:(NSURL *)url {
    if (url != nil) {
        NSMutableDictionary *queriesPayload = [BlueshiftEventAnalyticsHelper getQueriesFromURL: url];
        if ((queriesPayload && ([queriesPayload objectForKey: kInAppNotificationModalUIDKey] &&
                        [queriesPayload objectForKey: kInAppNotificationModalMIDKey])) ||
                        [url.absoluteString rangeOfString:kUniversalLinkShortURLKey].location != NSNotFound) {
            return true;
        }
    }
    return false;
}

- (BOOL)isBlueshiftPushNotification:(NSDictionary *)userInfo {
    if (userInfo && [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey]) {
        return  YES;
    }
    return  NO;
}

- (BOOL)isBlueshiftPushCustomActionResponse:(UNNotificationResponse *)response {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if (userInfo && [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey] && [userInfo valueForKey:kNotificationActions] && ![response.actionIdentifier isEqualToString:kUNNotificationDefaultActionIdentifier] && ![BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload:userInfo]) {
        return  YES;
    }
    return  NO;
}

- (BOOL)isBlueshiftOpenURLData:(NSURL*)url additionalData:(NSDictionary<UIApplicationOpenURLOptionsKey,id> * _Nonnull)urlOptions {
    if (url && urlOptions && [urlOptions[openURLOptionsSource] isEqual:openURLOptionsBlueshift]) {
        return YES;
    }
    return NO;
}

#pragma mark Mobile Inbox
- (BOOL)createInAppNotificationForInboxMessage:(BlueshiftInboxMessage* _Nullable)message inboxInAppDelegate:(id<BlueshiftInboxInAppNotificationDelegate> _Nullable)inboxInAppDelegate {
    if (message && message.messagePayload && _inAppNotificationMananger.currentNotificationController == nil) {
        BlueShiftInAppNotification* inApp = [[BlueShiftInAppNotification alloc] initFromPayload:message.messagePayload forType:message.inAppNotificationType];
        inApp.isFromInbox = YES;
        inApp.inboxDelegate = inboxInAppDelegate;
        [_inAppNotificationMananger createInAppNotification:inApp displayOnScreen:@""];
        return YES;
    }
    [BlueshiftLog logInfo:@"Active In-app notification detected or message payload is nil, skipped displaying current inbox message." withDetails:nil methodName:nil];
    return NO;
}

#pragma mark Auto send app install/app update

/// Automatically detects new App install or App update and sends the app_install or app_update event to Blueshift.
- (void)trackAppInstallOrUpdateEvent {
    @try {
        NSString* savedAppVersion = [[NSUserDefaults standardUserDefaults] valueForKey:kBSLastOpenedAppVersion];
        NSString* lastModifiedUNAuthorizationStatus = [self.appDelegate getLastModifiedUNAuthorizationStatus];
        NSString *currentAppVersion = BlueShiftAppData.currentAppData.appVersion;
        
        if (!savedAppVersion && !lastModifiedUNAuthorizationStatus) {
            //New app install
            [self updateCurrentAppversion:currentAppVersion];
            NSDictionary * params = @{kBSAppInstalledAt: [BlueshiftEventAnalyticsHelper getCurrentUTCTimestamp]};
            [self trackEventForEventName:kBSAppInstallEvent andParameters:params canBatchThisEvent:NO];
        } else {
            if (!savedAppVersion) {
                //SDK update from old version to app_install supported version
                //Send App update
                [self updateCurrentAppversion:currentAppVersion];
                NSDictionary * params = @{kBSAppUpdatedAt: [BlueshiftEventAnalyticsHelper getCurrentUTCTimestamp]};
                [self trackEventForEventName:kBSAppUpdateEvent andParameters:params canBatchThisEvent:NO];
            } else if (![savedAppVersion isEqualToString:currentAppVersion]) {
                //App update
                [self updateCurrentAppversion:currentAppVersion];
                NSDictionary * params = @{kBSPrevAppVersion: savedAppVersion,
                                          kBSAppUpdatedAt: [BlueshiftEventAnalyticsHelper getCurrentUTCTimestamp]};
                [self trackEventForEventName:kBSAppUpdateEvent andParameters:params canBatchThisEvent:NO];
            }
        }
    } @catch (NSException *exception) {
    }
}

- (void)updateCurrentAppversion:(NSString*)currentAppVersion {
    [[NSUserDefaults standardUserDefaults] setValue:currentAppVersion forKey:kBSLastOpenedAppVersion];
}

@end
