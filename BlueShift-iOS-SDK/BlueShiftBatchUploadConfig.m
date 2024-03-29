//
//  BlueShiftBatchUploadConfig.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftBatchUploadConfig.h"

#define kDefaultBatchUploadTimer 300

static BlueShiftBatchUploadConfig *_sharedInstance = nil;

@implementation BlueShiftBatchUploadConfig

// Create shared instance of BlueShiftBatchUploadConfig
+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (_sharedInstance==nil) {
            _sharedInstance = [[BlueShiftBatchUploadConfig alloc] init];
        }
    });
    return _sharedInstance;
}

- (void)setBatchUploadTimer:(double)batchUploadTimer {
    _batchUploadTimer = batchUploadTimer;
}

- (double)fetchBatchUploadTimer {
    if(_batchUploadTimer > 0) {
        return _batchUploadTimer;
    } else {
        return kDefaultBatchUploadTimer;
    }
}

@end
