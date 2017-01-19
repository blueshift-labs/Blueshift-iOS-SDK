//
//  BlueShiftLiveContent.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 13/01/17.
//  Copyright © 2017 Bullfinch Software. All rights reserved.
//

#import "BlueShiftLiveContent.h"
#import "BlueShiftRequestOperationManager.h"

@implementation BlueShiftLiveContent

+ (void) fetchLiveContentByEmail:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *slot = campaignName;
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    NSDictionary *parameters = @{
                                 @"x":apiKey,
                                 @"slot":campaignName,
                                 @"email":email
                                 };
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] getRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
        if(status) {
            success(data);
        } else {
            failure(error);
        }
    }];
}

+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *slot = campaignName;
    NSString *customerID = [BlueShiftUserInfo sharedInstance].retailerCustomerID;
    NSDictionary *parameters = @{
                                 @"x":apiKey,
                                 @"slot":campaignName,
                                 @"customer_id":customerID
                                 };
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] getRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
        if(status) {
            success(data);
        } else {
            failure(error);
        }
    }];
}

+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *slot = campaignName;
    NSString *deviceID = [BlueShift sharedInstance].deviceData.deviceIDFV;
    NSDictionary *parameters = @{
                                 @"x":apiKey,
                                 @"slot":campaignName,
                                 @"device_id":deviceID
                                 };
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] getRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
        if(status) {
            success(data);
        } else {
            failure(error);
        }
    }];
}

@end
