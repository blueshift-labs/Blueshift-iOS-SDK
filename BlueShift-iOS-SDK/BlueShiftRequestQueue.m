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

+ (void)deleteRecords:(NSManagedObjectContext *)context forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted;
    
+ (void)retryProcessRequestWithContext:(NSManagedObjectContext *)context requestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted;

@end

/// Shows the status of the non batch request queue
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;


@implementation BlueShiftRequestQueue

#pragma mark Real time events processing
+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation {
    @synchronized(self) {
        if(requestOperation != nil) {
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
            if(appDelegate) {
                NSString *url = requestOperation.url;
                BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
                NSDictionary *parameters = requestOperation.parameters;
                NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
                NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                BOOL isBatchEvent = requestOperation.isBatchEvent;
                
                if ([BlueShiftNetworkReachabilityManager networkConnected] == NO)  {
                    isBatchEvent = YES;
                }
                // Treat all the tracking events as non-batched events to stop them from getting batched
                NSString *trackURL = [BlueshiftRoutes getTrackURL];
                if ([requestOperation.url rangeOfString:trackURL].location != NSNotFound) {
                    isBatchEvent = NO;
                }
                NSManagedObjectContext *context = appDelegate.realEventManagedObjectContext;
                if (context) {
                    @try {
                        NSEntityDescription *entity = [NSEntityDescription entityForName:kHttpRequestOperationEntity inManagedObjectContext:context];
                        if(entity != nil) {
                            [context performBlock:^{
                                @try {
                                    HttpRequestOperationEntity * httpRequestOperationEntity = [[HttpRequestOperationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                                    if(httpRequestOperationEntity != nil) {
                                        [httpRequestOperationEntity insertEntryWithMethod:httpMethod andParameters:parameters andURL:url andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount andIsBatchEvent:isBatchEvent];
                                        if(!isBatchEvent) {
                                            [BlueShiftRequestQueue processRequestsInQueue];
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
    }
}

+ (void)processRequestsInQueue {
    // Process when the requestQueue and internet is available
    if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES && BlueShift.sharedInstance.config.apiKey) {
        // requestQueue status is made busy
        _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
        // Gets the current NSManagedObjectContext via appDelegate
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate) {
            // Fetch the first record from the Core Data
            [HttpRequestOperationEntity fetchFirstRecordFromCoreDataWithCompletetionHandler:^(BOOL status, HttpRequestOperationEntity *operationEntityToBeExecuted) {
                if(status) {
                    [self processRequestsWithContext:appDelegate.realEventManagedObjectContext forEntity:operationEntityToBeExecuted];
                } else {
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                }
            }];
        } else {
            [self setRequestQueueAvailableAndProcessRequestQueue];
        }
    }
}

+ (void)processRequestsWithContext:(NSManagedObjectContext *)context forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    if(context && operationEntityToBeExecuted) {
        // Create new request operation
        BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
        
        // Perform the request operation
        [BlueShiftRequestQueue performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
            if (status == YES) {
                // Delete record for the request operation if it is successfully executed
                [BlueShiftRequestQueue deleteRecords:context forEntity:operationEntityToBeExecuted];
            } else {
                // Handle the retry for the failed execution
                [BlueShiftRequestQueue retryProcessRequestWithContext:context requestOperation:requestOperation forEntity:operationEntityToBeExecuted];
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

+ (void)deleteRecords:(NSManagedObjectContext *)context forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    NSError *saveError = nil;
                    if(context && [context respondsToSelector:@selector(deleteObject:)]) {
                        [context deleteObject:operationEntityToBeExecuted];
                        [context save:&saveError];
                    }
                    [self setRequestQueueAvailableAndProcessRequestQueue];
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    [self setRequestQueueAvailableAndProcessRequestQueue];
                }
            }];
        } else {
            [self setRequestQueueAvailableAndProcessRequestQueue];
        }
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

+ (void)retryProcessRequestWithContext:(NSManagedObjectContext *)context requestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    @try {
        // Set retry info
        NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
        requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
        requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
        requestOperation.isBatchEvent = YES;

        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    NSError *saveError = nil;
                    if(context) {
                        // Delete the record from core data
                        [context deleteObject:operationEntityToBeExecuted];
                        [context save:&saveError];
                    }
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    // Add the same record with the updated retry details
                    if (requestOperation.retryAttemptsCount > 0) {
                        [BlueShiftRequestQueue addRequestOperation:requestOperation];
                    }
                    [self processRequestsInQueue];
                } @catch (NSException *exception) {
                    [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    [self setRequestQueueAvailableAndProcessRequestQueue];
                }
            }];
        }
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
    @synchronized(self) {
        @try {
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
            NSManagedObjectContext *context;
            if(appDelegate) {
                context = appDelegate.batchEventManagedObjectContext;
            }
            if(context) {
                NSEntityDescription *entity;
                entity = [NSEntityDescription entityForName:kBatchEventEntity inManagedObjectContext:context];
                if(entity != nil) {
                    NSArray *paramsArray = requestOperation.paramsArray;
                    NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
                    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                    
                    BatchEventEntity *batchEventEntity = [[BatchEventEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:appDelegate.batchEventManagedObjectContext];
                    if(batchEventEntity != nil) {
                        [batchEventEntity insertEntryParametersList:paramsArray andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount];
                    }
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

@end
