//
//  BlueShiftUserNotificationSettings.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 22/03/18.
//

#import "BlueShiftUserNotificationSettings.h"
#import "BlueShiftNotificationConstants.h"
#import <UserNotificationsUI/UserNotificationsUI.h>

@implementation BlueShiftUserNotificationSettings

- (UNNotificationCategory *)buyCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationAction *buyAction = [UNNotificationAction actionWithIdentifier:kNotificationActionBuyIdentifier title:@"Buy" options:UNNotificationActionOptionForeground];
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:kNotificationActionViewIdentifier title:@"View" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *buyCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCategoryBuyIdentifier actions:@[buyAction, viewAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return buyCategory;
}

- (UNNotificationCategory *)viewCartCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationAction *openCartAction = [UNNotificationAction actionWithIdentifier:kNotificationActionOpenCartIdentifier title:@"Open Cart" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *viewCartCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCategoryViewCartIdentifier actions:@[openCartAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return viewCartCategory;
}

- (UNNotificationCategory *)oneButtonAlertCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationCategory *oneButtonAlertCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationOneButtonAlertIdentifier actions:@[] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return oneButtonAlertCategory;
}

- (UNNotificationCategory *)twoButtonAlertCategory  API_AVAILABLE(ios(10.0)){
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:kNotificationActionViewIdentifier title:@"View" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *twoButtonAlertCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationTwoButtonAlertIdentifier actions:@[viewAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return twoButtonAlertCategory;
}

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
    return [NSSet setWithObjects:self.buyCategory, self.viewCartCategory, self.oneButtonAlertCategory, self.twoButtonAlertCategory, self.carouselCategory, self.carouselAnimationCategory, nil];
}

- (UNAuthorizationOptions)notificationTypes  API_AVAILABLE(ios(10.0)){
    return (UNAuthorizationOptionAlert|
            UNAuthorizationOptionSound|
            UNAuthorizationOptionBadge);
}

@end
