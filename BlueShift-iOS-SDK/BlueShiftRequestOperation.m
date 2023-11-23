//
//  BlueShiftRequestOperation.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperation.h"
#import "BlueshiftLog.h"

@implementation BlueShiftRequestOperation

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

- (id)initWithHttpRequestOperationEntity:(HttpRequestOperationEntity *)httpRequestionOperationEntity {
    self = [super init];
    if (httpRequestionOperationEntity) {
        self.url = httpRequestionOperationEntity.url;
        self.httpMethod = [httpRequestionOperationEntity httpMethod];
        if (httpRequestionOperationEntity.parameters) {
            NSError *error;
            if (@available(iOS 11.0, *)) {
                self.parameters = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:[NSDictionary class], [NSNumber class], [NSArray class], [NSString class], [NSNull class], nil] fromData:httpRequestionOperationEntity.parameters error:&error];
                if (error) {
                    [BlueshiftLog logError:error withDescription:@"Failed to unarchive object" methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
                }
            } else {
                self.parameters = [NSKeyedUnarchiver unarchiveObjectWithData:httpRequestionOperationEntity.parameters];
            }
        }
        self.nextRetryTimeStamp = [httpRequestionOperationEntity.nextRetryTimeStamp integerValue];
        self.retryAttemptsCount = [httpRequestionOperationEntity.retryAttemptsCount integerValue];
        self.isBatchEvent = httpRequestionOperationEntity.isBatchEvent;
    }
    
    return self;
}
@end
