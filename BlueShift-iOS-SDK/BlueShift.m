//
//  BlueShift.m
//  BlueShift
//
//  Created by Asif on 2/16/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "BlueShift.h"

BlueShiftAppDelegate *_newDelegate;
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
    [[BlueShift sharedInstance] performSelectorInBackground:@selector(setupWithConfiguration:) withObject:config];
}

- (void) setupWithConfiguration:(BlueShiftConfig *)config {
    NSLog(@"\n\n Intializing BlueShift library \n\n");
    
    // validating the configuration details set by the user ...
    BOOL configurationSetCorrectly = [config validateConfigDetails];

    if (configurationSetCorrectly == NO) {
        return ;
    }
    
    // setting config ...
    _sharedBlueShiftInstance.config = config;
    _sharedBlueShiftInstance.deviceData = [[BlueShiftDeviceData alloc] init];
    
    // Initialize deeplinks ...
    [self initDeepLinks];
    
    // Getting the original Delegate ...
    NSObject<UIApplicationDelegate> *oldDelegate = [UIApplication sharedApplication].delegate;
    
    // initiating the newDelegate ...
    _newDelegate = [[BlueShiftAppDelegate alloc] init];
    
    // assigning the current application delegate with the app delegate we are going to use in the SDK ...
    [UIApplication sharedApplication].delegate = _newDelegate;
    
    // setting the new delegate's old delegate with the original delegate we saved...
    BlueShiftAppDelegate *blueShiftAppDelegate = (BlueShiftAppDelegate *)_newDelegate;
    blueShiftAppDelegate.oldDelegate = oldDelegate;
    
    [blueShiftAppDelegate registerForNotification]; 
    [blueShiftAppDelegate registerLocationService];
    //blueShiftAppDelegate.blueShiftPushDelegate = oldDelegate;
    [blueShiftAppDelegate handleRemoteNotificationOnLaunchWithLaunchOptions:config.applicationLaunchOptions];
    
    [BlueShiftNetworkReachabilityManager monitorNetworkConnectivity];
    NSLog(@"\n\n BlueShift initialization completed successfully \n\n");
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

- (NSString *) getDeviceToken {
    return _deviceToken;
}


- (void)identifyUserWithDetails:(NSDictionary *)details {
    [self identifyUserWithEmail:[BlueShiftUserInfo sharedUserInfo].email andDetails:details];
}

- (void)identifyUserWithEmail:(NSString *)email andDetails:(NSDictionary *)details {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    if (email) {
        [parameterMutableDictionary setObject:email forKey:@"email"];
    }
    
    if (details) {
        [parameterMutableDictionary addEntriesFromDictionary:details];
    }
    [self trackEventForEventName:kEventIdentify andParameters:details];
}

- (void)trackScreenViewedForViewController:(UIViewController *)viewController {
    [self trackScreenViewedForViewController:viewController withParameters:nil];
}


- (void)trackScreenViewedForViewController:(UIViewController *)viewController withParameters:(NSDictionary *)parameters {
    NSString *viewControllerString = @"";
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (viewController) {
        viewControllerString = NSStringFromClass([viewController class]);
        [parameterMutableDictionary setObject:viewControllerString forKey:@"screen_viewed"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventPageLoad andParameters:[parameterMutableDictionary copy]];
}


- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID {
    [self trackProductViewedWithSKU:sku andCategoryID:categoryID withParameter:nil];
}


- (void)trackProductViewedWithSKU:(NSString *)sku andCategoryID:(NSInteger)categoryID withParameter:(NSDictionary *)parameters {
    
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
    
    [self trackEventForEventName:kEventProductViewed andParameters:[parameterMutableDictionary copy]];
}


- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity {
    [self trackAddToCartWithSKU:sku andQuantity:quantity andParameters:nil];
}


- (void)trackAddToCartWithSKU:(NSString *)sku andQuantity:(NSInteger)quantity andParameters:(NSDictionary *)parameters {
    
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
    
    [self trackEventForEventName:kEventAddToCart andParameters:[parameterMutableDictionary copy]];
}


- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon {
    [self trackCheckOutCartWithProducts:products andRevenue:revenue andDiscount:discount andCoupon:coupon andParameters:nil];
    
}


- (void)trackCheckOutCartWithProducts:(NSArray *)products andRevenue:(float)revenue andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters {
    
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
    
    
    [self trackEventForEventName:kEventCheckout andParameters:[parameterMutableDictionary copy]];
}


- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon {
    
    [self trackProductsPurchased:products withOrderID:orderID andRevenue:revenue andShippingCost:shippingCost andDiscount:discount andCoupon:coupon andParameters:nil];
    
}


- (void)trackProductsPurchased:(NSArray *)products withOrderID:(NSString *)orderID andRevenue:(float)revenue andShippingCost:(float)shippingCost andDiscount:(float)discount andCoupon:(NSString *)coupon andParameters:(NSDictionary *)parameters {
    
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
    
    [self trackEventForEventName:kEventPurchase andParameters:[parameterMutableDictionary copy]];
    
}


- (void)trackPurchaseCancelForOrderID:(NSString *)orderID {
    [self trackPurchaseCancelForOrderID:orderID andParameters:nil];
}


- (void)trackPurchaseCancelForOrderID:(NSString *)orderID andParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (orderID) {
        [parameterMutableDictionary setObject:orderID forKey:@"order_id"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventCancel andParameters:[parameterMutableDictionary copy]];
    
}


- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products {
    [self trackPurchaseReturnForOrderID:orderID andProducts:products andParameters:nil];
}


- (void)trackPurchaseReturnForOrderID:(NSString *)orderID andProducts:(NSArray *)products andParameters:(NSDictionary *)parameters {
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
    
    [self trackEventForEventName:kEventReturn andParameters:[parameterMutableDictionary copy]];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters {
    [self trackProductSearchWithSkuArray:skuArray andNumberOfResults:numberOfResults andPageNumber:pageNumber andQuery:query andFilters:filters andParameters:nil];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andParameters:(NSDictionary *)parameters {
    [self trackProductSearchWithSkuArray:skuArray andNumberOfResults:numberOfResults andPageNumber:pageNumber andQuery:query andFilters:nil andParameters:parameters];
}


- (void)trackProductSearchWithSkuArray:(NSArray *)skuArray andNumberOfResults:(NSInteger)numberOfResults andPageNumber:(NSInteger)pageNumber andQuery:(NSString *)query andFilters:(NSDictionary *)filters andParameters:(NSDictionary *)parameters {
    
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
    
    [self trackEventForEventName:kEventSearch andParameters:[parameterMutableDictionary copy]];
    
}


- (void)trackEmailListSubscriptionForEmail:(NSString *)email {
    [self trackEmailListSubscriptionForEmail:email andParameters:nil];
}


- (void)trackEmailListSubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (email) {
        [parameterMutableDictionary setObject:email forKey:@"email"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventSubscribeMailing andParameters:[parameterMutableDictionary copy]];
}


- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email {
    [self trackEmailListUnsubscriptionForEmail:email andParameters:nil];
}


- (void)trackEmailListUnsubscriptionForEmail:(NSString *)email andParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (email) {
        [parameterMutableDictionary setObject:email forKey:@"email"];
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self trackEventForEventName:kEventUnSubscribeMailing andParameters:[parameterMutableDictionary copy]];
}


- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate {
    
    [self trackSubscriptionInitializationForSubscriptionState:subscriptionState andCycleType:cycleType andCycleLength:cycleLength andSubscriptionType:subscriptionType andPrice:price andStartDate:startDate andParameters:nil];
}


- (void)trackSubscriptionInitializationForSubscriptionState:(BlueShiftSubscriptionState)subscriptionState andCycleType:(NSString *)cycleType andCycleLength:(NSInteger)cycleLength andSubscriptionType:(NSString *)subscriptionType andPrice:(float)price andStartDate:(NSTimeInterval)startDate andParameters:(NSDictionary *)parameters {
    
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
    
    [self trackEventForEventName:subscriptionEventName andParameters:[parameterMutableDictionary copy]];
    
}


- (void)trackSubscriptionPause {
    [self trackSubscriptionPauseWithParameters:nil];
}


- (void)trackSubscriptionPauseWithParameters:(NSDictionary *)parameters {
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
    
    [self trackEventForEventName:kEventSubscriptionDowngrade andParameters:[parameterMutableDictionary copy]];
}


- (void)trackSubscriptionUnpause {
    [self trackSubscriptionUnpauseWithParameters:nil];
}


- (void)trackSubscriptionUnpauseWithParameters:(NSDictionary *)parameters {
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
    
    [self trackEventForEventName:kEventSubscriptionUpgrade andParameters:[parameterMutableDictionary copy]];
}


- (void)trackSubscriptionCancel {
    [self trackSubscriptionCancelWithParamters:nil];
}


- (void)trackSubscriptionCancelWithParamters:(NSDictionary *)parameters {
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
    
    [self trackEventForEventName:kEventSubscriptionCancel andParameters:[parameterMutableDictionary copy]];
}


- (void)trackEventForEventName:(NSString *)eventName {
    [self trackEventForEventName:eventName andParameters:nil];
}

- (void)trackEventForEventName:(NSString *)eventName andParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    [parameterMutableDictionary setObject:eventName forKey:kEventGeneric];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self performRequestWithRequestParameters:[parameterMutableDictionary copy]];
}

- (void)performRequestWithRequestParameters:(NSDictionary *)requestParameters {
    NSString *url = kBaseURL;
    
    NSMutableDictionary *requestMutableParameters = [requestParameters mutableCopy];
    [requestMutableParameters addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];

    if ([BlueShiftUserInfo sharedUserInfo]==nil) {
        NSLog(@"\n\n BlueShift Warning: Please set BlueShiftUserInfo for sending retailer customer ID, email and so on.");
    }
    else {
        NSString *email = [requestMutableParameters objectForKey:@"email"];
        NSMutableDictionary *blueShiftUserInfoMutableDictionary = [[BlueShiftUserInfo sharedUserInfo].toDictionary mutableCopy];
        
        if (email) {
            if ([blueShiftUserInfoMutableDictionary objectForKey:@"email"]) {
                [blueShiftUserInfoMutableDictionary removeObjectForKey:@"email"];
            }
        }
        
        [requestMutableParameters addEntriesFromDictionary:[blueShiftUserInfoMutableDictionary copy]];
    }
    
    
    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodPOST andParameters:[requestMutableParameters copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0];
    [BlueShiftRequestQueue addRequestOperation:requestOperation];
    
    
}

@end
