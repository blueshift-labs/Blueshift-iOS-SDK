//
//  BlueShiftHttpRequestBatchUpload.m
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 25/08/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
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
    NSArray *operationEntitiesToBeExecuted = [HttpRequestOperationEntity fetchBatchWiseRecordFromCoreData];
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    while (operationEntitiesToBeExecuted.count >0) {
        NSMutableArray *paramsArray = [[NSMutableArray alloc]init];
        for(HttpRequestOperationEntity *operationEntityToBeExecuted in operationEntitiesToBeExecuted) {
            if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970]) {
                BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                [paramsArray addObject:requestOperation.parameters];
                [context deleteObject:operationEntityToBeExecuted];
                NSError *saveError = nil;
                BOOL deletedStatus = [context save:&saveError];
            }
        }
        [self createBatch:paramsArray];
        operationEntitiesToBeExecuted = [HttpRequestOperationEntity fetchBatchWiseRecordFromCoreData];
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
    [self uploadBatchAtIndex:0 fromBatches:batches];
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
            
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            
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
                        BOOL deletedStatus = [context save:&saveError];
                        
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
                        BOOL deletedStatus = [context save:&saveError];
                        
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
    BlueShiftHTTPMethod httpMethod = BlueShiftHTTPMethodPOST;
    
    NSMutableArray *parametersArray = requestOperation.paramsArray;
    
    NSDictionary *paramsDictionary = @{@"events": parametersArray};
    // perform executions based on the request operation http method ...
    
    if (httpMethod == BlueShiftHTTPMethodGET) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] addBasicAuthenticationRequestHeaderForUsername:[BlueShiftConfig config].apiKey andPassword:nil];
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] GET:url parameters:paramsDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            BOOL status = NO;
            
            // If server responds with status code ...
            if (operation.response.statusCode == kStatusCodeSuccessfullResponse) {
                status = YES;
            }
            
            // Performs the corresponding handler function ...
            handler(status);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            // Performs the corresponding handler function ...
            
            handler(NO);
        }];
    } else if (httpMethod == BlueShiftHTTPMethodPOST) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] addBasicAuthenticationRequestHeaderForUsername:[BlueShift sharedInstance].config.apiKey andPassword:nil];
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] POST:url parameters:paramsDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            BOOL status = NO;
            // If server responds with status code ...
            if (operation.response.statusCode == kStatusCodeSuccessfullResponse) {
                status = YES;
            }
            // Performs the corresponding handler function ...
            handler(status);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Performs the corresponding handler function ...
            handler(NO);
        }];
    }
}


@end
