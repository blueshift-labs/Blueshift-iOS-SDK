//
//  BlueShiftPushNotification.h
////  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(10.0))
@interface BlueShiftPushNotification : NSObject

@property NSArray <UNNotificationAttachment *>* _Nullable attachments;

+ (instancetype _Nullable) sharedInstance;

/// Download the media for rendering the Rich push notificaiton.
/// @param request UNNotificationRequest
/// @param appGroupID This method no longer uses the appGroupId value, this parameter is marked as deprecated
/// and will be removed from the method definition in the future SDK release. You may pass `nil` as value for this param.
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString * _Nullable)appGroupID DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in future. Use method `integratePushNotificationWithMediaAttachementsForRequest` instead.");

/// Download the media for rendering the Rich push notificaiton.
/// @param request UNNotificationRequest
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request;

/// Check if the push notification is from Blueshift.
/// @param request   push notification request.
/// @returns true or false based on if push notification is from Blueshift or not.
- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;

- (BOOL)hasBlueShiftAttachments;

/// Returns the number of pending notifications (including the current notification)  in the notification center.
/// You should assign this number to badge, so that the iOS will update the badge number on app icon after presenting the notificaiton.
/// - Parameter request: notification request
- (NSNumber* _Nullable)getUpdatedBadgeNumberForRequest:(UNNotificationRequest *)request;

@end

NS_ASSUME_NONNULL_END
