//
//  BlueShiftRequestQueue.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestQueue.h"
#import "BlueshiftLog.h"
#import "BlueshiftConstants.h"

@interface BlueShiftRequestQueue ()

+ (void)retryRequestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted;

@end

/// Shows the status of the non batch request queue
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;

@implementation BlueShiftRequestQueue

#pragma mark Real time events processing
+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation {
    @synchronized (self) {
        if(requestOperation) {
            @try {
                
                NSString *url = requestOperation.url;
                BOOL isBatchEvent = requestOperation.isBatchEvent;
                
                if ([BlueShiftNetworkReachabilityManager networkConnected] == NO)  {
                    isBatchEvent = YES;
                }
                // Treat all the tracking events as non-batched events to stop them from getting batched
                NSString *trackURL = [BlueshiftRoutes getTrackURL];
                if ([requestOperation.url rangeOfString:trackURL].location != NSNotFound) {
                    isBatchEvent = NO;
                }
                //Insert event to in the core data HttpRequestOperationEntity
                NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
                if (context) {
                    [context performBlock:^{
                        @try {
                            NSEntityDescription *entity = [NSEntityDescription entityForName:kHttpRequestOperationEntity inManagedObjectContext:context];
                            if(entity) {
                                HttpRequestOperationEntity * httpRequestOperationEntity = [[HttpRequestOperationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                                if(httpRequestOperationEntity) {
                                    [httpRequestOperationEntity insertEntryWithMethod:requestOperation.httpMethod andParameters:requestOperation.parameters andURL:url andNextRetryTimeStamp:requestOperation.nextRetryTimeStamp andRetryAttemptsCount:requestOperation.retryAttemptsCount andIsBatchEvent:isBatchEvent];
                                    if(!isBatchEvent) {
                                        [BlueShiftRequestQueue processRequestsInQueue];
                                    }
                                }
                            }
                        } @catch (NSException *exception) {
                            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                        }
                    }];
                }
            } @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
        }
    }
}

+ (void)processRequestsInQueue {
    // Process when the requestQueue and internet is available
    if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected] == YES && BlueShift.sharedInstance.config.apiKey) {
        // requestQueue status is made busy
        _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
        // Gets the current NSManagedObjectContext via appDelegate
        // Fetch the first record from the Core Data
        [HttpRequestOperationEntity fetchOneRealTimeEventFromDBWithCompletionHandler:^(BOOL status, HttpRequestOperationEntity *entity) {
            if(status) {
                [self processRequestForQueuedEntity:entity];
            } else {
                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
            }
        }];
    }
}

+ (void)processRequestForQueuedEntity:(HttpRequestOperationEntity*)entity {
    if(entity) {
        // Create new request operation
        BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:entity];
        
        // Perform the request operation
        [BlueShiftRequestQueue performRequestOperation:requestOperation  completionHandler:^(BOOL status) {
            if (status == YES) {
                // Delete record for the request operation if it is successfully executed
                [HttpRequestOperationEntity deleteRecordForObjectId:entity.objectID completionHandler:^(BOOL status) {
                    [self setRequestQueueAvailableAndProcessRequestQueue];
                }];
            } else {
                // Handle the retry for the failed execution
                [BlueShiftRequestQueue retryRequestOperation:requestOperation forEntity:entity];
            }
        }];
    } else {
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

+ (void)performRequestOperation:(BlueShiftRequestOperation *)requestOperation completionHandler:(void (^)(BOOL))handler {
    NSString *url = requestOperation.url;
    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
    NSDictionary *parameters = requestOperation.parameters;
    
    // perform executions based on the request method type
    if (httpMethod == BlueShiftHTTPMethodGET) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] getRequestWithURL:url andParams:parameters completionHandler:^(BOOL status, NSDictionary *data, NSError* error) {
            handler(status);
        }];
    } else if (httpMethod == BlueShiftHTTPMethodPOST) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completionHandler:^(BOOL status, NSDictionary *response, NSError *error) {
            handler(status);
        }];
    }
}

+ (void)retryRequestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)entity {
    @try {
        // Set retry info
        requestOperation.retryAttemptsCount = requestOperation.retryAttemptsCount - 1;
        requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
        requestOperation.isBatchEvent = YES;
        
        [HttpRequestOperationEntity deleteRecordForObjectId:entity.objectID completionHandler:^(BOOL status) {
            if (status) {
                if (requestOperation.retryAttemptsCount > 0) {
                    [BlueShiftRequestQueue addRequestOperation:requestOperation];
                }
                [self setRequestQueueAvailableAndProcessRequestQueue];
            } else {
                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
            }
        }];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
    }
}

+ (void)setRequestQueueAvailableAndProcessRequestQueue {
    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
    [self processRequestsInQueue];
}

#pragma mark Batch events processing
+ (void)addBatchRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation {
    @try {
        NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
        if(context && BlueShift.sharedInstance.config.apiKey) {
            [context performBlock:^{
                NSEntityDescription *entity = [NSEntityDescription entityForName:kBatchEventEntity inManagedObjectContext:context];
                if(entity) {
                    BatchEventEntity *batchEventEntity = [[BatchEventEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                    if(batchEventEntity) {
                        [batchEventEntity insertEntryParametersList:requestOperation.paramsArray andNextRetryTimeStamp:requestOperation.nextRetryTimeStamp andRetryAttemptsCount:requestOperation.retryAttemptsCount];
                    }
                }
            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
