//
//  BlueShiftRequestQueue.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestQueue.h"


// this static variable is meant to show the status of the request queue ...

static BlueShiftRequestQueueStatus _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;


// this static variable holds the value for the maximum number of retry that can be made when the request execution from requests fails ...



@implementation BlueShiftRequestQueue



// Method to trigger request executions from the Queue ...

+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation {
    @synchronized(self) {
        if(requestOperation != nil) {
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[BlueShift sharedInstance].appDelegate;
            NSManagedObjectContext *masterContext;
            if (appDelegate) {
                @try {
                    masterContext = appDelegate.managedObjectContext;
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
            }
            if(masterContext) {
                NSEntityDescription *entity;
                @try {
                    entity = [NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:masterContext];
                }
                @catch (NSException *exception) {
                    NSLog(@"Caught exception %@", exception);
                }
                if(entity != nil) {
                    NSString *url = requestOperation.url;
                    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
                    NSDictionary *parameters = requestOperation.parameters;
                    NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
                    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                    BOOL isBatchEvent = requestOperation.isBatchEvent;
                    
                    if ([BlueShiftNetworkReachabilityManager networkConnected] == NO)  {
                        isBatchEvent = YES;
                    }
                    NSManagedObjectContext *context;
                    if (isBatchEvent) {
                        context = appDelegate.batchEventManagedObjectContext;
                    } else {
                        context = appDelegate.realEventManagedObjectContext;
                    }
                    HttpRequestOperationEntity *httpRequestOperationEntity = [[HttpRequestOperationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
                    if(httpRequestOperationEntity != nil) {
                        [httpRequestOperationEntity insertEntryWithMethod:httpMethod andParameters:parameters andURL:url andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount andIsBatchEvent:isBatchEvent];
                        
                        if(!isBatchEvent) {
                            [BlueShiftRequestQueue processRequestsInQueue];
                        }
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
                NSLog(@"Caught exception %@", exception);
            }
        }
        if(context) {
            NSEntityDescription *entity;
            @try {
                entity = [NSEntityDescription entityForName:@"BatchEventEntity" inManagedObjectContext:context];
            }
            @catch (NSException *exception) {
                NSLog(@"Caught exception %@", exception);
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
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL:url andParams:parameters completetionHandler:^(BOOL status) {
            handler(status);
        }];
    }
}

// Method to trigger request executions from the Queue ...

+ (void)processRequestsInQueue {
    @synchronized(self) {
        // Will execute the code when the requestQueue is free / available and internet is connected ...
        if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES) {
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
                            NSLog(@"Caught exception %@", exception);
                        }
                        if(context) {
                            // Only handles when the fetched record is not nil ...
                            if (operationEntityToBeExecuted!=nil) {
                                if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[NSDate date] timeIntervalSince1970]) {
                                    
                                    // a new request operation is created with details taken from core data ...
                                    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                                    
                                    // Performs the request operation ...
                                    [BlueShiftRequestQueue performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
                                        if (status == YES) {
                                            // delete record for the request operation if it is successfully executed ...
                                            @try {
                                                if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                                    [context performBlock:^{
                                                        [context deleteObject:operationEntityToBeExecuted];
                                                        [context performBlock:^{
                                                            NSError *saveError = nil;
                                                            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                                                [context save:&saveError];
                                                            }
                                                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                                            [self processRequestsInQueue];
                                                        }];
                                                    }];
                                                } else {
                                                    [self processRequestsInQueue];
                                                }
                                            }
                                            @catch (NSException *exception) {
                                                NSLog(@"Caught exception %@", exception);
                                                [self processRequestsInQueue];
                                            }
                                        } else {
                                            // Request is not executed due to some reasons ...
                                            NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                                            requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
                                            requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
                                            requestOperation.isBatchEvent = YES;
                                            
                                            @try {
                                                if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                                    [context performBlock:^{
                                                        [context deleteObject:operationEntityToBeExecuted];
                                                        [context performBlock:^{
                                                            NSError *saveError = nil;
                                                            if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                                                [context save:&saveError];
                                                            }
                                                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                                            
                                                            // request record is removed successfully from core data ...
                                                            if (requestOperation.retryAttemptsCount > 0) {
                                                                [BlueShiftRequestQueue addRequestOperation:requestOperation];
                                                            }
                                                            [self processRequestsInQueue];
                                                        }];
                                                    }];
                                                }
                                            }
                                            @catch (NSException *exception) {
                                                NSLog(@"Caught exception %@", exception);
                                                [self processRequestsInQueue];
                                            }
                                        }
                                    }];
                                }
                                else {
                                    @try {
                                        if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                            [context performBlock:^{
                                                [context deleteObject:operationEntityToBeExecuted];
                                                [context performBlock:^{
                                                    NSError *saveError = nil;
                                                    if(context && [context isKindOfClass:[NSManagedObjectContext class]]) {
                                                        [context save:&saveError];
                                                    }
                                                    _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                                    [self processRequestsInQueue];
                                                }];
                                            }];
                                        } else {
                                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                            [self processRequestsInQueue];
                                        }
                                    }
                                    @catch (NSException *exception) {
                                        NSLog(@"Caught exception %@", exception);
                                        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                        [self processRequestsInQueue];
                                    }
                                }
                            }
                        } else {
                            _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                            [self processRequestsInQueue];
                        }
                    } else {
                        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                    }
                }];
            } else {
                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                [self processRequestsInQueue];
            }
        }
    }
}


// Method to set the request queue status explicity ...
// Meant to be used by other classes ...

+ (void)setRequestQueueStatus:(BlueShiftRequestQueueStatus)requestQueueStatus {
    _requestQueueStatus = requestQueueStatus;
}


@end
