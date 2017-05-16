//
//  BlueShiftBatchUploadConfig.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftBatchUploadConfig : NSObject

// Property hold periodic intervell in which batch uploader will envoke(in seconds)
@property(nonatomic) double batchUploadTimer;

// Create shared instance of BlueShiftBatchUploadConfig
+ (instancetype) sharedInstance;

// Method to set intervell timer (in seconds)
- (void)setBatchUploadTimer:(double)batchUploadTimer;

// Method to get intervell timer
- (double)fetchBatchUploadTimer;

@end
