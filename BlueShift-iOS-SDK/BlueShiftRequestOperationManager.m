//
//  BlueShiftRequestOperationManager.m
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"

static BlueShiftRequestOperationManager *_sharedRequestOperationManager = nil;

@implementation BlueShiftRequestOperationManager



// Method to get the shared instance for BlueShiftOperationManager ...

+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedRequestOperationManager = [BlueShiftRequestOperationManager manager];
    });
    return _sharedRequestOperationManager;
}



// Method to add Basic authentication request Header ...

- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password {
    
    if (password==nil || password == NULL) {
        password = @"";
    }
    
    
    // Generates the Base 64 encryption for the request ...
    // Adds it to the request Header ...
    
    NSString *credentials = [NSString stringWithFormat:@"%@:%@",username,password];
    
    NSData *credentialsData = [credentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *credentialsBase64String = [credentialsData base64EncodedStringWithOptions:0];
    NSString *requestValue = [NSString stringWithFormat:@"Basic %@",credentialsBase64String];
    
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.requestSerializer setValue:requestValue forHTTPHeaderField:@"Authorization"];
    
}

@end
