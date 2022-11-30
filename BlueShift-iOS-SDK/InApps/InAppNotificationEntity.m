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
@dynamic readStatus;

+ (void)fetchAll:(BlueShiftInAppTriggerMode)triggerMode forDisplayPage:(NSString *)displayOn context:(NSManagedObjectContext *)masterContext  withHandler:(void (^)(BOOL, NSArray *))handler {
    if (nil != masterContext) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        @try {
            [fetchRequest setEntity:[NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext: masterContext]];
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
        if(fetchRequest.entity != nil) {
            [self fetchFromCoreDataFromContext: masterContext forTriggerMode: triggerMode forDisplayPage: displayOn request: fetchRequest handler: handler];
        } else {
            handler(NO, nil);
        }
    } else {
        handler(NO, nil);
    }
}

+ (void *)fetchFromCoreDataFromContext:(NSManagedObjectContext *)context forTriggerMode: (BlueShiftInAppTriggerMode) triggerMode forDisplayPage:(NSString *)displayOn request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    displayOn =  (displayOn ? displayOn: @"");
    NSPredicate *predicate = [self getPredicateForTrigger:triggerMode andDisplayOn: displayOn];
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
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
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, nil);
    }
}

+ (NSPredicate * _Nullable)getPredicateForTrigger:(BlueShiftInAppTriggerMode)trigger andDisplayOn:(NSString *)displayOn {
    NSString* triggerStr = trigger == BlueShiftInAppTriggerUpComing ? kInAppTriggerModeUpcoming : kInAppTriggerModeNow;
    
    if (trigger == BlueShiftInAppTriggerNowAndUpComing) {
        return [NSPredicate predicateWithFormat:@"(triggerMode == %@ OR triggerMode == %@)AND status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@) AND (availability == %@ OR availability == %@)", @"now",@"upcoming", @"pending", displayOn, @"", nil, kBSAvailabiltyInAppOnly, nil];
    } else if(trigger == BlueShiftInAppTriggerModeInbox) {
        return [NSPredicate predicateWithFormat:@"triggerMode == %@ AND (availability == %@ OR availability == %@)", kInAppTriggerModeNow, kBSAvailabiltyInboxAndInApp, kBSAvailabiltyInboxOnly];
    } else {
        return [NSPredicate predicateWithFormat:@"(triggerMode == %@ AND status == %@) AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@) AND availability == %@", triggerStr, @"pending", displayOn, @"", nil, kBSAvailabiltyInAppOnly];
    }
}

+ (NSPredicate* _Nullable)getPredicateForNotificationIds {
    return [NSPredicate predicateWithFormat:@"id IN %@", @[]];
}

- (void) insert:(NSDictionary *)dictionary usingPrivateContext: (NSManagedObjectContext*)privateContext
 andMainContext: (NSManagedObjectContext*)masterContext
        handler:(void (^)(BOOL))handler {
    if (masterContext && privateContext) {
        [self map:dictionary];
        
        @try {
            if([privateContext isKindOfClass:[NSManagedObjectContext class]]) {
                [privateContext performBlock:^{
                    @try {
                        NSError *error = nil;
                        [privateContext save:&error];
                        if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                            [masterContext performBlock:^{
                                @try {
                                    NSError *error = nil;
                                    [masterContext save:&error];
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

+ (void)fetchNotificationByID :(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", notificationID];
    [fetchRequest setPredicate:predicate];
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
                            entity.readStatus = YES;
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

+ (void)markNotificationAsRead:(BlueshiftInboxMessage *)message {
    @try {
        NSManagedObjectContext* context = [BlueShift sharedInstance].appDelegate.managedObjectContext;
        if(context && message.readStatus == NO) {
            NSEntityDescription *entity;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            entity = [NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:[BlueShift sharedInstance].appDelegate.managedObjectContext];
            [fetchRequest setEntity:entity];
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"id == %@", message.messageUUID];
            fetchRequest.predicate = predicate;
            [context performBlock:^{
                @try {
                    NSError *error;
                    NSArray *arrResult = [context executeFetchRequest:fetchRequest error:&error];
                    if (arrResult.count > 0) {
                        InAppNotificationEntity *notification = arrResult[0];
                        notification.readStatus = YES;
                        error = nil;
                        [context save:&error];
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
            self.id = [NSString stringWithFormat:@"%u",arc4random_uniform(99999)];
            [payload setValue:self.id forKey:kInAppId];
        }
        /* parse the payload and save the relevant keys related to presentation of In-App msg */
        
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
        self.status = kInAppStatusPending;
        self.readStatus = NO;
        self.availability = [dictionary valueForKey:kBSAvailabilty];
        self.createdAt = [NSNumber numberWithDouble: (double)[[NSDate date] timeIntervalSince1970]];
        self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)eraseEntityData {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *context;
    @try {
        if (appDelegate) {
            context = appDelegate.managedObjectContext;
        }
        if (context) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kInAppNotificationEntityNameKey];
            if (@available(iOS 9.0, *)) {
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
                            } else {
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the InAppNotification entity", deleteResult.result] withDetails:nil methodName:nil];
                            }
                        } @catch (NSException *exception) {
                            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        }
                    }];
                }
            }
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
