//
//  BlueshiftInAppNotificationRequest.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 29/10/19.
//

#import "BlueshiftInAppNotificationRequest.h"
#import "BlueShiftRequestOperationManager.h"

@implementation BlueshiftInAppNotificationRequest

+ (void) fetchInAppNotification:(NSString *)lastMessageID andLastTimestamp:(NSString *)lastTimestamp success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kInAppMessageURL];
    
    NSString *deviceID = @"";
    if ([BlueShift sharedInstance].deviceData.deviceIDFV) {
        deviceID = [BlueShift sharedInstance].deviceData.deviceIDFV.lowercaseString;
    }
    
    NSString *apiKey = @"";
    if([BlueShift sharedInstance].config.apiKey) {
        apiKey = [BlueShift sharedInstance].config.apiKey;
    }
    
    NSString *email = @"";
    if ([BlueShiftUserInfo sharedInstance].email) {
        email = [BlueShiftUserInfo sharedInstance].email;
    }
    
    deviceID = @"ade9bc2d-3315-4519-bf03-886eee979797";
    
    if ((deviceID && ![deviceID isEqualToString:@""]) || (email && ![email isEqualToString:@""])) {
        NSDictionary *parameters = @{
                                        @"email":email,
                                        @"bsft_message_uuid" : lastMessageID,
                                        @"api_key" : apiKey,
                                        @"device_id": deviceID,
                                        @"last_timestamp" : (lastTimestamp && ![lastTimestamp isEqualToString:@""]) ? lastTimestamp :@0
                                    };
        
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
