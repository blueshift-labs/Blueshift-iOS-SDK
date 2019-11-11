//
//  BlueshiftEventAnalyticsHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import "BlueshiftEventAnalyticsHelper.h"

@implementation BlueshiftEventAnalyticsHelper

+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    NSString *bsft_experiment_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalExperimentIDKey];
    NSString *bsft_user_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalUserIDKey];
    NSString *message_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalMessageUDIDKey];
    NSString *transactional_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalTransactionIDKey];
    NSString *sdkVersion = [NSString stringWithFormat:@"%@", kSDKVersionNumber];
    NSString *element = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalElementKey];
    NSMutableDictionary *pushTrackParametersMutableDictionary = [NSMutableDictionary dictionary];
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

+ (BOOL)isSilentPushNotification:(NSDictionary *)userInfo {
    if (userInfo && [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey]
        && [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey] != [NSNull null]) {
        userInfo = [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey];
        return (userInfo && [userInfo objectForKey: kInAppNotificationModalSilentPushKey] && [userInfo objectForKey: kInAppNotificationModalSilentPushKey] != [NSNull null]);
    } else {
        return NO;
    }
}

@end
