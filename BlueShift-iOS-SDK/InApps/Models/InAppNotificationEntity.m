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

+ (void)fetchAll:(void (^)(BOOL, NSArray *))handler {
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
                    [fetchRequest setEntity:[NSEntityDescription entityForName:@"InAppNotificationEntity" inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(fetchRequest.entity != nil) {
                    [self fetchFromCoreDataFromContext:context request:fetchRequest handler:handler];
                } else {
                    handler(NO, nil);
                }
            }
        } else {
            handler(NO, nil);
        }
    }
}

+ (void *)fetchFromCoreDataFromContext:(NSManagedObjectContext*) context request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    //NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"triggerMode == %@ AND status == %@", @"NOW", @"READY"];
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


- (void)insert:(NSDictionary *)dictionary handler:(void (^)(BOOL))handler {
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
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
    //self.id = [dictionary objectForKey:@"id"];
    // Temporary
    self.id = [NSString stringWithFormat:@"%u",arc4random_uniform(99999)];
    NSMutableDictionary *payload = [dictionary mutableCopy];
    [payload setValue:self.id forKey:@"id"];
    self.type = [dictionary objectForKey:@"type"];
    self.startTime = [NSNumber numberWithDouble: [[dictionary objectForKey:@"start_time"] doubleValue]];
    self.endTime = [NSNumber numberWithDouble: [[dictionary objectForKey:@"end_time"] doubleValue]];
    self.payload = [NSKeyedArchiver archivedDataWithRootObject:payload];
    self.priority = @"MEDIUM";
    self.triggerMode = @"NOW";
    self.eventName = @"";
    self.status = @"READY";
}

@end
