//
//  BlueShiftLiveContent.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 13/01/17.
//  Copyright © 2017 Bullfinch Software. All rights reserved.
//

#import "BlueShiftLiveContent.h"
#import "BlueShiftRequestOperationManager.h"
#import "BlueshiftLog.h"

@implementation BlueShiftLiveContent

+ (void) fetchLiveContentByEmail:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [self fetchLiveContentByEmail:campaignName withContext:nil success:^(NSDictionary *data) {
        success(data);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [self fetchLiveContentByCustomerID:campaignName withContext:nil success:^(NSDictionary * data) {
        success(data);
    } failure:^(NSError * error) {
        failure(error);
    }];
}

+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [self fetchLiveContentByDeviceID:campaignName withContext:nil success:^(NSDictionary *data) {
        success(data);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

+ (void) fetchLiveContentByEmail:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    if(email && apiKey && campaignName) {
        if(!context) {
            context = @{};
        }
        NSDictionary *userData = @{
                                        @"email":email
                                   };
        NSDictionary *parameters = @{
                                         @"api_key":apiKey,
                                         @"slot":campaignName,
                                         @"user": userData,
                                         @"context":context
                                     };
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if(status) {
                success(data);
            } else {
                failure(error);
            }
        }];
    } else {
        NSError *error = (NSError*)@"Email Id, SDK API key and campaign name are required to fetch live content. Set Email Id in BlueshiftUserInfo and set API key during the SDK initialisation.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *customerID = [BlueShiftUserInfo sharedInstance].retailerCustomerID;
    if(customerID && apiKey && campaignName) {
        if(!context) {
            context = @{};
        }
        NSDictionary *userData = @{
                                        @"customer_id":customerID
                                   };
        NSDictionary *parameters = @{
                                         @"api_key":apiKey,
                                         @"slot":campaignName,
                                         @"user": userData,
                                         @"context":context
                                     };
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if(status) {
                success(data);
            } else {
                failure(error);
            }
        }];
    } else {
        NSError *error = (NSError*)@"Customer Id, SDK API key and campaign name are required to fetch live content. Set Customer Id in BlueshiftUserInfo and set API key during the SDK initialisation.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *deviceID = [BlueShiftDeviceData currentDeviceData].deviceUUID;
    if(deviceID && apiKey && campaignName) {
        if(!context) {
            context = @{};
        }
        NSDictionary *userData = @{
                                        @"device_id":deviceID
                                   };
        NSDictionary *parameters = @{
                                         @"api_key":apiKey,
                                         @"slot":campaignName,
                                         @"user": userData,
                                         @"context":context
                                     };
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if(status) {
                success(data);
            } else {
                failure(error);
            }
        }];
    } else {
        NSError *error = (NSError*)@"Device id, SDK API key and campaign name are required to fetch live content. Set API key during the SDK initialisation.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

@end
