//
//  BlueshiftInAppNotificationRequest.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 29/10/19.
//

#import "BlueshiftInAppNotificationRequest.h"

@implementation BlueshiftInAppNotificationRequest

+ (void) fetchInAppNotification:(NSString *)lastMessageID andLastTimestamp:(NSString *)lastTimestamp success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kInAppMessageURL];
    NSString *deviceID = [BlueShiftDeviceData currentDeviceData].deviceUUID.lowercaseString;
    NSString *email = [BlueShiftUserInfo sharedInstance].email;

    NSString *apiKey = @"";
    if([BlueShift sharedInstance].config.apiKey) {
        apiKey = [BlueShift sharedInstance].config.apiKey;
    }
    
    

    if ((deviceID && ![deviceID isEqualToString:@""]) || (email && ![email isEqualToString:@""])) {
        NSMutableDictionary *parameters = [@{
                                        @"bsft_message_uuid" : lastMessageID,
                                        @"api_key" : apiKey,
                                        @"last_timestamp" : (lastTimestamp && ![lastTimestamp isEqualToString:@""]) ? lastTimestamp :@0,
                                        kInAppNotificationModalSDKVersionKey : kSDKVersionNumber
                                        } mutableCopy];
        [parameters addEntriesFromDictionary:[BlueShiftDeviceData currentDeviceData].toDictionary];
        [parameters addEntriesFromDictionary:[BlueShiftAppData currentAppData].toDictionary];
        [parameters addEntriesFromDictionary:[[BlueShiftUserInfo sharedInstance].toDictionary mutableCopy]];
        if (deviceID && parameters[@"device_id"] == nil) {
            [parameters setValue:deviceID forKey:@"device_id"];
        }
        if (email && [parameters objectForKey:@"email"] == nil) {
            [parameters setValue:email forKey:@"email"];
         }
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if (status) {
                success(data);
            } else {
                failure(error);
            }
        }];
    } else {
        NSLog(@"Device ID is not there");
        NSError *error = (NSError*)@"Device ID not set";
        failure(error);
    }
}

@end
