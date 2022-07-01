//
//  BlueshiftExtensionAnalyticsHelper.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 18/10/19.
//

#import "BlueshiftExtensionAnalyticsHelper.h"

@implementation BlueshiftExtensionAnalyticsHelper

+ (NSDictionary * _Nullable)getPushNotificationDeliveredPayload:(UNNotificationRequest *)request {
    NSMutableDictionary *userInfo = [request.content.userInfo mutableCopy];
    return userInfo;
}

@end
