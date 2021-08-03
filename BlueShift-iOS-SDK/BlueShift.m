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

BlueShiftInAppNotificationManager *_inAppNotificationMananger;
static BlueShift *_sharedBlueShiftInstance = nil;

@implementation BlueShift

static dispatch_queue_t bsft_serial_queue() {
    static dispatch_queue_t bsft_serial_queue;
    static dispatch_once_t s_done;
    dispatch_once(&s_done, ^{
        bsft_serial_queue = dispatch_queue_create(kBSSerialQueue, DISPATCH_QUEUE_SERIAL);
    });
    return bsft_serial_queue;
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

- (void) setupWithConfiguration:(BlueShiftConfig *)config {
    @try {
        // Validate the API key
        if ([config validateConfigDetails] == NO) {
            return ;
        }
        
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
        
        // Initialise core data
        [_sharedBlueShiftInstance.appDelegate initializeCoreData];
        
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
        
        // Initialize custom deeplinks
        [self initDeepLinks];
        
        // Push notification callback delegate
        if(config.blueShiftPushDelegate) {
            _sharedBlueShiftInstance.appDelegate.blueShiftPushDelegate = config.blueShiftPushDelegate;
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
        }
        
        // Initialise timer for batch upload
        [BlueShiftHttpRequestBatchUpload startBatchUpload];
        
        // Initialize In App Manager
        _inAppNotificationMananger = [[BlueShiftInAppNotificationManager alloc] init];
        if (config.inAppNotificationDelegate) {
            _inAppNotificationMananger.inAppNotificationDelegate = config.inAppNotificationDelegate;
        }
        
        if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES && config.inAppManualTriggerEnabled == NO) {
            _inAppNotificationMananger.inAppNotificationTimeInterval = [NSNumber numberWithDouble:config.BlueshiftInAppNotificationTimeInterval];
            [_inAppNotificationMananger load];
            
            [self fetchInAppNotificationFromAPI:^(void) {
                [self fetchInAppNotificationFromDBforApplicationState:UIApplicationStateActive];
            } failure:^(NSError *error){ }];
        }
        
        [self setupObservers];
        
        [self logSDKInitializationDetails];
        
        [[BlueShiftDeviceData currentDeviceData] saveDeviceDataForNotificationExtensionUse];
        
        // Fire app open if device token is already present, else delay it till app receives device token.
        if ([self getDeviceToken]) {
            [_sharedBlueShiftInstance.appDelegate trackAppOpenOnAppLaunch:nil];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:@"Failed to initialise SDK." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
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
    BOOL isSceneDelegateConfiguration = NO;
    // If sceneDelegate enabled app, then set scene lifecycle notification observers
    if (@available(iOS 13.0, *)) {
        if ([BlueShift sharedInstance].config.isSceneDelegateConfiguration == YES) {
            isSceneDelegateConfiguration = YES;
            [[NSNotificationCenter defaultCenter] addObserverForName:UISceneWillEnterForegroundNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [[BlueShift sharedInstance].appDelegate checkUNAuthorizationStatus];
            }];
        }
    }
    
    // If non sceneDelegate enabled app, then set app lifecycle notification observers
    if (isSceneDelegateConfiguration == NO) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [[BlueShift sharedInstance].appDelegate checkUNAuthorizationStatus];
        }];
    }
}

- (void)initDeepLinks {
    
    BlueShiftDeepLink *deepLink;
    
    // map newly allocated deeplink instance to product page route ...
    deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkRouteProductPage andNSURL:self.config.productPageURL];
    [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkRouteProductPage];
    
    // map newly allocated deeplink instance to cart page route ...
    deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkRouteCartPage andNSURL:self.config.cartPageURL];
    [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkRouteCartPage];
    
    // map newly allocated deeplink instance to cart page route ...
    deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkRouteOfferPage andNSURL:self.config.offerPageURL];
    [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkRouteOfferPage];
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

#pragma mark Device token
- (void)setDeviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[BlueShiftDeviceData currentDeviceData].deviceToken forKey:kBlueshiftDeviceToken];
    [defaults synchronize];
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
    NSString *viewControllerString = @"";
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (viewController) {
        viewControllerString = NSStringFromClass([viewController class]);
        [parameterMutableDictionary setObject:viewControllerString forKey:@"screen_viewed"];
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
    if (eventName) {
        [parameterMutableDictionary setObject:eventName forKey:kEventGeneric];
    }
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }    
    [self performRequestWithRequestParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}

#pragma mark Process custom and tracking events

/// Add event to event processing queue
/// @param requestParameters event parameters
/// @param isBatchEvent  BOOL to determine if the event needs to be batched or not.
- (void)performRequestWithRequestParameters:(NSDictionary *)requestParameters canBatchThisEvent:(BOOL)isBatchEvent{
    if([self validateSDKTrackingRequirements] == false) {
        return;
    }
    NSString *url = nil;
    if(isBatchEvent) {
        url = [NSString stringWithFormat:@"%@%@", kBaseURL, kBatchUploadURL];
    } else {
        url = [NSString stringWithFormat:@"%@%@", kBaseURL, kRealTimeUploadURL];
    }
    NSDictionary* eventParams = [self addDefaultParamsToDictionary:requestParameters];
    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodPOST andParameters:[eventParams copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
    
    dispatch_async(bsft_serial_queue(), ^{
        [BlueShiftRequestQueue addRequestOperation:requestOperation];
    });
}

-(NSDictionary*)addDefaultParamsToDictionary:(NSDictionary*)requestParameters {
    NSMutableDictionary *requestMutableParameters = [[NSMutableDictionary alloc] init];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftAppData currentAppData].toDictionary];
    if ([BlueShiftUserInfo sharedInstance]==nil) {
        [BlueshiftLog logInfo:[NSString stringWithFormat:@"Please set BlueshiftUserInfo for sending the user attributes such as email id, customer id"] withDetails:nil methodName:nil];
    } else {
        NSString *email = [requestMutableParameters objectForKey:kEmail];
        NSMutableDictionary *blueShiftUserInfoMutableDictionary = [[BlueShiftUserInfo sharedInstance].toDictionary mutableCopy];
        
        if (email) {
            if ([blueShiftUserInfoMutableDictionary objectForKey:kEmail]) {
                [blueShiftUserInfoMutableDictionary removeObjectForKey:kEmail];
            }
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

- (void)performRequestQueue:(NSMutableDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    if([self validateSDKTrackingRequirements] == false) {
        return;
    }
    dispatch_async(bsft_serial_queue(), ^{
        if (parameters != nil) {
            NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kPushEventsUploadURL];
            BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodGET andParameters:[parameters copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
            [BlueShiftRequestQueue addRequestOperation:requestOperation];
        }
    });
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
    [self sendPushAnalytics:kBSClick withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:kBSDelivered withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackInAppNotificationDeliveredWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:kBSDelivered withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationShowingWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:kBSOpen withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationButtonTappedWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:kBSClick withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationDismissWithParameter:(NSDictionary *)notificationPayload canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:kBSDismiss withParams: notificationPayload canBatchThisEvent: isBatchEvent];
}

- (void)sendPushAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics:userInfo]) {
        NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary: userInfo];
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        
        if (pushTrackParameterDictionary) {
            [parameterMutableDictionary addEntriesFromDictionary:pushTrackParameterDictionary];
        }
        if (type) {
            [parameterMutableDictionary setObject:type forKey:kBSAction];
        }
        [self performRequestQueue:parameterMutableDictionary canBatchThisEvent:isBatchEvent];
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
        [BlueshiftLog logInfo:@"Successfully unegistered for in-app for screen " withDetails:_inAppNotificationMananger.inAppNotificationDisplayOnPage methodName:nil];
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
        [_inAppNotificationMananger deleteExpireInAppNotificationFromDataStore];
    }
}

- (void)handleSilentPushNotification:(NSDictionary *)dictionary forApplicationState:(UIApplicationState)applicationState {
    [BlueshiftLog logInfo:@"Silent push notification received - " withDetails:dictionary methodName:nil];
    if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES) {
        if ([BlueshiftEventAnalyticsHelper isFetchInAppAction: dictionary] && _config.inAppBackgroundFetchEnabled == YES) {
            [self fetchInAppNotificationFromAPI:^() {
                if (self->_config.inAppManualTriggerEnabled == NO) {
                         [self fetchInAppNotificationFromDBforApplicationState:applicationState];
                    }
                } failure:^(NSError *error){ }];
        } else if ([BlueshiftEventAnalyticsHelper isMarkInAppAsOpen:dictionary]) {
            if (_inAppNotificationMananger) {
                NSDictionary *silentPushData = [[dictionary objectForKey: kSilentNotificationPayloadIdentifierKey] objectForKey: kInAppNotificationModalSilentPushKey];
                NSArray * messageUUIDArray = (NSArray*)[silentPushData objectForKey:kInAppNotificationOpenedInAppUUID];
                [_inAppNotificationMananger markAsDisplayedForNotificationsViewedOnOtherDevice:messageUUIDArray];
            }
        } else if(_config.inAppManualTriggerEnabled == NO){
          [self fetchInAppNotificationFromDBforApplicationState:applicationState];
        }
    }
}

/// Fetch in-app notification from db and display on the screen when app is in active state
- (void)fetchInAppNotificationFromDBforApplicationState:(UIApplicationState)applicationState {
    if (_inAppNotificationMananger && applicationState == UIApplicationStateActive) {
        [_inAppNotificationMananger fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNowAndUpComing];
    }
}


- (void)fetchInAppNotificationFromAPI:(void (^_Nonnull)(void))success failure:(void (^)(NSError*))failure {
    if ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES && _inAppNotificationMananger) {
        [BlueshiftInAppNotificationRequest fetchInAppNotificationWithSuccess:^(NSDictionary * apiResponse) {
            [self handleInAppMessageForAPIResponse:apiResponse withCompletionHandler:^(BOOL status) {
                success();
            }];
        } failure:^(NSError * error) {
            failure(error);
        }];
    } else {
        NSError *error = (NSError*)@"In-app is opted out, can not fetch in-app notifications from API.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

- (void)handleInAppMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler {
    if (apiResponse && [apiResponse objectForKey: kInAppNotificationContentPayloadKey]) {
        NSMutableArray *inAppNotifications = [apiResponse objectForKey: kInAppNotificationContentPayloadKey];
        if (inAppNotifications.count > 0 && _inAppNotificationMananger) {
            [_inAppNotificationMananger initializeInAppNotificationFromAPI:inAppNotifications handler:^(BOOL status) {
                completionHandler(YES);
            }];
        } else {
            completionHandler(YES);
        }
    } else {
        completionHandler(NO);
        [BlueshiftLog logInfo:@"The in-app API response is nil or does not have content attribute." withDetails:nil methodName:nil];
    }
}

- (void)getInAppNotificationAPIPayloadWithCompletionHandler:(void (^)(NSDictionary * _Nullable))completionHandler {
    if (_inAppNotificationMananger) {
        [_inAppNotificationMananger fetchLastInAppMessageIDFromDB:^(BOOL status, NSString * notificationID, NSString * lastTimestamp) {
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

#pragma mark Universal links
- (BOOL)isBlueshiftUniversalLinkURL:(NSURL *)url {
    if (url != nil) {
        NSMutableDictionary *queriesPayload = [BlueshiftEventAnalyticsHelper getQueriesFromURL: url];
        if (queriesPayload && ([queriesPayload objectForKey: kInAppNotificationModalUIDKey] &&
                        [queriesPayload objectForKey: kInAppNotificationModalMIDKey])) {
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

@end
