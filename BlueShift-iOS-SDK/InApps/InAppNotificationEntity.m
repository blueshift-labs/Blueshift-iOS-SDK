//
//  InAppNotificationEntity.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//
#import "InAppNotificationEntity.h"
#import "BlueShiftInAppNotificationConstant.h"
#import "BlueShiftInAppTriggerMode.h"
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


+ (void)fetchAllMessagesForTrigger:(BlueShiftInAppTriggerMode)triggerMode andDisplayPage:(NSString *)displayOn  withHandler:(void (^)(BOOL, NSArray *))handler {
    @synchronized(self) {
        NSManagedObjectContext* privateContext = BlueShift.sharedInstance.appDelegate.inboxManagedObjectContext;
        if (privateContext) {
            @try {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setEntity:[NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext: privateContext]];
                if(fetchRequest && fetchRequest.entity) {
                    displayOn =  (displayOn ? displayOn: @"");
                    
                    NSPredicate *predicate = [self getPredicateForTrigger:triggerMode andDisplayOn: displayOn];
                    if (predicate) {
                        [fetchRequest setPredicate:predicate];
                    }
                    NSSortDescriptor *sortByDisplayOn = [NSSortDescriptor sortDescriptorWithKey:@"displayOn" ascending:NO];
                    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:NO];
                    if (triggerMode != BlueShiftInAppTriggerModeInbox) {
                        [fetchRequest setSortDescriptors:@[sortByDisplayOn,sortByDate]];
                    } else {
                        [fetchRequest setSortDescriptors:@[sortByDate]];
                    }
                    [privateContext performBlock:^{
                        @try {
                            NSError *error;
                            NSArray *results = [[NSArray alloc]init];
                            results = [privateContext executeFetchRequest:fetchRequest error:&error];
                            if (results && results.count > 0) {
                                handler(YES, results);
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
        } else {
            handler(NO, nil);
        }
    }
}

+ (NSPredicate * _Nullable)getPredicateForTrigger:(BlueShiftInAppTriggerMode)trigger andDisplayOn:(NSString *)displayOn {
    NSString* triggerStr = trigger == BlueShiftInAppTriggerUpComing ? kInAppTriggerModeUpcoming : kInAppTriggerModeNow;
    
    if (trigger == BlueShiftInAppTriggerNowAndUpComing) {
        if (BlueShift.sharedInstance.config.enableMobileInbox == YES) {
            return [NSPredicate predicateWithFormat:@"(triggerMode == %@ OR triggerMode == %@) AND (status == %@) AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@) AND (availability == %@ OR availability == %@ OR availability == %@)", kInAppTriggerModeNow,kInAppTriggerModeUpcoming, kInAppStatusPending, displayOn, @"", nil, kBSAvailabiltyInAppOnly, nil, kBSAvailabiltyInboxAndInApp];
        } else {
            return [NSPredicate predicateWithFormat:@"(triggerMode == %@ OR triggerMode == %@)AND status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@)", kInAppTriggerModeNow,kInAppTriggerModeUpcoming, kInAppStatusPending, displayOn, @"", nil];
        }
    } else if(trigger == BlueShiftInAppTriggerModeInbox) {
        return [NSPredicate predicateWithFormat:@"triggerMode == %@ AND (availability == %@ OR availability == %@)", kInAppTriggerModeNow, kBSAvailabiltyInboxAndInApp, kBSAvailabiltyInboxOnly];
    } else {
        return [NSPredicate predicateWithFormat:@"(triggerMode == %@ AND status == %@) AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@) AND availability == %@", triggerStr, @"pending", displayOn, @"", nil, kBSAvailabiltyInAppOnly];
    }
}

- (void)insert:(NSDictionary *)dictionary handler:(void (^)(BOOL))handler {
    NSManagedObjectContext* privateContext = BlueShift.sharedInstance.appDelegate.inboxManagedObjectContext;
    if (privateContext) {
        @try {
            [self map:dictionary];
            [privateContext performBlock:^{
                @try {
                    NSError *error = nil;
                    [privateContext save:&error];
                    if(privateContext.parentContext) {
                        [privateContext.parentContext performBlock:^{
                            @try {
                                NSError *error = nil;
                                [privateContext.parentContext save:&error];
                                handler(YES);
                            } @catch (NSException *exception) {
                                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
        NSManagedObjectContext *privateContext = BlueShift.sharedInstance.appDelegate.inboxManagedObjectContext;
        if (privateContext) {
            NSEntityDescription *entity;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:privateContext];
            if(entity) {
                [fetchRequest setEntity:entity];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id IN %@", messageUUIDs];
                [fetchRequest setPredicate:predicate];
                if(privateContext) {
                    [privateContext performBlock:^{
                        @try {
                            NSError *error;
                            NSArray *results = [[NSArray alloc]init];
                            results = [privateContext executeFetchRequest:fetchRequest error:&error];
                            NSMutableDictionary* uuids = [[NSMutableDictionary alloc] init];
                            if (results && results.count > 0) {
                                for (InAppNotificationEntity* message in results) {
                                    [uuids setValue:@YES forKey:message.id];
                                }
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
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, nil);
    }
}

//TODO: need to be deleted
+ (void)fetchInAppNotificationByStatus :(NSManagedObjectContext *)context forNotificatioID: (NSString *) status request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status == %@", status];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit: 10];
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *results = [[NSArray alloc]init];
                    results = [context executeFetchRequest:fetchRequest error:&error];
                    if (results && results.count > 0) {
                        handler(YES, results);
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
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, nil);
    }
}

//TODO: Need to be deleted, replaced by new method markNotificationAsRead
+ (void)updateInAppNotificationStatus:(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest notificationStatus:(NSString *)status
    andAppDelegate:(BlueShiftAppDelegate *)appdelegate handler:(void (^)(BOOL))handler{
    if (status) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", notificationID];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setFetchLimit:1];
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    @try {
                        NSError *error;
                        NSArray *arrResult = [context executeFetchRequest:fetchRequest error:&error];
                        if (arrResult.count > 0) {
                            InAppNotificationEntity *entity = arrResult[0];
                            [entity setValue: status forKey: kInAppStatus];
                            error = nil;
                            [context save:&error];
                            handler(YES);
                        }
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        handler(NO);
                    }
                }];
            } else {
                handler(NO);
            }
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO);
        }
    } else {
        handler(NO);
    }
}

#pragma mark - Inbox
+ (void)fetchLastReceivedMessageId:(void (^)(BOOL, NSString *, NSString *))handler {
    NSManagedObjectContext* privateContext = BlueShift.sharedInstance.appDelegate.inboxManagedObjectContext;
    if (privateContext) {
        @try {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:privateContext];
            [fetchRequest setEntity:entity];
            NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:NO];
            [fetchRequest setSortDescriptors:@[sortByDate]];
            [fetchRequest setFetchLimit:1];
            if(fetchRequest && fetchRequest.entity) {
                [privateContext performBlock:^{
                    @try {
                        NSError *error;
                        NSArray *results = [privateContext executeFetchRequest: fetchRequest error:&error];
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
    } else {
        handler(NO, @"", @"");
    }
}

+ (void)updateMessageUnreadStatusInDB:(NSDictionary * _Nullable)messages status:(NSDictionary* _Nullable)statusArray {
    if (statusArray && messages && messages.count > 0) {
        NSManagedObjectContext* context = [BlueShift sharedInstance].appDelegate.inboxManagedObjectContext;
        if(context) {
            [context performBlock:^{
                @try {
                    for(NSString* key in statusArray.allKeys) {
                        InAppNotificationEntity* entity = (InAppNotificationEntity*)messages[key];
                        //TODO: verify the data type of recieved bool status
                        if([statusArray[key] isEqual: @YES]) {
                            entity.status = kInAppStatusDisplayed;
                        }
                    }
                    NSError *error;
                    [context save:&error];
                    
                    [context.parentContext performBlock:^{
                        @try {
                            NSError *error;
                            [context.parentContext save:&error];
                            //TODO: Fire event to tell SDK taht update is complete and in-app can be shown.
                        } @catch (NSException *exception) {
                            
                        }
                    }];
                } @catch (NSException *exception) {
                    
                }
            }];
        }
    }
}

+ (void)updateDeletedMessagesinDB:(NSArray *)deleteIds {
    if (deleteIds && deleteIds.count > 0) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kInAppNotificationEntityNameKey];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"id IN %@", deleteIds];
        [InAppNotificationEntity batchDeleteDataForFetchRequest:fetchRequest];
    }
}

+ (void)markMessageAsRead:(NSString *)messageUUID {
    @try {
        NSManagedObjectContext* context = [BlueShift sharedInstance].appDelegate.inboxManagedObjectContext;
        if(context) {
            NSEntityDescription *entity;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:context.parentContext];
            [fetchRequest setEntity:entity];
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"id == %@", messageUUID];
            fetchRequest.predicate = predicate;
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *arrResult = [context executeFetchRequest:fetchRequest error:&error];
                    if (arrResult.count > 0) {
                        InAppNotificationEntity *notification = arrResult[0];
                        notification.status = kInAppStatusDisplayed;
                        error = nil;
                        [context save:&error];
                        
                        [context.parentContext performBlock:^{
                            @try {
                                NSError *error;
                                [context.parentContext save:&error];
                            } @catch (NSException *exception) {
                                
                            }
                        }];
                    }
                } @catch (NSException *exception) {
                    
                }
            }];
                    
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
            // TODO: read the status from the payload
            self.status = kInAppStatusPending;
            self.availability = kBSAvailabiltyInboxOnly;//[dictionary valueForKey:kBSAvailabilty];
        } else {
            self.status = kInAppStatusPending;
            self.availability = kBSAvailabiltyInAppOnly;
        }
        self.createdAt = [NSNumber numberWithDouble: (double)[[BlueShiftInAppNotificationHelper getUTCDateFromDateString:self.timestamp] timeIntervalSince1970]];
        self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)eraseEntityData {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kInAppNotificationEntityNameKey];
    [InAppNotificationEntity batchDeleteDataForFetchRequest:fetchRequest];
}

+ (void)batchDeleteDataForFetchRequest:(NSFetchRequest*)fetchRequest {
    if (@available(iOS 9.0, *)) {
        @try {
            NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.inboxManagedObjectContext;
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
                            
                            [context.parentContext performBlock:^{
                                @try {
                                    NSError *error;
                                    [context.parentContext save:&error];
                                } @catch (NSException *exception) {
                                    
                                }
                            }];
                            
                            if (error) {
                                [BlueshiftLog logError:error withDescription:@"Failed to save the data after deleting InApp notifications." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            } else {
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the InAppNotification entity", deleteResult.result] withDetails:nil methodName:nil];
                            }
                        } @catch (NSException *exception) {
                            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        }
                    }];
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

@end
