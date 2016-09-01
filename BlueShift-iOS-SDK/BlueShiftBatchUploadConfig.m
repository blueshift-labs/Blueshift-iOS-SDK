//
//  BlueShiftBatchUploadConfig.m
//  Pods
//
//  Created by Shahas on 27/08/16.
//
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

// Method to set intervell timer (in seconds)
- (void)setBatchUploadTimer:(double)batchUploadTimer {
    _batchUploadTimer = batchUploadTimer;
}

// Method to get intervell timer
- (double)fetchBatchUploadTimer {
    if(_batchUploadTimer == 0) {
        return kDefaultBatchUploadTimer;
    } else {
        return _batchUploadTimer;
    }
}

@end
