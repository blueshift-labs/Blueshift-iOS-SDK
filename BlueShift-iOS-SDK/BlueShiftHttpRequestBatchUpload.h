//
//  BlueShiftHttpRequestBatchUpload.h
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
#import "BlueShiftBatchUploadConfig.h"

@interface BlueShiftHttpRequestBatchUpload : NSObject

/// Start the interval based batch upload
+ (void)startBatchUpload;

/// Stop the batch upload timer
+ (void)stopBatchUpload;

/// Upload batches in background just for once.
+ (void)batchEventsUploadInBackground;

@end
