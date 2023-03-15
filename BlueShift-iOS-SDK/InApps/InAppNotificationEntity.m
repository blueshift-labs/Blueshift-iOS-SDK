//
//  InAppNotificationEntity.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//
#import "InAppNotificationEntity.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppNotification.h"
#import "BlueShiftAppDelegate.h"
#import "BlueShiftNotificationConstants.h"
#import "BlueshiftLog.h"
#import "BlueShiftConstants.h"

@implementation InAppNotificationEntity

@dynamic id;
@dynamic type;
@dynamic startTime;
@dynamic endTime;
@dynamic payload;
@dynamic priority;
@dynamic triggerMode;
@dynamic eventName;
@dynamic status;
@dynamic createdAt;
@dynamic displayOn;
@dynamic timestamp;
@dynamic availability;

+ (void)fetchAllMessagesForInboxWithHandler:(void (^)(BOOL, NSArray * _Nullable))handler {
    NSNumber* currentTime = [NSNumber numberWithDouble:(double)[[NSDate date] timeIntervalSince1970]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startTime < %@ AND endTime > %@ AND (availability == %@ OR availability == %@)", currentTime, currentTime, kBSAvailabilityInboxOnly, kBSAvailabilityInboxAndInApp];
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:NO];
    NSFetchRequest *fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:@[sortByDate]];
    [InAppNotificationEntity fetchMessagesForFetchRequest:fetchRequest withHandler:^(BOOL status, NSArray *messages) {
        [BlueshiftLog logInfo:@"Fetched inbox messages from local DB, count - " withDetails:[NSNumber numberWithUnsignedInteger:messages.count] methodName:nil];
        handler(status,messages);
    }];
}

+ (void)fetchInAppMessageToDisplayOnScreen:(NSString*)displayOn WithHandler:(void (^)(BOOL, NSArray * _Nullable))handler {
    NSNumber* currentTime = [NSNumber numberWithDouble:(double)[[NSDate date] timeIntervalSince1970]];
    NSPredicate *predicate;
    if ( BlueShift.sharedInstance.config.enableMobileInbox == YES) {
        predicate = [NSPredicate predicateWithFormat:@"startTime < %@ AND endTime > %@ AND status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@) AND (availability == %@ OR availability == %@ OR availability == %@ OR availability == %@)", currentTime, currentTime, kInAppStatusPending, displayOn, @"", nil, kBSAvailabilityInAppOnly, kBSAvailabilityInboxAndInApp, nil, @""];
    } else {
        // Display now and if inbox is disabled
        predicate = [NSPredicate predicateWithFormat: @"startTime < %@ AND endTime > %@ AND status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@)", currentTime, currentTime, kInAppStatusPending, displayOn, @"", nil];
    }

    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:NO];
    NSSortDescriptor *sortByDisplayOn = [NSSortDescriptor sortDescriptorWithKey:@"displayOn" ascending:NO];
    NSArray* sortDescriptor = @[sortByDisplayOn,sortByDate];
    NSFetchRequest *fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:sortDescriptor];
    fetchRequest.fetchLimit = 1;
    [InAppNotificationEntity fetchMessagesForFetchRequest:fetchRequest withHandler:^(BOOL status, NSArray *messages) {
        handler(status,messages);
    }];
}

+(void)fetchMessagesForFetchRequest:(NSFetchRequest*)fetchRequest withHandler:(void (^)(BOOL, NSArray *))handler {
//    @synchronized (self) {
        @try {
            NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
            if (fetchRequest && context) {
                [context performBlock:^{
                    @try {
                        NSError *error;
                        NSArray *results = [[NSArray alloc]init];
                        results = [context executeFetchRequest:fetchRequest error:&error];
                        if (results && results.count > 0) {
                            handler(YES, results);
                        } else {
                            handler(YES, nil);
                        }
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        handler(NO, nil);
                    }
                }];
            } else {
                handler(NO, nil);
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO, nil);
        }
//    }
}


+ (BOOL)insertMesseages:(NSArray<NSDictionary*> *)messagesToInsert {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.inboxMOContext;
    __block BOOL success = NO;
    if (context) {
        [context performBlockAndWait:^{
            @try {
                for (NSDictionary* messagePayload in messagesToInsert) {
                    NSEntityDescription *entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:context];
                    if(entity) {
                        InAppNotificationEntity *inAppNotificationEntity = [[InAppNotificationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext: context];
                        if(inAppNotificationEntity) {
                            [inAppNotificationEntity map:messagePayload];
                            NSError *error = nil;
                            [context save:&error];
                            if (!error) {
                                [[BlueShift sharedInstance] trackInAppNotificationDeliveredWithParameter: messagePayload canBacthThisEvent: NO];
                                // invoke the inApp delivered callback method
                                if ([BlueShift.sharedInstance.config.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDidDeliver:)]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [BlueShift.sharedInstance.config.inAppNotificationDelegate inAppNotificationDidDeliver:messagePayload];
                                    });
                                }
                                [BlueshiftLog logInfo:@"Added inbox notification to DB with message id - " withDetails:inAppNotificationEntity.id methodName:nil];
                            }
                        }
                    }
                }
                success = YES;
            } @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                success = NO;
            }
        }];
        return success;
    } else {
        return success;
    }
}

- (void)insert:(NSDictionary *)dictionary handler:(void (^)(BOOL))handler {
    NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
    if (context) {
        @try {
            [self map:dictionary];
            [context performBlock:^{
                @try {
                    NSError *error = nil;
                    [context save:&error];
                    if (error) {
                        [BlueshiftLog logError:error withDescription:[NSString stringWithFormat:@"Failed to insert Inbox message, message UUID - %@", self.id] methodName:nil];
                        handler(NO);
                    } else {
                        [BlueshiftLog logInfo:@"Successfully added inbox message, message UUID - " withDetails:self.id methodName:nil];
                        handler(YES);
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    handler(NO);
                }
            }];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO);
        }
    } else {
        handler(NO);
    }
}

+ (void)checkIfMessagesPresentForMessageUUIDs:(NSArray*)messageUUIDs handler:(void (^)(BOOL, NSDictionary *))handler {
    @try {
        NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id IN %@", messageUUIDs];
        NSFetchRequest* fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:nil];
        if(fetchRequest && context) {
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *results = [[NSArray alloc]init];
                    results = [context executeFetchRequest:fetchRequest error:&error];
                    NSMutableDictionary* uuids = [[NSMutableDictionary alloc] init];
                    if (results && results.count > 0) {
                        for (InAppNotificationEntity* message in results) {
                            [uuids setValue:@YES forKey:message.id];
                        }
                        [BlueshiftLog logInfo:@"Messages present in Local, message UUIDs - %@" withDetails:uuids methodName:nil];
                        handler(YES, uuids);
                    } else {
                        handler(NO, nil);
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    handler(NO, nil);
                }
            }];
        } else {
            handler(NO, nil);
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, nil);
    }
}

+ (NSFetchRequest*)getFetchRequestForPredicate:(NSPredicate* _Nullable)predicate sortDescriptor:(NSArray<NSSortDescriptor*>* _Nullable)sortDescriptor {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kInAppNotificationEntityNameKey];
    if (sortDescriptor) {
        [fetchRequest setSortDescriptors:sortDescriptor];
    }
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    return fetchRequest;
}

#pragma mark - Inbox
+ (void)fetchLastReceivedMessageId:(void (^)(BOOL, NSString *, NSString *))handler {
    NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
    @try {
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:NO];
        NSFetchRequest* fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:nil sortDescriptor:@[sortByDate]];
        [fetchRequest setFetchLimit:1];
        if(fetchRequest && context) {
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *results = [context executeFetchRequest: fetchRequest error:&error];
                    if (results.count > 0) {
                        InAppNotificationEntity *notification = results[0];
                        handler(YES, notification.id, notification.timestamp);
                    } else {
                        handler(NO, @"", @"");
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    handler(NO, @"", @"");
                }
            }];
        } else {
            handler(NO, @"", @"");
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, @"", @"");
    }
}

+ (void)syncMessageUnreadStatusWithDB:(NSDictionary * _Nullable)messages status:(NSDictionary* _Nullable)statusArray {
    if (statusArray && messages && messages.count > 0) {
        NSManagedObjectContext* context = [BlueShift sharedInstance].appDelegate.inboxMOContext;
        if(context) {
            [context performBlock:^{
                @try {
//                    BOOL isStatusChanged = NO;
                    for(NSString* key in statusArray.allKeys) {
                        if (messages[key]) {
                            InAppNotificationEntity* entity = (InAppNotificationEntity*)messages[key];
                            //TODO: verify the data type of recieved bool status
                            
                            if([statusArray[key] isEqual: @"read"]) {
                                entity.status = kInAppStatusDisplayed;
//                                isStatusChanged = YES;
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Updated unread status for message UUID - %@",entity.id] withDetails:nil methodName:nil];
                            }
                        }
                    }
                    NSError *error;
                    [context save:&error];
//                    if (isStatusChanged && !error) {
//                        [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange];
//                    } else {
                    if (error) {
                        [BlueshiftLog logError:error withDescription:@"Failed to save updated Inbox messages." methodName:nil];
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            }];
        }
    }
}

+ (void)getUnreadMessagesCountFromDB:(void(^)(BOOL, NSUInteger))handler {
    NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
    [context performBlock:^{
        @try {
            NSNumber* currentTime = [NSNumber numberWithDouble:(double)[[NSDate date] timeIntervalSince1970]];
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"status == %@ AND (availability == %@ OR availability == %@) AND startTime < %@ AND endTime > %@ ",kInAppStatusPending, kBSAvailabilityInboxOnly, kBSAvailabilityInboxAndInApp, currentTime, currentTime];
            NSFetchRequest *fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:nil];
            NSError* error;
            NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
            if (error) {
                count = 0;
            }
            [BlueshiftLog logInfo:[NSString stringWithFormat:@"Inbox unread messages count - %lu",(unsigned long)count] withDetails:nil methodName:nil];
            handler(YES, count);
        } @catch (NSException *exception) {
            handler(NO, 0);
        }
    }];
}

+ (void)markMessageAsRead:(NSString *)messageUUID {
    @try {
        NSManagedObjectContext* context = [BlueShift sharedInstance].appDelegate.inboxMOContext;
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"id == %@", messageUUID];
        NSFetchRequest *fetchRequest =[InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:nil];
        if(context && fetchRequest) {
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *arrResult = [context executeFetchRequest:fetchRequest error:&error];
                    if (arrResult.count > 0) {
                        InAppNotificationEntity *notification = arrResult[0];
                        notification.status = kInAppStatusDisplayed;
                        error = nil;
                        [context save:&error];
                        if (error) {
                            [BlueshiftLog logError:error withDescription:[NSString stringWithFormat:@"Failed to mark Inbox message as read, message UUID - %@", notification.id] methodName:nil];
                        } else {
                            [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeMarkAsUnread];
                            [BlueshiftLog logInfo:@"Marked Inbox message as read, message UUID -" withDetails:notification.id methodName:nil];
                        }
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

+ (void)deleteInboxMessageFromDB:(NSManagedObjectID *)objectId completionHandler:(void (^_Nonnull)(BOOL))handler {
    NSManagedObjectContext * context = [BlueShift sharedInstance].appDelegate.inboxMOContext;
    if (context) {
        @try {
            [context performBlock:^{
                @try {
                    InAppNotificationEntity* managedObject =  (InAppNotificationEntity*)[context objectWithID: objectId];
                    NSString* messageUUID = managedObject.id;
                    [context deleteObject: managedObject];
                    NSError *saveError = nil;
                    [context save:&saveError];
                    if (saveError) {
                        [BlueshiftLog logError:saveError withDescription:[NSString stringWithFormat:@"Failed to Delete Inbox message from DB, Message UUID - %@", messageUUID] methodName:nil];
                        handler(NO);
                    } else {
                        [BlueshiftLog logInfo:@"Deleted Inbox message from DB, Message UUID -" withDetails:messageUUID methodName:nil];
                        [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeMessageDelete];
                        handler(YES);
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    handler(NO);
                }
            }];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO);
        }
    } else {
        handler(NO);
    }
}

- (void)map:(NSDictionary *)dictionary {
    @try {
        NSMutableDictionary *payload = [dictionary mutableCopy];
        if ([dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] &&
            [dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] != [NSNull null]) {
            self.id =(NSString *)[dictionary objectForKey: kInAppNotificationModalMessageUDIDKey];
        } else {
            self.id = [[NSUUID UUID] UUIDString];
            [payload setValue:self.id forKey:kInAppId];
        }
        
        /* get in-app payload */
        if ([dictionary objectForKey: kSilentNotificationPayloadIdentifierKey]) {
            dictionary = [dictionary objectForKey: kSilentNotificationPayloadIdentifierKey];
        }
        
        if ([dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] &&
            [dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] != [NSNull null]) {
            self.id =(NSString *)[dictionary objectForKey: kInAppNotificationModalMessageUDIDKey];
        }
        
        if ([dictionary objectForKey: kInAppNotificationModalTimestampKey] &&
            [dictionary objectForKey: kInAppNotificationModalTimestampKey] != [NSNull null]) {
            self.timestamp = (NSString *) [dictionary objectForKey: kInAppNotificationModalTimestampKey];
        }
        
        if ([dictionary objectForKey: kInAppNotificationKey]) {
            dictionary = [dictionary objectForKey: kInAppNotificationKey];
        }
        
        // Get type of In-App msg
        if ([dictionary objectForKey: kSilentNotificationPayloadTypeKey] &&
            [dictionary objectForKey: kSilentNotificationPayloadTypeKey] != [NSNull null]) {
            self.type = [dictionary objectForKey: kSilentNotificationPayloadTypeKey];
        }
        
        if ([dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey] &&
            [dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey] != [NSNull null]) {
            self.displayOn = [dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey];
        }
        
        // Get start and end Time
        if ([dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] &&
            [dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] != [NSNull null]) {
            self.endTime = [NSNumber numberWithDouble: [[dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] doubleValue]];
        }
        
        self.triggerMode = kInAppTriggerModeNow;
        if ([dictionary objectForKey: kSilentNotificationTriggerKey]) {
            NSString *trigger = (NSString *)[dictionary objectForKey: kSilentNotificationTriggerKey];
            if (![trigger isEqualToString:@""]) {
                if ([BlueShiftInAppNotificationHelper hasDigits: trigger] == YES) {
                    self.triggerMode = kInAppTriggerModeUpcoming;
                    self.startTime = [NSNumber numberWithDouble: [trigger doubleValue]];
                } else {
                    self.triggerMode = trigger;
                }
            }
        }
        
        self.priority = kInAppPriorityMedium;
        self.eventName = kInAppNotificationKey;
        if (BlueShift.sharedInstance.config.enableMobileInbox == YES) {
            // TODO: read the status from the payload and change the default availbility
            self.status = [[payload objectForKey:@"status"] isEqualToString:@"unread"] ? kInAppStatusPending : kInAppStatusDisplayed;
            self.availability = [dictionary objectForKey:kBSAvailabilityScope] ? [dictionary objectForKey:kBSAvailabilityScope] : kBSAvailabilityInboxOnly;
        } else {
            self.status = kInAppStatusPending;
            self.availability = kBSAvailabilityInAppOnly;
        }
        self.createdAt = [NSNumber numberWithDouble: (double)[[BlueShiftInAppNotificationHelper getUTCDateFromDateString:self.timestamp] timeIntervalSince1970]];
        self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)postNotificationInboxUnreadMessageCountDidChange:(BlueshiftInboxChangeType)refreshType {
    [NSNotificationCenter.defaultCenter postNotificationName:kBSInboxUnreadMessageCountDidChange object:nil userInfo:@{@"refreshType": [NSNumber numberWithUnsignedInteger:refreshType]}];
}

+ (void)syncDeletedMessagesWithDB:(NSArray *)deleteIds {
    if (deleteIds && deleteIds.count > 0) {
        [BlueshiftLog logInfo:@"Deleting local messages to Sync with server, message UUIDs - " withDetails:deleteIds methodName:nil];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id IN %@", deleteIds];
        NSFetchRequest* fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:nil];
        [InAppNotificationEntity batchDeleteDataForFetchRequest:fetchRequest handler:^(BOOL status, NSInteger count) {
            //No need of posting notification as this will be taken care by sync API
        }];
    }
}

+ (void)deleteExpiredMessagesFromDB {
    [BlueshiftLog logInfo:@"Deleting expired local messages." withDetails:nil methodName:nil];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"endTime < %f", [[NSDate date] timeIntervalSince1970]];
    NSFetchRequest *fetchRequest = [InAppNotificationEntity getFetchRequestForPredicate:predicate sortDescriptor:nil];
    [InAppNotificationEntity batchDeleteDataForFetchRequest:fetchRequest handler:^(BOOL status, NSInteger count) {
        if (status && count > 0) {
            [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeMessageDelete];
        }
    }];
}

+ (void)eraseEntityData {
    [BlueshiftLog logInfo:@"Erasing all the inbox messages." withDetails:nil methodName:nil];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kInAppNotificationEntityNameKey];
    [InAppNotificationEntity batchDeleteDataForFetchRequest:fetchRequest handler:^(BOOL status, NSInteger count) {
        if (status && count > 0) {
            [InAppNotificationEntity postNotificationInboxUnreadMessageCountDidChange:BlueshiftInboxChangeTypeMessageDelete];
        }
    }];
}

+ (void)batchDeleteDataForFetchRequest:(NSFetchRequest*)fetchRequest handler:(void(^)(BOOL, NSInteger))success {
    if (@available(iOS 9.0, *)) {
        @try {
            NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.inboxMOContext;
            if (context) {
                NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
                [deleteRequest setResultType:NSBatchDeleteResultTypeCount];
                if([context isKindOfClass:[NSManagedObjectContext class]]) {
                    [context performBlock:^{
                        @try {
                            NSError *error = nil;
                            // check if there are any changes to be saved and save it
                            if ([context hasChanges]) {
                                [context save:&error];
                            }
                            NSBatchDeleteResult* deleteResult = [context executeRequest:deleteRequest error:&error];
                            [context save:&error];
                            if (error) {
                                [BlueshiftLog logError:error withDescription:@"Failed to save the data after deleting InApp notifications." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                                success(NO, 0);
                            } else {
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the InAppNotification entity", deleteResult.result] withDetails:nil methodName:nil];
                                success(YES, [deleteResult.result integerValue]);
                            }
                        } @catch (NSException *exception) {
                            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            success(NO, 0);
                        }
                    }];
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            success(NO, 0);
        }
    } else {
        success(NO, 0);
    }
}

@end
