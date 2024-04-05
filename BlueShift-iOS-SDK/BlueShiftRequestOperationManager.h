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

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftRequestOperationManager : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property NSURLSession * _Nullable mainURLSession;
@property NSURLSessionConfiguration* _Nullable sessionConfiguraion;
@property NSURLSession* _Nullable replayURLSesion;

/// Image cache for storing downloaded images from the inbox and in-app notifications.
@property (nonatomic, strong) NSCache<NSString*, NSData *> *sdkCachedData;

/// Get the shared instance for BlueShiftOperationManager
+ (BlueShiftRequestOperationManager *)sharedRequestOperationManager;

/// To execute the POST requests like event, bulkevents API calls
- (void)postRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completionHandler:(void (^)(BOOL, NSDictionary * _Nullable, NSError * _Nullable))handler;

/// To execute the GET request like tracking API calls
- (void)getRequestWithURL:(NSString *)urlString andParams:(NSDictionary *)params completionHandler:(void (^)(BOOL, NSDictionary* _Nullable, NSError* _Nullable))handler;

/// Add Basic authentication to Header
- (void)addBasicAuthenticationRequestHeaderForUsername:(NSString *)username andPassword:(NSString *)password;

/// Replay the universal link to perform a click and get the original URL.
- (void)replayUniversalLink:(NSURL *)url completionHandler:(void (^)(BOOL, NSURL* _Nullable, NSError* _Nullable))handler;

/// Reset URL config to re-initialize the SDK
- (void)resetURLSessionConfig;

- (void)downloadDataForURL:(NSURL*)url shouldCache:(BOOL)shouldCache handler:(void (^)(BOOL, NSData * _Nullable, NSError * _Nullable))handler;

- (NSData* _Nullable)getCachedDataForURL:(NSString*)url;

@end

NS_ASSUME_NONNULL_END
