//
//  BlueShiftInAppNotificationManager.m
//  BlueShift-iOS-SDK
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
#import "BlueshiftInboxManager.h"

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
    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO && ([[BlueShiftAppData currentAppData] getCurrentInAppNotificationStatus] == YES || BlueShift.sharedInstance.config.enableMobileInbox == YES)) {
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

#pragma mark - fetch, update in-app notifications
- (void)updateInAppNotificationAsDisplayed:(NSDictionary *)payload {
    NSString *messageUUID = [BlueShiftInAppNotificationHelper getMessageUUID: payload];
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
                            InAppNotificationEntity *inAppEntity = results.firstObject;
                            BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
                            [BlueshiftLog logInfo:@"Created in-app object from dictionary, message Id: " withDetails:inAppEntity.id methodName:nil];
                            [self createInAppNotification: inAppNotification displayOnScreen:inAppEntity.displayOn];
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
- (void)createInAppNotification:(BlueShiftInAppNotification*)notification displayOnScreen:(NSString*)displayOnScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification == nil || self.currentNotificationController != nil || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            [BlueshiftLog logInfo:@"Active In-app notification detected or app is not running in active state, skipped displaying current in-app." withDetails:nil methodName:nil];
            return;
        } else if (!notification.notificationPayload) {
            self.currentNotificationController = nil;
            //If payload is nil, then discard the in-app and delete it from db.
            [InAppNotificationEntity deleteInboxMessageFromDB:[BlueShiftInAppNotificationHelper getMessageUUID:notification.notificationPayload] completionHandler:^(BOOL status) {
            }];
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
                [self updateInAppNotificationAsDisplayed:notification.notificationPayload];
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
        dispatch_group_async(serviceGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
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
        dispatch_group_async(serviceGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
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
            if ([self shouldDisplayInAppNotification:notificationController] == YES) {
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
/// @param notificationController InAppNotificationVC object
- (BOOL)shouldDisplayInAppNotification:(BlueShiftNotificationViewController*)notificationController {
    if(!notificationController) {
        return false;
    } else if (notificationController.notification.isFromInbox == YES) {
        //Show in-app notification always if its from the Inbox.
        return YES;
    } if ([self inAppNotificationDisplayOnPage] == nil) {
        [BlueshiftLog logInfo:@"Current screen is not registered to receive in-app notification." withDetails:nil methodName:nil];
        return NO;
    } else if ([BlueshiftEventAnalyticsHelper isNotNilAndNotEmpty:notificationController.displayOnScreen]) {
        if(![[self inAppNotificationDisplayOnPage] isEqualToString:notificationController.displayOnScreen]) {
            [BlueshiftLog logInfo:@"Current screen name is different than in-app notification target screen name." withDetails:@{@"currentScreenName":self.inAppNotificationDisplayOnPage, @"inAppTargetScreenName":notificationController.displayOnScreen} methodName:nil];
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
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
    //Send broadcast to let inbox know that inapp is displayed on the screen.
    [NSNotificationCenter.defaultCenter postNotificationName:kBSInAppNotificationDidAppear object:nil];

    // Set opened by attribute for inbox
    NSMutableDictionary* mutableNotification = [notification mutableCopy];
    if (controller.notification.isFromInbox) {
        [mutableNotification setValue:kBSTrackingOpenedByUser forKey:kBSTrackingOpenedBy];
    } else {
        [mutableNotification setValue:kBSTrackingOpenedByPrefetch forKey:kBSTrackingOpenedBy];
    }
    //Update in-app as displayed
    [self updateInAppNotificationAsDisplayed: notification];

    //Perform open tracking
    [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter: mutableNotification canBacthThisEvent: NO];

    // invoke the inApp open callback method
    if ([self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidOpen:)]) {
        [self.inAppNotificationDelegate inAppNotificationDidOpen:notification];
    }

    if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
        [self stopInAppMessageFetchTimer];
    }
}

@end
