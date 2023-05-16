//
//  BlueShiftPushNotificationSettings.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 05/11/17.
//

#import "BlueShiftPushNotificationSettings.h"
#import "BlueShiftNotificationConstants.h"

@implementation BlueShiftPushNotificationSettings

- (UIMutableUserNotificationCategory *)carouselCategory  API_AVAILABLE(ios(8.0)){
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

- (UIMutableUserNotificationCategory *)carouselAnimationCategory  API_AVAILABLE(ios(8.0)){
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
    return [NSSet setWithObjects: self.carouselCategory, self.carouselAnimationCategory, nil];
}

- (UIUserNotificationType)notificationTypes  API_AVAILABLE(ios(8.0)){
    return (UIUserNotificationTypeAlert|
            UIUserNotificationTypeSound|
            UIUserNotificationTypeBadge);
}

- (UIUserNotificationSettings *)notificationSettings  API_AVAILABLE(ios(8.0)){
    return [UIUserNotificationSettings settingsForTypes:self.notificationTypes categories:self.notificationCategories];
}

@end
