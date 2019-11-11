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
+ (BOOL)isSilentPushNotification:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
