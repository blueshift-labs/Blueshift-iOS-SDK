//
//  BlueShiftRequestQueue.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftAppDelegate.h"
#import <CoreData/CoreData.h>
#import "HttpRequestOperationEntity.h"
#import "BlueShiftHTTPMethod.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftStatusCodes.h"
#import "BlueShiftRequestOperation.h"
#import "BlueShiftRequestQueueStatus.h"
#import "BlueShiftNetworkReachabilityManager.h"
#import "NSDate+BlueShiftDateHelpers.h"
#import "BlueShiftBatchRequestOperation.h"


@class BlueShiftRequestOperation;
@class BlueShiftBatchRequestOperation;

// Defines the maximum number of requests that can be retried ...
#define kRequestTryMaximumLimit                 3

// Defines the time interval for requests to be retried ...
#define kRequestRetryMinutesInterval            5

@interface BlueShiftRequestQueue : NSObject



// Method to trigger request executions from the Queue ...

+ (void)processRequestsInQueue;



// Method to add Request Operation to the Queue ...

+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation;

// Method to add Batch Request Operation to Queue ....

+ (void)addBatchRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation;

// Method to set the request queue status explicity ...

+ (void)setRequestQueueStatus:(BlueShiftRequestQueueStatus)requestQueueStatus;

@end
