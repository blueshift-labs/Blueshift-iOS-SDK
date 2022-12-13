//
//  InAppNotificationEntity.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BlueShiftAppDelegate.h"
#import "BlueShiftInAppNotificationHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface InAppNotificationEntity : NSManagedObject

@property (nonatomic, retain) NSString *id;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *triggerMode;

// Notification name inapp or push
@property (nonatomic, retain) NSString *eventName;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *displayOn;
@property (nonatomic, retain) NSString *timestamp;
@property (nonatomic, retain) NSString *availability;

@property (nonatomic, retain) NSNumber *startTime;
@property (nonatomic, retain) NSNumber *endTime;
@property (nonatomic, retain) NSNumber *createdAt;

@property (nonatomic, retain) NSData *payload;

- (void)insert:(NSDictionary *)dictionary handler:(void (^)(BOOL))handler;

+ (void)fetchAllMessagesForInbox:(NSComparisonResult)sortOrder handler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)fetchInAppMessageToDisplayOnScreen:(NSString*)displayOn WithHandler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)fetchLastReceivedMessageId:(void (^)(BOOL, NSString *, NSString *))handler;

+ (void)checkIfMessagesPresentForMessageUUIDs:(NSArray*)messageUUIDs handler:(void (^)(BOOL, NSDictionary *))handler;

/// Erase all the In app notifications records from the SDK database.
+ (void)eraseEntityData;

+ (void)markMessageAsRead:(NSString *)messageUUID;

+ (void)updateMessageUnreadStatusInDB:(NSDictionary * _Nullable)messages status:(NSDictionary* _Nullable)statusArray;

+ (void)syncDeletedMessagesWithDB:(NSArray *)deleteIds;

+ (void)deleteInboxMessageFromDB:(NSManagedObjectID *)objectId completionHandler:(void (^_Nonnull)(BOOL))handler;

+ (NSFetchRequest*)getFetchRequestForPredicate:(NSPredicate* _Nullable)predicate sortDescriptor:(NSArray<NSSortDescriptor*>* _Nullable)sortDescriptor;

+ (void)deleteExpiredMessagesFromDB;

+ (void)getUnreadMessagesCountFromDB:(void(^)(NSUInteger))handler;

+ (void)postNotificationInboxUnreadMessageCountDidChange;

NS_ASSUME_NONNULL_END

@end
