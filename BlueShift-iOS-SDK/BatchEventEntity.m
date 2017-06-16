//
//  BatchEventEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BatchEventEntity.h"

@implementation BatchEventEntity

@dynamic paramsArray;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;

// Method to insert Entry for a particular request operation in core data ...

- (void)insertEntryParametersList:(NSArray *)parametersArray andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        @try {
            masterContext = appDelegate.batchEventManagedObjectContext;
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
            return ;
        }
        // will only archive parameters list if they are present to prevent crash ...
        if (parametersArray) {
            self.paramsArray = [NSKeyedArchiver archivedDataWithRootObject:parametersArray];
        }
        self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
        self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSError *error = nil;
                    [context save:&error];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            if (masterContext) {
                                [masterContext save:&error];
                            }
                        }];
                    }
                }];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception %@", exception);
        }
    } else {
        return ;
    }
}


// Method to return the failed batch records from Core Data ....

+ (void *)fetchBatchesFromCoreDataWithCompletetionHandler:(void (^)(BOOL, NSArray *))handler {
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
                    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BatchEventEntity" inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(fetchRequest.entity != nil) {
                    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
                    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@", currentTimeStamp];
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
                } else {
                    handler(NO, nil);
                }
            }
        } else {
            handler(NO, nil);
        }
    }
}


@end
