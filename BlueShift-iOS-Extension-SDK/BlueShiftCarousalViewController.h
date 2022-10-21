//
//  BlueShiftCarousalViewController.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "BlueShiftiCarousel.h"

@interface BlueShiftCarousalViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

@property UIImageView *backgroundImageView;
@property BlueShiftiCarousel *carousel;
@property UIPageControl *pageControl;

/// SDK requires the app group id to share the carousel click details with the main app. This helps to track the deep links correctly.
/// In order to use the carousel push notifications, it is mandatory to set the app group id.
@property NSString *appGroupID;

/// Check if the push notification is from Blueshift.
/// @param notification push notification.
/// @returns true or false based on if push notification is from Blueshift or not.
- (BOOL)isBlueShiftCarouselPushNotification:(UNNotification *)notification API_AVAILABLE(ios(10.0));

/// Checks if the received action is from Blueshift carousel push notification.
/// @param response action response.
/// @returns true or false based on if action is from Blueshift carousel push or not.
- (BOOL)isBlueShiftCarouselActions:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0));

/// Present carousel push notification
/// @param notification push notification
- (void)showCarouselForNotfication:(UNNotification *)notification API_AVAILABLE(ios(10.0));

/// Share the action response to SDK to process the next & prev button actions
/// @param response action response.
- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion API_AVAILABLE(ios(10.0));

@end
