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
#import "BlueshiftWebBrowserViewController.h"

static NSManagedObjectContext * _Nullable inboxMOContext;
static NSManagedObjectContext * _Nullable eventsMOContext;

@implementation BlueShiftAppDelegate {
    NSString *lastProcessedPushNotificationUUID;
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
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kBSCategoryMigrationForDismissAction] == NO) {
                    //Do the category migration to support the updating of badge count using custom dismiss action option. This needs to be done only once.
                    [[existingCategories allObjects] enumerateObjectsUsingBlock:^(UNNotificationCategory * _Nonnull categoryItem, NSUInteger idx, BOOL * _Nonnull stop) {
                        //create new category with dismiss action
                        UNNotificationCategory* updatedCategory = nil;
                        if (@available(iOS 12.0, *)) {
                            updatedCategory = [UNNotificationCategory categoryWithIdentifier:categoryItem.identifier
                               actions:categoryItem.actions intentIdentifiers:categoryItem.intentIdentifiers
                               hiddenPreviewsBodyPlaceholder:categoryItem.hiddenPreviewsBodyPlaceholder
                               categorySummaryFormat:categoryItem.categorySummaryFormat
                               options:UNNotificationCategoryOptionCustomDismissAction];
                        } else if (@available(iOS 11.0, *)) {
                            updatedCategory = [UNNotificationCategory categoryWithIdentifier:categoryItem.identifier actions:categoryItem.actions intentIdentifiers:categoryItem.intentIdentifiers hiddenPreviewsBodyPlaceholder:categoryItem.hiddenPreviewsBodyPlaceholder options:UNNotificationCategoryOptionCustomDismissAction];
                        } else {
                            updatedCategory = [UNNotificationCategory categoryWithIdentifier:categoryItem.identifier actions:categoryItem.actions intentIdentifiers:categoryItem.intentIdentifiers  options:UNNotificationCategoryOptionCustomDismissAction];
                        }
                        
                        if (updatedCategory) {
                            [categoryDictionary setValue:updatedCategory forKey:updatedCategory.identifier];
                        }
                    }];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBSCategoryMigrationForDismissAction];
                    [BlueshiftLog logInfo:@"Migration completed for adding custom dismiss action to the categories" withDetails:nil methodName:nil];
                } else {
                    [[existingCategories allObjects] enumerateObjectsUsingBlock:^(UNNotificationCategory * _Nonnull categoryItem, NSUInteger idx, BOOL * _Nonnull stop) {
                        [categoryDictionary setValue:categoryItem forKey:categoryItem.identifier];
                    }];
                }
                // Add new categories from the configCategories to register.
                [configCategories enumerateObjectsUsingBlock:^(UNNotificationCategory *  _Nonnull categoryItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    [categoryDictionary setValue:categoryItem forKey:categoryItem.identifier];
                }];
                NSSet* updatedCategories = [NSSet setWithArray:[categoryDictionary allValues]];
                [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:updatedCategories];
            } @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:nil];
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

- (void) failedToRegisterForRemoteNotificationWithError:(NSError *)error {
    [BlueshiftLog logError:error withDescription:[NSString stringWithFormat:@"Failed to register for remote notification"] methodName:nil];
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

- (void) registerForRemoteNotification:(NSData *)deviceToken {
    if (deviceToken) {
        NSString *deviceTokenString = [self hexadecimalStringFromData: deviceToken];
        deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
        [BlueShiftDeviceData currentDeviceData].deviceToken = deviceTokenString;
        [BlueshiftLog logInfo:[NSString stringWithFormat:@"Successfully registered for remote notifications. Device token: "] withDetails:deviceTokenString methodName:nil];
        NSString *previousDeviceToken = [[BlueShift sharedInstance] getDeviceToken];
        // Send identify event after receiveing the device token for the first time & when device token changes
        if (previousDeviceToken && deviceTokenString) {
            if(![previousDeviceToken isEqualToString:deviceTokenString]) {
                [self autoIdentifyOnDeviceTokenChange];
            }
        } else if (deviceTokenString) {
            [self autoIdentifyOnDeviceTokenChange];
        }
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

- (void)autoIdentifyOnDeviceTokenChange {
    //set fireAppOpen to true on receiving device_token for very first time
    BOOL fireAppOpen = NO;
    if(![[BlueShift sharedInstance] getDeviceToken]) {
        fireAppOpen = YES;
    }
    [BlueshiftLog logInfo:[NSString stringWithFormat:@"Initiating Auto identify on device token change."] withDetails:nil methodName:nil];
    [[BlueShift sharedInstance] setDeviceToken];
    [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    
    //fire delayed app_open after firing the identify call
    if(fireAppOpen) {
        [self trackAppOpenOnAppLaunch:nil];
    }
}

#pragma mark - Enable push and auto identify
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
    //Skipping push authorization change check when tracking is disabled
    //to not miss the automatic identify event
    if ([BlueShift sharedInstance].isTrackingEnabled == NO) {
        return;
    }
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (@available(iOS 12.0, *)) {
                // Set enable_push to true for provisional and athorized status
                if ([settings authorizationStatus] == UNAuthorizationStatusAuthorized || [settings authorizationStatus] == UNAuthorizationStatusProvisional) {
                    [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@YES];
                } else {
                    [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@NO];
                }
            } else {
                if ([settings authorizationStatus] == UNAuthorizationStatusAuthorized) {
                    [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@YES];
                } else {
                    [[BlueShiftAppData currentAppData] setCurrentUNAuthorizationStatus:@NO];
                }
            }
            //Fire auto identify call in case any device attribute changes
            [self autoIdentifyCheck];
        }];
    }
}

#pragma mark - Legacy Auto integration methods
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [self registerForRemoteNotification:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    [self failedToRegisterForRemoteNotificationWithError:error];
}

// Handle silent push notifications when id is sent from backend
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [self handleRemoteNotification:userInfo forApplication:application fetchCompletionHandler:handler];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo {
    [self application:application handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification completionHandler: (void (^)(void)) completionHandler {
    [self handleActionWithIdentifier:identifier forRemoteNotification:notification completionHandler:completionHandler];
}

#pragma mark - Handle Push notification external methods
- (void)application:(UIApplication *)application handleRemoteNotification:(NSDictionary *)userInfo {
    [self processSilentPushAndClicksForNotification:userInfo applicationState:application.applicationState];
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [self processSilentPushAndClicksForNotification:userInfo applicationState:application.applicationState];
    handler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application handleLocalNotification:(nonnull UNNotificationRequest *)notification {
    [self processPushClickForNotification:notification.content.userInfo actionIdentifer:nil];
}

- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *)launchOptions {
    if (launchOptions) {
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo) {
            [self processPushClickForNotification:userInfo actionIdentifer: nil];
            return YES;
        }
    }
    return NO;
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    [self processPushClickForNotification:userInfo actionIdentifer: nil];
}

- (void)handleActionWithIdentifier: (NSString *)identifier forRemoteNotification:(NSDictionary *)notification completionHandler: (void (^)(void)) completionHandler {
    [self processPushClickForNotification:notification actionIdentifer:[identifier copy]];
    completionHandler();
}

#pragma mark Schedule notifications
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
        dispatch_async(BlueShift.sharedInstance.dispatch_get_blueshift_queue, ^{
            @try {
                //add title, body and userinfo
                UNMutableNotificationContent* notificationContent = [[UNMutableNotificationContent alloc] init];
                notificationContent.title = [notification objectForKey:kNotificationTitleKey];
                notificationContent.body =  [notification objectForKey:kNotificationBodyKey];
                notificationContent.sound = [notification objectForKey:kNotificationSoundIdentifierKey] ? [notification objectForKey:kNotificationSoundIdentifierKey] : [UNNotificationSound defaultSound];
                notificationContent.categoryIdentifier = [notification objectForKey: kNotificationCategoryIdentifierKey];
                notificationContent.userInfo = [notification mutableCopy];
                //Create schedule date component on basis of fire date
                NSDateComponents *fireDatecomponents = [NSCalendar.currentCalendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitTimeZone fromDate:fireDate];
                
                //Download image attachment if present and create attachment
                NSURL* imageURL = [NSURL URLWithString: [notification valueForKey:kNotificationImageURLKey]];
                if(imageURL != nil) {
                    NSData *imageData = [[NSData alloc] initWithContentsOfURL: imageURL];
                    if(imageData) {
                        NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
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
                    } else {
                        [BlueshiftLog logInfo:@"Failed to download image." withDetails:nil methodName:nil];
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
                
            } @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:nil];
            }
        });
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

#pragma mark Process Push notification
/// Single entry to handle silent push processing and push notifications clicks
- (void)processSilentPushAndClicksForNotification:(NSDictionary*)userInfo applicationState:(UIApplicationState)applicationState {
    @try {
        NSDictionary *notification = [userInfo copy];
        [BlueshiftLog logInfo:@"Silent push notification received." withDetails:notification methodName:nil];
        if ([BlueshiftEventAnalyticsHelper isInAppSilenPushNotificationPayload: notification]) {
            // process in-app notifications silent push
            [[BlueShift sharedInstance] handleSilentPushNotification: notification forApplicationState: applicationState];
        } else if([BlueshiftEventAnalyticsHelper isSchedulePushNotification:notification]) {
            // process scheuled type push notifications
            [self validateAndScheduleLocalNotification:notification];
        } else {
            if(@available(iOS 10, *)) {
                // Placeholder to not handle silent push clicks from iOS 10 onwards.
            } else {
                // process push notification click for iOS 9
                [self processPushClickForNotification:notification actionIdentifer:nil];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
}

- (void)processPushClickForNotification:(NSDictionary*)userInfo actionIdentifer:(NSString* _Nullable)actionIdentifier {
    @try {
        NSDictionary *notification = [userInfo copy];
        NSDictionary *aps = [notification objectForKey: kNotificationAPSIdentifierKey];
        NSNumber *isContentAvailable = aps ? (NSNumber*)[aps objectForKey: kNotificationContentAvailableKey] : nil;
        NSString *pushUUID = [notification valueForKey:kInAppNotificationModalMessageUDIDKey];
        if ([isContentAvailable boolValue] == YES || [pushUUID isEqualToString:lastProcessedPushNotificationUUID]) {
            [BlueshiftLog logInfo:@"Skipped processing notification due to one of the following reasons. 1. The push notification is silent push notification 2. The push notification click is already processed." withDetails:notification methodName:nil];
            return;
        } else if (notification[kNotificationActions] && actionIdentifier != nil) {
            // Handle custom action buttons push notification
            notification = [self parseCustomActionPushNotification:notification forActionIdentifier:actionIdentifier];
        } else if([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: notification] &&
                  [actionIdentifier isEqualToString:kNotificationCarouselGotoappIdentifier] == NO) {
            // Handle Carousel push notification click
            notification = [self handleCarouselPushNotification:notification];
        } else {
            // Remove the selected index of the carousel push notification
            if ([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: notification]
                && [actionIdentifier isEqualToString:kNotificationCarouselGotoappIdentifier] == YES) {
                [self resetCarouselSelectedImageIndex];
            }
            // Handle rest push notifications clicks + go to app button click
            [self invokeCallbackPushNotificationDidClick:notification];
        }
        
        lastProcessedPushNotificationUUID = pushUUID;
        [BlueShift.sharedInstance trackPushClickedWithParameters:notification canBatchThisEvent:NO];
        
        [self handleDeeplinkForPushNotification: notification];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
}

- (void)handleDeeplinkForPushNotification:(NSDictionary *)userInfo {
    if (@available(iOS 9.0, *)) {
        @try {
            // fire app_open only for Blueshift push notifications
            if ([BlueShift.sharedInstance isBlueshiftPushNotification:userInfo]) {
                [self trackAppOpenWithParameters:userInfo];
            }
            if (userInfo != nil && ([userInfo objectForKey: kPushNotificationDeepLinkURLKey] ||
                                    [userInfo objectForKey: kNotificationURLElementKey])) {
                NSURL *deepLinkURL = [userInfo objectForKey: kNotificationURLElementKey] ? [NSURL URLWithString: [userInfo objectForKey: kNotificationURLElementKey]] : nil;
                // If clk_url is nil, then check the deep link for deep_link_url key
                if (deepLinkURL == nil && [userInfo objectForKey: kPushNotificationDeepLinkURLKey]) {
                    deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kPushNotificationDeepLinkURLKey]];
                }
                //check if deep link url is of open in web, else deliver to app
                BOOL success = NO;
                if ([BlueShiftInAppNotificationHelper isValidWebURL:deepLinkURL]) {
                    success = [self openDeepLinkInWebViewBrowser:deepLinkURL showOpenInBrowserButton:[self shouldShowOpenInBrowserButton:userInfo]];
                }
                if (!success) {
                    [self shareDeepLinkToApp:deepLinkURL userInfo:userInfo];
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:nil];
        }
    }
}

- (NSNumber* _Nullable)shouldShowOpenInBrowserButton:(NSDictionary*)userInfo {
    NSNumber *showOpenInBrowserButtonValue = [userInfo valueForKey:kBSWebBrowserShowOpenInBrowserButton];
    if (showOpenInBrowserButtonValue) {
        if ([showOpenInBrowserButtonValue intValue] == 1) {
            return @YES;
        } else if([showOpenInBrowserButtonValue intValue] == 0) {
            return @NO;
        }
    }
    return nil;
}

-(void)shareDeepLinkToApp:(NSURL* _Nullable)deepLinkURL userInfo:(NSDictionary* _Nonnull)userInfo {
    if (deepLinkURL && [self.mainAppDelegate respondsToSelector:@selector(application:openURL:options:)]) {
        NSMutableDictionary *pushOptions = [@{openURLOptionsSource:openURLOptionsBlueshift,
                                              openURLOptionsChannel:openURLOptionsPush,
                                              openURLOptionsPushUserInfo:userInfo ? userInfo : @{}} mutableCopy];
        
        [self.mainAppDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:pushOptions];
        [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered push notification deeplink to AppDelegate openURL method, Deep link - ", [deepLinkURL absoluteString]] withDetails: pushOptions methodName:nil];
    }
}

- (BOOL)openDeepLinkInWebViewBrowser:(NSURL* _Nullable) deepLinkURL showOpenInBrowserButton:(NSNumber* _Nullable)showOpenInBrowserButton {
    if (deepLinkURL && [BlueShiftInAppNotificationHelper isOpenInWebURL:deepLinkURL]) {
        NSURL *newURL = [BlueShiftInAppNotificationHelper removeQueryParam:kBSOpenInWebBrowserKey FromURL:deepLinkURL];
        if (newURL) {
            BlueshiftWebBrowserViewController *webBrowser = [[BlueshiftWebBrowserViewController alloc] init];
            webBrowser.url = newURL;
            if (showOpenInBrowserButton) {
                webBrowser.showOpenInBrowserButton = [showOpenInBrowserButton boolValue];
            }
            [webBrowser show:YES];
            return YES;
        }
    }
    return NO;
}

- (BOOL)openCustomSchemeDeepLink:(NSURL* _Nullable)deepLinkURL {
    if (deepLinkURL) {
        NSURL *newURL = [BlueShiftInAppNotificationHelper removeQueryParam:kBSOpenInWebBrowserKey FromURL:deepLinkURL];
        if (newURL && [UIApplication.sharedApplication canOpenURL:newURL]) {
            if (@available(iOS 10.0, *)) {
                [UIApplication.sharedApplication openURL:newURL options:@{} completionHandler:^(BOOL success) {
                    if (success) {
                        [BlueshiftLog logInfo:@"Opened custom scheme url successfully." withDetails:newURL methodName:nil];
                    } else {
                        [BlueshiftLog logInfo:@"Failed to open custom scheme url." withDetails:newURL methodName:nil];
                    }
                }];
            } else {
                [UIApplication.sharedApplication openURL:newURL];
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark - Handle Carousel PushNotifications
- (NSDictionary*)handleCarouselPushNotification:(NSDictionary *) userInfo {
    NSMutableDictionary *notification = [userInfo mutableCopy];
    @try {
        NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
        if([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:appGroupID]) {
            // Get clicked image index from the shared UserDefaults
            NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
            NSNumber *clickedImageIndex = [userDefaults objectForKey: kNotificationSelectedIndexKey];
            [BlueshiftLog logInfo:[NSString stringWithFormat: @"Clicked image index for carousel push notification : %@",clickedImageIndex] withDetails:nil methodName:nil];
            
            if (clickedImageIndex != nil) {
                [self resetCarouselSelectedImageIndex];
                
                NSInteger index = [clickedImageIndex integerValue];
                index = (index > 0) ? index : 0;
                NSArray *carouselItems = [userInfo objectForKey: kNotificationCarouselElementIdentifierKey];
                NSDictionary *clickedItem = [carouselItems objectAtIndex:index];
                NSString *urlString = [clickedItem objectForKey: kPushNotificationDeepLinkURLKey];
                if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:urlString]) {
                    [notification setObject:urlString forKey:kNotificationURLElementKey];
                }
                [self invokeCallbackHandleCarouselPushForCategoryWithIndex:index userInfo:userInfo];
                return notification;
            }
        } else {
            [BlueshiftLog logInfo:@"Unable to process the deeplink as AppGroupId is not set in config during Blueshift SDK initialization." withDetails:nil methodName:nil];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:@"Failed to process carousel notification." methodName:nil];
    }
    // Invoke the `pushNotificationDidClick` when image index is not availble for carousel push notification.
    [self invokeCallbackPushNotificationDidClick:userInfo];
    return notification;
}

- (void)resetCarouselSelectedImageIndex {
    NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
    if([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:appGroupID]) {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
        // Remove clicked image index from the shared UserDefaults
        [userDefaults removeObjectForKey:kNotificationSelectedIndexKey];
        [userDefaults synchronize];
    }
}

#pragma mark - Handle custom action button push notifications
- (NSDictionary* _Nullable)parseCustomActionPushNotification:(NSDictionary *_Nonnull)userInfo forActionIdentifier:(NSString *_Nonnull)identifier {
    if (userInfo && identifier) {
        NSMutableDictionary *mutableNotification = [userInfo mutableCopy];
        if (userInfo[kNotificationActions]) {
            @try {
                NSArray *actions = (NSArray*)userInfo[kNotificationActions];
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
                    if(identifier) {
                        [mutableNotification setValue:identifier forKey:openURLOptionsPushActionIdentifier];
                    }
                }
            } @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
            // invoke the push clicked callback method
            [self invokeCallbackPushNotificationDidClick:mutableNotification forActionIdentifier:identifier];
        }
        return mutableNotification;
    }
    return @{};
}

#pragma mark - Handle the push notification callback methods provided by SDK
- (void)invokeCallbackPushNotificationDidClick:(NSDictionary*)userInfo {
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(pushNotificationDidClick:)]) {
        [self.blueShiftPushDelegate pushNotificationDidClick:[userInfo copy]];
    }
}

-(void)invokeCallbackHandleCarouselPushForCategoryWithIndex:(NSInteger)index userInfo:(NSDictionary *)userInfo {
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(handleCarouselPushForCategory: clickedWithIndex: withDetails:)]) {
        NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
        [self.blueShiftPushDelegate handleCarouselPushForCategory:pushCategory clickedWithIndex:index withDetails:[userInfo copy]];
    }
}

-(void)invokeCallbackPushNotificationDidClick:(NSDictionary*)userInfo forActionIdentifier:(NSString*)identifier {
    if ([[[BlueShift sharedInstance].config blueShiftPushDelegate] respondsToSelector:@selector(pushNotificationDidClick:forActionIdentifier:)]) {
        [self.blueShiftPushDelegate pushNotificationDidClick:[userInfo copy] forActionIdentifier:identifier];
    }
}



#pragma mark - Application lifecyle events
- (void)appDidBecomeActive:(UIApplication *)application {
    // Moved the code to the observer
}

- (void)appDidEnterBackground:(UIApplication *)application {
    // Moved the code to the observer
}

- (void)sceneWillEnterForeground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) {
    // Moved the code to the observer,
}

- (void)sceneDidEnterBackground:(UIScene* _Nullable)scene API_AVAILABLE(ios(13.0)) {
    // Moved the code to the observer
}

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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [self.mainAppDelegate applicationDidBecomeActive:application];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
        [self.mainAppDelegate applicationDidEnterBackground:application];
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:[self mainAppDelegate]];
}

#pragma mark - Track App Opens
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

#pragma mark - Core Data
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationLibraryDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString*)getManagedObjectModelPath {
    @try {
        // Hardcoded SDK directory path
        NSString* path = [[NSBundle mainBundle] pathForResource:kBSCoreDataDataModel ofType:kBSCoreDataMOMD inDirectory:kBSFrameWorkPath];
        if (path != nil) {
            return path;
        }
        // path for the cocoa pod framework
        path = [[NSBundle bundleForClass:self.class] pathForResource:kBSCoreDataDataModel ofType:kBSCoreDataMOMD];
        if (path != nil) {
            return path;
        }
        
        // Path for swift package bundle
        path = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:kBSSPMResourceBundlePath];
        if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            path = [bundle pathForResource:kBSCoreDataDataModel ofType:kBSCoreDataMOMD];
            if (path != nil) {
                return path;
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:@"Failed to get data model path" methodName:nil];
    }
    return @"";
}

-(void)removeFiles {
    NSArray* files = @[
        @"BlueShift-iOS-SDK.sqlite",
        @"BlueShift-iOS-SDK.sqlite-shm",
        @"BlueShift-iOS-SDK.sqlite-wal"
    ];
    if ([BlueShift sharedInstance].config.sdkCoreDataFilesLocation == BlueshiftFilesLocationLibraryDirectory) {
        @try {
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            
            for(NSString *file in files) {
                NSError *error = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:[documentsPath stringByAppendingPathComponent:file]]) {
                    [[NSFileManager defaultManager] removeItemAtPath:[documentsPath stringByAppendingPathComponent:file] error:&error];
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:nil];
        }
    }
}

- (void)initializeCoreData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            [BlueshiftLog logInfo:@"Initializing Core Data for SDK." withDetails:nil methodName:nil];
            NSURL* url = [NSURL fileURLWithPath:[self getManagedObjectModelPath]];
            if (url) {
                NSManagedObjectModel* mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
                NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
                NSURL *storeURL = nil;
                NSURL *documentsStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kBSCoreDataSQLiteFileName];
                NSURL *libraryStoreURL = [[[self applicationLibraryDirectory] URLByAppendingPathComponent:kBSCoreDataSQLiteLibraryPath] URLByAppendingPathComponent:kBSCoreDataSQLiteFileName];
                
                NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];

                // Select the core data files location
                if ([BlueShift sharedInstance].config.sdkCoreDataFilesLocation == BlueshiftFilesLocationDocumentDirectory) {
                    storeURL = documentsStoreURL;
                } else {
                    // Check if migration is required,
                    // Check if Documents has coredata files and Library does not have the core data files.
                    // If Migration is required, then use the Documents store for migration.
                    // Else use the Library store.
                    BOOL isMigrationRequired = (documentsPath && libraryPath && [[NSFileManager defaultManager] fileExistsAtPath:[documentsPath stringByAppendingPathComponent:kBSCoreDataSQLiteFileName]] == YES && [[NSFileManager defaultManager] fileExistsAtPath:[[libraryPath stringByAppendingPathComponent:kBSCoreDataSQLiteLibraryPath] stringByAppendingPathComponent:kBSCoreDataSQLiteFileName]] == NO);
                    if (isMigrationRequired == YES) {
                        storeURL = documentsStoreURL;
                    } else {
                        storeURL = libraryStoreURL;
                    }
                    NSError *error = nil;
                    // create directory 'Application Support/Blueshift' in the Library if not present.
                    [[NSFileManager defaultManager] createDirectoryAtURL:[[self applicationLibraryDirectory] URLByAppendingPathComponent:kBSCoreDataSQLiteLibraryPath] withIntermediateDirectories:YES attributes:nil error:&error];
                }
                NSError *error = nil;
                NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
                NSPersistentStore* store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
                if (!store) {
                    [BlueshiftLog logError:error withDescription:@"Unresolved error while creating persistent store coordinator" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    return;
                }
                
                // Migrate the core data location and remove the old files from document directory if the store location gets changed.
                if ([BlueShift sharedInstance].config.sdkCoreDataFilesLocation == BlueshiftFilesLocationLibraryDirectory &&
                    documentsPath &&
                    [[NSFileManager defaultManager] fileExistsAtPath:[documentsPath stringByAppendingPathComponent:kBSCoreDataSQLiteFileName]]) {
                    error = nil;
                    if (libraryPath) {
                        NSString *libraryStorePath = [[libraryPath stringByAppendingPathComponent:kBSCoreDataSQLiteLibraryPath] stringByAppendingPathComponent:kBSCoreDataSQLiteFileName];
                        // If core data files are not present at Library location, then migrate the store.
                        if([[NSFileManager defaultManager] fileExistsAtPath:libraryStorePath] == NO) {
                            NSPersistentStore* newStore = [coordinator migratePersistentStore:store toURL:libraryStoreURL options:nil withType:NSSQLiteStoreType error:&error];
                            if (newStore) {
                                [self removeFiles];
                            }
                        } else {
                            [self removeFiles];
                        }
                    }
                }
                
                inboxMOContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                [inboxMOContext setPersistentStoreCoordinator:coordinator];
                
                eventsMOContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                [eventsMOContext setPersistentStoreCoordinator:coordinator];
            } else {
                [BlueshiftLog logInfo:@"Failed to initialise core data as MOMD URL is found nil." withDetails:nil methodName:nil];
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:@"Failed to initialise core data." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    });
}

- (NSManagedObjectContext* _Nullable)inboxMOContext {
    return  inboxMOContext;
}

- (NSManagedObjectContext* _Nullable)eventsMOContext {
    return eventsMOContext;
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
                } else {
                    if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didFailLinkProcessingWithError:url:)]) {
                        [self.blueshiftUniversalLinksDelegate didFailLinkProcessingWithError:error url:url];
                    }
                }
            }];
        } else if ([url.absoluteString rangeOfString: kUniversalLinkTrackURLKey].location != NSNotFound && [queriesPayload objectForKey: kUniversalLinkRedirectURLKey] && [queriesPayload objectForKey: kUniversalLinkRedirectURLKey] != [NSNull null]) {
            NSURL *redirectURL = [[NSURL alloc] initWithString: [queriesPayload objectForKey: kUniversalLinkRedirectURLKey]];
            [queriesPayload removeObjectForKey:kUniversalLinkRedirectURLKey];
            [[BlueShift sharedInstance] addTrackingEventToQueueWithParams:queriesPayload isBatch:NO];
            [BlueshiftLog logInfo:@"Universal link is of /track type. Passing the redirectURL to host app." withDetails:redirectURL methodName:nil];
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing: redirectURL];
            }
        } else {
            [BlueshiftLog logInfo:@"Universal link is not from the Blueshift. Passing the url to app without processing." withDetails:url methodName:nil];
            if ([[BlueShift sharedInstance] isBlueshiftUniversalLinkURL:url]) {
                [[BlueShift sharedInstance] addTrackingEventToQueueWithParams:queriesPayload isBatch:NO];
            }
            if ([self.blueshiftUniversalLinksDelegate respondsToSelector:@selector(didCompleteLinkProcessing:)]) {
                [self.blueshiftUniversalLinksDelegate didCompleteLinkProcessing:url];
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
