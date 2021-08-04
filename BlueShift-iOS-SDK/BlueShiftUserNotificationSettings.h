//
//  BlueShiftUserNotificationSettings.h
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 22/03/18.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

API_AVAILABLE(ios(10.0))
@interface BlueShiftUserNotificationSettings : NSObject

@property (nonatomic, strong) UNNotificationCategory *buyCategory;
@property (nonatomic, strong) UNNotificationCategory *viewCartCategory;
@property (nonatomic, strong) UNNotificationCategory *carouselCategory;
@property (nonatomic, strong) UNNotificationCategory *carouselAnimationCategory;
@property (nonatomic, strong) NSSet *notificationCategories;
@property (nonatomic) UNAuthorizationOptions notificationTypes;
@property (nonatomic, strong) UNNotificationSettings *notificationSettings;

@end
