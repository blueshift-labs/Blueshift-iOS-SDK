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
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"
#import "BlueShiftInAppNotificationHelper.h"

#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSManagedObjectContext * _Nullable managedObjectContext;
static NSManagedObjectContext * _Nullable realEventManagedObjectContext;
static NSManagedObjectContext * _Nullable batchEventManagedObjectContext;

@implementation BlueShiftAppDelegate {
    NSString *lastProcessedPushNotificationUUID;
}

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

- (void)setNotificationCategories {
    if (@available(iOS 10.0, *)) {
        NSArray *configCategories = [[[[BlueShift sharedInstance] userNotification] notificationCategories] allObjects];
        
        // Get existing categories from UNUserNotificationCenter
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull existingCategories) {
            @try {
                NSMutableDictionary<NSString*, UNNotificationCategory *>* categoryDictionary = [NSMutableDictionary dictionary];
                // Create a dictionary of existing category-identifiers and categories for comparison
                [[existingCategories allObjects] enumerateObjectsUsingBlock:^(UNNotificationCategory * _Nonnull categoryItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    [categoryDictionary setValue:categoryItem forKey:categoryItem.identifier];
                }];
                // Add new categories from the configCategories to register.
                [configCategories enumerateObjectsUsingBlock:^(UNNotificationCategory *  _Nonnull categoryItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    [categoryDictionary setValue:categoryItem forKey:categoryItem.identifier];
                }];
                NSSet* updatedCategories = [NSSet setWithArray:[categoryDictionary allValues]];
                [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:updatedCategories];
            } @catch (NSException *exception) {
            }
        }];
    }
}

/// Call this method to register for remote notifications.
- (void) registerForNotification {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self.userNotificationDelegate;
        [self setNotificationCategories];
        [center requestAuthorizationWithOptions:([[[BlueShift sharedInstance] userNotification] notificationTypes]) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if(!error){
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
            }
            [self broadcastNotificationOnRespondingToPushPermission:granted];
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
}

- (void)broadcastNotificationOnRespondingToPushPermission:(BOOL)status {
    @try {
        if([[NSUserDefaults standardUserDefaults] objectForKey:kBlueshiftDidAskPushPermission] == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:kYES forKey:kBlueshiftDidAskPushPermission];
            [[NSNotificationCenter defaultCenter] postNotificationName:kBSPushAuthorizationStatusDidChangeNotification object:nil userInfo:@{kBSStatus:[NSNumber numberWithBool:status]}];
        }
    } @catch (NSException *exception) {}
}

// Handles the push notification payload when the app is in killed state and lauched using push notification
- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *)launchOptions {
    if (launchOptions) {
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo) {
            [self handleRemoteNotification:userInfo];
            return YES;
        }
    }
    return NO;
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
    [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    
    //fire delayed app_open after firing the identify call
    if(fireAppOpen) {
        [self trackAppOpenOnAppLaunch:nil];
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
    if ([[BlueShiftAppData currentAppData] currentUNAuthorizationStatus].boolValue == YES) {
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
        [BlueshiftLog logInfo:@"Initiated auto ideantify" withDetails:nil methodName:nil];
        [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    }
}

///Update current UNAuthorizationStatus in BlueshiftAppData on app launch and on app didBecomeActive
- (void)checkUNAuthorizationStatus {
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if ([settings authorizationStatus] == UNAuthorizationStatusAuthorized) {
                [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@YES];
            } else {
                [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@NO];
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
                if (expiryTimeStamp && expiryTimeStamp.doubleValue > 0) {
                    double currentTimeStamp = (double)[[NSDate date] timeIntervalSince1970];
                    if([expiryTimeStamp doubleValue] > currentTimeStamp) {
                        NSNumber *fireTimeStamp = (NSNumber *)[notification valueForKey:kNotificationTimestampToDisplayKey];
                        if (fireTimeStamp && fireTimeStamp.doubleValue > 0) {
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
        NSString *pushUUID = [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey];
        NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
        if ([pushCategory isEqualToString:kNotificationCategorySilentPushIdentifier] || [pushUUID isEqualToString:lastProcessedPushNotificationUUID]) {
            [BlueshiftLog logInfo:@"Skipped processing notification due to one of the following reasons." withDetails:@"1. The push notification is silent push notification 2. The push notification click is already processed." methodName:nil];
            return;
        }
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
            [self setupPushNotificationDeeplink: userInfo actionIdentifier:nil];
        }
    }
}

- (void)setupPushNotificationDeeplink:(NSDictionary *)userInfo actionIdentifier:(NSString* _Nullable)identifier {
    @try {
        // invoke the push clicked callback method
        if (userInfo[kNotificationActions] && identifier && [[[BlueShift sharedInstance].config blueShiftPushDelegate] respondsToSelector:@selector(pushNotificationDidClick:forActionIdentifier:)]) {
            [[[BlueShift sharedInstance].config blueShiftPushDelegate] pushNotificationDidClick:userInfo forActionIdentifier:identifier];
        } else if ([[[BlueShift sharedInstance].config blueShiftPushDelegate] respondsToSelector:@selector(pushNotificationDidClick:)]) {
            [[[BlueShift sharedInstance].config blueShiftPushDelegate] pushNotificationDidClick:userInfo];
        }
        
        lastProcessedPushNotificationUUID = [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey];
        
        [self trackAppOpenWithParameters:userInfo];
        
        if (userInfo != nil && ([userInfo objectForKey: kPushNotificationDeepLinkURLKey] || [userInfo objectForKey: kNotificationURLElementKey])) {
            NSURL *deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kNotificationURLElementKey]];
            // If clk_url is nil and identifier is nil, then check the deep link using deep_link_url key
            if (!deepLinkURL && !identifier) {
                deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kPushNotificationDeepLinkURLKey]];
            }
            if ([self.mainAppDelegate respondsToSelector:@selector(application:openURL:options:)] && deepLinkURL) {
                if (@available(iOS 9.0, *)) {
                    NSMutableDictionary *pushOptions = [@{openURLOptionsSource:openURLOptionsBlueshift,
                                                          openURLOptionsChannel:openURLOptionsPush,
                                                          openURLOptionsPushUserInfo:userInfo} mutableCopy];
                    if(identifier) {
                        [pushOptions setValue:identifier forKey:openURLOptionsPushActionIdentifier];
                    }
                    [self.mainAppDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:pushOptions];
                    [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered push notification deeplink to AppDelegate openURL method, Deep link - ", [deepLinkURL absoluteString]] withDetails: pushOptions methodName:nil];
                }
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
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
            NSString *pushUUID = [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey];
            if ([pushCategory isEqualToString:kNotificationCategorySilentPushIdentifier] || [pushUUID isEqualToString:lastProcessedPushNotificationUUID]) {
                [BlueshiftLog logInfo:@"Skipped processing notification due to following reasons" withDetails:@"1. The push notification is silent push notification 2. The push notification click is already processed." methodName:nil];
                return;
            }
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
                [self setupPushNotificationDeeplink: userInfo actionIdentifier:nil];
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
            
            [self setupPushNotificationDeeplink: pushDetails actionIdentifier:nil];
            return;
        } else {
            
            [self setupPushNotificationDeeplink: pushDetailsDictionary actionIdentifier:nil];
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
    
    // If user taps on the actionable push notification view
    // then remove actions array to avoid the ambiguity in selecting deep link
    NSMutableDictionary *trackingParams = [pushDetailsDictionary mutableCopy];
    if(trackingParams[kNotificationActions]) {
        [trackingParams removeObjectForKey:kNotificationActions];
    }
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:trackingParams];
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
    if (notification[kNotificationActions]) {
        notification = [self handleCustomActionablePushNotification:notification forActionIdentifier:identifier];
    } else if ([identifier isEqualToString: kNotificationActionBuyIdentifier]) {
        [self handleActionForBuyUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if ([identifier isEqualToString: kNotificationActionViewIdentifier]) {
        [self handleActionForViewUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if([identifier isEqualToString:kNotificationActionOpenCartIdentifier]) {
        [self handleActionForOpenCartUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if([identifier isEqualToString:kNotificationCarouselGotoappIdentifier]) {
        [self handleActionForCustomPageForIdentifier:kNotificationCarouselGotoappIdentifier UsingPushDetailsDictionary:pushDetailsDictionary];
    } else {
        // If any action other than the predefined action is selected ...
        // We allow user to implement a custom method which we will provide the neccessary details to the user which includes action identifier and push details ...
        
        if ([self.blueShiftPushDelegate respondsToSelector:@selector(handlePushActionForIdentifier:withDetails:)]) {
            // User needs to implemented if he needs to perform other actions other than the predefined one in App Delegate...
            
            self.blueShiftPushDelegate = (id<BlueShiftPushDelegate>)self.blueShiftPushDelegate;
            [self.blueShiftPushDelegate handlePushActionForIdentifier:identifier withDetails:pushAlertDictionary];
        }
    }
    
    [self setupPushNotificationDeeplink:notification actionIdentifier:identifier];
    
    // Must be called when finished
    completionHandler();
}

- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification
  completionHandler: (void (^)(void)) completionHandler {
    
    [self handleActionWithIdentifier:identifier forRemoteNotification:notification completionHandler:completionHandler];
}

- (NSDictionary*)handleCustomActionablePushNotification:(NSDictionary *)notification forActionIdentifier:(NSString *)identifier {
    NSMutableDictionary *mutableNotification = [notification mutableCopy];
    @try {
        NSArray *actions = (NSArray*)notification[kNotificationActions];
        if (actions && actions.count > 0) {
            NSString *deepLink = nil;
            NSString *actionTitle = nil;
            //Check if the identifier is not created by the SDK and it is coming in the payload
            if ([identifier rangeOfString:kNotificationDefaultActionIdentifier].location == NSNotFound) {
                for (NSDictionary* action in actions) {
                    if ([action[kNotificationActionIdentifier] isEqualToString: identifier]) {
                        deepLink = action[kPushNotificationDeepLinkURLKey];
                        actionTitle = action[kNotificationTitleKey];
                        break;
                    }
                }
            } else {
                // If the identifier is created by SDK, then it will look like `BSPushIdentifier_2`
                // Use the last character as index and get the deep link and button title
                NSString *indexString = [identifier substringFromIndex:identifier.length - 1];
                int index = [indexString intValue];
                if (index < actions.count) {
                    actionTitle = actions[index][kNotificationTitleKey];
                    deepLink = actions[index][kPushNotificationDeepLinkURLKey];
                }
            }
            if (deepLink) {
                [mutableNotification setValue:deepLink forKey:kNotificationURLElementKey];
            }
            if (actionTitle) {
                [mutableNotification setValue:actionTitle forKey:kNotificationClickElementKey];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    NSDictionary *trackingParams = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:mutableNotification];
    [self trackPushClickedWithParameters:trackingParams];
    return mutableNotification;
}

#pragma mark - Application lifecyle events
- (void)applicationWillResignActive:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationWillResignActive:)]) {
        [self.mainAppDelegate applicationWillResignActive:application];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
        [self.mainAppDelegate applicationWillEnterForeground:application];
    }
}

- (void)appDidBecomeActive:(UIApplication *)application {
    // Uploading previous Batch events if anything exists
    //To make the code block asynchronous
    [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [self.mainAppDelegate applicationDidBecomeActive:application];
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
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
        [self.mainAppDelegate applicationDidEnterBackground:application];
    }
    [self appDidEnterBackground:application];
}

- (void) forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:[self mainAppDelegate]];
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

#pragma mark - Track Push click
- (void)trackPushClickedWithParameters:(NSDictionary *)parameters {
    if ([BlueshiftEventAnalyticsHelper isSendPushAnalytics: parameters]) {
        NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
        if (parameters) {
            [parameterMutableDictionary addEntriesFromDictionary:parameters];
            [parameterMutableDictionary setObject:kBSClick forKey:kBSAction];
        }
        [[BlueShift sharedInstance] performRequestQueue:[parameterMutableDictionary copy] canBatchThisEvent:NO];
    }
}

#pragma mark - Core Data stack
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString*)getManagedObjectModelPath {
    NSString* path = [[NSBundle mainBundle] pathForResource:kBSCoreDataDataModel ofType:kBSCoreDataMOMD inDirectory:kBSFrameWorkPath];
    if (path != nil) {
        return path;
    }
    
    path = [[NSBundle bundleForClass:self.class] pathForResource:kBSCoreDataDataModel ofType:kBSCoreDataMOMD];
    if(path != nil) {
        return path;
    }
    return @"";
}

- (void)initializeCoreData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSURL* url = [NSURL fileURLWithPath:[self getManagedObjectModelPath]];
            if (url) {
                NSManagedObjectModel* mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
                NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
                NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kBSCoreDataSQLiteFileName];
                NSError *error = nil;
                NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
                NSPersistentStore* store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
                if (!store) {
                    [BlueshiftLog logError:error withDescription:@"Unresolved error while creating persistent store coordinator" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    return;
                }
                managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                [managedObjectContext setPersistentStoreCoordinator:coordinator];

                realEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                [realEventManagedObjectContext setPersistentStoreCoordinator:coordinator];

                batchEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                [batchEventManagedObjectContext setPersistentStoreCoordinator:coordinator];
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:@"Failed to initialise core data." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    });
}

- (NSManagedObjectContext *)managedObjectContext {
    return managedObjectContext;
}

- (NSManagedObjectContext *)realEventManagedObjectContext {
    return realEventManagedObjectContext;
}

- (NSManagedObjectContext *)batchEventManagedObjectContext {
    return batchEventManagedObjectContext;
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
        [BlueshiftLog logInfo:@"Started universal links processing for the url:" withDetails:url methodName:nil];
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
            [queriesPayload removeObjectForKey:kUniversalLinkRedirectURLKey];
            [[BlueShift sharedInstance] performRequestQueue:queriesPayload canBatchThisEvent:NO];
            [BlueshiftLog logInfo:@"Universal link is of /track type. Passing the redirectURL to host app." withDetails:redirectURL methodName:nil];
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing: redirectURL];
            }
        } else {
            [BlueshiftLog logInfo:@"Universal link is not from the Blueshift. Passing the url to app without processing." withDetails:url methodName:nil];
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

#pragma mark - Handle sceneDelegate lifecycle methods
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
