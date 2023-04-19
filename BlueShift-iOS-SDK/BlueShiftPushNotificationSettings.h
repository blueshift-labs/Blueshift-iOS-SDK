//
//  BlueShiftPushNotificationSettings.h
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 05/11/17.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import <Foundation/Foundation.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

API_AVAILABLE(ios(8.0))
@interface BlueShiftPushNotificationSettings : NSObject

@property (nonatomic, strong) UIMutableUserNotificationCategory *carouselCategory;
@property (nonatomic, strong) UIMutableUserNotificationCategory *carouselAnimationCategory;
@property (nonatomic, strong) NSSet *notificationCategories;
@property (nonatomic) UIUserNotificationType notificationTypes;
@property (nonatomic, strong) UIUserNotificationSettings *notificationSettings;

@end

#pragma clang diagnostic pop
