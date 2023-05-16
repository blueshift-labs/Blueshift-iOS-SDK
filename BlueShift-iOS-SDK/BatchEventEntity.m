//
//  BatchEventEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BatchEventEntity.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@implementation BatchEventEntity

@dynamic paramsArray;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;
@dynamic createdAt;

- (void)insertEntryParametersList:(NSArray *)parametersArray andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.eventsMOContext;
    if (context) {
        @try {
            if (parametersArray) {
                self.paramsArray = [NSKeyedArchiver archivedDataWithRootObject:parametersArray];
            }
            self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
            self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
            self.createdAt = [[NSDate date] timeIntervalSince1970];
            [context performBlock:^{
                @try {
                    NSError *error = nil;
                    [context save:&error];
                    if(error) {
                        [BlueshiftLog logError:error withDescription:@"Failed to insert batch event record." methodName:nil];
                    } else {
                        [BlueshiftLog logInfo:@"Inserted batch event record successfully." withDetails:nil methodName:nil];
                    }
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            }];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

+ (void)fetchBatchesFromCoreDataWithCompletionHandler:(void (^)(BOOL, NSArray * _Nullable))handler {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.eventsMOContext;
    if(context) {
        @try {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kBatchEventEntity];
            if (fetchRequest) {
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
                                NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
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
        @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    } else {
        handler(NO, nil);
    }
}

+ (void)deleteEntryForObjectId:(NSManagedObjectID *)objectId completionHandler:(void (^)(BOOL))handler {
    NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
    if (context) {
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    @try {
                        NSManagedObject* managedObject =  [context objectWithID: objectId];
                        [context deleteObject:managedObject];
                        NSError *saveError;
                        [context save:&saveError];
                        if (saveError) {
                            [BlueshiftLog logError:saveError withDescription:@"Failed to delete Batch record." methodName:nil];
                            handler(NO);
                        } else {
                            [BlueshiftLog logInfo:@"Deleted Batch record successfully." withDetails:nil methodName:nil];
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
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            handler(NO);
        }
    } else {
        handler(NO);
    }
}


+ (void)eraseEntityData {
    NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
    @try {
        if (context) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kBatchEventEntity];
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
