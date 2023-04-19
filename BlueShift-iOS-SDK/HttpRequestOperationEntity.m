//
//  HttpRequestOperationEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "HttpRequestOperationEntity.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@implementation HttpRequestOperationEntity

@dynamic httpMethodNumber;
@dynamic parameters;
@dynamic url;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;
@dynamic isBatchEvent;
@dynamic createdAt;

- (void)insertEntryWithMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andURL:(NSString *)url andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount andIsBatchEvent:(BOOL) isBatchEvent {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.eventsMOContext;
    if (context) {
        self.httpMethodNumber = [NSNumber numberWithBlueShiftHTTPMethod:httpMethod];
        if (parameters) {
            self.parameters = [NSKeyedArchiver archivedDataWithRootObject:parameters];
        }
        self.url = url;
        self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
        self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
        self.isBatchEvent = isBatchEvent;
        self.createdAt = [[NSDate date] timeIntervalSince1970];
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSError *error = nil;
                    @try {
                        [context save:&error];
                        if(error) {
                            [BlueshiftLog logError:error withDescription:@"Failed to insert event record." methodName:nil];
                        } else {
                            [BlueshiftLog logInfo:@"Inserted event record successfully." withDetails:nil methodName:nil];
                        }
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }];
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    } else {
        return ;
    }
}

- (BlueShiftHTTPMethod)httpMethod {
    return [self.httpMethodNumber blueShiftHTTPMethodValue];
}

+ (void)fetchOneRealTimeEventFromDBWithCompletionHandler:(void (^)(BOOL, HttpRequestOperationEntity * _Nullable))handler {
    @try {
        NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kHttpRequestOperationEntity];
        if(context && fetchRequest) {
            NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate] ];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@ && isBatchEvent == NO", currentTimeStamp];
            NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:kBSCreatedAt ascending:YES];
            [fetchRequest setSortDescriptors:@[sortByDate]];
            [fetchRequest setPredicate:predicate];
            [fetchRequest setFetchLimit:1];
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    @try {
                        NSError *error;
                        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
                        if(results.count > 0) {
                            HttpRequestOperationEntity *operationEntityToBeExecuted = (HttpRequestOperationEntity *)[results firstObject];
                            handler(YES, operationEntityToBeExecuted);
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
        } else {
            handler(NO, nil);
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        handler(NO, nil);
    }
}

+ (void)fetchBatchedEventsFromDBWithCompletionHandler:(void (^)(BOOL, NSArray * _Nullable))handler {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.eventsMOContext;
    if(context) {
        @try {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kHttpRequestOperationEntity];
            if(fetchRequest) {
                NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@ && isBatchEvent == YES", currentTimeStamp];
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
                    }
                }
                @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    handler(NO, nil);
                }
            } else {
                handler(NO, nil);
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

+ (void)deleteRecordForObjectId:(NSManagedObjectID*)objectId completionHandler:(void (^)(BOOL))handler {
    NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
    if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
        [context performBlock:^{
            @try {
                NSError *saveError = nil;
                if(context && [context respondsToSelector:@selector(deleteObject:)]) {
                    NSManagedObject* object = [context objectWithID:objectId];
                    [context deleteObject:object];
                    [context save:&saveError];
                    if (saveError) {
                        [BlueshiftLog logError:saveError withDescription:@"Failed to delete event record." methodName:nil];
                        handler(NO);
                    } else {
                        [BlueshiftLog logInfo:@"Deleted event record." withDetails:nil methodName:nil];
                        handler(YES);
                    }
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

+ (void)eraseEntityData {
    NSManagedObjectContext *context = [BlueShift sharedInstance].appDelegate.eventsMOContext;
    @try {
        if(context) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kHttpRequestOperationEntity];
            if (@available(iOS 9.0, *)) {
                NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
                [deleteRequest setResultType:NSBatchDeleteResultTypeCount];
                if([context isKindOfClass:[NSManagedObjectContext class]]) {
                    [context performBlock:^{
                        @try {
                            NSError *error = nil;
                            // check if there are any changes for realtime events to be saved and save it
                            if ([context hasChanges]) {
                                [context save:&error];
                            }
                            NSBatchDeleteResult* deleteResult = [context executeRequest:deleteRequest error:&error];
                            [context save:&error];
                            if (error) {
                                [BlueshiftLog logError:error withDescription:@"Failed to save the data after deleting events." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                            } else {
                                [BlueshiftLog logInfo:[NSString stringWithFormat:@"Deleted %@ records from the HttpRequestOperationEntity entity", deleteResult.result] withDetails:nil methodName:nil];
                            }
                            
                        } @catch (NSException *exception) {
                            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        }
                    }];
                }
            }
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
