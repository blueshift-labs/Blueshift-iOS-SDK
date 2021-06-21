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

@implementation BlueShiftAppDelegate {
    NSString *lastProcessedPushNotificationUUID;
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

#pragma mark - Device token processing
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

- (void) failedToRegisterForRemoteNotificationWithError:(NSError *)error {
    [BlueshiftLog logError:error withDescription:[NSString stringWithFormat:@"Failed to register for remote notification"] methodName:nil];
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
        [BlueshiftLog logInfo:@"Initiated auto ideantify" withDetails:nil methodName:nil];
        [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
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

#pragma mark - Remote notification delegates For SDK Auto Integration
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    [self registerForRemoteNotification:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    [self failedToRegisterForRemoteNotificationWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [self handleRemoteNotification:userInfo forApplication:application fetchCompletionHandler:handler];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo {
    [self application:application handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification
  completionHandler: (void (^)(void)) completionHandler {
    [self handleActionWithIdentifier:identifier forRemoteNotification:notification completionHandler:completionHandler];
}

#pragma mark - Remote & local notification handling methods
- (void) handleRemoteNotification:(NSDictionary *)userInfo forApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    [self handleRemoteNotification:userInfo forApplicationState:application.applicationState];
    handler(UIBackgroundFetchResultNewData);
}

- (void) application:(UIApplication *)application handleRemoteNotification:(NSDictionary *)userInfo {
    [self handleRemoteNotification:userInfo forApplicationState:application.applicationState];
}

- (void)application:(UIApplication *)application handleLocalNotification:(nonnull UNNotificationRequest *)notification  API_AVAILABLE(ios(10.0)){
    [self handleLocalNotification:notification.content.userInfo forApplicationState:application.applicationState];
}

#pragma mark - Schedule local notifications
- (void)validateAndScheduleLocalNotification:(NSDictionary *)userInfo {
    @try {
        NSDictionary *dataPayload = [userInfo valueForKey:kSilentNotificationPayloadIdentifierKey];
        if ([dataPayload valueForKey:kNotificationsArrayKey]) {
            NSArray *notifications = (NSArray*)[dataPayload valueForKey:kNotificationsArrayKey];
            for (NSDictionary *notification in notifications) {
                NSNumber *expiryTimeStamp = (NSNumber *)[notification objectForKey: kNotificationTimestampToExpireDisplay];
                if (expiryTimeStamp && expiryTimeStamp > [NSNumber numberWithInt:0]) {
                    double currentTimeStamp = (double)[[NSDate date] timeIntervalSince1970];
                    if([expiryTimeStamp doubleValue] > currentTimeStamp) {
                        NSNumber *fireTimeStamp = (NSNumber *)[notification valueForKey:kNotificationTimestampToDisplayKey];
                        if (fireTimeStamp && fireTimeStamp > [NSNumber numberWithInt:0]) {
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
    [self processSilentPushAndClicksForUserInfo:userInfo applicationState:applicationState];
}

#pragma mark - Process remote notification
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

/// Process notification click from user notification and from the launch options
- (void)handleRemoteNotification:(NSDictionary *)userInfo {
    [self processSilentPushAndClicksForUserInfo:userInfo applicationState:UIApplicationStateActive];
}

/// Process push notification recevied from didRecevieRemote notification
- (void)handleRemoteNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    // Handle push notification when the app is in active state
    if (applicationState == UIApplicationStateActive) {
        [self processSilentPushForUserInfo:userInfo applicationState:applicationState];
    } else {
        [self processSilentPushAndClicksForUserInfo:userInfo applicationState:applicationState];
    }
}

- (void)handleActionWithIdentifier: (NSString *)identifier forRemoteNotification:(NSDictionary *)notification completionHandler: (void (^)(void)) completionHandler {
    NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:notification];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];

    if ([self.blueShiftPushDelegate respondsToSelector:@selector(handlePushActionForIdentifier:withDetails:)]) {
        [self.blueShiftPushDelegate handlePushActionForIdentifier:identifier withDetails:notification];
    }
        
    [self setupPushNotificationDeeplink: notification];
    
    completionHandler();
}

- (void)processSilentPushForUserInfo:(NSDictionary*)userInfo applicationState:(UIApplicationState)applicationState {
    if([BlueshiftEventAnalyticsHelper isSilenPushNotificationPayload: userInfo]) {
        [[BlueShift sharedInstance] handleSilentPushNotification: userInfo forApplicationState: applicationState];
    } else if([BlueshiftEventAnalyticsHelper isSchedulePushNotification:userInfo]) {
        [self validateAndScheduleLocalNotification:userInfo];
    }
}

- (void)processSilentPushAndClicksForUserInfo:(NSDictionary*)userInfo applicationState:(UIApplicationState)applicationState {
    NSString *pushUUID = [userInfo valueForKey:kInAppNotificationModalMessageUDIDKey];
    if ([BlueshiftEventAnalyticsHelper isSilenPushNotificationPayload: userInfo]) {
        [[BlueShift sharedInstance] handleSilentPushNotification: userInfo forApplicationState: applicationState];
    } else if([BlueshiftEventAnalyticsHelper isSchedulePushNotification:userInfo]) {
        [self validateAndScheduleLocalNotification:userInfo];
    } else {
        NSString *pushCategory = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
        if ([pushCategory isEqualToString:kNotificationCategorySilentPushIdentifier] || [pushUUID isEqualToString:lastProcessedPushNotificationUUID]) {
            [BlueshiftLog logInfo:@"Skipped processing notification due to one of the following reasons." withDetails:@"1. The push notification is silent push notification 2. The push notification click is already processed." methodName:nil];
            return;
        } else if ([pushCategory isEqualToString:kNotificationCategoryPromotionIdentifier]) {
            [self handleCategoryForPromotionUsingPushDetailsDictionary:userInfo];
        } else {
            if([BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
                [self handleCarouselPushForCategory:pushCategory usingPushDetailsDictionary:userInfo];
            } else {
                [self handleCustomCategory:pushCategory UsingPushDetailsDictionary:userInfo];
            }
        }
        
        // Process Deep link and perform click tracking except for the carousel push
        if (![BlueshiftEventAnalyticsHelper isCarouselPushNotificationPayload: userInfo]) {
            NSDictionary *pushTrackParameterDictionary = [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
            [self trackPushClickedWithParameters:pushTrackParameterDictionary];

            [self setupPushNotificationDeeplink: userInfo];
        }
        
        // invoke the push clicked callback method
        if ([self.blueShiftPushDelegate respondsToSelector:@selector(pushNotificationDidClick:)]) {
            [[[BlueShift sharedInstance].config blueShiftPushDelegate] pushNotificationDidClick:userInfo];
        }
        
        lastProcessedPushNotificationUUID = pushUUID;
    }
}

#pragma mark - Process deep link
- (void)setupPushNotificationDeeplink:(NSDictionary *)userInfo {
    [self trackAppOpenWithParameters:userInfo];

    if (userInfo != nil && ([userInfo objectForKey: kPushNotificationDeepLinkURLKey] || [userInfo objectForKey: kNotificationURLElementKey])) {
        NSURL *deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kPushNotificationDeepLinkURLKey]];
        if (!deepLinkURL) {
            deepLinkURL = [NSURL URLWithString: [userInfo objectForKey: kNotificationURLElementKey]];
        }
        if ([self.mainAppDelegate respondsToSelector:@selector(application:openURL:options:)]) {
            if (@available(iOS 9.0, *)) {
                NSDictionary *pushOptions = @{openURLOptionsSource:openURLOptionsBlueshift,openURLOptionsChannel:openURLOptionsPush,openURLOptionsPushUserInfo:userInfo};
                [self.oldDelegate application:[UIApplication sharedApplication] openURL: deepLinkURL options:pushOptions];
                [BlueshiftLog logInfo:[NSString stringWithFormat:@"%@ %@",@"Delivered push notification deeplink to AppDelegate openURL method, Deep link - ", [deepLinkURL absoluteString]] withDetails: pushOptions methodName:nil];
            }
        }
    }
}

#pragma mark - Handle carousel push notification actions
- (void)handleCarouselPushForCategory:(NSString *)categoryName usingPushDetailsDictionary:(NSDictionary *) pushDetailsDictionary {
    NSDictionary *pushDetailsMutableDictionary = [pushDetailsDictionary mutableCopy];
    NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
    if([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:appGroupID]) {
        // Get clicked image index from the shared UserDefaults
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
        NSNumber *clickedImageIndex = [userDefaults objectForKey: kNotificationSelectedIndexKey];
        [BlueshiftLog logInfo:[NSString stringWithFormat: @"Clicked image index for carousel push notification : %@",clickedImageIndex] withDetails:nil methodName:nil];

        if (clickedImageIndex != nil) {
            // Reset shared userDefault
            [self resetUserDefaults: userDefaults];
            
            NSInteger index = [clickedImageIndex integerValue];
            index = (index > 0) ? index : 0;
            NSArray *carouselItems = [pushDetailsDictionary objectForKey: kNotificationCarouselElementIdentifierKey];
            NSDictionary *clickedItem = [carouselItems objectAtIndex:index];
            NSString *urlString = [clickedItem objectForKey: kPushNotificationDeepLinkURLKey];
            [pushDetailsMutableDictionary setValue:urlString forKey:kNotificationURLElementKey];
            if ([self.blueShiftPushDelegate respondsToSelector:@selector(handleCarouselPushForCategory: clickedWithIndex: withDetails:)]) {
                [self.blueShiftPushDelegate handleCarouselPushForCategory:categoryName clickedWithIndex:index withDetails:pushDetailsDictionary];
            }
        }
    } else {
        [BlueshiftLog logInfo:@"Unable to process the deeplink as AppGroupId is not set during Blueshift SDK initialization." withDetails:nil methodName:nil];
    }
    [self trackPushClickedWithParameters: [BlueshiftEventAnalyticsHelper pushTrackParameterDictionaryForPushDetailsDictionary:pushDetailsMutableDictionary]];
    
    [self setupPushNotificationDeeplink: pushDetailsMutableDictionary];
}

- (void)resetUserDefaults:(NSUserDefaults *)userDefaults {
    [userDefaults removeObjectForKey:kNotificationSelectedIndexKey];
    [userDefaults synchronize];
}

#pragma mark - Handle promotion and custom category push notification actions
- (void)handleCategoryForPromotionUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(promotionCategoryPushClickedWithDetails:)]) {
        [self.blueShiftPushDelegate promotionCategoryPushClickedWithDetails:pushDetailsDictionary];
    }
}

/// This method gets called when a push notification with category other than Blueshift specified category is clicked
- (void)handleCustomCategory:(NSString *)categoryName UsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    if ([self.blueShiftPushDelegate respondsToSelector:@selector(handleCustomCategory:clickedWithDetails:)]) {
        [self.blueShiftPushDelegate handleCustomCategory:categoryName clickedWithDetails:pushDetailsDictionary];
    }
}

#pragma mark - Application lifecyle events
- (void)applicationWillResignActive:(UIApplication *)application {
    if (self.mainAppDelegate) {
        if ([self.mainAppDelegate respondsToSelector:@selector(applicationWillResignActive:)]) {
            [self.mainAppDelegate applicationWillResignActive:application];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.mainAppDelegate && [self.mainAppDelegate respondsToSelector:@selector(applicationWillEnterForeground:)]) {
        [self.mainAppDelegate applicationWillEnterForeground:application];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.mainAppDelegate) {
        if ([self.mainAppDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [self.mainAppDelegate applicationDidBecomeActive:application];
        }
    }
    [self appDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.mainAppDelegate) {
        if([self.mainAppDelegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            [self.mainAppDelegate applicationDidEnterBackground:application];
        }
    }
    [self appDidEnterBackground:application];
}

#pragma mark - Handle App lifecycle events
- (void)appDidBecomeActive:(UIApplication *)application {
    // Uploading previous Batch events if anything exists
    //To make the code block asynchronous
    [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    [self checkUNAuthorizationStatus];
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
        
        // Uploading 1 batch of events in background
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
}

- (void)appWillEnterForeground:(UIApplication *)application {
    [self appDidBecomeActive:application];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:[self mainAppDelegate]];
}

#pragma mark - App Open Tracking method
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
    [[BlueShift sharedInstance] trackPushClickedWithParameters:parameters canBatchThisEvent:NO];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize realEventManagedObjectContext = _realEventManagedObjectContext;
@synthesize batchEventManagedObjectContext = _batchEventManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;

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
    if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd" inDirectory:@"Frameworks/BlueShift_iOS_SDK.framework"];
    } else if ([[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"] != nil) {
        path = [[NSBundle mainBundle] pathForResource:@"BlueShiftSDKDataModel" ofType:@"momd"];
    }

    NSURL *modelURL = [NSURL fileURLWithPath:path];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (void)initializeCoreData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
            NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BlueShift-iOS-SDK.sqlite"];
            NSError *error = nil;
            NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
            if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
                [BlueshiftLog logError:error withDescription:@"Unresolved error while creating persistent store coordinator" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];

            _realEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_realEventManagedObjectContext setPersistentStoreCoordinator:coordinator];

            _batchEventManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_batchEventManagedObjectContext setPersistentStoreCoordinator:coordinator];

        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    });
}

#pragma mark - Font awesome support
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
