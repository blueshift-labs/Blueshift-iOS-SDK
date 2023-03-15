//
//  BlueshiftInboxManager.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 14/12/22.
//

#import "BlueshiftInboxManager.h"
#import "BlueShift.h"
#import "BlueShiftInAppNotification.h"
#import "BlueshiftInAppNotificationRequest.h"
#import "BlueshiftLog.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "InAppNotificationEntity.h"

#define kPaginationSize     10


static BOOL isSyncing = NO;

@implementation BlueshiftInboxManager

#pragma mark - Mobile Inbox External Methods
+ (BOOL)showInboxNotificationForMessage:(BlueshiftInboxMessage* _Nullable)message {
    return [BlueShift.sharedInstance createInAppNotificationForInboxMessage:message];
}

+ (void)deleteInboxMessage:(BlueshiftInboxMessage* _Nullable)message completionHandler:(void (^_Nonnull)(BOOL))handler  {
    //Delete in-app from server first. Deleting in-apps in offline mode is not allowed ATM.
    [BlueshiftInboxAPIManager deleteMessagesWithMessageUUIDs:@[message.messageUUID] success:^(BOOL status) {
        if (status) {
            //On success, delete the in-app from db.
            [InAppNotificationEntity deleteInboxMessageFromDB:message.objectId completionHandler:^(BOOL status) {
                handler(status);
            }];
        } else {
            handler(status);
        }
    } failure:^(NSError * _Nonnull error) {
        handler(NO);
    }];
}

+ (void)markInboxMessageAsRead:(BlueshiftInboxMessage* _Nullable)message {
    if (message.readStatus == NO) {
        // If message is unread then only mark it as read.
        [InAppNotificationEntity markMessageAsRead:message.messageUUID];
    }
}

+ (void)getCachedInboxMessagesWithHandler:(void (^_Nonnull)(BOOL, NSMutableArray<BlueshiftInboxMessage*>* _Nullable))success {
    [BlueshiftLog logInfo:@"Fetching inbox messages from local DB." withDetails:nil methodName:nil];
    [InAppNotificationEntity fetchAllMessagesForInboxWithHandler:^(BOOL status, NSArray *results) {
        if (status) {
            NSMutableArray<BlueshiftInboxMessage*>* messages = [BlueshiftInboxManager prepareInboxMessages:results];
            success(YES, messages);
        } else {
            success(NO, nil);
        }
    }];
}

+ (void)getInboxUnreadMessagesCount:(void(^)(BOOL, NSUInteger))handler {
    [InAppNotificationEntity getUnreadMessagesCountFromDB:^(BOOL status, NSUInteger count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(status, count);
        });
    }];
}

+ (void)syncNewInboxMessages:(void (^_Nonnull)(void))handler {
    isSyncing = YES;
    [BlueshiftInboxAPIManager getMessageIdsAndStatus:^(NSArray * _Nonnull statusArray) {
        [InAppNotificationEntity fetchAllMessagesForInboxWithHandler:^(BOOL status, NSArray *messages) {
            //Get message Ids from status api response
            NSMutableDictionary* statusMessageIds = [[NSMutableDictionary alloc] init];
            [statusArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [statusMessageIds setValue:obj[@"status"] forKey:obj[kBSMessageUUID]];
            }];

            //If messages are present in the db
            if (status && messages.count > 0) {
                //Get existing messages id
                NSMutableDictionary* existingMessages = [[NSMutableDictionary alloc] init];
                for(InAppNotificationEntity* message in messages) {
                    [existingMessages setValue:message forKey:message.id];
                }
                
                //Calculate new messages by substracting the local db message ids from the status message ids.
                NSMutableArray* newMessages = [[statusMessageIds allKeys] mutableCopy];
                [newMessages removeObjectsInArray:[existingMessages allKeys]];
                
                //Calculate deleted messages on server by substracting status message ids from the local db message ids
                NSMutableArray* deletedMessages = [[existingMessages allKeys] mutableCopy];
                [deletedMessages removeObjectsInArray:[statusMessageIds allKeys]];
                
                //Sync server unread messages status with local messages
                [InAppNotificationEntity syncMessageUnreadStatusWithDB:existingMessages status:statusMessageIds];
                
                //Sync server deleted messages with local db
                //TODO: enable when actual apis are availble
                [InAppNotificationEntity syncDeletedMessagesWithDB:deletedMessages];
                
                //Fetch only new messages with pagination
                [BlueshiftInboxManager getNewMessagesWithPagination:newMessages isRetry:NO completionHandler:handler];
            } else {
                //If messages are not present in the db
                //Fetch all the messages with pagination
                [BlueshiftInboxManager getNewMessagesWithPagination:[statusMessageIds allKeys] isRetry:NO completionHandler:handler];
            }
        }];
    } failure:^(NSError * _Nonnull error) {
        handler();
    }];
}

+ (void)handleInboxMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler {
    if (apiResponse && [apiResponse objectForKey: kInAppNotificationContentPayloadKey]) {
        NSMutableArray *notifications = [apiResponse objectForKey: kInAppNotificationContentPayloadKey];
        if (notifications.count > 0) {
            [self addInboxNotifications:notifications handler:^(BOOL status) {
                completionHandler(status);
            }];
        } else {
            completionHandler(NO);
        }
    } else {
        completionHandler(NO);
        [BlueshiftLog logInfo:@"The in-app API response is nil or does not have content attribute." withDetails:nil methodName:nil];
    }
}

+ (void)addInboxNotifications:(NSMutableArray *)messagesToBeAdded handler:(void (^)(BOOL))handler {
    @try {
        if (messagesToBeAdded && messagesToBeAdded.count > 0) {
            NSMutableArray *newMessageUUIDs = [NSMutableArray arrayWithCapacity:[messagesToBeAdded count]];
            //get message UUIDs to check if exists already in DB.
            [messagesToBeAdded enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                NSString* messageUUID = [BlueShiftInAppNotificationHelper getMessageUUID:obj];
                if (messageUUID) {
                    [newMessageUUIDs addObject:messageUUID];
                }
            }];
            
            [InAppNotificationEntity checkIfMessagesPresentForMessageUUIDs:newMessageUUIDs handler:^(BOOL status, NSDictionary * _Nonnull existingMessageUUIDs) {
                @try {
                    NSMutableArray* messagesToInsertInDB = [[NSMutableArray alloc] init];
                    for (int counter = 0; counter < messagesToBeAdded.count ; counter++) {
                        NSDictionary* messagePayload = [messagesToBeAdded objectAtIndex: counter];
                        NSString* messageUUID = [BlueShiftInAppNotificationHelper getMessageUUID:messagePayload];
                        //Do not add duplicate messages in the db
                        if(messageUUID && ![existingMessageUUIDs valueForKey:messageUUID]) {
                            double expiresAt = [messagePayload[kInAppNotificationDataKey][kInAppNotificationKey][kSilentNotificationTriggerEndTimeKey] doubleValue];
                            
                            // Do not add expired in-app notifications to in-app DB.
                            if ([BlueShiftInAppNotificationHelper isInboxNotificationExpired:expiresAt] == NO) {
                                [messagesToInsertInDB addObject:messagePayload];
                            } else {
                                [BlueshiftLog logInfo:@"Skipped adding expired in-app message to DB. MessageUUID -" withDetails:[messagePayload[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                            }
                        } else {
                            [BlueshiftLog logInfo:@"Skipped adding duplicate in-app message to DB. MessageUUID -" withDetails:[messagePayload[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                        }
                    }
                    if (messagesToInsertInDB.count > 0) {
                        handler([InAppNotificationEntity insertMesseages:messagesToInsertInDB]);
                    } else {
                        handler(NO);
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

#pragma mark - Mobile Inbox helper methods

+ (void)getNewMessagesWithPagination:(NSArray*)messageIds isRetry:(BOOL)isRetry completionHandler:(void(^)(void))handler  {
    NSMutableArray *batchList = [[NSMutableArray alloc] init];
    // Split the messageIds array into array of 30 ids.
    // Fetch in-apps for 30 ids at a time, and repear same if there are more.
    if (messageIds && messageIds.count > kPaginationSize) {
        NSUInteger paginationLength = messageIds.count/kPaginationSize;
        if (messageIds.count % kPaginationSize != 0) {
            paginationLength = paginationLength + 1;
        }
        for (NSUInteger i = 0; i < paginationLength; i++) {
            NSRange range;
            range.location = i * kPaginationSize;
            if (i == paginationLength - 1) {
                range.length = messageIds.count % kPaginationSize;
            } else {
                range.length = kPaginationSize;
            }
            NSArray* batch = [messageIds subarrayWithRange:range];
            [batchList addObject:batch];
        }
    } else {
        [batchList addObject:messageIds];
    }
    
    NSUInteger totalAPICount = batchList.count;
    __block NSUInteger sucessAPICount = 0;
    __block dispatch_group_t dGroup = dispatch_group_create();
    __block NSArray* failedMessageIds = [[NSMutableArray alloc] init];
    dispatch_group_async(dGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSUInteger paginationLocation = 0;
        for (NSArray* batch in batchList) {
            dispatch_group_enter(dGroup);
            [BlueshiftInboxAPIManager getMessagesForMessageUUIDs:batch success:^(NSDictionary * _Nonnull data) {
                [self handleInboxMessageForAPIResponse:data withCompletionHandler:^(BOOL status) {
                    sucessAPICount++;
                    dispatch_group_leave(dGroup);
                }];
            } failure:^(NSError * _Nullable err, NSArray * _Nullable failedBatch) {
                //Collect failed request messageIds for retry
                failedMessageIds = [failedMessageIds arrayByAddingObject:failedBatch];
                dispatch_group_leave(dGroup);
            }];
            paginationLocation = paginationLocation + kPaginationSize;
        }
        
        dispatch_group_notify(dGroup,dispatch_get_main_queue(),^{
            // All the pagination calls are success, then post notification
            if(sucessAPICount == totalAPICount) {
                isSyncing = NO;
            } else if (sucessAPICount > 0) {
                //If some pagination api calls are success,then retry for failed messagesIds and post notification
                if (!isRetry) {
                    [BlueshiftInboxManager getNewMessagesWithPagination:failedMessageIds isRetry:YES completionHandler:^{ }];
                } else {
                    isSyncing = NO;
                }
            }
            [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeSync];
            handler();
        });
    });
}

+ (NSMutableArray*)prepareInboxMessages:(NSArray*)results {
    NSMutableArray<BlueshiftInboxMessage*>* inboxMessages = [[NSMutableArray alloc] init];
    if ([results count] > 0) {
        for (InAppNotificationEntity *message in results) {
            NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:message.payload];
            
            NSDictionary* inboxDict = payloadDictionary[@"data"][@"inbox"];
            NSString* title = [inboxDict valueForKey:@"title"];
            NSString* detail = [inboxDict valueForKey:@"details"];
            NSString* icon = [inboxDict valueForKey:@"icon"];
            BOOL readStatus = [message.status isEqualToString:kInAppStatusPending] ? NO : YES;
            
            NSDate* date = [BlueShiftInAppNotificationHelper getUTCDateFromDateString:message.timestamp];
            BlueshiftInboxMessage *inboxMessage = [[BlueshiftInboxMessage alloc] initMessageId:message.id objectId:message.objectID inAppType:message.type readStatus:readStatus title:title detail:detail date:date iconURL:icon messagePayload:payloadDictionary];
            [inboxMessages addObject:inboxMessage];
        }
    }
    return inboxMessages;
}

+ (void)deleteAllInboxMessagesFromDB {
    [InAppNotificationEntity eraseEntityData];
}

+ (BOOL)isSyncing {
    return isSyncing;
}

@end
