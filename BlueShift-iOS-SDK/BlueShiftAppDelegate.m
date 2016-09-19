//
//  BlueShiftAppDelegate.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAppDelegate.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueShiftAlertView.h"
#import "BlueShiftHttpRequestBatchUpload.h"

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
    NSLog(@"\n\n Attempting to register for notification \n\n");
    
    // register for remote notifications
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIMutableUserNotificationAction *buyAction;
        buyAction = [[UIMutableUserNotificationAction alloc] init];
        [buyAction setActivationMode:UIUserNotificationActivationModeForeground];
        [buyAction setTitle:@"Buy"];
        [buyAction setIdentifier:kNotificationActionBuyIdentifier];
        [buyAction setDestructive:NO];
        [buyAction setAuthenticationRequired:NO];
        
        UIMutableUserNotificationAction *viewAction;
        viewAction = [[UIMutableUserNotificationAction alloc] init];
        [viewAction setActivationMode:UIUserNotificationActivationModeForeground];
        [viewAction setTitle:@"View"];
        [viewAction setIdentifier:kNotificationActionViewIdentifier];
        [viewAction setDestructive:NO];
        [viewAction setAuthenticationRequired:NO];
        
        UIMutableUserNotificationCategory *buyCategory;
        buyCategory = [[UIMutableUserNotificationCategory alloc] init];
        [buyCategory setIdentifier:kNotificationCategoryBuyIdentifier];
        [buyCategory setActions:@[buyAction, viewAction]
                        forContext:UIUserNotificationActionContextDefault];
        
        
        UIMutableUserNotificationAction *openCartAction;
        openCartAction = [[UIMutableUserNotificationAction alloc] init];
        [openCartAction setActivationMode:UIUserNotificationActivationModeForeground];
        [openCartAction setTitle:@"Open Cart"];
        [openCartAction setIdentifier:kNotificationActionOpenCartIdentifier];
        [openCartAction setDestructive:NO];
        [openCartAction setAuthenticationRequired:NO];
        
        UIMutableUserNotificationCategory *viewCartCategory;
        viewCartCategory = [[UIMutableUserNotificationCategory alloc] init];
        [viewCartCategory setIdentifier:kNotificationCategoryViewCartIdentifier];
        [viewCartCategory setActions:@[openCartAction]
                     forContext:UIUserNotificationActionContextDefault];
        
        
        
        NSSet *categories = [NSSet setWithObjects:buyCategory,viewCartCategory, nil];
        
        UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                        UIUserNotificationTypeSound|
                                        UIUserNotificationTypeBadge);
        
        
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
     
     // Ignore the warning for now.
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
}

// Handles the push notification payload when the app is killed and lauched from push notification tray ...
- (BOOL)handleRemoteNotificationOnLaunchWithLaunchOptions:(NSDictionary *)launchOptions {
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (userInfo) {
        // Handling the push notification if we get the userInfo from launchOptions ...
        // It's the only way to track notification payload while app is on launch (i.e after the app is killed) ...
        //[self handleRemoteNotification:userInfo forApplicationState:[UIApplication sharedApplication].applicationState];
    }
    
    return YES;
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [BlueShift sharedInstance].deviceToken = deviceTokenString;
    [BlueShiftDeviceData currentDeviceData].deviceToken = deviceTokenString;
    NSLog(@"\n\n Push Token Generated is: %@ \n\n", deviceTokenString);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"\n\n Failed to get push token, error: %@ \n\n", error);
}

// Handle silent push notifications when id is sent from backend
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler {
    self.userInfo = userInfo;
    
    [self handleRemoteNotification:userInfo forApplicationState:application.applicationState];
    handler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(nonnull UILocalNotification *)notification {
    self.userInfo = notification.userInfo;
    [self handleLocalNotification:self.userInfo forApplicationState:application.applicationState];
}

- (void)scheduleLocalNotification:(NSDictionary *)userInfo {
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:600];
    localNotification.alertBody = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.category = [[userInfo objectForKey:@"aps"] objectForKey:@"category"];
    localNotification.soundName = [[userInfo objectForKey:@"aps"] objectForKey:@"sound"];
    localNotification.userInfo = userInfo;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)handleLocalNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    NSString *pushCategory = [[userInfo objectForKey:@"aps"] objectForKey:@"category"];
    //self.pushAlertDictionary = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    self.pushAlertDictionary = [userInfo objectForKey:@"aps"];
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
    
    // Way to handle push notification in three states
    if (applicationState == UIApplicationStateActive) {
        
        // Track notification view when app is open ...
        [self trackPushViewedWithParameters:pushTrackParameterDictionary];
        
        // Handle push notification when the app is in active state...
        BlueShiftAlertView *pushAlertView = [BlueShiftAlertView alertViewWithPushDetailsDictionary:userInfo andDelegate:self];
        
        if (pushAlertView) {
            [pushAlertView show];
        }
    } else {
        
        // Track notification when app is in background and when we click the push notification from tray..
        [self trackPushClickedWithParameters:pushTrackParameterDictionary];
        
        // Handle push notification when the app is in inactive or background state ...
        if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
            [self.deepLinkToProductPage performDeepLinking];
            
            self.blueShiftPushParamDelegate = [self.deepLinkToProductPage lastViewController];
            
            // Track notification when the page is deeplinked ...
            [self trackAppOpenWithParameters:pushTrackParameterDictionary];
            
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
            }
        } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
            [self.deepLinkToCartPage performDeepLinking];
            
            self.blueShiftPushParamDelegate = [self.deepLinkToCartPage lastViewController];
            
            // Track notification when the page is deeplinked ...
            [self trackAppOpenWithParameters:pushTrackParameterDictionary];
            
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
            }
        } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
            
            // Handling this as a separate function since push this category does not have an action ...
            [self handleCategoryForOfferUsingPushDetailsDictionary:self.pushAlertDictionary];
            
        }
    }
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo forApplicationState:(UIApplicationState)applicationState {
    NSString *pushCategory = [[userInfo objectForKey:@"aps"] objectForKey:@"category"];
    //self.pushAlertDictionary = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    self.pushAlertDictionary = [userInfo objectForKey:@"aps"];
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:userInfo];
    
    // Way to handle push notification in three states
    if (applicationState == UIApplicationStateActive) {
        

        if([[self.pushAlertDictionary objectForKey:@"notification_type"] isEqualToString:@"alert_box"]) {
            // Track notification view when app is open ...
            [self trackPushViewedWithParameters:pushTrackParameterDictionary];
            
            
            // Handle push notification when the app is in active state...
            BlueShiftAlertView *pushAlertView = [BlueShiftAlertView alertViewWithPushDetailsDictionary:userInfo andDelegate:self];
            
            if (pushAlertView) {
                [pushAlertView show];
            }
        } else {
            [self scheduleLocalNotification:userInfo];
        }
    } else {
        
        // Track notification when app is in background and when we click the push notification from tray..
        [self trackPushClickedWithParameters:pushTrackParameterDictionary];
        
        // Handle push notification when the app is in inactive or background state ...
        if ([pushCategory isEqualToString:kNotificationCategoryBuyIdentifier]) {
            [self.deepLinkToProductPage performDeepLinking];
            
            self.blueShiftPushParamDelegate = [self.deepLinkToProductPage lastViewController];
            
            // Track notification when the page is deeplinked ...
            [self trackAppOpenWithParameters:pushTrackParameterDictionary];
            
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
            }
        } else if ([pushCategory isEqualToString:kNotificationCategoryViewCartIdentifier]) {
            [self.deepLinkToCartPage performDeepLinking];
            
            self.blueShiftPushParamDelegate = [self.deepLinkToCartPage lastViewController];
            
            // Track notification when the page is deeplinked ...
            [self trackAppOpenWithParameters:pushTrackParameterDictionary];
            
            if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
                [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
            }
        } else if ([pushCategory isEqualToString:kNotificationCategoryOfferIdentifier]) {
            
            // Handling this as a separate function since push this category does not have an action ...
            [self handleCategoryForOfferUsingPushDetailsDictionary:self.pushAlertDictionary];
    
        }
    }
}


- (void)handleCategoryForOfferUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    [self.deepLinkToOfferPage performDeepLinking];
    
    self.blueShiftPushParamDelegate = [self.deepLinkToOfferPage lastViewController];
    
    // Track notification when the page is deeplinked ...
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackAppOpenWithParameters:pushTrackParameterDictionary];
    
    if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
        [self.blueShiftPushParamDelegate handlePushDictionary:self.pushAlertDictionary];
    }
}


- (void)handleActionForBuyUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when buy action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.oldDelegate respondsToSelector:@selector(buyPushActionWithDetails:)]) {
        // User already implemented the buyPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = self.oldDelegate;
        [self.blueShiftPushDelegate buyPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the Buy Action in SDK ...
            
        [self.deepLinkToCartPage performDeepLinking];
        self.blueShiftPushParamDelegate = [self.deepLinkToCartPage lastViewController];
        
        // Track notification when the page is deeplinked ...
        [self trackAppOpenWithParameters:pushTrackParameterDictionary];
        
        if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
            [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
        }
    }
}

- (void)handleActionForViewUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when view action is selected for push message of buy category ...
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.oldDelegate respondsToSelector:@selector(viewPushActionWithDetails:)]) {
        // User already implemented the viewPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = self.oldDelegate;
        [self.blueShiftPushDelegate viewPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the View Action in SDK ...
        
        [self.deepLinkToProductPage performDeepLinking];
        self.blueShiftPushParamDelegate = [self.deepLinkToProductPage lastViewController];
        
        // Track notification when the page is deeplinked ...
        [self trackAppOpenWithParameters:pushTrackParameterDictionary];
        
        if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
            [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
        }
    }
}

- (void)handleActionForOpenCartUsingPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    // method to handle the scenario when open cart action is selected for push message of cart category ...
    NSDictionary *pushTrackParameterDictionary = [self pushTrackParameterDictionaryForPushDetailsDictionary:self.userInfo];
    [self trackPushClickedWithParameters:pushTrackParameterDictionary];
    
    if ([self.oldDelegate respondsToSelector:@selector(openCartPushActionWithDetails:)]) {
        // User already implemented the buyPushActionWithDetails in App Delegate...
        
        self.blueShiftPushDelegate = self.oldDelegate;
        [self.blueShiftPushDelegate openCartPushActionWithDetails:pushDetailsDictionary];
    } else {
        // Handle the Open Cart Action in SDK ...
        
        [self.deepLinkToCartPage performDeepLinking];
        self.blueShiftPushParamDelegate = [self.deepLinkToCartPage lastViewController];
        
        // Track notification when the page is deeplinked ...
        [self trackAppOpenWithParameters:pushTrackParameterDictionary];
        
        if ([self.blueShiftPushParamDelegate respondsToSelector:@selector(handlePushDictionary:)]) {
            [self.blueShiftPushParamDelegate handlePushDictionary:pushDetailsDictionary];
        }
    }
}

- (void)application:(UIApplication *) application handleActionWithIdentifier: (NSString *) identifier forRemoteNotification: (NSDictionary *) notification
  completionHandler: (void (^)()) completionHandler {
    // Handles the scenario when a push message action is selected ...
    // Differentiation is done on the basis of identifier of the push notification ...
    
    //NSDictionary *pushAlertDictionary = [[notification objectForKey:@"aps"] objectForKey:@"alert"];
    NSDictionary *pushAlertDictionary = [notification objectForKey:@"aps"];
    NSDictionary *pushDetailsDictionary = nil;
    if ([pushAlertDictionary isKindOfClass:[NSDictionary class]]) {
        pushDetailsDictionary = pushAlertDictionary;
    }
    
    if ([identifier isEqualToString: kNotificationActionBuyIdentifier]) {
        [self handleActionForBuyUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if ([identifier isEqualToString: kNotificationActionViewIdentifier]) {
        [self handleActionForViewUsingPushDetailsDictionary:pushDetailsDictionary];
    } else if([identifier isEqualToString:kNotificationActionOpenCartIdentifier]) {
        [self handleActionForOpenCartUsingPushDetailsDictionary:pushDetailsDictionary];
    }
    else {
        // If any action other than the predefined action is selected ...
        // We allow user to implement a custom method which we will provide the neccessary details to the user which includes action identifier and push details ...
        
        if ([self.oldDelegate respondsToSelector:@selector(handlePushActionForIdentifier:withDetails:)]) {
            // User needs to implemented if he needs to perform other actions other than the predefined one in App Delegate...
            
            self.blueShiftPushDelegate = self.oldDelegate;
            [self.blueShiftPushDelegate handlePushActionForIdentifier:identifier withDetails:pushAlertDictionary];
        }
    }
    
    // Must be called when finished
    completionHandler();
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    BOOL canOpenURLStatus = NO;
    canOpenURLStatus = [self trackOpenURLWithCampaignURLString:[url absoluteString] andParameters:nil];
    
    if ([self.oldDelegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
        canOpenURLStatus = [self.oldDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return canOpenURLStatus;
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
    [self.oldDelegate applicationWillEnterForeground:application];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self trackAppOpen];
    if (self.oldDelegate) {
        if ([self.oldDelegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
            [self.oldDelegate applicationDidBecomeActive:application];
        }
    }
    // Uploading previous Batch events if anything exists
    //To make the code block asynchronous
    [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];

    // Will have to handled by SDK .....
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self.oldDelegate applicationWillTerminate:application];
    
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
        [BlueShiftHttpRequestBatchUpload batchEventsUploadInBackground];
    }
}

- (void) forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:[self oldDelegate]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    BlueShiftAlertView *blueShiftAlertView = (BlueShiftAlertView *)alertView;
    BlueShiftAlertViewContext alertViewContext = blueShiftAlertView.alertViewContext;
    if (alertViewContext == BlueShiftAlertViewContextNotificationCategoryBuy) {
        switch (buttonIndex) {
            case 1:
                [self handleActionForViewUsingPushDetailsDictionary:self.pushAlertDictionary];
                break;
            case 2:
                [self handleActionForBuyUsingPushDetailsDictionary:self.pushAlertDictionary];
                break;
                
            default:
                [self trackAlertDismiss];
                break;
        }
    } else if (alertViewContext == BlueShiftAlertViewContextNotificationCategoryCart) {
        switch (buttonIndex) {
            case 1:
                [self handleActionForOpenCartUsingPushDetailsDictionary:self.pushAlertDictionary];
                break;
                
            default:
                [self trackAlertDismiss];
                break;
        }
    } else if (alertViewContext == BlueShiftAlertViewContextNotificationCategoryOffer) {
        switch (buttonIndex) {
            case 1:
                [self handleCategoryForOfferUsingPushDetailsDictionary:self.pushAlertDictionary];
                break;
                
            default:
                [self trackAlertDismiss];
                break;
        }
    }
}

- (void)trackAlertDismiss {
    [[BlueShift sharedInstance] trackEventForEventName:kEventAlertDismiss andParameters:nil canBatchThisEvent:YES];
}

- (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    //NSDictionary *pushAlertDictionary = [[pushDetailsDictionary objectForKey:@"aps"] objectForKey:@"alert"];
    NSDictionary *pushAlertDictionary = [pushDetailsDictionary objectForKey:@"aps"];
    NSString *pushMessageID = [pushAlertDictionary objectForKey:@"id"];
    NSNumber *timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *pushTrackParametersMutableDictionary = [NSMutableDictionary dictionary];
    if (pushMessageID) {
        [pushTrackParametersMutableDictionary setObject:pushMessageID forKey:@"notification_id"];
        [pushTrackParametersMutableDictionary setObject:timeStamp forKey:@"timestamp"];
    }
    
    return [pushTrackParametersMutableDictionary copy];
}

- (void)trackAppOpen {
    [self trackAppOpenWithParameters:nil];
}

- (void)trackAppOpenWithParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [[BlueShift sharedInstance] trackEventForEventName:kEventAppOpen andParameters:parameters canBatchThisEvent:NO];
}

- (void)trackPushViewed {
    [self trackPushViewedWithParameters:nil];
}

- (void)trackPushViewedWithParameters:(NSDictionary *)parameters {
    
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    [[BlueShift sharedInstance] trackEventForEventName:kEventPushView andParameters:parameters canBatchThisEvent:YES];
    
}

- (void)trackPushClicked {
    [self trackPushClickedWithParameters:nil];
}

- (void)trackPushClickedWithParameters:(NSDictionary *)parameters {
    NSMutableDictionary *parameterMutableDictionary = [NSMutableDictionary dictionary];
    
    if (parameters) {
        [parameterMutableDictionary addEntriesFromDictionary:parameters];
    }
    
    
    [[BlueShift sharedInstance] trackEventForEventName:kEventPushClicked andParameters:parameters canBatchThisEvent:YES];
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
        [[BlueShiftDeviceData currentDeviceData].locationManager requestWhenInUseAuthorization];
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
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BlueShiftSDKDataModel" withExtension:@"momd"];
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
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
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
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
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
            abort();
        }
    }
}


@end
