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
#import "../BlueShiftNotificationConstants.h"
#import "../BlueshiftLog.h"

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

- (void)fetchBy:(NSString *)key withValue:(NSString *)value {
}

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
    
    NSString* triggerStr;
    
    switch (triggerMode) {
        case BlueShiftInAppTriggerNow:
            triggerStr = @"now";
            break;
        case BlueShiftInAppTriggerUpComing:
            triggerStr = @"upcoming";
            break;
        case BlueShiftInAppTriggerEvent:
            triggerStr = @"event";
            break;
        case BlueShiftInAppNoTriggerEvent:
            triggerStr = @"";
            break;
        case BlueShiftInAppTriggerNowAndUpComing:
            triggerStr = @"NowAndUpComing";
            break;
    }
    
    displayOn =  (displayOn ? displayOn: @"");
    
    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [self getPredicates: triggerStr andDisplayOn: displayOn];
    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
    
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                NSError *error;
                NSArray *results = [[NSArray alloc]init];
                results = [context executeFetchRequest:fetchRequest error:&error];
                if (results && results.count > 0) {
                    handler(YES, results);
                } else {
                    handler(NO, nil);
                }
            }];
        } else {
            handler(NO, nil);
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (NSPredicate *)getPredicates:(NSString *)triggerStr andDisplayOn:(NSString *)displayOn {
    if ([triggerStr isEqualToString:@"NowAndUpComing"]) {
        return [NSPredicate predicateWithFormat:@"(triggerMode == %@ OR triggerMode == %@)AND status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@)", @"now",@"upcoming", @"pending", displayOn, @"", nil];
    } else if (triggerStr && ![triggerStr isEqualToString: @""]) {
        return [NSPredicate predicateWithFormat:@"(triggerMode == %@ AND status == %@) AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@)", triggerStr, @"pending", displayOn, @"", nil];
    } else {
        return [NSPredicate predicateWithFormat:@"status == %@ AND (displayOn == %@ OR displayOn == %@ OR displayOn == %@)", @"pending", displayOn, @"", nil];
    }
}

- (void) insert:(NSDictionary *)dictionary usingPrivateContext: (NSManagedObjectContext*)privateContext
 andMainContext: (NSManagedObjectContext*)masterContext
        handler:(void (^)(BOOL))handler {
    
    if (nil != masterContext && nil != privateContext) {
        
        NSManagedObjectContext *context = privateContext;
        context.parentContext = masterContext;
        // return if context is unavailable ...
        if (context == nil || masterContext == nil) {
            handler(NO);
            return;
        }
        [self map:dictionary];
        
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSError *error = nil;
                    [context save:&error];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            [masterContext save:&error];
                            handler(YES);
                        }];
                    } else {
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
    
    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"id == %@", notificationID];
    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
    
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                NSError *error;
                NSArray *results = [[NSArray alloc]init];
                results = [context executeFetchRequest:fetchRequest error:&error];
                if (results && results.count > 0) {
                    handler(YES, results);
                } else {
                    handler(NO, nil);
                }
            }];
        } else {
            handler(NO, nil);
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)fetchInAppNotificationByStatus :(NSManagedObjectContext *)context forNotificatioID: (NSString *) status request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    
    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"status == %@", status];
    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
    [fetchRequest setFetchLimit: 10];
    
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                NSError *error;
                NSArray *results = [[NSArray alloc]init];
                results = [context executeFetchRequest:fetchRequest error:&error];
                if (results && results.count > 0) {
                    handler(YES, results);
                } else {
                    handler(NO, nil);
                }
            }];
        } else {
            handler(NO, nil);
        }
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)updateInAppNotificationStatus:(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest notificationStatus:(NSString *)status
    andAppDelegate:(BlueShiftAppDelegate *)appdelegate handler:(void (^)(BOOL))handler{
    if (status) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", notificationID];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setFetchLimit:1];
        NSError *error;
        NSArray *arrResult = [context executeFetchRequest:fetchRequest error:&error];
        if (arrResult.count > 0) {
            InAppNotificationEntity *entity = arrResult[0];
            [entity setValue: status forKey: @"status"];
            @try {
                if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                    [context performBlock:^{
                        NSError *error = nil;
                        [context save:&error];
                        handler(YES);
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
    } else {
        handler(NO);
    }
}

- (void)delete {
    
}

- (void)map:(NSDictionary *)dictionary {
    
    NSMutableDictionary *payload = [dictionary mutableCopy];
    if ([dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] &&
        [dictionary objectForKey: kInAppNotificationModalMessageUDIDKey] != [NSNull null]) {
        self.id =(NSString *)[dictionary objectForKey: kInAppNotificationModalMessageUDIDKey];
    } else {
        self.id = [NSString stringWithFormat:@"%u",arc4random_uniform(99999)];
        [payload setValue:self.id forKey:@"id"];
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
    
    /* get type of In-App msg */
    if ([dictionary objectForKey: kSilentNotificationPayloadTypeKey] &&
        [dictionary objectForKey: kSilentNotificationPayloadTypeKey] != [NSNull null]) {
        self.type = [dictionary objectForKey: kSilentNotificationPayloadTypeKey];
    }

    if ([dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey] &&
        [dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey] != [NSNull null]) {
        self.displayOn = [dictionary objectForKey: kInAppNotificationPayloadDisplayOnKey];
    }
    
    /* get start and end Time */
    if ([dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] &&
        [dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] != [NSNull null]) {
        self.endTime = [NSNumber numberWithDouble: [[dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] doubleValue]];
    }
    
    self.triggerMode = @"now";
    if ([dictionary objectForKey: kSilentNotificationTriggerKey]) {
        NSString *trigger = (NSString *)[dictionary objectForKey: kSilentNotificationTriggerKey];
        if (![trigger isEqualToString:@""]) {
            if ([BlueShiftInAppNotificationHelper hasDigits: trigger] == YES) {
                self.triggerMode = @"upcoming";
                self.startTime = [NSNumber numberWithDouble: [trigger doubleValue]];
            } else {
                self.triggerMode = trigger;
            }
        }
    }
    
    /* Other properties */
    self.priority = @"medium";
    self.eventName = @"";
    self.status = @"pending";
    self.createdAt = [NSNumber numberWithDouble: (double)[[NSDate date] timeIntervalSince1970]];
    self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
}

@end
