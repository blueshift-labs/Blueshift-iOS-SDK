//
//  BlueShiftRequestOperationManager.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftAppDelegate.h"
#import <CoreData/CoreData.h>
#import "HttpRequestOperationEntity.h"
#import "BlueShiftHTTPMethod.h"
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftStatusCodes.h"

@interface BlueShiftRequestOperationManager : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>



@property NSURLSessionConfiguration *sessionConfiguraion;

// Method to get the shared instance for BlueShiftOperationManager ...

+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager;


- (void) postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL))handler;

- (void) getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary*, NSError*))handler;

// Method to add Basic authentication request Header ...

- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password;

@end
