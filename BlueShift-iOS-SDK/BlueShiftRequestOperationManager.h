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

@property NSURLSession *mainURLSession;
@property NSURLSessionConfiguration *sessionConfiguraion;
@property NSURLSession *replayURLSesion;

/// Get the shared instance for BlueShiftOperationManager
+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager;

/// To execute the POST requests like event, bulkevents API calls
- (void) postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary *,NSError *))handler;

/// To execute the GET request like tracking API calls
- (void) getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completetionHandler:(void (^)(BOOL, NSDictionary*, NSError*))handler;

/// Add Basic authentication to Header
- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password;

/// Replay the universal link to perform a click and get the original URL.
- (void)replayUniversalLink:(NSURL *)url completionHandler:(void (^)(BOOL, NSURL*, NSError*))handler;

/// Reset URL config to re-initialize the SDK
- (void)resetURLSessionConfig;

@end
