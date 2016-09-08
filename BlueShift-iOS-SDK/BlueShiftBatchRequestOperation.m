//
//  BlueShiftBatchRequestOperation.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftBatchRequestOperation.h"

@implementation BlueShiftBatchRequestOperation

// initialize BlueShiftRequestOperation instance with url and other request based details...

- (id)initParametersList:(NSArray *)parametersArray andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp {
    self = [super init];
    if (self) {
        self.paramsArray = parametersArray;
        self.retryAttemptsCount = retryAttemptsCount;
        self.nextRetryTimeStamp = nextRetryTimeStamp;
    }
    
    return self;
}




// initialize BlueShiftRequestOperation instance with Core Data entity ...

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
