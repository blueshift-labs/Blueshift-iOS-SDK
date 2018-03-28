//
//  BlueShiftUserNotificationSettings.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 22/03/18.
//

#import "BlueShiftUserNotificationSettings.h"
#import "BlueShiftNotificationConstants.h"

@implementation BlueShiftUserNotificationSettings

- (UNNotificationCategory *)buyCategory {
    UNNotificationAction *buyAction = [UNNotificationAction actionWithIdentifier:kNotificationActionBuyIdentifier title:@"Buy" options:UNNotificationActionOptionForeground];
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:kNotificationActionViewIdentifier title:@"View" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *buyCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCategoryBuyIdentifier actions:@[buyAction, viewAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return buyCategory;
}

- (UNNotificationCategory *)viewCartCategory {
    UNNotificationAction *openCartAction = [UNNotificationAction actionWithIdentifier:kNotificationActionOpenCartIdentifier title:@"Open Cart" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *viewCartCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCategoryViewCartIdentifier actions:@[openCartAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return viewCartCategory;
}

- (UNNotificationCategory *)oneButtonAlertCategory {
    UNNotificationCategory *oneButtonAlertCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationOneButtonAlertIdentifier actions:@[] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    return oneButtonAlertCategory;
}

- (UNNotificationCategory *)twoButtonAlertCategory {
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:kNotificationActionViewIdentifier title:@"View" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *twoButtonAlertCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationTwoButtonAlertIdentifier actions:@[viewAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

    return twoButtonAlertCategory;
}

- (UNNotificationCategory *)carouselCategory {
    NSString *nextHtmlString = @"&#9654;&#9654;";
    NSData *nextStringData = [nextHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString *decodedString;
    decodedString = [[NSAttributedString alloc] initWithData:nextStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:decodedString.string options:UNNotificationActionOptionNone];
    
    NSString *previousHtmlString = @"&#9664;&#9664;";
    NSData *previousStringData = [previousHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    decodedString = [[NSAttributedString alloc] initWithData:previousStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:decodedString.string options:UNNotificationActionOptionNone];
    
    
    UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionNone];
    
    UNNotificationCategory *carouselCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    
    return carouselCategory;
}

- (UNNotificationCategory *)carouselAnimationCategory {
    NSString *nextHtmlString = @"&#9654;&#9654;";
    NSData *nextStringData = [nextHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString *decodedString;
    decodedString = [[NSAttributedString alloc] initWithData:nextStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UNNotificationAction *nextAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselNextIdentifier title:decodedString.string options:UNNotificationActionOptionNone];
    
    NSString *previousHtmlString = @"&#9664;&#9664;";
    NSData *previousStringData = [previousHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    decodedString = [[NSAttributedString alloc] initWithData:previousStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UNNotificationAction *previousAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselPreviousIdentifier title:decodedString.string options:UNNotificationActionOptionNone];
    
    
    UNNotificationAction *gotoAppAction = [UNNotificationAction actionWithIdentifier:kNotificationCarouselGotoappIdentifier title:@"Go to app" options:UNNotificationActionOptionForeground];
    
    UNNotificationCategory *carouselAnimationCategory = [UNNotificationCategory categoryWithIdentifier:kNotificationCarouselAnimationIdentifier actions:@[nextAction, previousAction, gotoAppAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    
    
    return carouselAnimationCategory;
}




- (NSSet *)notificationCategories {
    return [NSSet setWithObjects:self.buyCategory, self.viewCartCategory, self.oneButtonAlertCategory, self.twoButtonAlertCategory, self.carouselCategory, self.carouselAnimationCategory, nil];
}

- (UNAuthorizationOptions)notificationTypes {
    return (UNAuthorizationOptionAlert|
            UNAuthorizationOptionSound|
            UNAuthorizationOptionBadge);
}

//- (UNNotificationSettings *)notificationSettings {
//    return [UIUserNotificationSettings settingsForTypes:self.notificationTypes categories:self.notificationCategories];
//}


@end
