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
    NSString *lastTimestamp = [self getValueBykey: pushDetailsDictionary andKey: kInAppNotificationModalTimestampKey];
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
    if (lastTimestamp) {
        [pushTrackParametersMutableDictionary setObject:lastTimestamp forKey: kInAppNotificationCreatedTimestampKey];
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

+ (BOOL) isInAppMessagePayload: (NSDictionary*)userInfo {
    BOOL isIAMPayloadPresent = false;
    if (nil != userInfo) {
        NSDictionary *dataPayload =  [userInfo objectForKey: kSilentNotificationPayloadIdentifierKey];
        if (nil != dataPayload) {
            isIAMPayloadPresent = true;
        } else {
            NSDictionary *apNSData = [userInfo objectForKey:@"aps"];
            NSNumber *num = [NSNumber numberWithInt:1];
            isIAMPayloadPresent = [[apNSData objectForKey:@"content-available"] isEqualToNumber:num];
        }
    }
    
    return isIAMPayloadPresent;
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
    @try {
        NSMutableDictionary *queryDictionary =[[NSMutableDictionary alloc] init];
        if (URL !=  nil && [URL absoluteString] != nil && ![URL.absoluteString isEqualToString:@""]) {
            NSURLComponents *URLComponents =[[NSURLComponents alloc] initWithString: URL.absoluteString];
             if (@available(iOS 8.0, *)) {
                 if (URLComponents != nil && [URLComponents queryItems] != nil && [URLComponents.queryItems count] > 0) {
                     for (NSURLQueryItem *queryItem in URLComponents.queryItems) {
                        [queryDictionary setObject:queryItem.value forKey:queryItem.name];
                    }
                 }
             }
        }
        
        return queryDictionary;
    } @catch (NSException *exception) {
        NSLog(@"Caught exception %@", exception);
    }
    
}

@end
