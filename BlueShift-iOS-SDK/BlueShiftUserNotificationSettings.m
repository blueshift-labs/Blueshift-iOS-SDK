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
    if (@available(iOS 15,*)) {
        UNNotificationActionIcon * nextIcon = [UNNotificationActionIcon iconWithSystemImageName:@"forward.fill"];
        UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"Next" options:UNNotificationActionOptionNone icon:nextIcon];
        
        UNNotificationActionIcon * prevIcon = [UNNotificationActionIcon iconWithSystemImageName:@"backward.fill"];
        UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"Previous" options:UNNotificationActionOptionNone icon:prevIcon];
        
        UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionForeground];
        
        UNNotificationCategory *carouselCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        return carouselCategory;
    } else {
        UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"▶▶" options:UNNotificationActionOptionNone];
        UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"◀◀" options:UNNotificationActionOptionNone];
        UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionNone];
        
        UNNotificationCategory *carouselCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        return carouselCategory;
    }
}

- (UNNotificationCategory *)carouselAnimationCategory  API_AVAILABLE(ios(10.0)){
    if (@available(iOS 15,*)) {
        UNNotificationActionIcon * nextIcon = [UNNotificationActionIcon iconWithSystemImageName:@"forward.fill"];
        UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"Next" options:UNNotificationActionOptionNone icon:nextIcon];
        
        UNNotificationActionIcon * prevIcon = [UNNotificationActionIcon iconWithSystemImageName:@"backward.fill"];
        UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"Previous" options:UNNotificationActionOptionNone icon:prevIcon];
        
        UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionForeground];
        
        UNNotificationCategory *carouselAnimationCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselAnimationIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        return carouselAnimationCategory;
    } else {
        UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:@"▶▶" options:UNNotificationActionOptionNone];
        UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:@"◀◀" options:UNNotificationActionOptionNone];
        UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionForeground];
        
        UNNotificationCategory *carouselAnimationCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselAnimationIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        
        return carouselAnimationCategory;
    }
}

- (UNNotificationCategory *)promotionCategory API_AVAILABLE(ios(10.0)){
    UNNotificationCategory* promotionCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationPromotionIdentifier actions:@[] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    return promotionCategory;
}


- (NSSet *)notificationCategories {
    NSMutableSet *categories = [NSMutableSet setWithObjects: self.carouselCategory, self.carouselAnimationCategory, self.promotionCategory, nil];
    if ([BlueShift sharedInstance].config.customCategories) {
        return [categories setByAddingObjectsFromSet:[BlueShift sharedInstance].config.customCategories];
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
