//
//  BlueShiftRequestOperation.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftHTTPMethod.h"
#import "HttpRequestOperationEntity.h"

@class HttpRequestOperationEntity;

@interface BlueShiftRequestOperation : NSObject

/// Request operation URL
@property NSString *url;

/// Request operation http Method
@property BlueShiftHTTPMethod httpMethod;

/// Request operation parameters
@property NSDictionary *parameters;

/// Retry count
@property NSInteger retryAttemptsCount;

/// Next retry timestamp
@property NSInteger nextRetryTimeStamp;

/// Batch event or real time event
@property BOOL isBatchEvent;

/// Initialize BlueShiftRequestOperation instance with url and other request based details
- (id)initWithRequestURL:(NSString *)url andHttpMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andIsBatchEvent:(BOOL)isBatchEvent;

/// Initialize BlueShiftRequestOperation instance with Core Data entity
- (id)initWithHttpRequestOperationEntity:(HttpRequestOperationEntity *)httpRequestionOperationEntity;


@end
