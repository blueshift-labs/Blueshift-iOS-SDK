//
//  HttpRequestOperationEntity.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "HttpRequestOperationEntity.h"

#define kBatchSize  100

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
    if (appDelegate != nil && appDelegate.managedObjectContext != nil) {
        NSManagedObjectContext *masterContext = appDelegate.managedObjectContext;
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
        
        [context performBlock:^{
            NSError *error = nil;
            [context save:&error];
            [masterContext performBlockAndWait:^{
                NSError *error = nil;
                [masterContext save:&error];
            }];
        }];
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
        if(appDelegate != nil && appDelegate.managedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            if(context != nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:context]];
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
                                }
                                handler(NO, nil);
                            }];
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                }
            }
        }
        handler(NO, nil);
    }
}
    

// Method to return the batch records from Core Data ....
+ (NSArray *)fetchBatchWiseRecordFromCoreData {
    @synchronized(self) {
        NSArray *results = [[NSArray alloc]init];
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate != nil && appDelegate.managedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            if(context != nil) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:context]];
                if(fetchRequest.entity != nil) {
                    NSNumber *currentTimeStamp = [NSNumber numberWithDouble:[[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]];
                    NSPredicate *nextRetryTimeStampLessThanCurrentTimePredicate = [NSPredicate predicateWithFormat:@"nextRetryTimeStamp < %@ && isBatchEvent == YES", currentTimeStamp];
                    [fetchRequest setPredicate:nextRetryTimeStampLessThanCurrentTimePredicate];
                    [fetchRequest setFetchLimit:kBatchSize];
                    NSError *error;
                    
                    @try {
                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                            results = [context executeFetchRequest:fetchRequest error:&error];
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Caught exception %@", exception);
                    }
                }
            }
        }
        return results;
    }
}

@end
