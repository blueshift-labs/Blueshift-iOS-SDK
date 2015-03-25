//
//  BlueShiftRequestOperation.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "AFHTTPRequestOperation.h"
#import "BlueShiftHTTPMethod.h"
#import "HttpRequestOperationEntity.h"

@class HttpRequestOperationEntity;

@interface BlueShiftRequestOperation : AFHTTPRequestOperation



// property to hold the request operation URL ...

@property NSString *url;


// property to hold the request operation http Method ...

@property BlueShiftHTTPMethod httpMethod;



// property to hold the request operation parameters ...

@property NSDictionary *parameters;

// property to hold the retry count ...
@property NSInteger retryAttemptsCount;

// property to hold the timestamp for which next request to be send ...
@property NSInteger nextRetryTimeStamp;

// initialize BlueShiftRequestOperation instance with url and other request based details...

- (id)initWithRequestURL:(NSString *)url andHttpMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp;



// initialize BlueShiftRequestOperation instance with Core Data entity ...

- (id)initWithHttpRequestOperationEntity:(HttpRequestOperationEntity *)httpRequestionOperationEntity;


@end
