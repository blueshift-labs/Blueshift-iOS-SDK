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

@property NSString *appGroupID;

- (BOOL)isBlueShiftCarouselPushNotification:(UNNotification *)notification API_AVAILABLE(ios(10.0));
- (BOOL)isBlueShiftCarouselActions:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0));
- (void)showCarouselForNotfication:(UNNotification *)notification API_AVAILABLE(ios(10.0));
- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion API_AVAILABLE(ios(10.0));

@end
