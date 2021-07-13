//
//  BlueShiftBatchRequestOperation.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftBatchRequestOperation.h"

@implementation BlueShiftBatchRequestOperation
- (id)initParametersList:(NSArray *)parametersArray andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp {
    self = [super init];
    if (self) {
        self.paramsArray = parametersArray;
        self.retryAttemptsCount = retryAttemptsCount;
        self.nextRetryTimeStamp = nextRetryTimeStamp;
    }
    
    return self;
}

- (id)initWithBatchRequestOperationEntity:(BatchEventEntity *)batchEventEntity {
    self = [super init];
    if (batchEventEntity) {
        if (batchEventEntity.paramsArray) {
            self.paramsArray = [NSKeyedUnarchiver unarchiveObjectWithData:batchEventEntity.paramsArray];
        }
        self.nextRetryTimeStamp = [batchEventEntity.nextRetryTimeStamp integerValue];
        self.retryAttemptsCount = [batchEventEntity.retryAttemptsCount integerValue];
    }
    
    return self;
}

@end
