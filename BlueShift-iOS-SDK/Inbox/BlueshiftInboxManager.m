//
//  BlueshiftInboxManager.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 14/12/22.
//

#import "BlueshiftInboxManager.h"
#import "BlueShift.h"
#import "BlueShiftInAppNotification.h"
#import "BlueshiftInboxAPIManager.h"
#import "BlueshiftLog.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "InAppNotificationEntity.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueShiftConstants.h"

#define kPaginationSize     10

@implementation BlueshiftInboxManager

#pragma mark - Mobile Inbox External Methods
+ (BOOL)showNotificationForInboxMessage:(BlueshiftInboxMessage* _Nullable)message inboxInAppDelegate:(id<BlueshiftInboxInAppNotificationDelegate> _Nullable)inboxInAppDelegate {
    return [BlueShift.sharedInstance createInAppNotificationForInboxMessage:message inboxInAppDelegate:inboxInAppDelegate];
}

+ (void)deleteInboxMessage:(BlueshiftInboxMessage* _Nullable)message completionHandler:(void (^_Nonnull)(BOOL, NSString* _Nullable))handler  {
    if ([BlueShiftNetworkReachabilityManager networkConnected]) {
        //Delete in-app from server first. Deleting in-apps in offline mode is not allowed ATM.
        [BlueshiftInboxAPIManager deleteMessagesWithMessageUUIDs:@[message.messageUUID] success:^(void) {
            //On success, delete the in-app from db.
            [InAppNotificationEntity deleteInboxMessageFromDB:message.messageUUID completionHandler:^(BOOL status) {
                handler(status, nil);
            }];
        } failure:^(NSError * _Nonnull error) {
            handler(NO, error.localizedDescription);
        }];
    } else {
        NSString *desc = NSLocalizedString(kBSDeviceIsOfflineDescriptionLocalizedKey, @"");
        desc = [desc isEqualToString: kBSDeviceIsOfflineDescriptionLocalizedKey] ? kBSDeviceIsOfflineDescription : desc;
        handler(NO, desc);
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

+ (void)syncInboxMessages:(void (^_Nonnull)(void))handler {
    [BlueshiftInboxAPIManager getMessageIdsAndStatus:^(NSArray * _Nonnull statusArray) {
        [InAppNotificationEntity fetchAllMessagesWithHandler:^(BOOL status, NSArray *messages) {
            //Get message Ids from status api response
            NSMutableDictionary* statusMessageIds = [[NSMutableDictionary alloc] init];
            [statusArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [statusMessageIds setValue:obj[kInAppStatus] forKey:obj[kBSMessageUUID]];
            }];
            //If messages are present in the db
            if (status && messages.count > 0) {
                //Get existing messages id
                NSMutableDictionary* existingMessages = [[NSMutableDictionary alloc] init];
                for(InAppNotificationEntity* message in messages) {
                    [existingMessages setValue:message forKey:message.id];
                }
                [BlueshiftLog logInfo:@"Existing in-app messages, UUID - " withDetails:existingMessages.allKeys methodName:nil];

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
                [BlueshiftInboxManager getNewMessagesWithPagination:newMessages completionHandler:handler];
            } else {
                //If messages are not present in the db
                //Fetch all the messages with pagination
                [BlueshiftInboxManager getNewMessagesWithPagination:[statusMessageIds allKeys] completionHandler:handler];
            }
        }];
    } failure:^(NSError * _Nonnull error) {
        handler();
    }];
}

+ (void)processInboxMessagesForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler {
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
                            if ([BlueShiftInAppNotificationHelper isExpired:expiresAt] == NO) {
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

+ (void)getNewMessagesWithPagination:(NSArray*)messageIds completionHandler:(void(^)(void))handler  {
    if (messageIds.count == 0) {
        [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeSync];
        handler();
        return;
    }
    NSMutableArray *paginationList = [[NSMutableArray alloc] init];
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
            [paginationList addObject:batch];
        }
    } else {
        [paginationList addObject:messageIds];
    }
    [self getPageAtIdex:0 fromPaginationList:paginationList completionHanlder:handler];
}

+ (void)getPageAtIdex:(NSUInteger)page fromPaginationList:(NSArray*)paginationList completionHanlder:(void(^)(void))handler {
    if(page == paginationList.count) {
        [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeSync];
        handler();
        return;
    } else {
        // Show first 10 messages on the inbox, and send one more broadcast once sync is completed. 
        if (page == 1) {
                [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeSync];
            }
        [BlueshiftInboxAPIManager getMessagesForMessageUUIDs:paginationList[page] success:^(NSDictionary * _Nonnull data) {
            [self processInboxMessagesForAPIResponse:data withCompletionHandler:^(BOOL status) {
                [self getPageAtIdex:page+1 fromPaginationList:paginationList completionHanlder:handler];
            }];
        } failure:^(NSError * _Nullable err, NSArray * _Nullable failedBatch) {
            [self getPageAtIdex:page+1 fromPaginationList:paginationList completionHanlder:handler];
        }];
    }
}

+ (NSMutableArray*)prepareInboxMessages:(NSArray*)results {
    NSMutableArray<BlueshiftInboxMessage*>* inboxMessages = [[NSMutableArray alloc] init];
    if ([results count] > 0) {
        for (InAppNotificationEntity *message in results) {
            NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:message.payload];
            
            NSDictionary* inboxDict = payloadDictionary[kBSInboxMessageData][kBSInbox];
            NSString* title = [inboxDict valueForKey:kBSInboxMessageTitle];
            NSString* detail = [inboxDict valueForKey:kBSInboxMessageDetails];
            NSString* icon = [inboxDict valueForKey:kBSInboxMessageIcon];
            BOOL readStatus = [message.status isEqualToString:kInAppStatusPending] ? NO : YES;
            
            NSDate* date = [BlueShiftInAppNotificationHelper getUTCDateFromDateString:message.timestamp];
            BlueshiftInboxMessage *inboxMessage = [[BlueshiftInboxMessage alloc] initWithMessageId:message.id objectId:message.objectID inAppType:message.type readStatus:readStatus title:title detail:detail createdAtDate:date iconImageURL:icon messagePayload:payloadDictionary];
            [inboxMessages addObject:inboxMessage];
        }
    }
    return inboxMessages;
}

+ (void)deleteAllInboxMessagesFromDB {
    [InAppNotificationEntity eraseEntityData];
}

@end
