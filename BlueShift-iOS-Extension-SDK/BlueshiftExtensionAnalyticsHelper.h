//
//  BlueshiftExtensionAnalyticsHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import <Foundation/Foundation.h>
#import "BlueshiftExtensionConstants.h"
#import "ExtensionSDKVersion.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftExtensionAnalyticsHelper : NSObject

+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary;
+ (NSString *)getValueBykey:(NSDictionary *)notificationPayload andKey:(NSString *)key;
+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo;
+ (NSString *)getCurrentUTCTimestamp;

@end

NS_ASSUME_NONNULL_END
