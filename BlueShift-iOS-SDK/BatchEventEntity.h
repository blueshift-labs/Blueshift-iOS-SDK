//
//  BatchEventEntity.h
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

@interface BatchEventEntity : NSManagedObject

@property (nonatomic, retain) NSData *paramsArray;

@property (nonatomic, retain) NSNumber *retryAttemptsCount;

@property (nonatomic, retain) NSNumber *nextRetryTimeStamp;

@property double createdAt;

/// Insert a record in the BatchEventEntity
- (void)insertEntryParametersList:(NSArray *)parametersArray andNextRetryTimeStamp:(NSInteger)nextRetryTimeStamp andRetryAttemptsCount:(NSInteger)retryAttemptsCount;

/// Fetch batches to send async as part of bulk events
+ (void)fetchBatchesFromCoreDataWithCompletetionHandler:(void (^)(BOOL, NSArray *))handler;

+ (void)deleteEntryForObjectId:(NSManagedObjectID *)objectId completetionHandler:(void (^)(BOOL))handler;

/// Erase all the non synced event batches from the BatchEvent Entity of SDK database
+ (void)eraseEntityData;

@end
