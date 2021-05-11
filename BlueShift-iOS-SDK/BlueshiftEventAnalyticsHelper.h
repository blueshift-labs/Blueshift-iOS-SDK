//
//  BlueshiftEventAnalyticsHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftNotificationConstants.h"
#import "SDKVersion.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftEventAnalyticsHelper : NSObject

+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary;
+ (NSString *)getValueBykey:(NSDictionary *)notificationPayload andKey:(NSString *)key;
+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo;
+ (BOOL) isSilenPushNotificationPayload:(NSDictionary*)userInfo;
+ (BOOL)isCarouselPushNotificationPayload:(NSDictionary *)userInfo;
+ (NSMutableDictionary *)getQueriesFromURL:(NSURL *)url;
+ (BOOL)isMarkInAppAsOpen:(NSDictionary*)userInfo;
+ (BOOL)isFetchInAppAction:(NSDictionary*)userInfo;
+ (BOOL)isSchedulePushNotification:(NSDictionary*)userInfo;

/// Returns current UTC timestamp with format 2020-12-14T13:35:34.034000Z
+ (NSString *)getCurrentUTCTimestamp;

/// Check for nil and add the key value to the given dictionary
+ (void)addToDictionary:(NSMutableDictionary*)dictionary key:(NSString*)key value:(id)value;


/// Checks if the string is not nil and not empty
/// @param string  string value to check
/// @returns BOOL YES when string is valid
+(BOOL)isNotNilAndNotEmpty:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
