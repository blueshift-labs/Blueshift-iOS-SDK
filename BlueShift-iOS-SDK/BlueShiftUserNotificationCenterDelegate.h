//
//  BlueShiftUserNotificationCenterDelegate.h
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 28/03/18.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "BlueShift.h"

@interface BlueShiftUserNotificationCenterDelegate : NSObject<UNUserNotificationCenterDelegate>

- (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0));

/// Call this method in the `userNotificationCenter: didReceive response` method of the `UNUserNotificationCenterDelegate` method.
/// @discussion This method will track the push notification clicks and deliver the associated deep link in the `open url` method of the appDelegate.
- (void)handleUserNotification:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0));

@end
