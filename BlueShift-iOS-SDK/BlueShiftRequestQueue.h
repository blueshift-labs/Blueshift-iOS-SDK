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

#define kRequestTryMaximumLimit                 3
#define kRequestRetryMinutesInterval            5

@interface BlueShiftRequestQueue : NSObject

/// Trigger request executions from the Queue
+ (void)processRequestsInQueue;

/// Add realttime events to db
+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation;

/// Add batch events to db
+ (void)addBatchRequestOperation:(BlueShiftBatchRequestOperation *)requestOperation;

@end
