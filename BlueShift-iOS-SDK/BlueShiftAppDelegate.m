//
//  BlueShiftAppDelegate.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAppDelegate.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueShiftHttpRequestBatchUpload.h"
#import "BlueShiftInAppNotificationManager.h"
#import "BlueShiftInAppNotificationConstant.h"

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation BlueShiftAppDelegate

- (id) init {
    self = [super init];
    if (self) {
        self.deepLinkToCartPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkRouteCartPage];
        self.deepLinkToProductPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkRouteProductPage];
        self.deepLinkToOfferPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkRouteOfferPage];
        
    }
    return self;
}

- (void) registerForNotification {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        if(SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(@"10.0")){
            if (@available(iOS 10.0, *)) {
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                center.delegate = self.userNotificationDelegate;
                [center setNotificationCategories: [[[BlueShift sharedInstance] userNotification] notificationCategories]];
                [center requestAuthorizationWithOptions:([[[BlueShift sharedInstance] userNotification] notificationTypes]) completionHandler:^(BOOL granted, NSError * _Nullable error){
                    if(!error){
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            [[UIApplication sharedApplication] registerForRemoteNotifications];
                        });
                    }
                }];
            }
        } else {
           if (@available(iOS 10.0, *)) {
                UIUserNotificationSettings* notificationSettings = [[[BlueShift sharedInstance] pushNotification] notificationSettings];
                [[UIApplication sharedApplication] registerUserNotificationSettings: notificationSettings];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
        }
        
        [self downloadFileFromURL];
    }
}

// Handles the push notification payload when the app is killed and lauched from push notification tray ...
- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *)launchOptions {
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

    if (userInfo) {
        // Handling the push notification if we get the userInfo from launchOptions ...
        // It's the only way to track notification payload while app is on launch (i.e after the app is killed) ...
        [self handleRemoteNotification:userInfo];
    }
    
    return YES;
}

- (void) registerForRemoteNotification:(NSData *)deviceToken {
    if (@available(iOS 8.0, *)) {
        if ([[[UIApplication sharedApplication] currentUserNotificationSettings] types]) {
            NSDictionary *userInfo =
            [NSDictionary dictionaryWithObject:@YES forKey:[[[BlueShift sharedInstance] config] isEnabledPushNotificationKey]];
            [[NSNotificationCenter defaultCenter] postNotificationName:
             [[[BlueShift sharedInstance] config] blueShiftNotificationName] object:nil userInfo:userInfo];
        }
        else {
            NSDictionary *userInfo =
            [NSDictionary dictionaryWithObject:@NO forKey:[[[BlueShift sharedInstance] config] isEnabledPushNotificationKey]];
            [[NSNotificationCenter defaultCenter] postNotificationName:
             [[[BlueShift sharedInstance] config] blueShiftNotificationName] object:nil userInfo:userInfo];
        }
    } else {
        // Fallback on earlier versions
    }

    NSString *deviceTokenString = [self hexadecimalStringFromData: deviceToken];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [BlueShiftDeviceData currentDeviceData].deviceToken = deviceTokenString;
    NSString *previousDeviceToken = [[BlueShift sharedInstance] getDeviceToken];
    if (previousDeviceToken && deviceTokenString) {
        if(![previousDeviceToken isEqualToString:deviceTokenString]) {
            [self fireIdentifyCall];
        }
    } else if (deviceTokenString) {
        [self fireIdentifyCall];
    }
}

- (NSString *)hexadecimalStringFromData:(NSData *)data {
    NSUInteger dataLength = data.length;
    if (dataLength == 0) {
        return nil;
    }
    
    const unsigned char *dataBuffer = data.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return [hexString copy];
}

- (void)fireIdentifyCall {
    [[BlueShift sharedInstance] setDeviceToken];
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    if (email && ![email isEqualToString:@""]) {
        [[BlueShift sharedInstance] identifyUserWithEmail:email andDetails:nil canBatchThisEvent:NO];
    } else {
        [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [self registerForRemoteNotification:deviceToken];
}

- (void) failedToRegisterForRemoteNotificationWithError:(NSError *)error {
    NSLog(@"\n\n Failed to get push token, error: %@ \n\n", error);
    NSDictionary *userInfo =
    [NSDictionary dictionaryWithObject:@NO forKey:[[[BlueShift sharedInstance] config] isEnabledPushNotificationKey]];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [[[BlueShift sharedInstance] config] blueShiftNotificationName] object:nil userInfo:userInfo];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    [self failedToRegisterForRemoteNotificationWithError:error];
}

- (void) handleRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    self.userInfo = userInfo;
    [self handleRemoteNotification:userInfo forApplicationState:application.applicationState];
    handler(UIBackgroundFetchResultNewData);
}

// Handle silent push notifications when id is sent from backend
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [self handleRemoteNotification:userInfo forApplication:application fetchCompletionHandler:handler];
}

- (void) application:(UIApplication *)application handleRemoteNotification:(NSDictionary *)userInfo {
    self.userInfo = userInfo;
    [self handleRemoteNotification:userInfo forApplicationState:application.applicationState];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo {
    self.userInfo = userInfo;
    [self application:application handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application handleLocalNotification:(nonnull UNNotificationRequest *)notification  API_AVAILABLE(ios(10.0)){
    self.userInfo = notification.content.userInfo;
    [self handleLocalNotification:self.userInfo forApplicationState:application.applicationState];
}

- (void)scheduleLocalNotification:(NSDictionary *)userInfo {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:600];
    localNotification.alertBody = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationAlertIdentifierKey];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    if (@available(iOS 8.0, *)) {
        localNotification.category = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
    }
    localNotification.soundName = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationSoundIdentifierKey];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    dictionary = [userInfo mutableCopy];
    if([dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] == (id)[NSNull null]) {
        [dictionary removeObjectForKey: kInAppNotificationModalMessageUDIDKey];
    }
    localNotification.userInfo = dictionary;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)presentInAppAlert:(NSDictionary *)userInfo {
    // Track notification view when app is open ...
    //[self trackPushViewedWithParameters:pushTrackParameterDictionary];

    // Handle push notification when the app is in active state...
    //UIViewController *topViewController = [self topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    BlueShiftAlertView *pushNotificationAlertView = [[BlueShiftAlertView alloc] init];
    pushNotificationAlertView.alertControllerDelegate = (id<BlueShiftAlertControllerDelegate>)self;
    //UIAlertController *blueShiftAlertViewController = [pushNotificationAlertView alertViewWithPushDetailsDictionary:userInfo];
    //[topViewController presentViewController:blueShiftAlertViewController animated:YES completion:nil];
}

- (void)handleLocalNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
    self.pushAlertDictionary = [userInfo objectForKey: kNotificationAPSIdentifierKey];
    self.userInfo = userInfo;
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
    
    // Way to handle push notification in three states
    if (applicationState == UIApplicationStateActive) {
        [self presentInAppAlert:userInfo];
    } else {
        
        // Handle push notification when the app is in inactive or background state ...
        if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
            [self handleCategoryForBuyUsingPushDetailsDictionary:userInfo];
        } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
            [self handleCategoryForViewCartUsingPushDetailsDictionary:userInfo];
        } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
            [self handleCategoryForPromotionUsingPushDetailsDictionary:userInfo];
        }
        else {
            NSString *categoryName = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
            if(categoryName !=nil && ![categoryName isEqualToString:@""]) {
                if([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
                    [self handleCarouselPushForCategory:categoryName usingPushDetailsDictionary:userInfo];
                } else {
                    [self handleCustomCategory:categoryName UsingPushDetailsDictionary:userInfo];
                }
            } else {
                // Track notification when app is in background and when we click the push notification from tray..
                [self trackPushClickedWithParameters:pushTrackParameterDictionary];
            }
        }
    }
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    /* if there is payload for IAM , give priority to the it */
    if ([BlueshiftEventAnalyticsHelper isInAppMessagePayload: userInfo]) {
        [[BlueShift sharedInstance] createInAppNotification: userInfo forApplicationState: UIApplicationStateActive];
    } else {
        NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
        self.pushAlertDictionary = [userInfo objectForKey: kNotificationAPSIdentifierKey];
        self.userInfo = userInfo;
        NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
        
        if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
            [self handleCategoryForBuyUsingPushDetailsDictionary:userInfo];
        } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
            [self handleCategoryForViewCartUsingPushDetailsDictionary:userInfo];
        } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
            [self handleCategoryForPromotionUsingPushDetailsDictionary:userInfo];
        }
        else {
            NSString *categoryName = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
            if(categoryName !=nil && ![categoryName isEqualToString:@""]) {
                if([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
                    [self handleCarouselPushForCategory:categoryName usingPushDetailsDictionary:userInfo];
                } else {
                    [self handleCustomCategory:categoryName UsingPushDetailsDictionary:userInfo];
                }
            } else {
                // Track notification when app is in background and when we click the push notification from tray..
                [self trackPushClickedWithParameters:pushTrackParameterDictionary];
            }
        }
        
        if (![BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
            [self setupPushNotificationDeeplink: userInfo];
        }
    }
}

- (void)setupPushNotificationDeeplink:(NSDictionary *)userInfo {
    if (userInfo != nil && [userInfo objectForKey: kPushNotificationDeepLinkURLKey] && [userInfo objectForKey: kPushNotificationDeepLinkURLKey] != [NSNull null]) {
        NSURL *deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kPushNotificationDeepLinkURLKey]];
        if ([self.oldDelegate respondsToSelector:@selector(application:openURL:options:)]) {
            if (@available(iOS 9.0, *)) {
                [self.oldDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:@{}];
            }
        }
    }
}

- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
    self.pushAlertDictionary = [userInfo objectForKey: kNotificationAPSIdentifierKey];
    self.userInfo = userInfo;
    
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
    [self trackAppOpenWithParameters:pushTrackParameterDictionary];
    
    // Way to handle push notification in three states
    if (applicationState == UIApplicationStateActive) {
        // Track notification view when app is open ...
        [self trackPushViewedWithParameters:pushTrackParameterDictionary];
        
        if([[userInfo objectForKey: kNotificationTypeIdentifierKey] isEqualToString: kNotificationAlertIdentifierKey]) {
            // Handle push notification when the app is in active state...
            UIViewController *topViewController = [self topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
            BlueShiftAlertView *pushNotificationAlertView = [[BlueShiftAlertView alloc] init];
            pushNotificationAlertView.alertControllerDelegate = (id<BlueShiftAlertControllerDelegate>)self;
            
            if (@available(iOS 8.0, *)) {
                UIAlertController *blueShiftAlertViewController = [pushNotificationAlertView alertViewWithPushDetailsDictionary:userInfo];
                [topViewController presentViewController:blueShiftAlertViewController animated:YES completion:nil];
            }
        } else {
            if ([BlueshiftEventAnalyticsHelper isInAppMessagePayload: userInfo]) {
                [[BlueShift sharedInstance] createInAppNotification: userInfo forApplicationState: applicationState];
            } else {
               // [self scheduleLocalNotification:userInfo];
            }
        }
    } else {
        if ([BlueshiftEventAnalyticsHelper isInAppMessagePayload: userInfo]) {
            [[BlueShift sharedInstance] createInAppNotification: userInfo forApplicationState: applicationState];
        } else {
            // Handle push notification when the app is in inactive or background state ...
            if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
                [self handleCategoryForBuyUsingPushDetailsDictionary:userInfo];
            } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
                [self handleCategoryForViewCartUsingPushDetailsDictionary:userInfo];
            } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
                [self handleCategoryForPromotionUsingPushDetailsDictionary:userInfo];
            }
            else {
                NSString *categoryName = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
                if(categoryName !=nil && ![categoryName isEqualToString:@""]) {
                    if([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
                        [self handleCarouselPushForCategory:categoryName usingPushDetailsDictionary:userInfo];
                    } else {
                        [self handleCustomCategory:categoryName UsingPushDetailsDictionary:userInfo];
                    }
                } else {
                    NSString *urlString = [self.userInfo objectForKey: kPushNotificationDeepLinkURLKey];
                    NSURL *url = [NSURL URLWithString:urlString];
                    if(url) {
                        [self handleCustomCategory:@"" UsingPushDetailsDictionary:userInfo];
                    } else {
                        // Track notification when app is in background and when we click the push notification from tray..
                        [self trackPushClickedWithParameters:pushTrackParameterDictionary];
                    }
                }
            }
            
            if (![BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
                [self setupPushNotificationDeeplink: userInfo];
            }
        }
    }
}

- (BOOL)customDeepLinkToPrimitiveCategory {
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    NSString *urlString = [self.userInfo objectForKey: kPushNotificationDeepLinkURLKey];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if(url != nil) {
        // map newly allocated deeplink instance to product page route ...
        BlueShiftDeepLink *deepLink;
        deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkCustomePage andNSURL:url];
        [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkCustomePage];
        self.deepLinkToCustomPage = deepLink;
        self.deepLinkToCustomPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkCustomePage];
        BOOL status = [self.deepLinkToCustomPage performCustomDeepLinking:url];
        if(status) {
            self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCustomPage lastViewController];
            
            // Track notification when the page is deeplinked ...
            [self trackAppOpenWithParameters:pushTrackParameterDictionary];
            
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                [self.blueShiftPushParamDelegate handlePushDictionary:self.userInfo];
            }
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(fetchProductID:)]) {
                NSString *productID = [self.userInfo objectForKey: kNotificationProductIDIdenfierKey];
                [self.blueShiftPushParamDelegate fetchProductID:productID];
            }
            return true;
        }
    }
    return false;
}

- (void)handleCategoryForBuyUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when  buy category push notification is clicked ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(buyCategoryPushClickedWithDetails:)]) {
        // User already implemented the buyCategoryPushClickedWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate buyCategoryPushClickedWithDetails:pushDetailsDictionary];
    } else {
        // Handle the View Action in SDK ...
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToProductPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToProductPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(fetchProductID:)]) {
                    NSString *productID = [pushDetailsDictionary objectForKey: kNotificationProductIDIdenfierKey];
                    [self.blueShiftPushParamDelegate fetchProductID:productID];
                }
            }
        }
    }
}


- (void)handleCategoryForViewCartUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when open cart action is selected for push message of cart category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(cartViewCategoryPushClickedWithDetails:)]) {
        // User already implemented the cartViewCategoryPushClickedWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate cartViewCategoryPushClickedWithDetails:pushDetailsDictionary];
    } else {
        // Handle the Open Cart Action in SDK ...
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToCartPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCartPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleCategoryForPromotionUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // Track notification when the page is deeplinked ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(promotionCategoryPushClickedWithDetails:)]) {
        // User already implemented the promotionCategoryPushClickedWithDetails: in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate promotionCategoryPushClickedWithDetails:pushDetailsDictionary];
        
    } else {
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToOfferPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToOfferPage lastViewController];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleCarouselPushForCategory:(NSString *)categoryName usingPushDetailsDictionary:(NSDictionary *) pushDetailsDictionary {
    // method to handle the scenario when go to app action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    NSString *bundleIdentifier = [BlueShift sharedInstance].config.appGroupID;
    if(bundleIdentifier!=(id)[NSNull null] && ![bundleIdentifier isEqualToString:@""]) {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc]
                                      initWithSuiteName:bundleIdentifier];
        NSNumber *selectedIndex = [userDefaults objectForKey: kNotificationSelectedIndexKey];
        if (selectedIndex != nil) {
            [self resetUserDefaults: userDefaults];
            
            NSInteger index = [selectedIndex integerValue];
            index = (index > 0) ? index : 0;
            NSArray *carouselItems = [pushDetailsDictionary objectForKey: kNotificationCarouselElementIdentifierKey];
            NSDictionary *selectedItem = [carouselItems objectAtIndex:index];
            NSString *urlString = [selectedItem objectForKey: kPushNotificationDeepLinkURLKey];
            NSURL *url = [NSURL URLWithString:urlString];
            if ([self.blueShiftPushDelegate respondsToSelector:@selector(handleCarouselPushForCategory: clickedWithIndex: withDetails:)]) {
                // User already implemented the viewPushActionWithDetails in App Delegate...
            
                self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
                [self.blueShiftPushDelegate handleCarouselPushForCategory:categoryName clickedWithIndex:index withDetails:pushDetailsDictionary];
            } else {
                if(url != nil) {
                    // map newly allocated deeplink instance to product page route ...
                    BlueShiftDeepLink *deepLink;
                    deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkCustomePage andNSURL:url];
                    [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkCustomePage];
                    self.deepLinkToCustomPage = deepLink;
                    self.deepLinkToCustomPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkCustomePage];
                    [self.deepLinkToCustomPage performCustomDeepLinking:url];
                    self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCustomPage lastViewController];
                
                    // Track notification when the page is deeplinked ...
                    [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                    if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handleCarouselPushDictionary: withSelectedIndex:)]) {
                        [self.blueShiftPushParamDelegate handleCarouselPushDictionary:pushDetailsDictionary withSelectedIndex:index];
                    }
                }
            }
            
            [self setupPushNotificationDeeplink: selectedItem];
        } else {
            
            [self setupPushNotificationDeeplink: pushDetailsDictionary];
        }
    }
}

- (void)resetUserDefaults:(NSUserDefaults *)userDefaults {
    [userDefaults removeObjectForKey:kNotificationSelectedIndexKey];
    [userDefaults synchronize];
}

- (void)handleCustomCategory:(NSString *)categoryName UsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when go to app action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(handleCustomCategory:clickedWithDetails:)]) {
        // User already implemented the viewPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate handleCustomCategory:categoryName clickedWithDetails:pushDetailsDictionary];
    } else {
        // Handle the View Action in SDK ...
        
        NSString *urlString = [pushDetailsDictionary objectForKey: kPushNotificationDeepLinkURLKey];
        NSURL *url = [NSURL URLWithString:urlString];
        
        if(url != nil) {
            // map newly allocated deeplink instance to product page route ...
            BlueShiftDeepLink *deepLink;
            deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkCustomePage andNSURL:url];
            [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkCustomePage];
            self.deepLinkToCustomPage = deepLink;
            self.deepLinkToCustomPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkCustomePage];
            BOOL status = [self.deepLinkToCustomPage performCustomDeepLinking:url];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCustomPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleActionForBuyUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when buy action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(buyPushActionWithDetails:)]) {
        // User already implemented the buyPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate buyPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the Buy Action in SDK ...
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToCartPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCartPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(fetchProductID:)]) {
                    NSString *productID = [pushDetailsDictionary objectForKey: kNotificationProductIDIdenfierKey];
                    [self.blueShiftPushParamDelegate fetchProductID:productID];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleActionForViewUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when view action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(viewPushActionWithDetails:)]) {
        // User already implemented the viewPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate viewPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the View Action in SDK ...
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToProductPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToProductPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleActionForCustomPageForIdentifier:(NSString *)identifier UsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when go to app action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(handlePushActionForIdentifier:withDetails:)]) {
        // User already implemented the viewPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate handlePushActionForIdentifier:identifier withDetails:pushDetailsDictionary];
    } else {
        // Handle the View Action in SDK ...
        
        NSString *urlString = [pushDetailsDictionary objectForKey: kPushNotificationDeepLinkURLKey];
        NSURL *url = [NSURL URLWithString:urlString];
        
        if(url != nil) {
            BlueShiftDeepLink *deepLink;
            deepLink = [[BlueShiftDeepLink alloc] initWithLinkRoute:BlueShiftDeepLinkCustomePage andNSURL:url];
            [BlueShiftDeepLink mapDeepLink:deepLink toRoute:BlueShiftDeepLinkCustomePage];
            self.deepLinkToCustomPage = deepLink;
            self.deepLinkToCustomPage = [BlueShiftDeepLink deepLinkForRoute:BlueShiftDeepLinkCustomePage];
            BOOL status = [self.deepLinkToCustomPage performCustomDeepLinking:url];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCustomPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleActionForOpenCartUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when open cart action is selected for push message of cart category ...
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(openCartPushActionWithDetails:)]) {
        // User already implemented the buyPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
        [self.blueShiftPushDelegate openCartPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the Open Cart Action in SDK ...
        if(![self customDeepLinkToPrimitiveCategory]) {
            BOOL status = [self.deepLinkToCartPage performDeepLinking];
            if(status) {
                self.blueShiftPushParamDelegate = (id<BlueShiftPushParamDelegate>)[self.deepLinkToCartPage lastViewController];
                
                // Track notification when the page is deeplinked ...
                [self trackAppOpenWithParameters:pushTrackParameterDictionary];
                
                if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                    [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
                }
            } else {
                NSLog(@"Deep link URL not found / Something wrong with URL");
            }
        }
    }
}

- (void)handleActionWithIdentifier: (NSString *)identifier forRemoteNotification:(NSDictionary *)notification completionHandler: (void (^)(void)) completionHandler {
    // Handles the scenario when a push message action is selected ...
    // Differentiation is done on the basis of identifier of the push notification ...
    
    NSDictionary *pushAlertDictionary = [notification objectForKey:@"aps"];
    NSDictionary *pushDetailsDictionary = nil;
    pushDetailsDictionary = notification;
    self.userInfo = notification;
    if ([identifier isEqualToString: kNotificationActionBuyIdentifier]) {
        [self handleActionForBuyUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if ([identifier isEqualToString: kNotificationActionViewIdentifier]) {
        [self handleActionForViewUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if([identifier isEqualToString:kNotificationActionOpenCartIdentifier]) {
        [self handleActionForOpenCartUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if([identifier isEqualToString:kNotificationCarouselGotoappIdentifier]) {
        [self handleActionForCustomPageForIdentifier:kNotificationCarouselGotoappIdentifier UsingPushDetailsDictionary:pushDetailsDictionary];
    }
    else {
        // If any action other than the predefined action is selected ...
        // We allow user to implement a custom method which we will provide the neccessary details to the user which includes action identifier and push details ...
        
        if ([self.blueShiftPushDelegate respondsToSelector:@selector(handlePushActionForIdentifier:withDetails:)]) {
            // User needs to implemented if he needs to perform other actions other than the predefined one in App Delegate...
            
            self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
            [self.blueShiftPushDelegate handlePushActionForIdentifier:identifier withDetails:pushAlertDictionary];
        }
    }
    
    [self setupPushNotificationDeeplink: notification];
    
    // Must be called when finished
    completionHandler();
}

- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification
  completionHandler: (void (^)(void)) completionHandler {
    
    [self handleActionWithIdentifier:identifier forRemoteNotification:notification completionHandler:completionHandler];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if (self.oldDelegate) {
        if ([self.oldDelegate respondsToSelector:@selector(applicationWillResignActive:)]) {
            [self.oldDelegate applicationWillResignActive:application];
        }
    }
    
    // Will have to handled by SDK .....
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.oldDelegate && [self.oldDelegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
        [self.oldDelegate applicationWillEnterForeground:application];
    }
}

- (void)appDidBecomeActive:(UIApplication *)application {
    [self trackAppOpen];
    // Uploading previous Batch events if anything exists
    //To make the code block asynchronous
    if ([BlueShift sharedInstance].config.enableAnalytics) {
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
    // Will have to handled by SDK .....
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.oldDelegate) {
        if ([self.oldDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [self.oldDelegate applicationDidBecomeActive:application];
        }
    }
    [self appDidBecomeActive:application];
}

- (void)appDidEnterBackground:(UIApplication *)application {
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)])
    {
        __block UIBackgroundTaskIdentifier background_task;
        background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
            
            //Clean up code. Tell the system that we are done.
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        }];
        
        // Uploading Batch events
        //To make the code block asynchronous
        if ([BlueShift sharedInstance].config.enableAnalytics) {
            [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
        }
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.oldDelegate) {
        if([self.oldDelegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [self.oldDelegate applicationDidEnterBackground:application];
        }
    }
    [self appDidEnterBackground:application];
}

- (void) forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:[self oldDelegate]];
}

- (void)handleAlertActionButtonForCategoryBuyWithActionName:(NSString *)name {
    if([name  isEqual: kBuyButton]) {
        [self handleActionForBuyUsingPushDetailsDictionary:self.userInfo];
    }
    if([name isEqual: kViewButton]) {
        [self handleActionForViewUsingPushDetailsDictionary:self.userInfo];
    }
}

- (void)handleAlertActionButtonForCategoryCartWithActionName:(NSString *)name {
    if([name isEqual: kOpenButton]) {
        [self handleActionForOpenCartUsingPushDetailsDictionary:self.userInfo];
    }
}

- (void)handleAlertActionButtonForCategoryPromotionWithActionName:(NSString *)name {
    if([name isEqual: kShowButton]) {
        [self handleCategoryForPromotionUsingPushDetailsDictionary:self.userInfo];
    }
}

- (void)handleAlertActionButtonForCategoryTwoButtonAlertWithActionName:(NSString *)name {
    if([name isEqual: kShowButton]) {
        [self handleCustomCategory:kNotificationTwoButtonAlertIdentifier UsingPushDetailsDictionary:self.userInfo];
    }
}

- (void)trackAlertDismiss {
    [[BlueShift sharedInstance] trackEventForEventName:kEventDismissAlert andParameters:nil canBatchThisEvent:YES];
}

- (void)trackAppOpen {
    if ([BlueShift sharedInstance].config.enableAppOpenTrackEvent) {
        [self trackAppOpenWithParameters:nil];
    }
}

- (void)trackAppOpenWithParameters:(NSDictionary *)parameters {
    if ([BlueShift sharedInstance].config.enableAppOpenTrackEvent) {
        
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        
        if (parameters) {
            [parameterMutableDictionary addEntriesFromDictionary:parameters];
        }
        
        [[BlueShift sharedInstance] trackEventForEventName:kEventAppOpen andParameters:parameters canBatchThisEvent:NO];
    }
}

- (void)trackPushViewed {
    [self trackPushViewedWithParameters:nil];
}

- (void)trackPushViewedWithParameters:(NSDictionary *)parameters {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics: parameters]) {
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        
        if (parameters) {
            [parameterMutableDictionary addEntriesFromDictionary:parameters];
            [parameterMutableDictionary setObject:@"delivered" forKey:@"a"];
        }
        
        [self trackPushEventWithParameters:parameterMutableDictionary canBatchThisEvent:NO];
    }
}

- (void)trackPushClicked {
    [self trackPushClickedWithParameters:nil];
}

- (void)trackPushClickedWithParameters:(NSDictionary *)parameters {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics: parameters]) {
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        
        if (parameters) {
            [parameterMutableDictionary addEntriesFromDictionary:parameters];
            [parameterMutableDictionary setObject:@"click" forKey:@"a"];
        }
        
        [self trackPushEventWithParameters:parameterMutableDictionary canBatchThisEvent:NO];
    }
}

- (void)trackPushEventWithParameters:(NSDictionary *)parameters canBatchThisEvent:(BOOL)isBatchEvent{
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [self performPushEventsRequestWithRequestParameters:[parameterMutableDictionary copy] canBatchThisEvent:isBatchEvent];
}

- (void) performPushEventsRequestWithRequestParameters:(NSDictionary *)requestParameters canBatchThisEvent:(BOOL)isBatchEvent {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kPushEventsUploadURL];
    NSMutableDictionary *requestMutableParameters = [requestParameters mutableCopy];
    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithRequestURL:url andHttpMethod:BlueShiftHTTPMethodGET andParameters:[requestMutableParameters copy] andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0 andIsBatchEvent:isBatchEvent];
    [BlueShiftRequestQueue addRequestOperation:requestOperation];
}

- (BOOL)trackOpenURLWithCampaignURLString:(NSString *)campaignURLString andParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    BOOL isCampaignURL = NO;
    
    NSArray *components = [campaignURLString componentsSeparatedByString:@"?"];
    if (components.count == 2) {
        
        NSArray *nameValueStrings = [components[1] componentsSeparatedByString:@"&"];
        for (NSString *nameValueString in nameValueStrings) {
            NSArray *parts = [nameValueString componentsSeparatedByString:@"="];
            
            if (parts.count == 2) {
                if (parts[0]!=nil) {
                    if (parts[1]) {
                        [parameterMutableDictionary setObject:parts[1] forKey:parts[0]];
                    } else {
                        [parameterMutableDictionary setObject:@"" forKey:parts[0]];
                    }
                    isCampaignURL = YES;
                    
                } else {
                    isCampaignURL = NO;
                    break;
                }
            } else {
                isCampaignURL = NO;
                break;
            }
        }
    }
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    if (isCampaignURL) {
        [self trackAppOpenWithParameters:[parameterMutableDictionary copy]];
    }
    
    return isCampaignURL;
}

- (void)registerLocationService {
    [BlueShiftDeviceData currentDeviceData].locationManager = [[CLLocationManager alloc] init];
    
    if ([[BlueShiftDeviceData currentDeviceData].locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        if (@available(iOS 8.0, *)) {
            [[BlueShiftDeviceData currentDeviceData].locationManager requestWhenInUseAuthorization];
        }
    } else {
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            [[[UIAlertView alloc] initWithTitle:@"No GPS" message:@"Please Enable GPS in you device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        
        [BlueShiftDeviceData currentDeviceData].locationManager.delegate = self;
        [BlueShiftDeviceData currentDeviceData].locationManager.distanceFilter = kCLDistanceFilterNone;
        [BlueShiftDeviceData currentDeviceData].locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [[BlueShiftDeviceData currentDeviceData].locationManager startUpdatingLocation];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [BlueShiftDeviceData currentDeviceData].currentLocation = (CLLocation *)[locations lastObject];
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize realEventManagedObjectContext = _realEventManagedObjectContext;
@synthesize batchEventManagedObjectContext = _batchEventManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory in the application's documents directory.
    
    if([[[BlueShift sharedInstance] config] appGroupID] != nil)
        return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[[[BlueShift sharedInstance] config] appGroupID]];
    else
        return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSString * path = @"";
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_Bundle.framework"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_Bundle.framework"];
    }
    
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"];
    }
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"];
    }

    NSURL *modelURL = [NSURL fileURLWithPath:path];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BlueShift-iOS-SDK.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

- (NSManagedObjectContext *)realEventManagedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_realEventManagedObjectContext != nil) {
        return _realEventManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _realEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_realEventManagedObjectContext setPersistentStoreCoordinator:coordinator];
    return _realEventManagedObjectContext;
}

- (NSManagedObjectContext *)batchEventManagedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_batchEventManagedObjectContext != nil) {
        return _batchEventManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _batchEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_batchEventManagedObjectContext setPersistentStoreCoordinator:coordinator];
    return _batchEventManagedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

- (void)downloadFileFromURL {
    NSString *fontFileName = [BlueShiftInAppNotificationHelper createFileNameFromURL: kInAppNotificationFontFileDownlaodURL];
    if (![BlueShiftInAppNotificationHelper hasFileExist: fontFileName]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL  *url = [NSURL URLWithString: kInAppNotificationFontFileDownlaodURL];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *fontFilePath = [BlueShiftInAppNotificationHelper getLocalDirectory: fontFileName];
                    [urlData writeToFile: fontFilePath atomically:YES];
                });
            }
        });
    }
}

- (void)handleBlueshiftUniversalLinksForURL:(NSURL *_Nonnull)url  API_AVAILABLE(ios(8.0)) {
    if (url != nil) {
        [self processUniversalLinks:url];
    }
}

- (void)handleBlueshiftUniversalLinksForActivity:(NSUserActivity *)userActivity  API_AVAILABLE(ios(8.0)) {
    if (userActivity != nil && [userActivity.activityType isEqualToString: NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if (url != nil) {
            [self processUniversalLinks:url];
        }
    }
}

-(void)processUniversalLinks:(NSURL * _Nonnull)url {
    @try {
        if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didStartLinkProcessing)]) {
            [self.blueshiftUniversalLinksDelegate didStartLinkProcessing];
        }
        NSMutableDictionary *queriesPayload = [BlueshiftEventAnalyticsHelper getQueriesFromURL:url];
        if ([url.absoluteString rangeOfString: kUniversalLinkShortURLKey].location != NSNotFound) {
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] replayUniversalLink:url completionHandler:^(BOOL status, NSURL *redirectURL, NSError *error) {
                if (status == YES) {
                    if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                        [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing:redirectURL];
                    }
                }
                else
                {
                    if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didFailLinkProcessingWithError:url:)]) {
                        [self.blueshiftUniversalLinksDelegate didFailLinkProcessingWithError:error url:url];
                    }
                }
            }];
        } else if ([url.absoluteString rangeOfString: kUniversalLinkTrackURLKey].location != NSNotFound && [queriesPayload objectForKey: kUniversalLinkRedirectURLKey] && [queriesPayload objectForKey: kUniversalLinkRedirectURLKey] != [NSNull null]) {
            NSURL *redirectURL = [[NSURL alloc] initWithString: [queriesPayload objectForKey: kUniversalLinkRedirectURLKey]];
            [[BlueShift sharedInstance] performRequestQueue:queriesPayload canBatchThisEvent:YES];
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing: redirectURL];
            }
        } else {
            if ([[BlueShift sharedInstance] isBlueshiftUniversalLinkURL:url]) {
                [[BlueShift sharedInstance] performRequestQueue:queriesPayload canBatchThisEvent:YES];
            }
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing:url];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Caught exception %@", exception);
    }
}

@end
