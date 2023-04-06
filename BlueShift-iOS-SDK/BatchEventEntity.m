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

+ (void)fetchBatchesFromCoreDataFromContext:(NSManagedObjectContext*) context request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler;
@end

@implementation BatchEventEntity

@dynamic paramsArray;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;
@dynamic createdAt;

- (void)insertEntryParametersList:(NSArray *)parametersArray andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *masterContext;
    if (appDelegate) {
        masterContext = appDelegate.batchEventManagedObjectContext;
    }
    if (masterContext) {
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = masterContext;
        if (context == nil) {
            return ;
        }
        if (parametersArray) {
            self.paramsArray = [NSKeyedArchiver archivedDataWithRootObject:parametersArray];
        }
        self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
        self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
        self.createdAt = [[NSDate date] timeIntervalSince1970];
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    @try {
                        NSError *error = nil;
                        [context save:&error];
                        if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                            [masterContext performBlock:^{
                                @try {
                                    NSError *error = nil;
                                    if (masterContext) {
                                        [masterContext save:&error];
                                    }
                                } @catch (NSException *exception) {
                                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                                }
                            }];
                        }
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }];
            }
        }
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}


+ (void)fetchBatchesFromCoreDataWithCompletetionHandler:(void (^)(BOOL, NSArray *))handler {
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

+ (void)fetchBatchesFromCoreDataFromContext:(NSManagedObjectContext*) context request: (NSFetchRequest*)fetchRequest handler:(void (^)(BOOL, NSArray *))handler {
    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@", currentTimeStamp];
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:YES];
    [fetchRequest setSortDescriptors:@[sortByDate]];
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

+ (void)eraseEntityData {
    BlueShiftAppDelegate * appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
    NSManagedObjectContext *batchContext;
    @try {
        if (appDelegate) {
            batchContext = appDelegate.batchEventManagedObjectContext;
        }
        if (batchContext) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kBatchEventEntity];
            if (@available(iOS 9.0, *)) {
                NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
                [deleteRequest setResultType:NSBatchDeleteResultTypeCount];
                if([batchContext isKindOfClass:[NSManagedObjectContext class]]) {
                    [batchContext performBlock:^{
                        @try {
                            NSError *error = nil;
                            // check if there are any changes to be saved and save it
                            if ([batchContext hasChanges]) {
                                [batchContext save:&error];
                            }
                            NSBatchDeleteResult* deleteResult = [batchContext executeRequest:deleteRequest error:&error];
                            [batchContext save:&error];
                            if (error) {
                                [BlueshiftLog logError:error withDescription:@"Failed to save the data after deleting events." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            } else {
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the BatchEventEntity entity", deleteResult.result] withDetails:nil methodName:nil];
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
