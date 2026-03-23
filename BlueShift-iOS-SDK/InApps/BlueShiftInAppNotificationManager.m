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
                            if (inAppEntity.payload) {
                                BlueShiftInAppNotification *inAppNotification = [[BlueShiftInAppNotification alloc] initFromEntity:inAppEntity];
                                [BlueshiftLog logInfo:@"Created in-app object from dictionary, message Id: " withDetails:inAppEntity.id methodName:nil];
                                [self createInAppNotification: inAppNotification displayOnScreen:inAppEntity.displayOn];
                            } else {
                                //If payload is nil, then discard the in-app and delete it from db.
                                [InAppNotificationEntity deleteInboxMessageFromDB:inAppEntity.id completionHandler:^(BOOL status) {
                                }];
                                return;
                            }
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
    if (!notification.notificationPayload) {
            [BlueshiftLog logInfo:@"In-app payload is missing. Skipping in-app notification display." withDetails:nil methodName:nil];
            return;
        }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (notification == nil || self.currentNotificationController != nil || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            [BlueshiftLog logInfo:@"Active In-app notification detected or app is not running in active state, skipped displaying current in-app." withDetails:nil methodName:nil];
            return;
        }
        
        // NEW: Check if SwiftUI rendering is enabled
        if (@available(iOS 13.0, *)) {
            if ([BlueShift sharedInstance].config.useSwiftUIForInApp) {
                [self renderWithSwiftUI:notification displayOnScreen:displayOnScreen];
                return;
            }
        }
        
        // EXISTING: UIKit rendering
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

// NEW: SwiftUI rendering method
- (void)renderWithSwiftUI:(BlueShiftInAppNotification*)notification
          displayOnScreen:(NSString*)displayOnScreen API_AVAILABLE(ios(13.0)) {
    
    // Try multiple module name variations for the Swift class
    // 1. CocoaPods (same module as core SDK, no module prefix needed)
    Class bridgeClass = NSClassFromString(@"BlueShiftSwiftUIBridge");
    if (!bridgeClass) {
        // 2. SPM / Carthage (separate BlueShift_iOS_SDK_SwiftUI module)
        bridgeClass = NSClassFromString(@"BlueShift_iOS_SDK_SwiftUI.BlueShiftSwiftUIBridge");
    }
    if (!bridgeClass) {
        // 3. Legacy SPM (when Swift was in core module)
        bridgeClass = NSClassFromString(@"BlueShift_iOS_SDK.BlueShiftSwiftUIBridge");
    }
    if (!bridgeClass) {
        // 4. Edge case fallback
        bridgeClass = NSClassFromString(@"BlueShift_iOS_SDK_BlueShift_iOS_SDK.BlueShiftSwiftUIBridge");
    }
    
    if (bridgeClass) {
        [BlueshiftLog logInfo:@"Found SwiftUI bridge class" withDetails:[NSString stringWithFormat:@"%@", bridgeClass] methodName:nil];
        SEL sharedSelector = NSSelectorFromString(@"shared");
        if ([bridgeClass respondsToSelector:sharedSelector]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id bridge = [bridgeClass performSelector:sharedSelector];
            #pragma clang diagnostic pop
            
            __weak typeof(self) weakSelf = self;
            
            // Create blocks for callbacks
            
            // showBlock — matches UIKit's inAppDidShow: delegate
            // Fires a=open tracking and marks in-app as displayed (on show, not on dismiss)
            void (^showBlock)(void) = ^{
                NSMutableDictionary *mutablePayload = [notification.notificationPayload mutableCopy];
                // Set opened_by attribute — matches UIKit's inAppDidShow: lines 435-438
                if (notification.isFromInbox) {
                    mutablePayload[kBSTrackingOpenedBy] = kBSTrackingOpenedByUser;
                } else {
                    mutablePayload[kBSTrackingOpenedBy] = kBSTrackingOpenedByPrefetch;
                }
                // Track open event — matches UIKit's trackInAppNotificationShowingWithParameter:
                [[BlueShift sharedInstance] trackInAppNotificationShowingWithParameter:mutablePayload
                                                                    canBacthThisEvent:NO];
                // Mark as displayed on show — matches UIKit's inAppDidShow: line 441
                [weakSelf updateInAppNotificationAsDisplayed:notification.notificationPayload];
            };
            
            // dismissKey matches UIKit's kNotificationClickElementKey values: "swipe", "tap_outside", or nil for close button
            void (^dismissBlock)(NSString *) = ^(NSString *dismissKey) {
                // Build payload with dismiss key — matches UIKit's sendActionEventAnalytics:forActionType:
                NSMutableDictionary *payload = [notification.notificationPayload mutableCopy];
                if (dismissKey) {
                    payload[kNotificationClickElementKey] = dismissKey;
                }
                // Track dismiss event — matches UIKit's trackInAppNotificationDismissWithParameter:
                [[BlueShift sharedInstance] trackInAppNotificationDismissWithParameter:payload
                                                                    canBacthThisEvent:NO];
                // updateInAppNotificationAsDisplayed: moved to showBlock (called on show, not dismiss)
                weakSelf.currentNotificationController = nil;
                if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
                    [weakSelf startInAppMessageFetchTimer];
                }
            };
            
            void (^actionBlock)(NSString *) = ^(NSString *actionURL) {
                NSMutableDictionary *payload = [notification.notificationPayload mutableCopy];
                BOOL isDismissURL = (actionURL == nil || actionURL.length == 0 ||
                                     [actionURL isEqualToString:kInAppNotificationDismissDeepLinkURL]);
                
                // Check for push permission request URL — matches UIKit's processInAppActionForDeepLink:
                if ([actionURL isEqualToString:kInAppNotificationReqPNPermissionDeepLinkURL]) {
                    // Handle push permission request — matches UIKit's handleRequestPushPermissionDeepLink
                    if (@available(iOS 10.0, *)) {
                        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                            if ([settings authorizationStatus] == UNAuthorizationStatusDenied) {
                                // User has denied permission - show alert to go to Settings
                                // Note: For full parity, implement showEnablePushFromSettingsAlert logic here
                                // For now, just log
                                [BlueshiftLog logInfo:@"Push permission denied. User needs to enable from Settings." withDetails:nil methodName:nil];
                            } else if ([settings authorizationStatus] == UNAuthorizationStatusNotDetermined) {
                                // Permission not asked yet - show permission dialog
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[BlueShift sharedInstance].appDelegate registerForNotification];
                                });
                            }
                        }];
                    }
                    // Track the push permission request action
                    [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter:payload
                                                                                 canBacthThisEvent:NO];
                }
                else if (isDismissURL) {
                    // nil/empty/blueshift://dismiss → a=dismiss (matches UIKit's BlueshiftInAppDismissAction)
                    [[BlueShift sharedInstance] trackInAppNotificationDismissWithParameter:payload
                                                                        canBacthThisEvent:NO];
                } else {
                    // Real URL → a=click (matches UIKit's BlueshiftInAppClickAction)
                    NSString *encodedURL = [actionURL stringByAddingPercentEncodingWithAllowedCharacters:
                                            [NSCharacterSet URLQueryAllowedCharacterSet]];
                    if (encodedURL) {
                        payload[kNotificationURLElementKey] = encodedURL;
                    }
                    [[BlueShift sharedInstance] trackInAppNotificationButtonTappedWithParameter:payload
                                                                             canBacthThisEvent:NO];
                    // Open the URL — matches UIKit's handleDeeplinkForInAppNotification:
                    NSURL *url = [NSURL URLWithString:actionURL];
                    if (url) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                        });
                    }
                }
                // Dismiss housekeeping — matches UIKit's inAppDidDismiss:
                weakSelf.currentNotificationController = nil;
                if ([[[BlueShift sharedInstance] config] inAppManualTriggerEnabled] == NO) {
                    [weakSelf startInAppMessageFetchTimer];
                }
                [BlueshiftLog logInfo:@"In-app action tapped" withDetails:actionURL methodName:nil];
            };
            
            // Call the Swift bridge method using performSelector
            SEL renderSelector = NSSelectorFromString(@"renderInAppWithNotification:onShow:onDismiss:onAction:");
            if ([bridge respondsToSelector:renderSelector]) {
                NSMethodSignature *signature = [bridge methodSignatureForSelector:renderSelector];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                [invocation setTarget:bridge];
                [invocation setSelector:renderSelector];
                [invocation setArgument:&notification atIndex:2];
                [invocation setArgument:&showBlock    atIndex:3];
                [invocation setArgument:&dismissBlock atIndex:4];
                [invocation setArgument:&actionBlock  atIndex:5];
                [invocation invoke];
                
                [BlueshiftLog logInfo:@"Displaying in-app notification using SwiftUI" withDetails:notification.notificationPayload[@"bsft_message_uuid"] methodName:nil];
            } else {
                [BlueshiftLog logError:nil withDescription:@"SwiftUI bridge render method not found" methodName:nil];
            }
        }
    } else {
        [BlueshiftLog logError:nil withDescription:@"SwiftUI bridge not available. Install SwiftUI subspec or set useSwiftUIForInApp to NO." methodName:nil];
        // Fallback to UIKit
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
            default:
                break;
        }
    }
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
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadDataForURL:iconImageURL shouldCache:YES handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];
            
            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadDataForURL:backgroundImageURL shouldCache:YES handler:^(BOOL status, NSData *data, NSError *error) {
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
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadDataForURL:backgroundImageURL shouldCache:YES handler:^(BOOL status, NSData *data, NSError *error) {
                dispatch_group_leave(serviceGroup);
            }];

            dispatch_group_enter(serviceGroup);
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] downloadDataForURL:bannerImageURL shouldCache:YES handler:^(BOOL status, NSData *data, NSError *error) {
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
