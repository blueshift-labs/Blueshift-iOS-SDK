//
//  BlueshiftInAppNotificationRequest.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 29/10/19.
//

#import "BlueshiftInAppNotificationRequest.h"
#import "BlueshiftLog.h"

@implementation BlueshiftInAppNotificationRequest

+ (void) fetchInAppNotificationWithSuccess:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
        if(apiPayload) {
            NSString *url = [BlueshiftRoutes getInAppMessagesURL];
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: apiPayload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                if (status) {
                    [BlueshiftLog logAPICallInfo:@"Succesfully fetched in-app messages." withDetails:data statusCode:0];
                    success(data);
                } else {
                    failure(error);
                }
            }];
        } else {
            NSError *error = (NSError*)@"Unable to fetch in-app messages as device_id is missing.";
            failure(error);
        }
    }];
}

@end
