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
@property NSString *apiKey;
@property NSString* appGroupId;

+ (instancetype) sharedInstance;
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString *)appGroupID;
- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;
- (BOOL)hasBlueShiftAttachments;
- (void)trackPushViewedWithRequest:(UNNotificationRequest *)request;

@end
