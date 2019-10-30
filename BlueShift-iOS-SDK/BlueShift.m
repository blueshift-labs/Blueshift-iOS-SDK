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

BlueShiftAppDelegate *_newDelegate;
BlueShiftInAppNotificationManager *_inAppNotificationMananger;
static BlueShift *_sharedBlueShiftInstance = nil;

@implementation BlueShift

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedBlueShiftInstance = [[self alloc] init];
    });
    return _sharedBlueShiftInstance;
}

+ (void) initWithConfiguration:(BlueShiftConfig *)config {
    [[BlueShift sharedInstance] setupWithConfiguration:config];
}

+ (void) autoIntegration {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[BlueShift sharedInstance] setAppDelegate];
    });
}

- (void)setAppDelegate {
    [UIApplication sharedApplication].delegate = [BlueShift sharedInstance].appDelegate;
}

- (void)setUserNotificationDelegate {
    BlueShiftUserNotificationCenterDelegate *blueShiftUserNotificationCenterDelegate = [[BlueShiftUserNotificationCenterDelegate alloc] init];
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = blueShiftUserNotificationCenterDelegate;
    }
}

- (void) setupWithConfiguration:(BlueShiftConfig *)config {
    // validating the configuration details set by the user ...
    BOOL configurationSetCorrectly = [config validateConfigDetails];

    if (configurationSetCorrectly == NO) {
        return ;
    }
    
    // setting config ...
    _sharedBlueShiftInstance.config = config;
    _sharedBlueShiftInstance.deviceData = [[BlueShiftDeviceData alloc] init];
    _sharedBlueShiftInstance.appData = [[BlueShiftAppData alloc] init];
    if (@available(iOS 10.0, *)) {
        _sharedBlueShiftInstance.pushNotification = [[BlueShiftPushNotificationSettings alloc] init];
        _sharedBlueShiftInstance.userNotification = [[BlueShiftUserNotificationSettings alloc] init];
    }
    // Initialize deeplinks ...
    [self initDeepLinks];
    
    // Getting the original Delegate ...
    NSObject<UIApplicationDelegate> *oldDelegate = [UIApplication sharedApplication].delegate;
    
    // initiating the newDelegate ...
    _newDelegate = [[BlueShiftAppDelegate alloc] init];
    BlueShiftUserNotificationCenterDelegate *blueShiftUserNotificationCenterDelegate = [[BlueShiftUserNotificationCenterDelegate alloc] init];
    // assigning the current application delegate with the app delegate we are going to use in the SDK ...
    _sharedBlueShiftInstance.appDelegate = _newDelegate;
    _sharedBlueShiftInstance.userNotificationDelegate = blueShiftUserNotificationCenterDelegate;
    // setting the new delegate's old delegate with the original delegate we saved...
    BlueShiftAppDelegate *blueShiftAppDelegate = (BlueShiftAppDelegate *)_newDelegate;
    blueShiftAppDelegate.oldDelegate = oldDelegate;
    if (@available(iOS 10.0, *)) {
        if(config.userNotificationDelegate) {
            blueShiftAppDelegate.userNotificationDelegate = config.userNotificationDelegate;
        } else {
            blueShiftAppDelegate.userNotificationDelegate = blueShiftUserNotificationCenterDelegate;
        }
    }
    
    if(config.blueShiftPushDelegate) {
        blueShiftAppDelegate.blueShiftPushDelegate = config.blueShiftPushDelegate;
    }
    
    
    if (config.enableAnalytics == YES) {
        // Start periodic batch upload timer
        [BlueShiftHttpRequestBatchUpload startBatchUpload];
    }
    if (config.enablePushNotification == YES) {
        [blueShiftAppDelegate registerForNotification];
        [blueShiftAppDelegate handleRemoteNotificationOnLaunchWithLaunchOptions:config.applicationLaunchOptions];
    }
    if (config.enableLocationAccess == YES) {
        [blueShiftAppDelegate registerLocationService];
    }
    
    // Initialize In App Manager
    _inAppNotificationMananger = [[BlueShiftInAppNotificationManager alloc] init];
    if (config.inAppNotificationDelegate) {
        _inAppNotificationMananger.inAppNotificationDelegate = config.inAppNotificationDelegate;
    }
    
    if (config.enableInAppNotification == YES && config.inAppManualTriggerEnabled == NO) {
        [_inAppNotificationMananger load];
        
        if (config.BlueshiftInAppNotificationTimeInterval) {
            _inAppNotificationMananger.inAppNotificationTimeInterval = config.BlueshiftInAppNotificationTimeInterval;
        } else {
            _inAppNotificationMananger.inAppNotificationTimeInterval = 60;
        }
        
        [self fetchInAppNotificationFromAPI:^(){
            [_inAppNotificationMananger fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
        }];
    }
    
    [BlueShiftNetworkReachabilityManager monitorNetworkConnectivity];
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

- (void) setPushDelegate:(id)obj {
    if (_newDelegate != nil) {
        _newDelegate.blueShiftPushDelegate = obj;
    }
}

- (void) setPushParamDelegate:(id)obj {
    if (_newDelegate !=nil) {
        _newDelegate.blueShiftPushParamDelegate = obj;
    }
}

- (void)setDeviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[BlueShiftDeviceData currentDeviceData].deviceToken forKey:@"deviceToken"];
    [defaults synchronize];
}

- (NSString *) getDeviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _deviceToken = (NSString *)[defaults objectForKey:@"deviceToken"];
    return _deviceToken;
}

- (void) createInAppNotification:(NSDictionary *)dictionary forApplicationState:(UIApplicationState)applicationState {
    if (_config.enableInAppNotification == YES && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && _config.inAppManualTriggerEnabled == NO) {
        [self startInAppMessageLoadFromaDBTimer];
    }
}

- (void) fetchInAppNotificationFromDB{
    [_inAppNotificationMananger fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
    [self stopInAppMessageLoadDBTimer];
}


- (void)identifyUserWithDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent {
    [self identifyUserWithEmail:[BlueShiftUserInfo sharedInstance].email andDetails:details canBatchThisEvent:isBatchEvent];
}

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary *)details canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    if (email) {
        [parameterMutableDictionary setObject:email forKey:@"email"];
    }
    
    if (details) {
        [parameterMutableDictionary addEntriesFromDictionary:details];
    }
    [self trackEventForEventName:kEventIdentify andParameters:details canBatchThisEvent:isBatchEvent];
}

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
        [parameterMutableDictionary setObject:email forKey:@"email"];
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
        [parameterMutableDictionary setObject:email forKey:@"email"];
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
    NSString *subscriptionEventName;
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
        NSLog(@"\n\n Error: Could not pause subscription. Please initialize the subscription \n\n");
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
        NSLog(@"\n\n Error: Could not unpause subscription. Please initialize the subscription \n\n");
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
        NSLog(@"\n\n Error: Could not cancel subscription. Please initialize the subscription \n\n");
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
    [parameterMutableDictionary setObject:eventName forKey:kEventGeneric];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    [parameterMutableDictionary setObject:kSDKVersionNumber forKey:@"bsft_sdk_version"];
    
    [self performRequestWithRequestParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}

- (void)performRequestWithRequestParameters:(NSDictionary *)requestParameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSString *url = [[NSString alloc]init];
    if(isBatchEvent) {
        url = [NSString stringWithFormat:@"%@%@", kBaseURL, kBatchUploadURL];
    } else {
        url = [NSString stringWithFormat:@"%@%@", kBaseURL, kRealTimeUploadURL];
    }
    
    NSMutableDictionary *requestMutableParameters = [requestParameters mutableCopy];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftAppData currentAppData].toDictionary];
    if ([BlueShiftUserInfo sharedInstance]==nil) {
        NSLog(@"\n\n BlueShift Warning: Please set BlueShiftUserInfo for sending retailer customer ID, email and so on.");
    }
    else {
        NSString *email = [requestMutableParameters objectForKey:@"email"];
        NSMutableDictionary *blueShiftUserInfoMutableDictionary = [[BlueShiftUserInfo sharedInstance].toDictionary mutableCopy];
        
        if (email) {
            if ([blueShiftUserInfoMutableDictionary objectForKey:@"email"]) {
                [blueShiftUserInfoMutableDictionary removeObjectForKey:@"email"];
            }
        }
        
        [requestMutableParameters addEntriesFromDictionary:[blueShiftUserInfoMutableDictionary copy]];
    }
    
    
    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodPOST andParameters:[requestMutableParameters copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
    [BlueShiftRequestQueue addRequestOperation:requestOperation];
}

- (void)sendPushAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics:userInfo]) {
        NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary: userInfo];
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        
        if (pushTrackParameterDictionary) {
            [parameterMutableDictionary addEntriesFromDictionary:pushTrackParameterDictionary];
        }
        
        [parameterMutableDictionary setObject:type forKey:@"a"];
        
        NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kPushEventsUploadURL];
        BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodGET andParameters:[parameterMutableDictionary copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
        [BlueShiftRequestQueue addRequestOperation:requestOperation];
    }
}

- (void)trackPushClickedWithParameters:(NSDictionary *)userInfo canBatchThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"click" withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackPushViewedWithParameters:(NSDictionary *)userInfo canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"delivered" withParams:userInfo canBatchThisEvent:isBatchEvent];
}

- (void)trackInAppNotificationDeliveredWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"delivered" withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationShowingWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"open" withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationButtonTappedWithParameter:(NSDictionary *)notification canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"click" withParams: notification canBatchThisEvent: isBatchEvent];
}

- (void)trackInAppNotificationDismissWithParameter:(NSDictionary *)notificationPayload
                                 canBacthThisEvent:(BOOL)isBatchEvent {
    [self sendPushAnalytics:@"dismiss" withParams: notificationPayload canBatchThisEvent: isBatchEvent];
}

- (void)startInAppMessageLoadFromaDBTimer {
    if (nil == self.inAppDBTimer) {
        self.inAppDBTimer =  [NSTimer scheduledTimerWithTimeInterval: 2
                                                                  target:self
                                                                selector:@selector(fetchInAppNotificationFromDB)
                                                                userInfo:nil
                                                                 repeats:NO];
    }
}

- (void) stopInAppMessageLoadDBTimer {
    if (nil != self.inAppDBTimer) {
        [self.inAppDBTimer invalidate];
        self.inAppDBTimer = nil;
    }
}

- (void)registerForInAppMessage:(NSString *)displayPage {
    if (_inAppNotificationMananger && _config.inAppManualTriggerEnabled == NO) {
        if (displayPage) {
            _inAppNotificationMananger.inAppNotificationDisplayOnPage = displayPage;
        } else {
            _inAppNotificationMananger.inAppNotificationDisplayOnPage = @"";
        }
    
        [_inAppNotificationMananger fetchInAppNotificationsFromDataStore: BlueShiftInAppTriggerNow];
    }
}

- (void)unregisterForInAppMessage {
    if (_inAppNotificationMananger && _config.inAppManualTriggerEnabled == NO) {
        _inAppNotificationMananger.inAppNotificationDisplayOnPage = @"";
    }
}

- (void)displayInAppNotification {
    if (_inAppNotificationMananger && _config.inAppManualTriggerEnabled == YES) {
        [_inAppNotificationMananger fetchInAppNotificationsFromDataStore: BlueShiftInAppNoTriggerEvent];
        [_inAppNotificationMananger deleteExpireInAppNotificationFromDataStore];
    }
}

- (void)fetchInAppNotificationFromAPI:(void (^_Nonnull)(void))handler {
    if (_config.enableInAppNotification == YES) {
        [_inAppNotificationMananger fetchLastInAppMessageIDFromDB:^(BOOL status, NSString *notificationID, NSString *lastTimestamp) {
            if (status) {
                [BlueshiftInAppNotificationRequest fetchInAppNotification: notificationID andLastTimestamp:lastTimestamp success:^(NSDictionary *dictionary){
                    if ([dictionary objectForKey: kInAppNotificationContentPayloadKey]) {
                        NSMutableArray *notificationArray = [dictionary objectForKey: kInAppNotificationContentPayloadKey];
                        [_inAppNotificationMananger initializeInAppNotificationFromAPI:notificationArray handler:^(BOOL status){
                            handler();
                        }];
                    }
                } failure:^(NSError *error){
                    NSLog(@"Failed");
                    handler();
                }];
            } else {
                NSLog(@"Failed");
                handler();
            }
        }];
    }
}

@end
