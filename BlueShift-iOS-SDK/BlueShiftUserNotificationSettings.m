//
//  BlueShiftUserNotificationSettings.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 22/03/18.
//

#import "BlueShiftUserNotificationSettings.h"
#import "BlueShiftNotificationConstants.h"
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "BlueShift.h"

@implementation BlueShiftUserNotificationSettings

- (UNNotificationCategory *)carouselCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"▶▶" options:UNNotificationActionOptionNone];
    UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"◀◀" options:UNNotificationActionOptionNone];
    UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionNone];
    
    UNNotificationCategory *carouselCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return carouselCategory;
}

- (UNNotificationCategory *)carouselAnimationCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"▶▶" options:UNNotificationActionOptionNone];
    UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"◀◀" options:UNNotificationActionOptionNone];
    UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *carouselAnimationCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselAnimationIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return carouselAnimationCategory;
}

- (NSSet *)notificationCategories {
    NSMutableSet *categories = [NSMutableSet setWithObjects: self.carouselCategory, self.carouselAnimationCategory, nil];
    if ([BlueShift sharedInstance].config.customPushNotificationCategories) {
        [categories addObjectsFromArray:[BlueShift sharedInstance].config.customPushNotificationCategories];
    }
    return categories;
}

- (UNAuthorizationOptions)notificationTypes API_AVAILABLE(ios(10.0)){
    if ([BlueShift sharedInstance].config.customAuthorizationOptions) {
        return  [BlueShift sharedInstance].config.customAuthorizationOptions;
    } else {
        return (UNAuthorizationOptionAlert| UNAuthorizationOptionSound| UNAuthorizationOptionBadge);
    }
}

@end
