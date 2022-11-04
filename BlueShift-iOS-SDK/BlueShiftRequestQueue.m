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

// this static variable is meant to show the status of the request queue ...
static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;


@implementation BlueShiftRequestQueue

// Method to trigger request executions from the Queue ...
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

+ (void)addBatchRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation {
    @synchronized(self) {
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        NSManagedObjectContext *context;
        if(appDelegate) {
            @try {
                context = appDelegate.batchEventManagedObjectContext;
            }
            @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
        }
        if(context) {
            NSEntityDescription *entity;
            @try {
                entity = [NSEntityDescription entityForName:kBatchEventEntity inManagedObjectContext:context];
            }
            @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
            }
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
    }
}

// Method to add Request Operation to the Queue ...
+ (void)performRequestOperation:(BlueShiftRequestOperation *)requestOperation completetionHandler:(void (^)(BOOL))handler {
    // get the request operation details ...
    NSString *url = requestOperation.url;
    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
    NSDictionary *parameters = requestOperation.parameters;
    
    // perform executions based on the request operation http method ...
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

+ (void)processRequestsWithContext:(NSManagedObjectContext *)context forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    if(context && operationEntityToBeExecuted) {
        // Only handles when the fetched record is not nil ...
        if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[NSDate date] timeIntervalSince1970]) {
            
            // a new request operation is created with details taken from core data ...
            BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
            
            // Performs the request operation ...
            [BlueShiftRequestQueue performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
                if (status == YES) {
                    // delete record for the request operation if it is successfully executed ...
                    [BlueShiftRequestQueue deleteRecords:context forEntity:operationEntityToBeExecuted];
                } else {
                    // Request is not executed due to some reasons ...
                    [BlueShiftRequestQueue retryProcessRequestWithContext:context requestOperation:requestOperation forEntity:operationEntityToBeExecuted];
                }
            }];
        } else {
            @try {
                if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                    [context performBlock:^{
                        @try {
                            [context deleteObject:operationEntityToBeExecuted];
                            NSError *saveError = nil;
                            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
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
            }
            @catch (NSException *exception) {
                [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                [self setRequestQueueAvailableAndProcessRequestQueue];
            }
        }
    } else {
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

+ (void)deleteRecords:(NSManagedObjectContext *)context forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    // delete record for the request operation if it is successfully executed ...
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
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

+ (void)retryProcessRequestWithContext:(NSManagedObjectContext *)context requestOperation:(BlueShiftRequestOperation*)requestOperation forEntity:(HttpRequestOperationEntity*)operationEntityToBeExecuted {
    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
    requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
    requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
    requestOperation.isBatchEvent = YES;
    
    @try {
        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
            [context performBlock:^{
                @try {
                    NSError *saveError = nil;
                    if(context) {
                        [context deleteObject:operationEntityToBeExecuted];
                        [context save:&saveError];
                    }
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    // request record is removed successfully from core data.
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
    }
    @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        [self setRequestQueueAvailableAndProcessRequestQueue];
    }
}

// Method to trigger request executions from the Queue ...
+ (void)processRequestsInQueue {
    // Will execute the code when the requestQueue is free / available and internet is connected ...
    if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES && BlueShift.sharedInstance.config.apiKey) {
        // requestQueue status is made busy ...
        _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
        // Gets the current NSManagedObjectContext via appDelegate ...
        BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
        if(appDelegate) {
            // Fetches the first record from the Core Data ...
            [HttpRequestOperationEntity fetchFirstRecordFromCoreDataWithCompletetionHandler:^(BOOL status, HttpRequestOperationEntity *operationEntityToBeExecuted) {
                if(status) {
                    NSManagedObjectContext *context;
                    @try {
                        context = appDelegate.realEventManagedObjectContext;
                    }
                    @catch (NSException *exception) {
                        [BlueshiftLog logException:exception withDescription:nil methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                    }
                    [self processRequestsWithContext:context forEntity:operationEntityToBeExecuted];
                } else {
                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                }
            }];
        } else {
            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
        }
    }
}

+ (void)setRequestQueueAvailableAndProcessRequestQueue {
    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
    [self processRequestsInQueue];
}

@end
