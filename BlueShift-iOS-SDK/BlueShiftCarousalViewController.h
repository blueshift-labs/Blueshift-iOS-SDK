//
//  BlueShiftCarousalViewController.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 22/09/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "iCarousel.h"

@interface BlueShiftCarousalViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

@property UIImageView *backgroundImageView;
@property iCarousel *carousel;
@property UIPageControl *pageControl;

- (void)showCarouselForNotfication:(UNNotification *)notification;
- (void)setCarouselActionsForResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption))completion;

@end
