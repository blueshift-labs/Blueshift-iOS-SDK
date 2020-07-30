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
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    if(email) {
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
    } else {
        NSError *error = (NSError*)@"Email id is required to fetch live content by email. Set emailId in BlueshiftUserInfo";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *customerID = [BlueShiftUserInfo sharedInstance].retailerCustomerID;
    if(customerID) {
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
    } else {
        NSError *error = (NSError*)@"Customer id is required to fetch live content by email. Set customerId in BlueshiftUserInfo";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *deviceID = [BlueShiftDeviceData currentDeviceData].deviceUUID;
    if(deviceID) {
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
    } else {
        NSError *error = (NSError*)@"Device id is required to fetch live content by deviceId.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByEmail:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *email = [BlueShiftUserInfo sharedInstance].email;
    if(email) {
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
        NSError *error = (NSError*)@"Email id is required to fetch live content by email. Set emailId in BlueshiftUserInfo";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByCustomerID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *customerID = [BlueShiftUserInfo sharedInstance].retailerCustomerID;
    if(customerID) {
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
        NSError *error = (NSError*)@"Customer id is required to fetch live content by email. Set customerId in BlueshiftUserInfo";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

+ (void) fetchLiveContentByDeviceID:(NSString *)campaignName withContext:(NSDictionary *)context success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kLiveContent];
    NSString *apiKey = [BlueShift sharedInstance].config.apiKey;
    NSString *deviceID = [BlueShiftDeviceData currentDeviceData].deviceUUID;
    if(deviceID) {
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
        NSError *error = (NSError*)@"Device id is required to fetch live content by deviceId.";
        [BlueshiftLog logError:error withDescription:nil methodName:nil];
        failure(error);
    }
}

@end
