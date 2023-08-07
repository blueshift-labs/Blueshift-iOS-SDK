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

/// The Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications, so there is no need of setting the API key.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This variable is deprecated and will  be removed in the future release.
@property NSString *apiKey DEPRECATED_MSG_ATTRIBUTE("Extension SDK no longer requires the API key and this variable will be removed in the future SDK release.");

/// The SDK will no longer use the app group id for firing the push `delivered` event, so there is no need of setting appGroupId value here.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This variable is deprecated and will  be removed in the future release.
@property NSString* appGroupId DEPRECATED_MSG_ATTRIBUTE("This variable is deprecated and will be removed in the future SDK release.");

+ (instancetype _Nullable) sharedInstance;

/// Download the media for rendering the Rich push notificaiton.
/// @param request UNNotificationRequest
/// @param appGroupID This method no longer uses the appGroupId value, this parameter is marked as deprecated
/// and will be removed from the method definition in the future SDK release. You may pass `nil` as value for this param.
- (NSArray *)integratePushNotificationWithMediaAttachementsForRequest:(UNNotificationRequest *)request andAppGroupID:(NSString * _Nullable)appGroupID;

/// Check if the push notification is from Blueshift.
/// @param request   push notification request.
/// @returns true or false based on if push notification is from Blueshift or not.
- (BOOL)isBlueShiftPushNotification:(UNNotificationRequest *)request;

- (BOOL)hasBlueShiftAttachments;

- (NSNumber* _Nullable)getUpdatedBadgeNumberForRequest:(UNNotificationRequest *)request;

/// The Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications.
/// Blueshift will now provide the push delivery stats based on the APNS's response.
/// This method is deprecated and will  be removed in the future release.
- (void)trackPushViewedWithRequest:(UNNotificationRequest *)request DEPRECATED_MSG_ATTRIBUTE("This method is deprecated as Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications and will be removed in the future SDK release.");

@end

NS_ASSUME_NONNULL_END
