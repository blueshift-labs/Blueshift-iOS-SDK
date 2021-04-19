//
//  BlueShiftAppDelegate.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAppDelegate.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueShiftHttpRequestBatchUpload.h"
#import "InApps/BlueShiftInAppNotificationManager.h"
#import "InApps/BlueShiftInAppNotificationConstant.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"
#import "InApps/BlueShiftInAppNotificationHelper.h"

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

#pragma mark - Remote & silent push notification registration

/// Call this method to register for remote notifications.
- (void) registerForNotification {
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
            [self checkUNAuthorizationStatus];
            if (granted) {
                [BlueshiftLog logInfo:@"Push notification permission is granted. Registered for push notifications" withDetails:nil methodName:nil];
            } else {
                [BlueshiftLog logInfo:@"Push notification permission is denied. Registered for background silent notifications" withDetails:nil methodName:nil];
            }
        }];
    } else if ([UIApplication respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        if (@available(iOS 8.0, *)) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:([[[BlueShift sharedInstance] pushNotification] notificationTypes]) categories:[[[BlueShift sharedInstance] pushNotification] notificationCategories]]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    }
    [self downloadFileFromURL];
}

- (void)registerForSilentPushNotification {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if ([settings authorizationStatus] != UNAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
                [self checkUNAuthorizationStatus];
                [BlueshiftLog logInfo:@"config.enablePushNotification is set to false. Registered for background silent notifications" withDetails:nil methodName:nil];
            } else {
                [self registerForNotification];
            }
        }];
    }
    [self downloadFileFromURL];
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
    NSString *deviceTokenString = [self hexadecimalStringFromData: deviceToken];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [BlueShiftDeviceData currentDeviceData].deviceToken = deviceTokenString;
    [BlueshiftLog logInfo:[NSString stringWithFormat:@"Successfully registered for remote notifications. Device token: "] withDetails:deviceTokenString methodName:nil];
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
    //set fireAppOpen to true on receiving device_token for very first time
    BOOL fireAppOpen = NO;
    if(![[BlueShift sharedInstance] getDeviceToken]) {
        fireAppOpen = YES;
    }

    [[BlueShift sharedInstance] setDeviceToken];
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    if (email && ![email isEqualToString:@""]) {
        [[BlueShift sharedInstance] identifyUserWithEmail:email andDetails:nil canBatchThisEvent:NO];
    } else {
        [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    }
    
    //fire delayed app_open after firing the identify call
    if(fireAppOpen) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self trackAppOpenOnAppLaunch:nil];
        });
    }
}

#pragma mark - enable push and auto identify
- (NSString*)getLastModifiedUNAuthorizationStatus {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* authorizationStatus = (NSString *)[defaults objectForKey:kBlueshiftUNAuthorizationStatus];
    return  authorizationStatus;
}

- (void)setLastModifiedUNAuthorizationStatus:(NSString*) authorizationStatus {
    // Added try catch to avoid issues with App UI automation script execution
    @try {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:authorizationStatus forKey:kBlueshiftUNAuthorizationStatus];
        [defaults synchronize];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

/// Check current UNAuthorizationStatus status with last Modified UNAuthorizationStatus status, if its not matching
/// update the last Modified UNAuthorizationStatus in userdefault and fire identify call
- (BOOL)validateChangeInUNAuthorizationStatus {
     NSString* lastModifiedUNAuthorizationStatus = [self getLastModifiedUNAuthorizationStatus];
    if ([[BlueShiftAppData currentAppData] currentUNAuthorizationStatus]) {
        if(!lastModifiedUNAuthorizationStatus || [lastModifiedUNAuthorizationStatus isEqualToString:kNO]) {
            [self setLastModifiedUNAuthorizationStatus: kYES];
            [BlueshiftLog logInfo:@"UNAuthorizationStatus status changed to YES" withDetails:nil methodName:nil];
            if ([BlueShift sharedInstance].config.enablePushNotification || [BlueShift sharedInstance].config.enableSilentPushNotification) {
                [[[BlueShift sharedInstance]appDelegate] registerForNotification];
            }
            return YES;
        }
    } else {
        if(!lastModifiedUNAuthorizationStatus || [lastModifiedUNAuthorizationStatus isEqualToString:kYES]) {
            [self setLastModifiedUNAuthorizationStatus: kNO];
            [BlueshiftLog logInfo:@"UNAuthorizationStatus status changed to NO" withDetails:nil methodName:nil];
            return YES;
        }
    }
    return NO;
}

/// Check and fire identify call if any device attribute is changed
- (void) autoIdentifyCheck {
    BOOL autoIdentify = [self validateChangeInUNAuthorizationStatus];
    if (autoIdentify) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [BlueshiftLog logInfo:@"Initiated auto ideantify" withDetails:nil methodName:nil];
            [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
        });
    }
}
///Update current UNAuthorizationStatus in BlueshiftAppData on app launch and on app didBecomeActive
- (void)checkUNAuthorizationStatus {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if ([settings authorizationStatus] == UNAuthorizationStatusAuthorized) {
                [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:YES];
            } else {
                [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:NO];
            }
            //Fire auto identify call in case any device attribute changes
            [self autoIdentifyCheck];
        }];
    }
}

#pragma mark - Remote notification delegate
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [self registerForRemoteNotification:deviceToken];
}

- (void) failedToRegisterForRemoteNotificationWithError:(NSError *)error {
    [BlueshiftLog logError:error withDescription:[NSString stringWithFormat:@"Failed to register for remote notification"] methodName:nil];
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

- (void)validateAndScheduleLocalNotification:(NSDictionary *)userInfo {
    @try {
        NSDictionary *dataPayload = [userInfo valueForKey:kSilentNotificationPayloadIdentifierKey];
        if ([dataPayload valueForKey:kNotificationsArrayKey]) {
            NSArray *notifications = (NSArray*)[dataPayload valueForKey:kNotificationsArrayKey];
            for (NSDictionary *notification in notifications) {
                NSNumber *expiryTimeStamp = (NSNumber *)[notification objectForKey: kNotificationTimestampToExpireDisplay];
                if (expiryTimeStamp && expiryTimeStamp > 0) {
                    double currentTimeStamp = (double)[[NSDate date] timeIntervalSince1970];
                    if([expiryTimeStamp doubleValue] > currentTimeStamp) {
                        NSNumber *fireTimeStamp = (NSNumber *)[notification valueForKey:kNotificationTimestampToDisplayKey];
                        if (fireTimeStamp && fireTimeStamp > 0) {
                            NSDate *fireDate = [NSDate dateWithTimeIntervalSince1970: [fireTimeStamp doubleValue]];
                            if ([fireTimeStamp doubleValue] < [[NSDate date] timeIntervalSince1970]) {
                                [BlueshiftLog logInfo:@"The notification cant be scheduled as it has been already expired" withDetails:notification methodName:nil];
                                return;
                            }
                            [self scheduleUNLocalNotification:notification at:fireDate];
                        }
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
}

-(void)scheduleUNLocalNotification:(NSDictionary *)notification at:(NSDate *)fireDate {
    if (@available(iOS 10.0, *)) {
        //add title, body and userinfo
        UNMutableNotificationContent* notificationContent = [[UNMutableNotificationContent alloc] init];
        notificationContent.title = [notification objectForKey:kNotificationTitleKey];
        notificationContent.body =  [notification objectForKey:kNotificationBodyKey];;
        notificationContent.sound = [UNNotificationSound defaultSound];
        notificationContent.categoryIdentifier = [notification objectForKey: kNotificationCategoryIdentifierKey];
        notificationContent.userInfo = [notification mutableCopy];
        //Create schedule date component on basis of fire date
        NSDateComponents *fireDatecomponents = [NSCalendar.currentCalendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitTimeZone fromDate:fireDate];
        
        //Download image attachment if present and create attachment
        NSURL* imageURL = [NSURL URLWithString: [notification valueForKey:kNotificationImageURLKey]];
        if(imageURL != nil) {
            NSData *imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
            if(imageData) {
                NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString  *documentsDirectory = [paths objectAtIndex:0];
                NSString *attachmentName = [NSString stringWithFormat:kDownloadImageNameKey];
                NSURL *baseURL = [NSURL fileURLWithPath:documentsDirectory];
                NSURL *URL = [NSURL URLWithString:attachmentName relativeToURL:baseURL];
                NSString  *filePathToWrite = [NSString stringWithFormat:@"%@/%@", documentsDirectory, attachmentName];
                [imageData writeToFile:filePathToWrite atomically:YES];
                NSError *error;
                UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentName URL:URL options:nil error:&error];
                if (error) {
                    [BlueshiftLog logError:error withDescription:@"Failed to create image attachment for scheduling local notification" methodName:nil];
                }
                if(attachment != nil) {
                    NSMutableArray *attachments = [[NSMutableArray alloc]init];
                    [attachments addObject:attachment];
                    notificationContent.attachments = attachments;
                }
            }
        }
        //create and add trigger as fire date component
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:fireDatecomponents repeats:NO];
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:notificationContent trigger:trigger];
        
        // Schedule the local notification.
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (!error) {
                [BlueshiftLog logInfo:@"Scheduled local notification successfully - " withDetails:notification methodName:nil];
            } else {
                [BlueshiftLog logError:nil withDescription:@"Failed to schedule location notification" methodName:nil];
            }
        }];
    } else {
        [self scheduleLocalNotification:notification at:fireDate];
    }
}

-(void)scheduleLocalNotification:(NSDictionary *)notification at:(NSDate *)fireDate {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.fireDate = fireDate;
    if (@available(iOS 8.2, *)) {
        localNotification.alertTitle = [notification objectForKey:kNotificationTitleKey];
    }
    localNotification.alertBody = [notification objectForKey:kNotificationBodyKey];
    if (@available(iOS 8.0, *)) {
        localNotification.category = [notification objectForKey: kNotificationCategoryIdentifierKey];
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)handleLocalNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    if (applicationState == UIApplicationStateActive) {
        return;
    }
    NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
    self.pushAlertDictionary = [userInfo objectForKey: kNotificationAPSIdentifierKey];
    self.userInfo = userInfo;
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
    
    // Handle push notification when the app is in inactive or background state ...
    if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
        [self handleCategoryForBuyUsingPushDetailsDictionary:userInfo];
    } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
        [self handleCategoryForViewCartUsingPushDetailsDictionary:userInfo];
    } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
        [self handleCategoryForPromotionUsingPushDetailsDictionary:userInfo];
    } else {
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

- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    /* if there is payload for IAM , give priority to the it */
    if ([BlueshiftEventAnalyticsHelper isSilenPushNotificationPayload: userInfo]) {
        [[BlueShift sharedInstance] handleSilentPushNotification: userInfo forApplicationState: UIApplicationStateActive];
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
    // invoke the push clicked callback method
    if ([[[BlueShift sharedInstance].config blueShiftPushDelegate] respondsToSelector:@selector(pushNotificationDidClick:)]) {
        [[[BlueShift sharedInstance].config blueShiftPushDelegate] pushNotificationDidClick:userInfo];
    }

    [self trackAppOpenWithParameters:userInfo];

    if (userInfo != nil && ([userInfo objectForKey: kPushNotificationDeepLinkURLKey] || [userInfo objectForKey: kNotificationURLElementKey])) {
        NSURL *deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kPushNotificationDeepLinkURLKey]];
        if (!deepLinkURL) {
            deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kNotificationURLElementKey]];
        }
        if ([self.oldDelegate respondsToSelector:@selector(application:openURL:options:)]) {
            if (@available(iOS 9.0, *)) {
                NSDictionary *pushOptions = @{openURLOptionsSource:openURLOptionsBlueshift,openURLOptionsChannel:openURLOptionsPush};
                [self.oldDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:pushOptions];
                [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered push notification deeplink to AppDelegate openURL method, Deep link - ", [deepLinkURL absoluteString]] withDetails: pushOptions methodName:nil];
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
    
    // Handle push notification when the app is in active state
    if (applicationState == UIApplicationStateActive) {
        if([BlueshiftEventAnalyticsHelper isSilenPushNotificationPayload: userInfo]) {
            [[BlueShift sharedInstance] handleSilentPushNotification: userInfo forApplicationState: applicationState];
        } else if([BlueshiftEventAnalyticsHelper isSchedulePushNotification:userInfo]) {
            [self validateAndScheduleLocalNotification:userInfo];
        }
    } else {
        if ([BlueshiftEventAnalyticsHelper isSilenPushNotificationPayload: userInfo]) {
            [[BlueShift sharedInstance] handleSilentPushNotification: userInfo forApplicationState: applicationState];
        } else if([BlueshiftEventAnalyticsHelper isSchedulePushNotification:userInfo]) {
            [self validateAndScheduleLocalNotification:userInfo];
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
            }
        }
    }
}

#pragma mark - Handle custom push notification actions
- (void)handleCarouselPushForCategory:(NSString *)categoryName usingPushDetailsDictionary:(NSDictionary *) pushDetailsDictionary {
    // method to handle the scenario when go to app action is selected for push message of buy category ...
    NSDictionary *pushDetails = [self.userInfo mutableCopy];
    NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
    if(appGroupID && ![appGroupID isEqualToString:@""]) {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc]
                                      initWithSuiteName:appGroupID];
        NSNumber *selectedIndex = [userDefaults objectForKey: kNotificationSelectedIndexKey];
        [BlueshiftLog logInfo:[NSString stringWithFormat: @"Clicked image index for carousel push notification : %@",selectedIndex] withDetails:nil methodName:nil];

        if (selectedIndex != nil) {
            [self resetUserDefaults: userDefaults];
            
            NSInteger index = [selectedIndex integerValue];
            index = (index > 0) ? index : 0;
            NSArray *carouselItems = [pushDetailsDictionary objectForKey: kNotificationCarouselElementIdentifierKey];
            NSDictionary *selectedItem = [carouselItems objectAtIndex:index];
            NSString *urlString = [selectedItem objectForKey: kPushNotificationDeepLinkURLKey];
            NSURL *url = [NSURL URLWithString:urlString];
            [pushDetails setValue:urlString forKey:kNotificationURLElementKey];
            [self trackPushClickedWithParameters: [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:pushDetails]];
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
                    if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handleCarouselPushDictionary: withSelectedIndex:)]) {
                        [self.blueShiftPushParamDelegate handleCarouselPushDictionary:pushDetailsDictionary withSelectedIndex:index];
                    }
                }
            }
            
            [self setupPushNotificationDeeplink: pushDetails];
            return;
        } else {
            
            [self setupPushNotificationDeeplink: pushDetailsDictionary];
        }
    } else {
        [BlueshiftLog logInfo:@"Unable to process the deeplink as AppGroupId is not set in the Blueshift SDK initialization." withDetails:nil methodName:nil];
    }
    [self trackPushClickedWithParameters:[BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:pushDetails]];
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

#pragma mark - Application lifecyle events
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
    // Uploading previous Batch events if anything exists
    //To make the code block asynchronous
    if ([BlueShift sharedInstance].config.enableAnalytics) {
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
    [self checkUNAuthorizationStatus];
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

#pragma mark - Tracking methods
- (void)trackAppOpenOnAppLaunch:(NSDictionary *)parameters {
    if ([BlueShift sharedInstance].config.enableAppOpenTrackEvent) {
        if ([BlueShift sharedInstance].config.automaticAppOpenTimeInterval == 0) {
            [self trackAppOpenWithParameters:parameters];
        } else if ([self shouldFireAutomaticAppOpen] == YES) {
            double nowTimestamp = [[NSDate date] timeIntervalSince1970];
            [[NSUserDefaults standardUserDefaults] setDouble:nowTimestamp forKey:kBlueshiftLastAppOpenTimestamp];
            [self trackAppOpenWithParameters:parameters];
        }
    }
}

/// Checks if automatic app_open needs to be fired cosidering the automaticAppOpenTimeInterval value
-(BOOL)shouldFireAutomaticAppOpen {
    @try {
        double lastAppOpenTimestamp = [[NSUserDefaults standardUserDefaults] doubleForKey:kBlueshiftLastAppOpenTimestamp];
        double nowTimestamp = [[NSDate date] timeIntervalSince1970];
        if (lastAppOpenTimestamp != 0) {
            double secondsSinceLastAppOpen = nowTimestamp - lastAppOpenTimestamp;
            if (secondsSinceLastAppOpen > [BlueShift sharedInstance].config.automaticAppOpenTimeInterval) {
                return YES;
            }
        } else {
            return YES;
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    return NO;
}

- (void)trackAppOpenWithParameters:(NSDictionary *)parameters {
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        if (parameters) {
            [parameterMutableDictionary addEntriesFromDictionary:parameters];
        }
        [[BlueShift sharedInstance] trackEventForEventName:kEventAppOpen andParameters:parameters canBatchThisEvent:NO];
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
    [[BlueShift sharedInstance] performRequestQueue:[parameters copy] canBatchThisEvent:isBatchEvent];
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize realEventManagedObjectContext = _realEventManagedObjectContext;
@synthesize batchEventManagedObjectContext = _batchEventManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory in the application's documents directory.
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
    NSString* key = [NSString stringWithUTF8String:__PRETTY_FUNCTION__];
    @synchronized (key) {
        @try {
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
                [BlueshiftLog logError:error withDescription:@"Unresolved error while creating persistent store coordinator" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        
        return _persistentStoreCoordinator;
    }
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
            [BlueshiftLog logError:error withDescription:@"Unresolved error" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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

#pragma mark - Universal links
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
            [[BlueShift sharedInstance] performRequestQueue:queriesPayload canBatchThisEvent:NO];
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing: redirectURL];
            }
        } else {
            if ([[BlueShift sharedInstance] isBlueshiftUniversalLinkURL:url]) {
                [[BlueShift sharedInstance] performRequestQueue:queriesPayload canBatchThisEvent:NO];
            }
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing:url];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (void)sceneWillEnterForeground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) {
    if (BlueShift.sharedInstance.config.isSceneDelegateConfiguration == YES) {
        [self appDidBecomeActive:UIApplication.sharedApplication];
    }
}

- (void)sceneDidEnterBackground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) {
    if (BlueShift.sharedInstance.config.isSceneDelegateConfiguration == YES) {
        if ([NSThread isMainThread] == YES) {
            [self processSceneDidEnterBackground];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self processSceneDidEnterBackground];
            });
        }
    }
}

/// Call appDidEnterBackground if all the scenes of the app are in background
/// @warning - This function needs to be executed on the main thread
- (void)processSceneDidEnterBackground API_AVAILABLE(ios(13.0)) {
    BOOL areAllScenesInBackground = YES;
    for (UIWindow* window in UIApplication.sharedApplication.windows) {
        if (window.windowScene.activationState == UISceneActivationStateForegroundActive || window.windowScene.activationState == UISceneActivationStateForegroundInactive) {
            areAllScenesInBackground = NO;
            break;
        }
    }
    if (areAllScenesInBackground == YES) {
        [self appDidEnterBackground:UIApplication.sharedApplication];
    }
}

@end
