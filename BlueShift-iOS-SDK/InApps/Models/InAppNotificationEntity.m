//
//  InAppNotificationEntity.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import "InAppNotificationEntity.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftAppDelegate.h"
#import "NSDate+BlueShiftDateHelpers.h"
#import "../BlueShiftInAppNotificationConstant.h"

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

- (void)fetchBy:(NSString *)key withValue:(NSString *)value {
    
}

+ (void)fetchAll:(BlueShiftInAppTriggerMode)triggerMode withHandler:(void (^)(BOOL, NSArray *))handler {
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        NSManagedObjectContext *context;
        if (appDelegate) {
            @try {
                context = appDelegate.batchEventManagedObjectContext;
            }
            @catch (NSException *exception) {
                NSLog(@"Caught exception %@", exception);
            }
            if(context) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                @try {
                    [fetchRequest setEntity:[NSEntityDescription entityForName: kInAppNotificationEntityNameKey inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(fetchRequest.entity != nil) {
                    [self fetchFromCoreDataFromContext:context forTriggerMode:triggerMode request:fetchRequest handler:handler];
                } else {
                    handler(NO, nil);
                }
            }
        } else {
            handler(NO, nil);
        }
    }
}

+ (void *)fetchFromCoreDataFromContext:(NSManagedObjectContext*) context forTriggerMode: (BlueShiftInAppTriggerMode) triggerMode request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    
    //NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
    
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
    }
    
    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"triggerMode == %@ AND status == %@", triggerStr, @"ready"];
    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
    
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                NSError *error;
                NSArray *results = [[NSArray alloc]init];
                results = [context executeFetchRequest:fetchRequest error:&error];
                if (results && results.count > 0) {
                    [self updateNotificationsInQueue:context notifications:results];
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

+ (void)updateNotificationsInQueue:(NSManagedObjectContext *)context notifications:(NSArray *)notifications {
    for(int i = 0; i < notifications.count; i++) {
        InAppNotificationEntity *notification = [notifications objectAtIndex:i];
        [notification setValue:@"QUEUE" forKey:@"status"];
    }
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                NSError *error = nil;
                [context save:&error];
            }];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Caught exception %@", exception);
    }
}

- (void) insert:(NSDictionary *)dictionary inContext: (NSManagedObjectContext*) manageContext handler:(void (^)(BOOL))handler {

    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.managedObjectContext;
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
    }
    if (masterContext) {
        /*
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
         */
        NSManagedObjectContext *context = manageContext;
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

- (void)update:(NSDictionary *)dictionary {
    
}

- (void)delete {
    
}

- (void)map:(NSDictionary *)dictionary {
    
    self.id = [NSString stringWithFormat:@"%u",arc4random_uniform(99999)];
    
    NSMutableDictionary *payload = [dictionary mutableCopy];
    [payload setValue:self.id forKey:@"id"];
    
    
    /* parse the payload and save the relevant keys related to presentation of In-App msg */
    
    /* get in-app payload */
    dictionary = [dictionary objectForKey: kInAppNotificationKey];
    
    /* get type of In-App msg */
    if ([dictionary objectForKey:kSilentNotificationPayloadTypeKey]) {
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
    self.status = @"ready";
    
    self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
}

@end
