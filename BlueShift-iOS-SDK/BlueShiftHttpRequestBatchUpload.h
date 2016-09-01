//
//  BlueShiftHttpRequestBatchUpload.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 25/08/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
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

// Method to start batch uploading
+ (void)startBatchUpload;

@end
