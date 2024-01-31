//
//  BlueShiftBatchRequestOperation.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftBatchRequestOperation.h"
#import "BlueshiftLog.h"

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
            NSError *error;
            if (@available(iOS 11.0, *)) {
                self.paramsArray = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSNumber class], [NSArray class], [NSString class], [NSNull class], nil] fromData:batchEventEntity.paramsArray error:&error];
                if (error) {
                    [BlueshiftLog logError:error withDescription:@"Failed to unarchive object" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            } else {
                self.paramsArray = [NSKeyedUnarchiver unarchiveObjectWithData:batchEventEntity.paramsArray];
            }
        }
        self.nextRetryTimeStamp = [batchEventEntity.nextRetryTimeStamp integerValue];
        self.retryAttemptsCount = [batchEventEntity.retryAttemptsCount integerValue];
    }
    
    return self;
}

@end
