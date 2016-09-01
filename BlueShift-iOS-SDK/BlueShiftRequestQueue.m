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
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HttpRequestOperationEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    NSString *url = requestOperation.url;
    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
    NSDictionary *parameters = requestOperation.parameters;
    NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
    BOOL isBatchEvent = requestOperation.isBatchEvent;
    
    if (_requestQueueStatus == BlueShiftRequestQueueStatusBusy || [BlueShiftNetworkReachabilityManager networkConnected] == NO)  {
        isBatchEvent = YES;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        HttpRequestOperationEntity *httpRequestOperationEntity = [[HttpRequestOperationEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:appDelegate.managedObjectContext];
        
        [httpRequestOperationEntity insertEntryWithMethod:httpMethod andParameters:parameters andURL:url andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount andIsBatchEvent:isBatchEvent];
        
        if(!isBatchEvent) {
            [BlueShiftRequestQueue processRequestsInQueue];
        }
    });
}

+ (void)addBatchRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation {
    BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BatchEventEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    NSArray *paramsArray = requestOperation.paramsArray;
    NSInteger nextRetryTimeStamp = requestOperation.nextRetryTimeStamp;
    NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
    
    BatchEventEntity *batchEventEntity = [[BatchEventEntity alloc] initWithEntity:entity insertIntoManagedObjectContext:appDelegate.managedObjectContext];
    [batchEventEntity insertEntryParametersList:paramsArray andNextRetryTimeStamp:nextRetryTimeStamp andRetryAttemptsCount:retryAttemptsCount];
}

// Method to add Request Operation to the Queue ...

+ (void)performRequestOperation:(BlueShiftRequestOperation *)requestOperation completetionHandler:(void (^)(BOOL))handler {
    
    
    // get the request operation details ...
    NSString *url = requestOperation.url;
    BlueShiftHTTPMethod httpMethod = requestOperation.httpMethod;
    NSDictionary *parameters = requestOperation.parameters;
    
    
    // perform executions based on the request operation http method ...
    
    if (httpMethod == BlueShiftHTTPMethodGET) {
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] addBasicAuthenticationRequestHeaderForUsername:[BlueShiftConfig config].apiKey andPassword:nil];
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] GET:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
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
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
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

// Method to trigger request executions from the Queue ...

+ (void)processRequestsInQueue {
    
    @synchronized(self) {
        // Will execute the code when the requestQueue is free / available and internet is connected ...
        
        
        if (_requestQueueStatus == BlueShiftRequestQueueStatusAvailable && [BlueShiftNetworkReachabilityManager networkConnected]==YES) {
            
            
            // Gets the current NSManagedObjectContext via appDelegate ...
            
            BlueShiftAppDelegate *appDelegate = (BlueShiftAppDelegate *)[UIApplication sharedApplication].delegate;
            NSManagedObjectContext *context = appDelegate.managedObjectContext;
            
            
            // Fetches the first record from the Core Data ...
            
            HttpRequestOperationEntity *operationEntityToBeExecuted = [HttpRequestOperationEntity fetchFirstRecordFromCoreData];
            
            
            // Only handles when the fetched record is not nil ...
            
            if (operationEntityToBeExecuted!=nil) {
                
                if ([operationEntityToBeExecuted.nextRetryTimeStamp floatValue] < [[NSDate date] timeIntervalSince1970]) {
                    
                    // a new request operation is created with details taken from core data ...
                    
                    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                    
                    
                    // requestQueue status is made busy ...
                    
                    _requestQueueStatus = BlueShiftRequestQueueStatusBusy;
                    
                    
                    // Performs the request operation ...
                    
                    [BlueShiftRequestQueue performRequestOperation:requestOperation  completetionHandler:^(BOOL status) {
                        if (status == YES) {
                            
                            
                            // delete record for the request operation if it is successfully executed ...
                            
                            [context deleteObject:operationEntityToBeExecuted];
                            NSError *saveError = nil;
                            BOOL deletedStatus = [context save:&saveError];
                            
                            if (deletedStatus == YES) {
                                // request record is removed successfully from core data ...
                                
                                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                //[BlueShiftRequestQueue processRequestsInQueue];
                            } else {
                                
                                
                                // To be handled if request executed is not deleted from core data...
                                
                            }
                            
                        } else {
                            
                            // Request is not executed due to some reasons ...
                            
                            NSInteger retryAttemptsCount = requestOperation.retryAttemptsCount;
                            requestOperation.retryAttemptsCount = retryAttemptsCount - 1;
                            requestOperation.nextRetryTimeStamp = [[[NSDate date] dateByAddingMinutes:kRequestRetryMinutesInterval] timeIntervalSince1970];
                            requestOperation.isBatchEvent = YES;
                            
                            [context deleteObject:operationEntityToBeExecuted];
                            NSError *saveError = nil;
                            BOOL deletedStatus = [context save:&saveError];
                            
                            if (deletedStatus == YES) {
                                
                                _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                                
                                // request record is removed successfully from core data ...
                                if (requestOperation.retryAttemptsCount > 0) {
                                    [BlueShiftRequestQueue addRequestOperation:requestOperation];
                                }
                                //[BlueShiftRequestQueue processRequestsInQueue];
                                
                            } else {
                                
                                // To be handled if request executed is not deleted from core data...
                                
                            }
                            
                        }
                        
                    }];
                }
                else {
                    
                    BlueShiftRequestOperation *requestOperation = [[BlueShiftRequestOperation alloc] initWithHttpRequestOperationEntity:operationEntityToBeExecuted];
                    
                    [context deleteObject:operationEntityToBeExecuted];
                    NSError *saveError = nil;
                    BOOL deletedStatus = [context save:&saveError];
                    
                    if (deletedStatus == YES) {
                        _requestQueueStatus = BlueShiftRequestQueueStatusAvailable;
                        
                        // request record is removed successfully from core data ...
                        [BlueShiftRequestQueue addRequestOperation:requestOperation]; //- done to prevent crash ...
                        
                        //[BlueShiftRequestQueue processRequestsInQueue];
                        
                    } else {
                        
                        
                        // To be handled if request executed is not deleted from core data...
                        
                    }
                    
                }
                
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
