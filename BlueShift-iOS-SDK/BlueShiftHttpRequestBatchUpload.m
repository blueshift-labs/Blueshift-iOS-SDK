//
//  BlueShiftHttpRequestBatchUpload.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftHttpRequestBatchUpload.h"

// this static variable is meant to show the status of the request queue ...

static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;

@implementation BlueShiftHttpRequestBatchUpload

// Method to start batch uploading
+ (void)startBatchUpload {
    [NSTimer scheduledTimerWithTimeInterval:[[BlueShiftBatchUploadConfig sharedInstance] fetchBatchUploadTimer]
                                     target:self
                                   selector:@selector(batchEventsUploadInBackground)
                                   userInfo:nil
                                    repeats:YES];
}

// Perform uploading task in background (inclues core data operations)
+ (void)batchEventsUploadInBackground {
    [self performSelectorInBackground:@selector(createAndUploadBatches) withObject:nil];
}



// Method to create and upload batches
+ (void)createAndUploadBatches {
    [self createBatches];
    [self uploadBatches];
}

// Method to create batches
+ (void)createBatches {
    @synchronized(self) {
        NSArray *operationEntitiesToBeExecuted = [HttpRequestOperationEntity fetchBatchWiseRecordFromCoreData];
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate != nil && appDelegate.managedObjectContext != nil) {
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            if(context != nil) {
                while (operationEntitiesToBeExecuted.count >0) {
                    NSMutableArray *paramsArray = [[NSMutableArray alloc]init];
                    for(HttpRequestOperationEntity *operationEntityToBeExecuted in operationEntitiesToBeExecuted) {
                        if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]) {
                            BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                            if(requestOperation.parameters != nil) {
                                [paramsArray addObject:requestOperation.parameters];
                            }
                            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                [context deleteObject:operationEntityToBeExecuted];
                            }
                            NSError *saveError = nil;
                            @try {
                                if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                    [context save:&saveError];
                                }
                            }
                            @catch (NSException *exception) {
                                NSLog(@"Caught exception %@", exception);
                            }
                        }
                    }
                    [self createBatch:paramsArray];
                    operationEntitiesToBeExecuted = [HttpRequestOperationEntity fetchBatchWiseRecordFromCoreData];
                }
            }
        }
    }
}

// Method to create a batch
+ (void)createBatch:(NSArray *)paramsArray {
    BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc] initParametersList:paramsArray andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0];
    [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
}

// Method to upload all batches
+ (void)uploadBatches {
    NSArray *batches = [BatchEventEntity fetchBatchesFromCoreData];
    if(batches != nil && batches.count > 0) {
        [self uploadBatchAtIndex:0 fromBatches:batches];
    }
}

// Method to upload batch
+ (void)uploadBatchAtIndex:(int)index fromBatches:(NSArray *)batches {
    if(index == batches.count) {
        return;
    } else {
        BatchEventEntity *batchEvent = [batches objectAtIndex:index];
        [self processRequestsInQueue:batchEvent completetionHandler:^(BOOL status) {
            [self uploadBatchAtIndex:index+1 fromBatches:batches];
        }];
    }
}


+ (void) processRequestsInQueue:(BatchEventEntity *)batchEvent completetionHandler:(void (^)(BOOL))handler {
    @synchronized(self) {
        // Will execute the code when the requestQueue is free / available and internet is connected ...
        
        if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES) {
            
            // Gets the current NSManagedObjectContext via appDelegate ...
            
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
            if(appDelegate != nil && appDelegate.managedObjectContext != nil) {
                NSManagedObjectContext *context = appDelegate.managedObjectContext;
                
                if(context != nil) {
                    // Only handles when the fetched record is not nil ...
                    
                    BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc]initWithBatchRequestOperationEntity:batchEvent];
                    
                    if (requestOperation != nil) {
                        // requestQueue status is made busy ...
                        
                        _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
                        
                        // Performs the request operation ...
                        
                        [BlueShiftHttpRequestBatchUpload performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
                            if (status == YES) {
                                // delete batch records for the request operation if it is successfully executed ...
                                [context deleteObject:batchEvent];
                                NSError *saveError = nil;
                                BOOL deletedStatus;
                                
                                @try {
                                    if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                        deletedStatus = [context save:&saveError];
                                    }
                                }
                                @catch (NSException *exception) {
                                    NSLog(@"Caught exception %@", exception);
                                }
                                
                                if (deletedStatus == YES) {
                                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                } else {
                                    // To be handled if request executed is not deleted from core data...
                                    
                                }
                                handler(YES);
                            } else {
                                // Request is not executed due to some reasons ...
                                
                                [context deleteObject:batchEvent];
                                NSError *saveError = nil;
                                BOOL deletedStatus;
                                
                                @try {
                                    if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                        deletedStatus = [context save:&saveError];
                                    }
                                }
                                @catch (NSException *exception) {
                                    NSLog(@"Caught exception %@", exception);
                                }
                                
                                if (deletedStatus == YES) {
                                    
                                } else {
                                    // To be handled if request executed is not deleted from core data...
                                }
                                
                                NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                                requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
                                requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
                                
                                // request record is removed successfully from core data ...
                                if (requestOperation.retryAttemptsCount > 0) {
                                    [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
                                    [self retryBatchUpload];
                                }
                                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                handler(NO);
                            }
                        }];
                    }
                }
            }
        }
    }
}

// Method to retry batch uploading
+ (void)retryBatchUpload {
    [NSTimer scheduledTimerWithTimeInterval:kRequestRetryMinutesInterval * 60
                                     target:self
                                   selector:@selector(retryBatchEventsUploadInBackground)
                                   userInfo:nil
                                    repeats:NO];
}

// Perform uploading task in background (inclues core data operations)
+ (void)retryBatchEventsUploadInBackground {
    [self performSelectorInBackground:@selector(uploadBatches) withObject:nil];
}

+ (void)performRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation completetionHandler:(void (^)(BOOL))handler {
    
    // get the request operation details ...
    NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, kBatchUploadURL];
    
    NSMutableArray *parametersArray = (NSMutableArray*)requestOperation.paramsArray;
    if ((!parametersArray) || (parametersArray.count == 0)){
        handler(YES);
        return;
    }
    NSDictionary *paramsDictionary = @{@"events": parametersArray};
    // perform executions based on the request operation http method ...
    
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:paramsDictionary completetionHandler:^(BOOL status) {
        handler(status);
    }];}


@end
