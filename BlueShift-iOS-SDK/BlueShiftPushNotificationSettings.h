//
//  BlueShiftPushNotificationSettings.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 05/11/17.
//

#import <Foundation/Foundation.h>

@interface BlueShiftPushNotificationSettings : NSObject

@property (nonatomic, strong) UIMutableUserNotificationCategory *buyCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *viewCartCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *oneButtonAlertCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *twoButtonAlertCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *carouselCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *carouselAnimationCategory;
@property (nonatomic, strong) NSSet *notificationCategories;
@property (nonatomic) UIUserNotificationType notificationTypes;
@property (nonatomic, strong) UIUserNotificationSettings *notificationSettings;


@end
