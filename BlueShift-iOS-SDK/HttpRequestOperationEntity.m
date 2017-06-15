//
//  HttpRequestOperationEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "HttpRequestOperationEntity.h"

@implementation HttpRequestOperationEntity

@dynamic httpMethodNumber;
@dynamic parameters;
@dynamic url;
@dynamic nextRetryTimeStamp;
@dynamic retryAttemptsCount;
@dynamic isBatchEvent;

// Method to insert Entry for a particular request operation in core data ...

- (void)insertEntryWithMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andURL:(NSString *)url andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount andIsBatchEvent:(BOOL) isBatchEvent {
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
            return ;
        }
        // gets the httpMethodNumber type for the enum ...
        
        self.httpMethodNumber = [NSNumber numberWithBlueShiftHTTPMethod:httpMethod];
        
        // will only archive parameters if they are present to prevent crash ...
        
        if (parameters) {
            self.parameters = [NSKeyedArchiver archivedDataWithRootObject:parameters];
        }
        
        self.url = url;
        self.nextRetryTimeStamp = [NSNumber numberWithDouble:nextRetryTimeStamp];
        self.retryAttemptsCount = [NSNumber numberWithInteger:retryAttemptsCount];
        self.isBatchEvent = isBatchEvent;
        
        @try {
            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlock:^{
                    NSError *error = nil;
                    [context save:&error];
                    if(masterContext && [masterContext isKindOfClass:[NSManagedObjectContext class]]) {
                        [masterContext performBlock:^{
                            NSError *error = nil;
                            [masterContext save:&error];
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



// Method to return the httpMethod type as BlueShiftHTTPMethod enum ...

- (BlueShiftHTTPMethod)httpMethod {
    return [self.httpMethodNumber blueShiftHTTPMethodValue];
}

    
// Method to return the first record from Core Data ...

+ (void *)fetchFirstRecordFromCoreDataWithCompletetionHandler:(void (^)(BOOL, HttpRequestOperationEntity *))handler {
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate != nil && appDelegate.realEventManagedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.realEventManagedObjectContext;
            if(context != nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                @try {
                    [fetchRequest setEntity:[NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(fetchRequest.entity != nil) {
                    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate] ];
                    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@ && isBatchEvent == NO", currentTimeStamp];
                    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
                    [fetchRequest setFetchLimit:1];
                    @try {
                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                            [context performBlock:^{
                                NSArray *results = [[NSArray alloc]init];
                                NSError *error;
                                results = [context executeFetchRequest:fetchRequest error:&error];
                                if(results.count > 0) {
                                    HttpRequestOperationEntity *operationEntityToBeExecuted = (HttpRequestOperationEntity *)[results firstObject];
                                    handler(YES, operationEntityToBeExecuted);
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
            }
        } else {
            handler(NO, nil);
        }
    }
}
    

// Method to return the batch records from Core Data ....
+ (void *)fetchBatchWiseRecordFromCoreDataWithCompletetionHandler:(void (^)(BOOL, NSArray *))handler {
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate != nil && appDelegate.batchEventManagedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.batchEventManagedObjectContext;
            if(context != nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                @try {
                    [fetchRequest setEntity:[NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:context]];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(fetchRequest.entity != nil) {
                    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
                    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@ && isBatchEvent == YES", currentTimeStamp];
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
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                } else {
                    handler(NO, nil);
                }
            } else {
                handler(NO, nil);
            }
        } else {
            handler(NO, nil);
        }
    }
}

@end
