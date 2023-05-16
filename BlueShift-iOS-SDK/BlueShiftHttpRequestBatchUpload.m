//
//  BlueShiftHttpRequestBatchUpload.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftHttpRequestBatchUpload.h"
#import "BlueshiftLog.h"

#define kBatchSize  100

@interface BlueShiftHttpRequestBatchUpload ()

+ (void)processBatches:(NSMutableArray*)batchList;

+ (void)handleRetryBatchUploadForRequestOperation:(BlueShiftBatchRequestOperation*)requestOperation objectId:(NSManagedObjectID *)objectId completionHandler:(void (^)(BOOL))handler;

@end

// Shows the status of the batch upload request queue
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
static NSTimer *_batchUploadTimer = nil;

@implementation BlueShiftHttpRequestBatchUpload

+ (void)startBatchUpload {
    // Create timer only if tracking is enabled
    if ([BlueShift sharedInstance].isTrackingEnabled && _batchUploadTimer == nil) {
        [BlueshiftLog logInfo:@"Starting the batch upload timer." withDetails:nil methodName:nil];
        _batchUploadTimer = [NSTimer scheduledTimerWithTimeInterval:[[BlueShiftBatchUploadConfig sharedInstance] fetchBatchUploadTimer] target:self selector:@selector(batchEventsUploadInBackground) userInfo:nil repeats:YES];
    }
}

+ (void)stopBatchUpload {
    if (_batchUploadTimer) {
        [BlueshiftLog logInfo:@"Stopping the batch upload." withDetails:nil methodName:nil];
        [_batchUploadTimer invalidate];
        _batchUploadTimer = nil;
    }
}


// Perform batch upload task in background
+ (void)batchEventsUploadInBackground {
    [self performSelectorInBackground:@selector(createAndUploadBatches) withObject:nil];
}

// Create and upload batches
+ (void)createAndUploadBatches {
    [self createBatches];
    [self uploadBatches];
}

+ (void)createBatches {
    @synchronized(self) {
        [HttpRequestOperationEntity fetchBatchedEventsFromDBWithCompletionHandler:^(BOOL status, NSArray *results) {
            if(status) {
                NSMutableArray *batchList = [[NSMutableArray alloc] init];
                NSUInteger batchLength = results.count/kBatchSize;
                if (results.count % kBatchSize != 0) {
                    batchLength = batchLength + 1;
                }
                for (NSUInteger i = 0; i < batchLength; i++) {
                    NSRange range;
                    range.location = i * kBatchSize;
                    if (i == batchLength-1) {
                        range.length = results.count % kBatchSize;
                    } else {
                        range.length = kBatchSize;
                    }
                    [batchList addObject:[results subarrayWithRange:range]];
                }
                
                [BlueShiftHttpRequestBatchUpload processBatches:batchList];
            }
        }];
    }
}

+ (void)processBatches:(NSMutableArray*)batchList {
    NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
    if(context) {
        for (NSArray *operationEntitiesToBeExecuted in batchList) {
            NSMutableArray *paramsArray = [[NSMutableArray alloc]init];
            for(HttpRequestOperationEntity *operationEntityToBeExecuted in operationEntitiesToBeExecuted) {
                if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]) {
                    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                    if(requestOperation.parameters != nil) {
                        [paramsArray addObject:requestOperation.parameters];
                    }
                    @try {
                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                            [context performBlockAndWait:^{
                                [context deleteObject:operationEntityToBeExecuted];
                            }];
                        }
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }
            }
            [self insertBatchEvent:paramsArray];
            if (context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                [context performBlockAndWait:^{
                    @try {
                        NSError *saveError = nil;
                        [context save:&saveError];
                    } @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                }];
            }
        }
    }
}

+ (void)insertBatchEvent:(NSArray *)paramsArray {
    BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc] initParametersList:paramsArray andRetryAttemptsCount:kRequestTryMaximumLimit andNextRetryTimeStamp:0];
    [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
}

// Upload all batches one by one
+ (void)uploadBatches {
    if (BlueShift.sharedInstance.config.apiKey) {
        [BatchEventEntity fetchBatchesFromCoreDataWithCompletionHandler:^(BOOL status, NSArray *batches) {
            if (status) {
                if(batches && batches.count > 0) {
                    [self uploadBatchAtIndex:0 fromBatches:batches];
                }
            }
        }];
    }
}

+ (void)uploadBatchAtIndex:(int)index fromBatches:(NSArray *)batches {
    if(index == batches.count) {
        return;
    } else {
        BatchEventEntity *batchEvent = [batches objectAtIndex:index];
        [self processRequestsInQueue:batchEvent completionHandler:^(BOOL status) {
            [self uploadBatchAtIndex:index+1 fromBatches:batches];
        }];
    }
}

+ (void)processRequestsInQueue:(BatchEventEntity *)batchEvent completionHandler:(void (^)(BOOL))handler {
    @synchronized(self) {
        // Process requet when requestQueue and internet is available
        if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES) {
            BlueShiftBatchRequestOperation *requestOperation = [[BlueShiftBatchRequestOperation alloc]initWithBatchRequestOperationEntity:batchEvent];
            
            if (requestOperation) {
                // Set request queue to busy to process it
                _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
                
                // Performs the request operation
                [BlueShiftHttpRequestBatchUpload performRequestOperation:requestOperation  completionHandler:^(BOOL status) {
                    if (status == YES) {
                        // delete batch records for the request operation if it is successfully executed
                        [BatchEventEntity deleteEntryForObjectId:batchEvent.objectID completionHandler:^(BOOL status) {
                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                            handler(status);
                        }];
                    } else {
                        // Retry the request when fails
                        [BlueShiftHttpRequestBatchUpload handleRetryBatchUploadForRequestOperation:requestOperation objectId:batchEvent.objectID completionHandler:^(BOOL status) {
                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                            handler(status);
                        }];
                    }
                }];
            }
        }
    }
}


+ (void)handleRetryBatchUploadForRequestOperation:(BlueShiftBatchRequestOperation*)requestOperation objectId:(NSManagedObjectID *)objectId completionHandler:(void (^)(BOOL))handler {
    @try {
        @try {
            // Delete the existing record
            [BatchEventEntity deleteEntryForObjectId:objectId completionHandler:^(BOOL status) {
                if (status) {
                    //Decrese the retry count
                    requestOperation.retryAttemptsCount = requestOperation.retryAttemptsCount - 1;
                    requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
                    
                    // Add a new entry if eligible, with modified retry attempt and timestamp
                    if (requestOperation.retryAttemptsCount > 0) {
                        [BlueShiftRequestQueue addBatchRequestOperation:requestOperation];
                        [self retryBatchUpload];
                    }
                }
                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                handler(YES);
            }];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
            handler(NO);
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
        handler(NO);
    }
}


// Schedule the retry batch upload
+ (void)retryBatchUpload {
    [NSTimer scheduledTimerWithTimeInterval:kRequestRetryMinutesInterval * 60
                                     target:self
                                   selector:@selector(retryBatchEventsUploadInBackground)
                                   userInfo:nil
                                    repeats:NO];
}

// Perform retry batch upload task in background
+ (void)retryBatchEventsUploadInBackground {
    if ([BlueShift sharedInstance].isTrackingEnabled) {
        [self performSelectorInBackground:@selector(uploadBatches) withObject:nil];
    }
}

+ (void)performRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation completionHandler:(void (^)(BOOL))handler {
    NSString *url = [BlueshiftRoutes getBulkEventsURL];
    
    NSMutableArray *parametersArray = (NSMutableArray*)requestOperation.paramsArray;
    if ((!parametersArray) || (parametersArray.count == 0)){
        handler(YES);
        return;
    }
    NSDictionary *paramsDictionary = @{@"events": parametersArray};
    [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:paramsDictionary completionHandler:^(BOOL status, NSDictionary* response, NSError *error) {
        handler(status);
    }];
}

@end
