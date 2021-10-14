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

/// The Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications, so there is no need of setting the API key.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This variable is deprecated and will  be removed in the future release.
@property NSString *apiKey DEPRECATED_MSG_ATTRIBUTE("Extension SDK no longer requires the API key and this variable will be removed in the future SDK release.");

/// The SDK will no longer use the app group id for firing the push `delivered` event, so there is no need of setting appGroupId value.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This variable is deprecated and will  be removed in the future release.
@property NSString* appGroupId DEPRECATED_MSG_ATTRIBUTE("This variable is deprecated and will be removed in the future SDK release.");

+ (instancetype) sharedInstance;

/// Download the media for rendering the Rich push notificaiton.
/// @param request UNNotificationRequest
/// @param appGroupID This method no longer uses the appGroupId value, this parameter is marked as deprecated
/// and will be removed from the method definition in the future SDK release.
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString *)appGroupID;

- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;

- (BOOL)hasBlueShiftAttachments;

/// The Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This method is deprecated and will  be removed in the future release.
- (void)trackPushViewedWithRequest:(UNNotificationRequest *)request DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in the future SDK release.");

@end
