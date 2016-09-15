//
//  BlueShiftRequestOperation.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperation.h"

@implementation BlueShiftRequestOperation


// initialize BlueShiftRequestOperation instance with url and other request based details...

- (id)initWithRequestURL:(NSString *)url andHttpMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andRetryAttemptsCount:(NSInteger)retryAttemptsCount andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andIsBatchEvent:(BOOL)isBatchEvent {
    self = [super init];
    if (self) {
        self.url = url;
        self.httpMethod = httpMethod;
        self.parameters = parameters;
        self.retryAttemptsCount = retryAttemptsCount;
        self.nextRetryTimeStamp = nextRetryTimeStamp;
        self.isBatchEvent = isBatchEvent;
    }
    
    return self;
}




// initialize BlueShiftRequestOperation instance with Core Data entity ...

- (id)initWithHttpRequestOperationEntity:(HttpRequestOperationEntity *)httpRequestionOperationEntity {
    self = [super init];
    if (httpRequestionOperationEntity) {
        self.url = httpRequestionOperationEntity.url;
        self.httpMethod = [httpRequestionOperationEntity httpMethod];
        if (httpRequestionOperationEntity.parameters) {
            self.parameters = [NSKeyedUnarchiver unarchiveObjectWithData:httpRequestionOperationEntity.parameters];
        }
        self.nextRetryTimeStamp = [httpRequestionOperationEntity.nextRetryTimeStamp integerValue];
        self.retryAttemptsCount = [httpRequestionOperationEntity.retryAttemptsCount integerValue];
        self.isBatchEvent = httpRequestionOperationEntity.isBatchEvent;
    }
    
    return self;
}
@end
