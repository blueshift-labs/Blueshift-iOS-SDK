//
//  HttpRequestOperationEntity.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSNumber+BlueShiftHelpers.h"
#import "BlueShiftHTTPMethod.h"
#import "BlueShiftAppDelegate.h"
#import "NSDate+BlueShiftDateHelpers.h"

NS_ASSUME_NONNULL_BEGIN

@interface HttpRequestOperationEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * httpMethodNumber;

@property (nonatomic, retain) NSData * parameters;

@property BOOL isBatchEvent;

@property (nonatomic, retain) NSString * url;

@property (nonatomic, retain) NSNumber *retryAttemptsCount;

@property (nonatomic, retain) NSNumber *nextRetryTimeStamp;

@property double createdAt;

/// Insert a record in HttpRequestOperationEntity
- (void)insertEntryWithMethod:(BlueShiftHTTPMethod)httpMethod andParameters:(NSDictionary *)parameters andURL:(NSString *)url andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount andIsBatchEvent:(BOOL) isBatchEvent;

- (BlueShiftHTTPMethod)httpMethod;

/// Fetch first record from HttpRequestOperationEntity
+ (void)fetchOneRealTimeEventFromDBWithCompletionHandler:(void (^)(BOOL, HttpRequestOperationEntity * _Nullable))handler;

/// Fetch all the batch records from HttpRequestOperationEntity
+ (void)fetchBatchedEventsFromDBWithCompletionHandler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)deleteRecordForObjectId:(NSManagedObjectID*)objectId completionHandler:(void (^)(BOOL))handler;

/// Erase all the non synced batched and non-batched events from the HttpRequestOperation Entity of SDK database
+ (void)eraseEntityData;

@end

NS_ASSUME_NONNULL_END
