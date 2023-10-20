//
//  BlueShiftUserNotificationCenterDelegate.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 28/03/18.
//

#import "BlueShiftUserNotificationCenterDelegate.h"
#import "BlueshiftLog.h"

@implementation BlueShiftUserNotificationCenterDelegate

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    [self handleUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options) {
        completionHandler(options);
    }];
}

- (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    NSDictionary *userInfo = notification.request.content.userInfo;
    [BlueshiftLog logInfo:@"Push Notification received" withDetails:userInfo methodName:nil];
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    [self handleUserNotification:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

- (void)handleUserNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    [BlueshiftLog logInfo:[NSString stringWithFormat:@"Push notification action response received - %@", response.actionIdentifier] withDetails:response methodName:nil];
    if([response.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"]) {
        [[BlueShift sharedInstance].appDelegate handleRemoteNotification:response.notification.request.content.userInfo];
    } else if ([response.actionIdentifier isEqualToString:@"com.apple.UNNotificationDismissActionIdentifier"]) {
        [BlueshiftLog logInfo:@"Blueshift: Push notification dismissed." withDetails:nil methodName:nil];
    } else {
        [[BlueShift sharedInstance].appDelegate handleActionWithIdentifier:response.actionIdentifier forRemoteNotification:response.notification.request.content.userInfo completionHandler:^{}];
    }
    
    // Update the badge only if the push notification is of type 'auto update badge'
    if ([BlueShift.sharedInstance isAutoUpdateBadgePushNotification:response.notification.request]) {
        [BlueShift.sharedInstance refreshApplicationBadgeWithCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}

@end
