//
//  BlueShiftPushNotification.h
////  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

API_AVAILABLE(ios(10.0))
@interface BlueShiftPushNotification : NSObject

@property NSArray <UNNotificationAttachment *>* attachments;

+ (instancetype) sharedInstance;

/// Download the media for rendering the Rich push notificaiton.
/// @param request UNNotificationRequest
- (NSArray<UNNotificationAttachment*> *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request;

- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;

- (BOOL)hasBlueShiftAttachments;

@end
