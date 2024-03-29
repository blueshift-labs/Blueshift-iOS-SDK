//
//  BlueshiftExtensionAnalyticsHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import <Foundation/Foundation.h>
#import "BlueshiftExtensionConstants.h"
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftExtensionAnalyticsHelper : NSObject

/// This method is used to get the push notification payload which can be used to fire delivered event externally by the host app.
/// This method adds the device specific attributes (device_id, app_name) to the push payload.
/// @param request  Push notification request
/// @returns dictionary which includes device attributes and push payload
+ (NSDictionary * _Nullable)getPushNotificationDeliveredPayload:(UNNotificationRequest *)request API_AVAILABLE(ios(10.0)) DEPRECATED_MSG_ATTRIBUTE("This method is deprecated as Blueshift iOS Extension SDK will no longer send the `delivered` event for push notifications and will be removed in the future SDK release.");;

@end

NS_ASSUME_NONNULL_END
