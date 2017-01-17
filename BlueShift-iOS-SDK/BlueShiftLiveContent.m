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

+ (void) fetchLiveContent:(NSString *)campaignName success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
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

@end
