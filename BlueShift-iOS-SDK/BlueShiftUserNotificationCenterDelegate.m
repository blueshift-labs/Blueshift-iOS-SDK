//
//  BlueShiftUserNotificationCenterDelegate.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 28/03/18.
//

#import "BlueShiftUserNotificationCenterDelegate.h"

@implementation BlueShiftUserNotificationCenterDelegate

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    [self handleUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options) {
        completionHandler(options);
    }];
}

- (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    NSDictionary *userInfo = notification.request.content.userInfo;
    if([[userInfo objectForKey:@"notification_type"] isEqualToString:@"notification"]) {
        completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    } else {
        [[BlueShift sharedInstance].appDelegate presentInAppAlert:notification.request.content.userInfo];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    [self handleUserNotification:center didReceiveNotificationResponse:response withCompletionHandler:^{
    }];
    completionHandler();
}

- (void)handleUserNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    if([response.actionIdentifier isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"]) {
        [[BlueShift sharedInstance].appDelegate handleRemoteNotification:response.notification.request.content.userInfo];
    } else {
        [[BlueShift sharedInstance].appDelegate handleActionWithIdentifier:response.actionIdentifier forRemoteNotification:response.notification.request.content.userInfo completionHandler:^{
        }];
    }
}

@end
