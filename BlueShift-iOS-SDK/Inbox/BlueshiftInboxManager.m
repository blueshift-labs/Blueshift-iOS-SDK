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

#define kPaginationSize     40


static BOOL isSyncing = NO;

@implementation BlueshiftInboxManager

#pragma mark - Mobile Inbox External Methods
+ (void)showInboxNotificationForMessage:(BlueshiftInboxMessage* _Nullable)message {
    [BlueShift.sharedInstance createInAppNotificationForInboxMessage:message];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                success(YES, messages);
            });
        } else {
            success(NO, nil);
        }
    }];
}

+ (void)getInboxUnreadMessagesCount:(void(^)(NSUInteger))handler {
    [InAppNotificationEntity getUnreadMessagesCountFromDB:^(NSUInteger count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(count);
        });
    }];
}

+ (void)syncNewInboxMessages:(void (^_Nonnull)(void))success {
    isSyncing = YES;
    [BlueshiftInboxAPIManager getMessageIdsAndStatus:^(NSArray * _Nonnull statusArray) {
        [InAppNotificationEntity fetchAllMessagesForInboxWithHandler:^(BOOL status, NSArray *messages) {
            if (status) {
                //Get existing messages id
                NSMutableDictionary* existingMessages = [[NSMutableDictionary alloc] init];
                for(InAppNotificationEntity* message in messages) {
                    [existingMessages setValue:message forKey:message.id];
                }
                //Get updates message Ids from api response
                NSMutableDictionary* statusMessageIds = [[NSMutableDictionary alloc] init];
                [statusArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [statusMessageIds setValue:obj[@"status"] forKey:obj[kBSMessageUUID]];
                }];
                
                //Calculate new messages by substracting the local db message ids from the status message ids.
                NSMutableArray* newMessages = [[statusMessageIds allKeys] mutableCopy];
                [newMessages removeObjectsInArray:[existingMessages allKeys]];
                
                //Calculate deleted messages on server by substracting status message ids from the local db message ids
                NSMutableArray* deletedMessages = [[existingMessages allKeys] mutableCopy];
                [deletedMessages removeObjectsInArray:[statusMessageIds allKeys]];
                
                //Sync server unread messages status with local messages
                [InAppNotificationEntity syncMessageUnreadStatusWithDB:existingMessages status:statusMessageIds];
                
                //Sync server deleted messages with local db
                [InAppNotificationEntity syncDeletedMessagesWithDB:deletedMessages];
                
                //Fetch only new messages with pagination
                [BlueshiftInboxManager getNewMessagesWithPagination:newMessages isRetry:NO completionHandler:success];
            } else {
                success();
            }
        }];
    } failure:^(NSError * _Nonnull error) {
        success();
    }];
}

+ (void)handleInboxMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler {
    if (apiResponse && [apiResponse objectForKey: kInAppNotificationContentPayloadKey]) {
        NSMutableArray *notifications = [apiResponse objectForKey: kInAppNotificationContentPayloadKey];
        if (notifications.count > 0) {
            [self addInboxNotifications:notifications handler:^(BOOL status) {
                completionHandler(YES);
            }];
        } else {
            completionHandler(YES);
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
            [messagesToBeAdded enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                NSString* messageUUID = [BlueShiftInAppNotificationHelper getMessageUUID:obj];
                if (messageUUID) {
                    [newMessageUUIDs addObject:messageUUID];
                }
            }];
            
            [InAppNotificationEntity checkIfMessagesPresentForMessageUUIDs:newMessageUUIDs handler:^(BOOL status, NSDictionary * _Nonnull existingMessageUUIDs) {
                //Create dispatch group to notifify new messages are availble after adding in-apps to DB asynchronously.
                __block dispatch_group_t serviceGroup = dispatch_group_create();
                __block BOOL newMessageAdded = NO;
                dispatch_group_async(serviceGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                    @try {
                        for (int counter = 0; counter < messagesToBeAdded.count ; counter++) {
                            NSDictionary* inapp = [messagesToBeAdded objectAtIndex: counter];
                            NSString* messageUUID = [BlueShiftInAppNotificationHelper getMessageUUID:inapp];
                            //Do not add duplicate messages in the db
                            if(messageUUID && ![existingMessageUUIDs valueForKey:messageUUID]) {
                                double expiresAt = [inapp[kInAppNotificationDataKey][kInAppNotificationKey][kSilentNotificationTriggerEndTimeKey] doubleValue];
                                
                                // Do not add expired in-app notifications to in-app DB.
                                if ([BlueShiftInAppNotificationHelper isInboxNotificationExpired:expiresAt] == NO) {
                                    dispatch_group_enter(serviceGroup);
                                    [BlueshiftInboxManager insertMesseageInDB:inapp handler:^(BOOL status) {
                                        newMessageAdded = YES;
                                        dispatch_group_leave(serviceGroup);
                                    }];
                                } else {
                                    [BlueshiftLog logInfo:@"Skipped adding expired in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                                }
                            } else {
                                [BlueshiftLog logInfo:@"Skipped adding duplicate in-app message to DB. MessageUUID -" withDetails:[inapp[kInAppNotificationDataKey] objectForKey: kInAppNotificationModalMessageUDIDKey] methodName:nil];
                            }
                        }
                        dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{
                            serviceGroup = nil;
                            handler(newMessageAdded);
                        });
                        //Timout
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),dispatch_get_main_queue(),^{
                            if (serviceGroup) {
                                serviceGroup = nil;
                                handler(newMessageAdded);
                            }
                        });
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                });
            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

#pragma mark - Mobile Inbox helper methods

+ (void)insertMesseageInDB:(NSDictionary *)payload handler:(void(^)(BOOL))handler{
    @try {
        NSManagedObjectContext *privateContext = [BlueShift sharedInstance].appDelegate.inboxMOContext;
        if (privateContext) {
            [privateContext performBlock:^{
                NSEntityDescription *entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:privateContext];
                if(entity) {
                    InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: privateContext];
                    if(inAppNotificationEntity) {
                        [inAppNotificationEntity insert:payload handler:^(BOOL status) {
                            if(status) {
                                [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: payload canBacthThisEvent: NO];
                                // invoke the inApp clicked callback method
                                if ([BlueShift.sharedInstance.config.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDeliver:)]) {
                                    [BlueShift.sharedInstance.config.inAppNotificationDelegate inAppNotificationDidDeliver:payload];
                                }
                            }
                            handler(YES);
                        }];
                    } else {
                        handler(NO);
                    }
                } else {
                    handler(NO);
                }
            }];
        } else {
            handler(NO);
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO);
    }
}

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
            dispatch_group_notify(dGroup,dispatch_get_main_queue(),^{
                // All the pagination calls are success, then post notification
                if(sucessAPICount == totalAPICount) {
                    [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange];
                    isSyncing = NO;
                } else if (sucessAPICount > 0) {
                    [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange];
                    
                    //If some pagination api calls are success,then retry for failed messagesIds and post notification
                    if (!isRetry) {
                        [BlueshiftInboxManager getNewMessagesWithPagination:failedMessageIds isRetry:YES completionHandler:^{ }];
                    } else {
                        isSyncing = NO;
                    }
                }
                handler();
            });
        }
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
