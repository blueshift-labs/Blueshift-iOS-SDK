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
        NSString *bsft_experiment_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalExperimentIDKey];
        NSString *bsft_user_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalUserIDKey];
        NSString *message_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalMessageUDIDKey];
        NSString *transactional_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalTransactionIDKey];
        NSString *sdkVersion = [[[NSBundle bundleForClass:self.class] infoDictionary] objectForKey:kCFBundleShortVersionString];
        NSString *element = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalElementKey];
        NSString *timestamp = [self getCurrentUTCTimestamp];
        NSString *deviceId = (NSString *)[pushDetailsDictionary objectForKey:kDeviceID];
        NSString *appName = (NSString *)[pushDetailsDictionary objectForKey:kAppName];
        
        if (bsft_user_uuid) {
            [pushTrackParametersMutableDictionary setObject:bsft_user_uuid forKey: kInAppNotificationModalUIDKey];
        }
        if(bsft_experiment_uuid) {
            [pushTrackParametersMutableDictionary setObject:bsft_experiment_uuid forKey: kInAppNotificationModalEIDKey];
        }
        if (message_uuid) {
            [pushTrackParametersMutableDictionary setObject:message_uuid forKey: kInAppNotificationModalMIDKey];
        }
        if (transactional_uuid) {
            [pushTrackParametersMutableDictionary setObject:transactional_uuid forKey: kInAppNotificationModalTXNIDKey];
        }
        if (sdkVersion) {
            [pushTrackParametersMutableDictionary setObject:sdkVersion forKey: kInAppNotificationModalSDKVersionKey];
        }
        if (element) {
            [pushTrackParametersMutableDictionary setObject:element forKey: kInAppNotificationModalElementKey];
        }
        if (timestamp) {
            [pushTrackParametersMutableDictionary setObject:timestamp forKey: kInAppNotificationModalTimestampKey];
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

+ (NSString *)getValueBykey:(NSDictionary *)notificationPayload andKey:(NSString *)key {
    if (notificationPayload && key && ![key isEqualToString:@""]) {
        if ([notificationPayload objectForKey: key]) {
            return (NSString *)[notificationPayload objectForKey: key];
        } else if ([notificationPayload objectForKey: kSilentNotificationPayloadIdentifierKey]){
            notificationPayload = [notificationPayload objectForKey: kSilentNotificationPayloadIdentifierKey];
            return (NSString *)[notificationPayload objectForKey: key];
        }
    }
    
    return @"";
}

+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo {
    if (userInfo && userInfo[@"bsft_seed_list_send"] && [userInfo[@"bsft_seed_list_send"] boolValue] == YES) {
        return NO;
    } else {
        return YES;
    }
}

+ (NSString *)getCurrentUTCTimestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
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
