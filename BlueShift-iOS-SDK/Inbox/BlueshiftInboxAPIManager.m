//
//  BlueshiftInboxAPIManager.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 18/04/23.
//

#import "BlueshiftInboxAPIManager.h"
#import "BlueshiftLog.h"
#import "InAppNotificationEntity.h"
#import "BlueShiftRequestOperationManager.h"
#import "BlueshiftConstants.h"

@implementation BlueshiftInboxAPIManager

+ (void)fetchInAppNotificationWithSuccess:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [BlueshiftInboxAPIManager getMessagesForMessageUUIDs:nil success:^(NSDictionary * _Nonnull data) {
        success(data);
    } failure:^(NSError * _Nullable err, NSArray * _Nullable batch) {
        failure(err);
    }];
}

+ (void)getMessageIdsAndStatus:(void (^)(NSArray* _Nullable))success failure:(void (^)(NSError*))failure {
        [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
            if(apiPayload) {
                NSString *url = [BlueshiftRoutes getInboxStatusURL];
                [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: apiPayload completionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                    if (status) {
                        [BlueshiftLog logAPICallInfo:@"Succesfully fetched status for messages." withDetails:data statusCode:0];
                        NSArray* statusArray = (NSArray*)data[kInAppNotificationContentPayloadKey];
                        if (![statusArray isEqual: [NSNull null]] && statusArray && statusArray.count > 0) {
                            success(statusArray);
                        } else {
                            success(@[]);
                        }
                    } else {
                        failure(error);
                    }
                }];
            }
        }];
}

//This same method will be used to fetch messages for inbox and for inapp notifications.
//If inbox is enabled, then it will use inbox apis to fetch messages.
//If inbox is disabled, then it will use the inapp apis to getch messages.
+ (void)getMessagesForMessageUUIDs:(NSArray* _Nullable)messageIds success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*, NSArray*))failure {
    [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
        if(apiPayload) {
            NSMutableDictionary* payload = [apiPayload mutableCopy];
            NSString *url = nil;
            if (BlueShift.sharedInstance.config.enableMobileInbox == YES) {
                url = [BlueshiftRoutes getInboxMessagesURL];
                if (messageIds) {
                    [payload setValue:messageIds forKey:kBSMessageUUIDs];
                }
            } else {
                url = [BlueshiftRoutes getInAppMessagesURL];
            }
            
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                if (status) {
                    [BlueshiftLog logAPICallInfo:@"Succesfully fetched messages." withDetails:data statusCode:0];
                    success(data);
                } else {
                    failure(error, messageIds);
                }
            }];
        } else {
            NSError *error = (NSError*)@"Unable to fetch messages as device_id is missing.";
            failure(error, messageIds);
        }
    }];
}

+ (void)deleteMessagesWithMessageUUIDs:(NSArray*)messageIds success:(void (^)(void))success failure:(void (^)(NSError*))failure {
    if(BlueShift.sharedInstance.config.apiKey && messageIds && messageIds.count > 0 && [BlueShiftNetworkReachabilityManager networkConnected]) {
        NSString *url = [BlueshiftRoutes getInboxUpdateURL];
        NSDictionary* payload = @{
            kAPIKey: BlueShift.sharedInstance.config.apiKey,
            kDeviceID: BlueShiftDeviceData.currentDeviceData.deviceUUID,
            kBSInboxAction: kBSInboxActionDelete,
            kBSMessageUUIDs: messageIds
        };
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if (status) {
                [BlueshiftLog logAPICallInfo:@"Succesfully deleted messages." withDetails:nil statusCode:0];
                success();
            } else {
                failure(error);
            }
        }];
    } else {
        NSError *error = (NSError*)@"Unable to delete messages as API key is missing or device is offline.";
        failure(error);
    }
}


@end
