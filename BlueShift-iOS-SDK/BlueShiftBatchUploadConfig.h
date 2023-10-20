//
//  BlueShiftBatchUploadConfig.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftBatchUploadConfig : NSObject

@property(nonatomic) double batchUploadTimer;

+ (instancetype) sharedInstance;

/// Set Batch upload timer in seconds. The batches will be sent to Blueshift periodically after given time interval.
- (void)setBatchUploadTimer:(double)batchUploadTimer;

/// Get Batch upload timer in seconds
- (double)fetchBatchUploadTimer;

@end
