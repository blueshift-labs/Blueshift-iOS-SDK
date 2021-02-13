//
//  BlueshiftExtensionAnalyticsHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import <Foundation/Foundation.h>
#import "BlueshiftExtensionConstants.h"
#import "ExtensionSDKVersion.h"
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftExtensionAnalyticsHelper : NSObject

/// This method is responsible to convert the push notification payload to the tracking attributes.
/// @param pushDetailsDictionary  push notification payload
/// @returns push tracking attributes dictionary
+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary;

+ (NSString *)getValueBykey:(NSDictionary *)notificationPayload andKey:(NSString *)key;
+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo;
+ (NSString *)getCurrentUTCTimestamp;

/// This method is used to get the push notification payload which can be used to fire delivered event externally by the host app.
/// This method adds the device specific attributes (device_id, app_name) to the push payload.
/// @param request  Push notification request
/// @returns dictionary which includes device attributes and push payload
+ (NSDictionary *)getPushNotificationDeliveredPayload:(UNNotificationRequest *)request API_AVAILABLE(ios(10.0));

@end

NS_ASSUME_NONNULL_END
