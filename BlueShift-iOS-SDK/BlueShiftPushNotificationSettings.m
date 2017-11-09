//
//  BlueShiftPushNotificationSettings.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 05/11/17.
//

#import "BlueShiftPushNotificationSettings.h"
#import "BlueShiftNotificationConstants.h"

@implementation BlueShiftPushNotificationSettings

- (UIMutableUserNotificationCategory *)buyCategory {
    UIMutableUserNotificationAction *buyAction;
    buyAction = [[UIMutableUserNotificationAction alloc] init];
    [buyAction setActivationMode:UIUserNotificationActivationModeForeground];
    [buyAction setTitle:@"Buy"];
    [buyAction setIdentifier:kNotificationActionBuyIdentifier];
    [buyAction setDestructive:NO];
    [buyAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *viewAction;
    viewAction = [[UIMutableUserNotificationAction alloc] init];
    [viewAction setActivationMode:UIUserNotificationActivationModeForeground];
    [viewAction setTitle:@"View"];
    [viewAction setIdentifier:kNotificationActionViewIdentifier];
    [viewAction setDestructive:NO];
    [viewAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *buyCategory;
    buyCategory = [[UIMutableUserNotificationCategory alloc] init];
    [buyCategory setIdentifier:kNotificationCategoryBuyIdentifier];
    [buyCategory setActions:@[buyAction, viewAction]
                 forContext:UIUserNotificationActionContextDefault];
    
    return buyCategory;
}

- (UIMutableUserNotificationCategory *)viewCartCategory {
    UIMutableUserNotificationAction *openCartAction;
    openCartAction = [[UIMutableUserNotificationAction alloc] init];
    [openCartAction setActivationMode:UIUserNotificationActivationModeForeground];
    [openCartAction setTitle:@"Open Cart"];
    [openCartAction setIdentifier:kNotificationActionOpenCartIdentifier];
    [openCartAction setDestructive:NO];
    [openCartAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *viewCartCategory;
    viewCartCategory = [[UIMutableUserNotificationCategory alloc] init];
    [viewCartCategory setIdentifier:kNotificationCategoryViewCartIdentifier];
    [viewCartCategory setActions:@[openCartAction]
                      forContext:UIUserNotificationActionContextDefault];
    
    return viewCartCategory;
}

- (UIMutableUserNotificationCategory *)oneButtonAlertCategory {
    UIMutableUserNotificationCategory *oneButtonAlertCategory;
    oneButtonAlertCategory = [[UIMutableUserNotificationCategory alloc] init];
    [oneButtonAlertCategory setIdentifier:kNotificationOneButtonAlertIdentifier];
    [oneButtonAlertCategory setActions:@[]
                            forContext:UIUserNotificationActionContextDefault];
    
    return oneButtonAlertCategory;
}

- (UIMutableUserNotificationCategory *)twoButtonAlertCategory {
    UIMutableUserNotificationAction *viewAction;
    viewAction = [[UIMutableUserNotificationAction alloc] init];
    [viewAction setActivationMode:UIUserNotificationActivationModeForeground];
    [viewAction setTitle:@"View"];
    [viewAction setIdentifier:kNotificationActionViewIdentifier];
    [viewAction setDestructive:NO];
    [viewAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *twoButtonAlertCategory;
    twoButtonAlertCategory = [[UIMutableUserNotificationCategory alloc] init];
    [twoButtonAlertCategory setIdentifier:kNotificationTwoButtonAlertIdentifier];
    [twoButtonAlertCategory setActions:@[viewAction]
                            forContext:UIUserNotificationActionContextDefault];
    
    return twoButtonAlertCategory;
}

- (UIMutableUserNotificationCategory *)carouselCategory {
    NSString *nextHtmlString = @"&#9654;&#9654;";
    NSData *nextStringData = [nextHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString *decodedString;
    decodedString = [[NSAttributedString alloc] initWithData:nextStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UIMutableUserNotificationAction *nextAction;
    nextAction = [[UIMutableUserNotificationAction alloc] init];
    [nextAction setActivationMode:UIUserNotificationActivationModeForeground];
    [nextAction setTitle:decodedString.string];
    [nextAction setIdentifier:kNotificationCarouselNextIdentifier];
    [nextAction setDestructive:NO];
    [nextAction setAuthenticationRequired:NO];
    
    NSString *previousHtmlString = @"&#9664;&#9664;";
    NSData *previousStringData = [previousHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    decodedString = [[NSAttributedString alloc] initWithData:previousStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UIMutableUserNotificationAction *previousAction;
    previousAction = [[UIMutableUserNotificationAction alloc] init];
    [previousAction setActivationMode:UIUserNotificationActivationModeForeground];
    [previousAction setTitle:decodedString.string];
    [previousAction setIdentifier:kNotificationCarouselPreviousIdentifier];
    [previousAction setDestructive:NO];
    [previousAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *gotoAppAction;
    gotoAppAction = [[UIMutableUserNotificationAction alloc] init];
    [gotoAppAction setActivationMode:UIUserNotificationActivationModeForeground];
    [gotoAppAction setTitle:@"Go to app"];
    [gotoAppAction setIdentifier:kNotificationCarouselGotoappIdentifier];
    [gotoAppAction setDestructive:NO];
    [gotoAppAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *carouselCategory;
    carouselCategory = [[UIMutableUserNotificationCategory alloc] init];
    [carouselCategory setIdentifier:kNotificationCarouselIdentifier];
    [carouselCategory setActions:@[nextAction, previousAction, gotoAppAction]
                      forContext:UIUserNotificationActionContextDefault];
    
    return carouselCategory;
}

- (UIMutableUserNotificationCategory *)carouselAnimationCategory {
    NSString *nextHtmlString = @"&#9654;&#9654;";
    NSData *nextStringData = [nextHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType};
    NSAttributedString *decodedString;
    decodedString = [[NSAttributedString alloc] initWithData:nextStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UIMutableUserNotificationAction *nextAction;
    nextAction = [[UIMutableUserNotificationAction alloc] init];
    [nextAction setActivationMode:UIUserNotificationActivationModeForeground];
    [nextAction setTitle:decodedString.string];
    [nextAction setIdentifier:kNotificationCarouselNextIdentifier];
    [nextAction setDestructive:NO];
    [nextAction setAuthenticationRequired:NO];
    
    NSString *previousHtmlString = @"&#9664;&#9664;";
    NSData *previousStringData = [previousHtmlString dataUsingEncoding:NSUTF8StringEncoding];
    
    decodedString = [[NSAttributedString alloc] initWithData:previousStringData
                                                     options:options
                                          documentAttributes:NULL
                                                       error:NULL];
    
    UIMutableUserNotificationAction *previousAction;
    previousAction = [[UIMutableUserNotificationAction alloc] init];
    [previousAction setActivationMode:UIUserNotificationActivationModeForeground];
    [previousAction setTitle:decodedString.string];
    [previousAction setIdentifier:kNotificationCarouselPreviousIdentifier];
    [previousAction setDestructive:NO];
    [previousAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *gotoAppAction;
    gotoAppAction = [[UIMutableUserNotificationAction alloc] init];
    [gotoAppAction setActivationMode:UIUserNotificationActivationModeForeground];
    [gotoAppAction setTitle:@"Go to app"];
    [gotoAppAction setIdentifier:kNotificationCarouselGotoappIdentifier];
    [gotoAppAction setDestructive:NO];
    [gotoAppAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *carouselAnimationCategory;
    carouselAnimationCategory = [[UIMutableUserNotificationCategory alloc] init];
    [carouselAnimationCategory setIdentifier:kNotificationCarouselAnimationIdentifier];
    [carouselAnimationCategory setActions:@[nextAction, previousAction, gotoAppAction]
                               forContext:UIUserNotificationActionContextDefault];
    
    return carouselAnimationCategory;
}

- (NSSet *)notificationCategories {
    return [NSSet setWithObjects:self.buyCategory, self.viewCartCategory, self.oneButtonAlertCategory, self.twoButtonAlertCategory, self.carouselCategory, self.carouselAnimationCategory, nil];
}

- (UIUserNotificationType)notificationTypes {
    return (UIUserNotificationTypeAlert|
            UIUserNotificationTypeSound|
            UIUserNotificationTypeBadge);
}

- (UIUserNotificationSettings *)notificationSettings {
    return [UIUserNotificationSettings settingsForTypes:self.notificationTypes categories:self.notificationCategories];
}

@end
