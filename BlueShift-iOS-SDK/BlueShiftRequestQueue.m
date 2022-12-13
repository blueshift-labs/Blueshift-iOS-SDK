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

+ (void)retryProcessRequestWithContext:(NSManagedObjectContext *)context requestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted;

@end

/// Shows the status of the non batch request queue
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;


@implementation BlueShiftRequestQueue

#pragma mark Real time events processing
+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation {
    if(requestOperation) {
        @try {
            
            NSString *url = requestOperation.url;
            BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
            NSDictionary *parameters = requestOperation.parameters;
            NSInteger retryTimestamp = requestOperation.nextRetryTimeStamp;
            NSInteger retryCount = requestOperation.retryAttemptsCount;
            BOOL isBatchEvent = requestOperation.isBatchEvent;
            
            if ([BlueShiftNetworkReachabilityManager networkConnected] == NO)  {
                isBatchEvent = YES;
            }
            // Treat all the tracking events as non-batched events to stop them from getting batched
            NSString *trackURL = [BlueshiftRoutes getTrackURL];
            if ([requestOperation.url rangeOfString:trackURL].location != NSNotFound) {
                isBatchEvent = NO;
            }
            [BlueShiftRequestQueue insertEventInDBWithHTTPMethod:httpMethod parameters:parameters URL:url retryTimeStamp:retryTimestamp retryCount:retryCount isBatch:isBatchEvent];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

+ (void)insertEventInDBWithHTTPMethod:(BlueShiftHTTPMethod)httpMethod parameters:(NSDictionary*)parameters URL:(NSString*)url retryTimeStamp:(NSInteger)retryTimestamp retryCount:(NSInteger)retryCount isBatch:(BOOL)isBatch {
    @try {
        NSManagedObjectContext *context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
        if (context) {
            [context performBlock:^{
                @try {
                    NSEntityDescription *entity = [NSEntityDescription entityForName:kHttpRequestOperationEntity inManagedObjectContext:context];
                    if(entity) {
                        HttpRequestOperationEntity * httpRequestOperationEntity = [[HttpRequestOperationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                        if(httpRequestOperationEntity) {
                            [httpRequestOperationEntity insertEntryWithMethod:httpMethod andParameters:parameters andURL:url andNextRetryTimeStamp:retryTimestamp andRetryAttemptsCount:retryCount andIsBatchEvent:isBatch];
                            if(!isBatch) {
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
    NSManagedObjectContext* context = BlueShift.sharedInstance.appDelegate.eventsMOContext;
    if(context && entity) {
        // Create new request operation
        BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:entity];
        
        // Perform the request operation
        [BlueShiftRequestQueue performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
            if (status == YES) {
                // Delete record for the request operation if it is successfully executed
                [HttpRequestOperationEntity deleteRecordForObjectId:entity.objectID completetionHandler:^(BOOL status) {
                    [self setRequestQueueAvailableAndProcessRequestQueue];
                }];
            } else {
                // Handle the retry for the failed execution
                [BlueShiftRequestQueue retryProcessRequestWithContext:context requestOperation:requestOperation forEntity:entity];
            }
        }];
    } else {
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

+ (void)performRequestOperation:(BlueShiftRequestOperation *)requestOperation completetionHandler:(void (^)(BOOL))handler {
    NSString *url = requestOperation.url;
    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
    NSDictionary *parameters = requestOperation.parameters;
    
    // perform executions based on the request method type
    if (httpMethod == BlueShiftHTTPMethodGET) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] getRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *data, NSError* error) {
            handler(status);
        }];
    } else if (httpMethod == BlueShiftHTTPMethodPOST) {
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status, NSDictionary *response, NSError *error) {
            handler(status);
        }];
    }
}

+ (void)retryProcessRequestWithContext:(NSManagedObjectContext *)context requestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)entity {
    @try {
        // Set retry info
        requestOperation.retryAttemptsCount = requestOperation.retryAttemptsCount - 1;
        requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
        requestOperation.isBatchEvent = YES;
        
        [HttpRequestOperationEntity deleteRecordForObjectId:entity.objectID completetionHandler:^(BOOL status) {
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
        [self setRequestQueueAvailableAndProcessRequestQueue];
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
                if(entity != nil) {
                    NSArray *paramsArray = requestOperation.paramsArray;
                    NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
                    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                    
                    BatchEventEntity *batchEventEntity = [[BatchEventEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                    if(batchEventEntity) {
                        [batchEventEntity insertEntryParametersList:paramsArray andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount];
                    }
                }
            }];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
    }
}

@end
