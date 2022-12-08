//
//  BlueshiftInAppNotificationRequest.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 29/10/19.
//

#import "BlueshiftInAppNotificationRequest.h"
#import "BlueshiftLog.h"
#import "InAppNotificationEntity.h"

@implementation BlueshiftInAppNotificationRequest

+ (void)fetchInAppNotificationWithSuccess:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [BlueshiftInboxAPIManager getMessagesForMessageUUIDs:nil success:^(NSDictionary * _Nonnull data) {
        success(data);

    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

@end

@implementation BlueshiftInboxAPIManager

+ (void)getUnreadStatus:(void (^)(NSArray*))success failure:(void (^)(NSError*))failure {
    //TODO: remove the fetchAllMessagesForTrigger method call later
    [InAppNotificationEntity fetchAllMessagesForInbox:NSOrderedSame handler:^(BOOL status, NSArray *messages) {
        NSMutableDictionary* existingMessages = [[NSMutableDictionary alloc] init];
        for(InAppNotificationEntity* message in messages) {
            if([message.status isEqualToString:kInAppStatusPending]) {
                [existingMessages setValue:@NO forKey:message.id];
            } else {
                [existingMessages setValue:@YES forKey:message.id];
            }
        }
        // till here remove
        
        [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
            if(apiPayload) {
                //TODO: below line to be removed later
                NSMutableDictionary* payload = [apiPayload mutableCopy];
                [payload setObject:@[existingMessages] forKey:@"content"];
                
                NSString *url = [BlueshiftRoutes getInboxStatusURL];
                [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                    if (status) {
                        [BlueshiftLog logAPICallInfo:@"Succesfully fetched status for messages." withDetails:data statusCode:0];
                        NSArray* statusArray = (NSArray*)data[@"content"];
                        if (statusArray && statusArray.count > 0) {
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
    }];
}

+ (void)getMessagesForMessageUUIDs:(NSArray* _Nullable)messageIds success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
        if(apiPayload) {
            NSMutableDictionary* payload = [apiPayload mutableCopy];
            NSString *url = nil;
            if (BlueShift.sharedInstance.config.enableMobileInbox == YES) {
                url = [BlueshiftRoutes getInboxMessagesURL];
                if (messageIds) {
                    [payload setValue:messageIds forKey:@"message_uuids"];
                }
            } else {
                url = [BlueshiftRoutes getInAppMessagesURL];
            }
            
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
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

+ (void)deleteMessagesWithMessageUUIDs:(NSArray*)messageIds success:(void (^)(BOOL))success failure:(void (^)(NSError*))failure {
    if(BlueShift.sharedInstance.config.apiKey && messageIds && messageIds.count > 0 && [BlueShiftNetworkReachabilityManager networkConnected]) {
        NSString *url = [BlueshiftRoutes getInboxUpdateURL];
        NSDictionary* payload = @{
            @"api_key": BlueShift.sharedInstance.config.apiKey,
            @"device_id": BlueShiftDeviceData.currentDeviceData.deviceUUID,
            @"action": @"delete",
            @"message_uuids": messageIds
        };
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if (status) {
                [BlueshiftLog logAPICallInfo:@"Succesfully deleted messages." withDetails:nil statusCode:0];
                success(status);
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
