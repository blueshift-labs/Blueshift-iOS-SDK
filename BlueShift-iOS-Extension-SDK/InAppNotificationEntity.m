//
//  InAppNotificationEntity.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import "InAppNotificationEntity.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "NSDate+BlueShiftDateHelpers.h"
#import "BlueShiftNotificationConstants.h"

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

- (void) insert:(NSDictionary *)dictionary
usingPrivateContext: (NSManagedObjectContext*)privateContext
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
                    printf("%f InAppNotify:: saving child context ++\n", [[NSDate date] timeIntervalSince1970]);
                    [context save:&error];
                    
                    printf("%f InAppNotify:: saving child context --\n", [[NSDate date] timeIntervalSince1970]);
                    [context save:&error];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        printf("%f InAppNotify:: masterContext perform block --\n", [[NSDate date] timeIntervalSince1970]);
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            printf("%f InAppNotify:: saving parent context \n", [[NSDate date] timeIntervalSince1970]);
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
            NSLog(@"Caught exception %@", exception);
            handler(NO);
        }
    } else {
        handler(NO);
    }
}

- (void)fetchNotificationByID :(NSManagedObjectContext *)context forNotificatioID: (NSString *) notificationID request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler{
    
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
        NSLog(@"Caught exception %@", exception);
    }
}

- (void)map:(NSDictionary *)dictionary {
    
    NSMutableDictionary *payload = [dictionary mutableCopy];
    if ([dictionary objectForKey: kInAppNotificationModalMessageUDIDKey]) {
        self.id =(NSString *)[dictionary objectForKey: kInAppNotificationModalMessageUDIDKey];
    }else {
        self.id = [NSString stringWithFormat:@"%u",arc4random_uniform(99999)];
        [payload setValue:self.id forKey:@"id"];
    }
    /* parse the payload and save the relevant keys related to presentation of In-App msg */
    
    /* get in-app payload */
    if ([dictionary objectForKey: kSilentNotificationPayloadIdentifierKey]) {
        dictionary = [dictionary objectForKey: kSilentNotificationPayloadIdentifierKey];
    }
    
    if ([dictionary objectForKey: kInAppNotificationKey]) {
        dictionary = [dictionary objectForKey: kInAppNotificationKey];
    }
    
    /* get type of In-App msg */
    if ([dictionary objectForKey: kSilentNotificationPayloadTypeKey]) {
        self.type = [dictionary objectForKey: kSilentNotificationPayloadTypeKey];
    }
    
    /* get start and end Time */
    if ([dictionary objectForKey: kSilentNotificationTriggerEndTimeKey]) {
        self.endTime = [NSNumber numberWithDouble: [[dictionary objectForKey: kSilentNotificationTriggerEndTimeKey] doubleValue]];
    }
    
    if ([dictionary objectForKey: kSilentNotificationTriggerKey]) {
        NSDictionary *triggerDictionaryNode = [dictionary objectForKey: kSilentNotificationTriggerKey];
        if ([triggerDictionaryNode objectForKey:kSilentNotificationTriggerModeKey]) {
            self.triggerMode = (NSString *)[triggerDictionaryNode objectForKey:kSilentNotificationTriggerModeKey];
        }
        if ([triggerDictionaryNode objectForKey:kSilentNotificationTriggerStartTimeKey]) {
            self.startTime = [NSNumber numberWithDouble: [[triggerDictionaryNode objectForKey:kSilentNotificationTriggerStartTimeKey] doubleValue]];
        }
    }
    
    /* Other properties */
    self.priority = @"medium";
    self.eventName = @"";
    self.status = @"pending";
    self.createdAt = [NSNumber numberWithDouble: (double)([[NSDate date] timeIntervalSince1970] * 1000.0)];

    self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
}

@end
