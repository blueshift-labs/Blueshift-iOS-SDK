//
//  BlueshiftRoutes.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/09/21.
//

#import <Foundation/Foundation.h>
#import "BlueshiftRoutes.h"
#import "BlueShift.h"
#import "BlueShiftConfig.h"

@implementation BlueshiftRoutes

+ (NSString*)getBaseURLString {
    NSString *baseURL = kBS_USBaseURL;
    switch (BlueShift.sharedInstance.config.region) {
        case BlueshiftRegionEU:
            baseURL = kBS_EUBaseURL;
            break;
            
        default:
            baseURL = kBS_USBaseURL;
            break;
    }
    return baseURL;
}

+ (NSString*)getRealtimeEventsURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSRealtimeEvent];
    return URLString;
}

+ (NSString*)getBulkEventsURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSBulkEvents];
    return URLString;
}

+ (NSString*)getTrackURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSTrackAPI];
    return URLString;
}

+ (NSString*)getLiveContentURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSLiveContent];
    return URLString;
}

+ (NSString*)getInAppMessagesURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSInAppMessages];
    return URLString;
}

+ (NSString*)getInboxMessagesURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSInboxMessagesPath];
    return URLString;
}

+ (NSString*)getInboxStatusURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSInboxStatusPath];
    return URLString;
}

+ (NSString*)getInboxUpdateURL {
    NSString *baseURL = [self getBaseURLString];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, kBSInboxUpdatePath];
    return URLString;
}

@end
