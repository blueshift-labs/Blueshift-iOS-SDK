//
//  BlueshiftEventAnalyticsHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import "BlueshiftEventAnalyticsHelper.h"
#import "BlueShiftDeviceData.h"
#import "BlueShiftAppData.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@implementation BlueshiftEventAnalyticsHelper

+ (NSDictionary *)pushTrackParameterDictionaryForPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary {
    NSMutableDictionary *pushTrackParametersMutableDictionary = [NSMutableDictionary dictionary];
    if (pushDetailsDictionary) {
        NSString *bsft_experiment_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalExperimentIDKey];
        NSString *bsft_user_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalUserIDKey];
        NSString *message_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalMessageUDIDKey];
        NSString *transactional_uuid = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalTransactionIDKey];
        NSString *sdkVersion = [BlueShiftAppData currentAppData].sdkVersion;
        NSString *clickElement = [self getValueBykey: pushDetailsDictionary andKey: kNotificationClickElementKey];
        NSString *urlElement = [self getValueBykey: pushDetailsDictionary andKey: kNotificationURLElementKey];
        NSString *deviceId = [[BlueShiftDeviceData currentDeviceData] deviceUUID];
        NSString *appName = [[BlueShiftAppData currentAppData] bundleIdentifier];
        NSString *timestamp = [self getCurrentUTCTimestamp];
        NSString* notificationType = [pushDetailsDictionary objectForKey: kNotificationTypeIdentifierKey];
        NSString* openedBy = [pushDetailsDictionary objectForKey:kBSTrackingOpenedBy];
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
        if ([self isNotNilAndNotEmpty:clickElement]) {
            [pushTrackParametersMutableDictionary setObject:clickElement forKey: kNotificationClickElementKey];
        }
        if ([self isNotNilAndNotEmpty:urlElement]) {
            [pushTrackParametersMutableDictionary setObject:urlElement forKey: kNotificationURLElementKey];
        }
        //TODO: verify for push
        if (openedBy && pushDetailsDictionary[kInAppNotificationDataKey][kInAppNotificationKey]) {
            [pushTrackParametersMutableDictionary setObject:openedBy forKey: kBSTrackingOpenedBy];
        }
        
        if([notificationType isEqualToString:kNotificationKey]) {
            NSString *pushDeepLinkURL = @"";
            // If link inside the clk_url is valid, then consider it as deep link.
            if(urlElement) {
                pushDeepLinkURL = urlElement;
            } else {
                // if clk_url is not present, then get the deep link from pushDetailsDictionary for key deep_link_url
                pushDeepLinkURL = [self getValueBykey: pushDetailsDictionary andKey: kPushNotificationDeepLinkURLKey];
            }
            // If not nil, encode and add to track dictionary
            if ([self isNotNilAndNotEmpty:pushDeepLinkURL]) {
                NSString *encodedUrl = [BlueShiftInAppNotificationHelper getEncodedURLString:pushDeepLinkURL];
                if (encodedUrl) {
                    [pushTrackParametersMutableDictionary setObject:encodedUrl forKey: kNotificationURLElementKey];
                }
            }
        }
        if (deviceId) {
            [pushTrackParametersMutableDictionary setObject:deviceId forKey: kDeviceID];
        }
        if (appName) {
            [pushTrackParametersMutableDictionary setObject:appName forKey: kAppName];
        }
        if (timestamp) {
            [pushTrackParametersMutableDictionary setObject:timestamp forKey: kInAppNotificationModalTimestampKey];
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
    return nil;
}

+ (BOOL)isSendPushAnalytics:(NSDictionary *)userInfo {
    if (userInfo && userInfo[@"bsft_seed_list_send"] && [userInfo[@"bsft_seed_list_send"] boolValue] == YES) {
        return NO;
    } else {
        return YES;
    }
}

+(BOOL)isFetchInAppAction:(NSDictionary*)userInfo {
    if (userInfo && [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey]) {
        NSDictionary *silentPushData = [[userInfo objectForKey: kSilentNotificationPayloadIdentifierKey] objectForKey: kInAppNotificationModalSilentPushKey];
        if (silentPushData && [[silentPushData objectForKey:kInAppNotificationAction] isEqual: kInAppNotificationBackgroundFetch]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

+(BOOL)isMarkInAppAsOpen:(NSDictionary*)userInfo {
    if (userInfo && [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey]) {
        NSDictionary *silentPushData = [[userInfo objectForKey: kSilentNotificationPayloadIdentifierKey] objectForKey: kInAppNotificationModalSilentPushKey];
        if (silentPushData && [[silentPushData objectForKey:kInAppNotificationAction] isEqual: kInAppNotificationMarkAsOpen]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

+ (BOOL) isInAppSilenPushNotificationPayload: (NSDictionary*)userInfo {
    BOOL isSilenPushNotificationPayload = false;
    if (userInfo) {
        NSDictionary *dataPayload =  [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey];
        if (dataPayload && [dataPayload objectForKey:kInAppNotificationModalSilentPushKey]) {
            isSilenPushNotificationPayload = true;
        }
    }
    return isSilenPushNotificationPayload;
}

+ (BOOL)isCarouselPushNotificationPayload:(NSDictionary *)userInfo {
    if (userInfo != nil) {
        NSString *categoryName = [[userInfo objectForKey: kNotificationAPSIdentifierKey] objectForKey: kNotificationCategoryIdentifierKey];
        if(categoryName !=nil && ![categoryName isEqualToString:@""]) {
            return ([categoryName isEqualToString: kNotificationCarouselIdentifier] || [categoryName isEqualToString: kNotificationCarouselAnimationIdentifier]);
        }
    }
    
    return false;
}

+ (NSMutableDictionary *)getQueriesFromURL:(NSURL *)URL {
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    @try {
        if (URL !=  nil && [URL absoluteString] != nil && ![URL.absoluteString isEqualToString:@""]) {
            NSURLComponents *URLComponents =[[NSURLComponents alloc] initWithString: URL.absoluteString];
             if (@available(iOS 8.0, *)) {
                 if (URLComponents != nil && [URLComponents queryItems] != nil && [URLComponents.queryItems count] > 0) {
                     for (NSURLQueryItem *queryItem in URLComponents.queryItems) {
                         if (queryItem && queryItem.value && queryItem.name) {
                             [queryDictionary setObject:queryItem.value forKey:queryItem.name];
                         }
                    }
                 }
             }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    return queryDictionary;
}

+(BOOL)isNotNilAndNotEmpty:(NSString*)string {
    @try {
        if (string && ![string isEqualToString:@""]) {
            return YES;
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
    return NO;
}

+ (BOOL)isSchedulePushNotification:(NSDictionary*)userInfo {
    BOOL isSchedulePushNotification = false;
    if (userInfo) {
        if ([[userInfo valueForKey: kNotificationTypeIdentifierKey] isEqual: kNotificationSchedulerKey]) {
            isSchedulePushNotification = true;
        }
    }
    return isSchedulePushNotification;
}

+ (NSString *)getCurrentUTCTimestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601]];
    [dateFormatter setDateFormat:kDefaultDateFormat];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (void)addToDictionary:(NSMutableDictionary*)dictionary key:(NSString*)key value:(id)value {
    @try {
        if (dictionary && key && value) {
            [dictionary setValue:value forKey:key];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
