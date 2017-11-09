//
//  BlueShiftPushNotification.h
////  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface BlueShiftPushNotification : NSObject

@property NSArray <UNNotificationAttachment *>* attachments;

+ (instancetype) sharedInstance;
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request;
- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;
- (BOOL)hasBlueShiftAttachments;

@end
