//
//  BlueShiftCarousalViewController.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "iCarousel.h"

@interface BlueShiftCarousalViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

@property UIImageView *backgroundImageView;
@property iCarousel *carousel;
@property UIPageControl *pageControl;

@property NSString *appGroupID;

- (void)showCarouselForNotfication:(UNNotification *)notification;
- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion;

@end
