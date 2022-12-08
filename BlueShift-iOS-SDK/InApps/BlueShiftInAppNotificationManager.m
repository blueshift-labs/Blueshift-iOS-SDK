//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <StoreKit/StoreKit.h>
#import "BlueShiftInAppNotificationManager.h"
#import "BlueShiftNotificationWebViewController.h"
#import "BlueShiftNotificationModalViewController.h"
#import "BlueShiftNotificationSlideBannerViewController.h"
#import "InAppNotificationEntity.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShift.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@interface BlueShiftInAppNotificationManager() <BlueShiftNotificationDelegate>

@property (nonatomic, strong, readwrite) NSTimer *inAppMessageFetchTimer;

@end

@implementation BlueShiftInAppNotificationManager

#pragma mark - Set up

- (void)load {
    
    [self startInAppMessageFetchTimer];

    /* register for app background / foreground notification */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onApplicationEnteringBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onApplicationEnteringForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)onApplicationEnteringBackground:(NSNotification *)notification {
    // stop the timer once app enters background.
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

- (void)onApplicationEnteringForeground:(NSNotification *)notification {
    // start the timer once app enters foreground.
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO && [[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES) {
//        [self fetchAndShowInAppNotification];
        [self startInAppMessageFetchTimer];
    }
}

- (void)startInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer == nil) {
        double timeInterval = (self.inAppNotificationTimeInterval > kMinimumInAppTimeInterval) ? self.inAppNotificationTimeInterval : kDefaultInAppTimeInterval;
        self.inAppMessageFetchTimer = [NSTimer scheduledTimerWithTimeInterval: timeInterval target:self selector:@selector(fetchAndShowInAppNotification) userInfo:nil repeats: YES];
        [BlueshiftLog logInfo:@"Started InAppMessageFetchTimer with time interval in seconds -" withDetails:[NSNumber numberWithDouble: timeInterval] methodName:nil];
    }
}

// Method to stop time gap b/w loading inAppNotification timer
- (void)stopInAppMessageFetchTimer {
    if (self.inAppMessageFetchTimer != nil) {
        [self.inAppMessageFetchTimer invalidate];
        self.inAppMessageFetchTimer = nil;
        [BlueshiftLog logInfo:@"Stopped InAppMessageFetchTimer" withDetails:nil methodName:nil];
    }
}

#pragma mark - Insert, delete, update in-app notifications
- (void)initializeInAppNotificationFromAPI:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler {
    [self addInboxNotifications:notificationArray handler:^(BOOL status) {
        handler(status);
    }];
}

- (void)addInboxNotifications:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler {
    @try {
        if (notificationArray && notificationArray.count > 0) {
            NSMutableArray *messageUUIDs = [NSMutableArray arrayWithCapacity:[notificationArray count]];
            [notificationArray enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                NSString* messageUUID = [self getMessageUUID:obj];
                if (messageUUID) {
                    [messageUUIDs addObject:messageUUID];
                }
            }];
            
            [InAppNotificationEntity checkIfMessagesPresentForMessageUUIDs:messageUUIDs handler:^(BOOL status, NSDictionary * _Nonnull presentUUIDs) {
                @try {
                    
                    dispatch_group_t serviceGroup = dispatch_group_create();
                    dispatch_group_async(serviceGroup,BlueShift.sharedInstance.dispatch_get_blueshift_queue,^{
                        for (int counter = 0; counter < notificationArray.count ; counter++) {
                            NSDictionary* inapp = [notificationArray objectAtIndex: counter];
                            double expiresAt = [inapp[kInAppNotificationDataKey][kInAppNotificationKey][kSilentNotificationTriggerEndTimeKey] doubleValue];
                            NSString* messageUUID = [self getMessageUUID:inapp];
                            //Do not add duplicate messages in the db
                            if(messageUUID && ![presentUUIDs valueForKey:messageUUID]) {
                                // Do not add expired in-app notifications to in-app DB.
                                if ([self isInboxNotificationExpired:expiresAt] == NO) {
                                    dispatch_group_enter(serviceGroup);
                                    [self insertMesseageInDB: inapp handler:^(BOOL status) {
                                        dispatch_group_leave(serviceGroup);
                                    }];
                                } else {
                                    [BlueshiftLog logInfo:@"Skipped adding expired in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                                }
                            } else {
                                [BlueshiftLog logInfo:@"Skipped adding duplicate in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                            }
                        }
                        dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                            handler(YES);
                        });
                    });
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

- (void)insertMesseageInDB:(NSDictionary *)payload handler:(void(^)(BOOL))handler{
    @try {
        NSManagedObjectContext *privateContext = [BlueShift sharedInstance].appDelegate.inboxManagedObjectContext;
        if (privateContext) {
            [privateContext performBlock:^{
                NSEntityDescription *entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:privateContext];
                if(entity) {
                    InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: privateContext];
                    if(inAppNotificationEntity) {
                        [inAppNotificationEntity insert:payload handler:^(BOOL status) {
                            if(status) {
                                [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: payload canBacthThisEvent: NO];
                                // invoke the inApp clicked callback method
                                if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDeliver:)]) {
                                    [self.inAppNotificationDelegate inAppNotificationDidDeliver:payload];
                                }
                            }
                            handler(YES);
                        }];
                    } else {
                        handler(NO);
                    }
                } else {
                    handler(NO);
                }
            }];
        } else {
            handler(NO);
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO);
    }
}

-(NSString * _Nullable)getMessageUUID:(NSDictionary *)notificationPayload {
    if ([notificationPayload objectForKey: kBSMessageUUID]) {
        return (NSString *)[notificationPayload objectForKey: kBSMessageUUID];
    } else {
        if([notificationPayload objectForKey:kInAppNotificationDataKey]) {
            notificationPayload = [notificationPayload objectForKey:kInAppNotificationDataKey];
            if ([notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey]) {
                return (NSString *)[notificationPayload objectForKey: kInAppNotificationModalMessageUDIDKey];
            }
        }
    }
    return nil;
}

- (BOOL)isInboxNotificationExpired:(double)expiryTime {
    double currentTime =  [[NSDate date] timeIntervalSince1970];
    return currentTime > expiryTime;
}

- (void)updateInAppNotificationAsDisplayed:(NSDictionary *)payload {
    NSString *messageUUID = [self getMessageUUID: payload];
    if (messageUUID && ![messageUUID isEqualToString:@""]) {
        [InAppNotificationEntity markMessageAsRead:messageUUID];
    }
}

#pragma mark - Fetch in-app from the Datastore, filter and process it to display notification
- (void)fetchAndShowInAppNotification {
    //Check in-apps are enabled
    if([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus]) {
        //Check if current screen is registered to display in-apps
        if ([self inAppNotificationDisplayOnPage]) {
            //Check if in-app display is not in progress
            if (!self.currentNotificationController) {
                //Fetch one in-app to display
                [InAppNotificationEntity fetchInAppMessageToDisplayOnScreen:[self inAppNotificationDisplayOnPage] WithHandler:^(BOOL status, NSArray *results) {
                    if (status) {
                        if ([results count] > 0) {
                            InAppNotificationEntity *entity = [results objectAtIndex:0];
                            [BlueshiftLog logInfo:@"Fetched one in-app message from DB to display, message id - " withDetails:entity.id methodName:nil];
                            [self createNotificationFromDictionary: entity];
                        } else {
                            [BlueshiftLog logInfo:@"Skipping in-app display! Reason: No pending in-apps to display at this moment for current screen." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                        }
                    } else {
                        [BlueshiftLog logInfo:@"Skipping in-app display! Reason: No pending in-apps to display for current screen." withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                    }
                }];
            } else {
                [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: In-progress or active in-app detected." withDetails:nil methodName:nil];
            }
        } else {
            [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: screen is not registered to receive in-apps." withDetails:nil methodName:nil];
        }
    } else {
        [BlueshiftLog logInfo:@"Skipping in-app fetch! Reason: In-App notifications are not enabled" withDetails:nil methodName:nil];
    }
}

#pragma mark - Display in-app notification
- (void)createNotificationFromDictionary:(InAppNotificationEntity *) inAppEntity {
    BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
    [BlueshiftLog logInfo:@"Created in-app object from dictionary, message Id: " withDetails:inAppEntity.id methodName:nil];
    [self createInAppNotification: inAppNotification displayOnScreen:inAppEntity.displayOn];
}

- (void)createInAppNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentNotificationController != nil || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            [BlueshiftLog logInfo:@"Active In-app notification detected or app is not running in active state, skipped displaying current in-app." withDetails:nil methodName:nil];
            return;
        }
        
        switch (notification.inAppType) {
            case BlueShiftInAppTypeHTML:
                [self processHTMLNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftInAppTypeModal:
                [self processModalNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftNotificationSlideBanner:
                [self processSlideInBannerNotification:notification displayOnScreen:displayOnScreen];
                break;
                
            case BlueShiftNotificationRating:
            {
                [self displayReviewController];
                [InAppNotificationEntity deleteInboxMessageFromDB:notification.objectID completionHandler:^(BOOL status) { }];
                return;
            }
                
            default:
            {
                NSString* errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
                [BlueshiftLog logError:nil withDescription:errorString methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
            break;
        }
    });
}

- (void)displayReviewController {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

-(void)processSlideInBannerNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating HTML in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationSlideBannerViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    self.currentNotificationController = notificationVC;

    BOOL isSlideInIconImagePresent = [notificationVC isSlideInIconImagePresent:notification];
    BOOL isBackgroundImagePresent = [notificationVC isBackgroundImagePresentForNotification:notification];
    if (isSlideInIconImagePresent || isBackgroundImagePresent) {
        NSURL* iconImageURL = isSlideInIconImagePresent ? [NSURL URLWithString:notification.notificationContent.iconImage] : nil;
        NSURL* backgroundImageURL = isBackgroundImagePresent ? [NSURL URLWithString:notification.templateStyle.backgroundImage] : nil;
        dispatch_group_t serviceGroup = dispatch_group_create();
        dispatch_group_async(serviceGroup,BlueShift.sharedInstance.dispatch_get_blueshift_queue,^{
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:iconImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:backgroundImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                [self presentInAppViewController:notificationVC forNotification:notification];
            });
        });
    } else {
        [self presentInAppViewController:notificationVC forNotification:notification];
    }
}

-(void)processModalNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating Modal in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationModalViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    self.currentNotificationController = notificationVC;
    BOOL isBackgroundImagePresent = [notificationVC isBackgroundImagePresentForNotification:notification];
    BOOL isBannerImagePresent = [notificationVC isBannerImagePresentForNotification:notification];

    if (isBackgroundImagePresent || isBannerImagePresent) {
        NSURL* backgroundImageURL = isBackgroundImagePresent ? [NSURL URLWithString:notification.templateStyle.backgroundImage] : nil;
        NSURL* bannerImageURL = isBannerImagePresent ? [NSURL URLWithString:notification.notificationContent.banner] : nil;
        dispatch_group_t serviceGroup = dispatch_group_create();
        dispatch_group_async(serviceGroup,BlueShift.sharedInstance.dispatch_get_blueshift_queue,^{
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:backgroundImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];

            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadImageForURL:bannerImageURL handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                [self presentInAppViewController:notificationVC forNotification:notification];
            });
        });
    } else {
        [self presentInAppViewController:notificationVC forNotification:notification];
    }
}

-(void)processHTMLNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    [BlueshiftLog logInfo:@"Creating HTML in-app notification to display on screen name" withDetails:displayOnScreen methodName:nil];
    BlueShiftNotificationViewController* notificationVC = [[BlueShiftNotificationWebViewController alloc] initWithNotification:notification];
    notificationVC.displayOnScreen = displayOnScreen;
    notificationVC.delegate = self;
    self.currentNotificationController = notificationVC;

    BlueShiftNotificationWebViewController *webViewController = (BlueShiftNotificationWebViewController*) notificationVC;
    [webViewController setupWebView];
}

// Present ViewController
- (void)presentInAppViewController:(BlueShiftNotificationViewController*)notificationController forNotification:(BlueShiftInAppNotification*)notification {
    void(^ presentInAppBlock)(void) = ^{
        @try {
            if (notificationController && (notificationController.notification.isFromInbox == YES || [self shouldDisplayInAppNotification:notificationController.displayOnScreen] == YES)) {
                [BlueshiftLog logInfo:@"Presenting in-app notification on the screen name" withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
                if(notificationController.delegate == nil) {
                    notificationController.delegate = self;
                }
                notificationController.inAppNotificationDelegate = self.inAppNotificationDelegate;
                if (notification && notification.templateStyle) {
                    [notificationController setTouchesPassThroughWindow: notification.templateStyle.enableBackgroundAction];
                }
                [notificationController show:YES];
            } else {
                self.currentNotificationController = nil;
                [BlueshiftLog logInfo:@"Skipped preseting in-app notification for screen - " withDetails:[self inAppNotificationDisplayOnPage] methodName:nil];
            }

        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            if (notificationController && notificationController.window == nil) {
                self.currentNotificationController = nil;
            }
        }
    };
    
    if ([NSThread isMainThread] == YES) {
        presentInAppBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            presentInAppBlock();
        });
    }
}

/// Check if the notification is eligible to display on the current screen.
/// @param displayOnScreen Name of screen where notification should be displayed
- (BOOL)shouldDisplayInAppNotification:(NSString*)displayOnScreen {
    if ([self inAppNotificationDisplayOnPage] == nil) {
        [BlueshiftLog logInfo:@"Current screen is not registered to receive in-app notification." withDetails:nil methodName:nil];
        return false;
    } else if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:displayOnScreen]) {
        if(![[self inAppNotificationDisplayOnPage] isEqualToString:displayOnScreen]) {
            [BlueshiftLog logInfo:@"Current screen name is different than in-app notification target screen name." withDetails:@{@"currentScreenName":self.inAppNotificationDisplayOnPage, @"inAppTargetScreenName":displayOnScreen} methodName:nil];
            return false;
        } else {
            return true;
        }
    }
    return true;
}

#pragma mark - In App events
// Notification Click Callbacks
-(void)inAppDidDismiss:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController *)controller  {
    self.currentNotificationController = nil;
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self startInAppMessageFetchTimer];
    }
}

-(void)inAppActionDidTapped:(NSDictionary *)notificationPayload withAction:(BlueshiftInAppActions)action  fromViewController:(BlueShiftNotificationViewController *)controller {
    if (action == BlueshiftInAppDismissAction) {
        [[BlueShift sharedInstance] trackInAppNotificationDismissWithParameter:notificationPayload canBacthThisEvent:NO];
    } else {
        [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter:notificationPayload canBacthThisEvent:NO];
    }
    // invoke the inApp clicked callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidClick:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidClick:notificationPayload];
    }
}   

// Notification render Callbacks
-(void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController *)controller {
    // Set opened by attribute for inbox
    NSMutableDictionary* mutableNotification = [notification mutableCopy];
    if (controller.notification.isFromInbox) {
        [mutableNotification setValue:kBSTrackingOpenedByUser forKey:kBSTrackingOpenedBy];
    } else {
        [mutableNotification setValue:kBSTrackingOpenedByPrefetch forKey:kBSTrackingOpenedBy];
    }
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: mutableNotification canBacthThisEvent: NO];
    
    // invoke the inApp open callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidOpen:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidOpen:notification];
    }
    //Update in-app as displayed
    [self updateInAppNotificationAsDisplayed: notification];
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

@end
