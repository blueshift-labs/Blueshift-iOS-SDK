//
//  BlueshiftExtensionAnalyticsHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import "BlueshiftExtensionAnalyticsHelper.h"
#import "BlueShiftPushAnalytics.h"
#import "BlueshiftExtensionConstants.h"

@implementation BlueshiftExtensionAnalyticsHelper

+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    NSMutableDictionary *pushTrackParametersMutableDictionary = [NSMutableDictionary dictionary];
    if (pushDetailsDictionary) {
        NSString *bsft_experiment_uuid = [self getValueFrom:pushDetailsDictionary usingKey:kNotificationExperimentIDKey];
        NSString *bsft_user_uuid = [self getValueFrom:pushDetailsDictionary usingKey:kNotificationUserIDKey];
        NSString *message_uuid = [self getValueFrom:pushDetailsDictionary usingKey:kNotificationMessageUDIDKey];
        NSString *transactional_uuid = [self getValueFrom:pushDetailsDictionary usingKey:kNotificationTransactionIDKey];
        NSString *sdkVersion = [[[NSBundle bundleForClass:self.class] infoDictionary] objectForKey:kCFBundleShortVersionString];
        NSString *timestamp = [self getCurrentUTCTimestamp];
        NSString *deviceId = (NSString *)[pushDetailsDictionary objectForKey:kDeviceID];
        NSString *appName = (NSString *)[pushDetailsDictionary objectForKey:kAppName];
        
        if (bsft_user_uuid) {
            [pushTrackParametersMutableDictionary setObject:bsft_user_uuid forKey: kNotificationUIDKey];
        }
        if(bsft_experiment_uuid) {
            [pushTrackParametersMutableDictionary setObject:bsft_experiment_uuid forKey: kNotificationEIDKey];
        }
        if (message_uuid) {
            [pushTrackParametersMutableDictionary setObject:message_uuid forKey: kNotificationMIDKey];
        }
        if (transactional_uuid) {
            [pushTrackParametersMutableDictionary setObject:transactional_uuid forKey: kNotificationTXNIDKey];
        }
        if (sdkVersion) {
            [pushTrackParametersMutableDictionary setObject:sdkVersion forKey: kNotificationSDKVersionKey];
        }
        if (timestamp) {
            [pushTrackParametersMutableDictionary setObject:timestamp forKey: kNotificationTimestampKey];
        }
        if (deviceId) {
            [pushTrackParametersMutableDictionary setObject:deviceId forKey: kDeviceID];
        }
        if (appName) {
            [pushTrackParametersMutableDictionary setObject:appName forKey: kAppName];
        }
    }
    return [pushTrackParametersMutableDictionary copy];
}

+ (NSString * _Nullable)getValueFrom:(NSDictionary *)notificationPayload usingKey:(NSString *)key {
    if (notificationPayload && key && ![key isEqualToString:@""]) {
        if ([notificationPayload objectForKey:key]) {
            return (NSString *)[notificationPayload objectForKey:key];
        }
    }
    return nil;
}

+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo {
    if (userInfo && userInfo[kNotificationSeedListSend] && [userInfo[kNotificationSeedListSend] boolValue] == YES) {
        return NO;
    } else {
        return YES;
    }
}

+ (NSString *)getCurrentUTCTimestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDefaultTimezoneFormat];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:kTimezoneUTC]];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSDictionary * _Nullable)getPushNotificationDeliveredPayload:(UNNotificationRequest *)request {
    NSMutableDictionary *userInfo = [request.content.userInfo mutableCopy];
    NSDictionary* deviceData = (NSDictionary*)[BlueShiftPushAnalytics getDeviceData];
    if (userInfo && deviceData) {
        if ([deviceData objectForKey:kDeviceID]) {
            [userInfo setValue:[deviceData objectForKey:kDeviceID] forKey:kDeviceID];
        }
        if ([deviceData objectForKey:kAppName]) {
            [userInfo setValue:[deviceData objectForKey:kAppName] forKey:kAppName];
        }
    }
    return userInfo;
}

@end
