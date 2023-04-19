//
//  BlueShiftBatchRequestOperation.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <BlueShiftHTTPMethod.h>
#import <BatchEventEntity.h>

@class BatchEventEntity;

@interface BlueShiftBatchRequestOperation : NSObject

@property NSArray *paramsArray;
@property NSInteger retryAttemptsCount;
@property NSInteger nextRetryTimeStamp;

/// Initialize BlueShiftRequestOperation instance with url and other request based details.
/// @param parametersArray parameters for the request.
/// @param retryAttemptsCount number of retry attempts for the request.
/// @param nextRetryTimeStamp next retry time for the request.
- (id)initParametersList:(NSArray *)parametersArray andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp;


/// Initialize BlueShiftRequestOperation instance using Core Data entity.
/// @param batchEventEntity batch event entity to initialise the request operation.
- (id)initWithBatchRequestOperationEntity:(BatchEventEntity *)batchEventEntity;

@end
