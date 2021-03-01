//
//  BatchEventEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BatchEventEntity.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@interface BatchEventEntity ()

+ (void *)fetchBatchesFromCoreDataFromContext:(NSManagedObjectContext*) context request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler;
@end

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
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
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
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
            if(context) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                @try {
                    [fetchRequest setEntity:[NSEntityDescription entityForName:kBatchEventEntity inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
                if(fetchRequest.entity != nil) {
                    [BatchEventEntity fetchBatchesFromCoreDataFromContext:context request:fetchRequest handler:handler];
                } else {
                    handler(NO, nil);
                }
            }
        } else {
            handler(NO, nil);
        }
    }
}

+ (void *)fetchBatchesFromCoreDataFromContext:(NSManagedObjectContext*) context request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
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
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

+ (void)eraseEntityData {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    @try {
        if (appDelegate) {
            masterContext = appDelegate.batchEventManagedObjectContext;
        }
        if (masterContext) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kBatchEventEntity];
            if (@available(iOS 9.0, *)) {
                NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
                if([masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                    [masterContext performBlock:^{
                        NSError *error = nil;
                        // check if there are any changes to be saved and save it
                        if ([masterContext hasChanges]) {
                            [masterContext save:&error];
                        }
                        NSBatchDeleteResult* deleteReult = [masterContext executeRequest:deleteRequest error:&error];
                        [masterContext save:&error];
                        if (error) {
                            [BlueshiftLog logError:error withDescription:@"Failed to save the data after deleting events." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        } else {
                            [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the batched events table", deleteReult.result] withDetails:nil methodName:nil];
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
