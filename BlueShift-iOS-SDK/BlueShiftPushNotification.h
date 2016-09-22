//
//  BlueShiftPushNotification.h
//  Pods
//
//  Created by Shahas on 18/09/16.
//
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface BlueShiftPushNotification : NSObject

+ (instancetype) sharedInstance;
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request;

@end
