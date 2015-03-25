//
//  BlueShiftRequestQueue.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 04/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
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


@class BlueShiftRequestOperation;

// Defines the maximum number of requests that can be retried ...
#define kRequestTryMaximumLimit                 3

// Defines the time interval for requests to be retried ...
#define kRequestRetryMinutesInterval            5

@interface BlueShiftRequestQueue : NSObject



// Method to trigger request executions from the Queue ...

+ (void)processRequestsInQueue;



// Method to add Request Operation to the Queue ...

+ (void)addRequestOperation:(BlueShiftRequestOperation *)requestOperation;



// Method to set the request queue status explicity ...

+ (void)setRequestQueueStatus:(BlueShiftRequestQueueStatus)requestQueueStatus;

@end
