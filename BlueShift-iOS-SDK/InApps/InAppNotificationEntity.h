//
//  InAppNotificationEntity.h
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <BlueShiftAppDelegate.h>
#import <BlueShiftInAppNotificationHelper.h>

NS_ASSUME_NONNULL_BEGIN

@interface InAppNotificationEntity : NSManagedObject

/// message uuid
@property (nonatomic, retain) NSString *id;

/// Type of inapp message -slidein/modal/html
@property (nonatomic, retain) NSString *type;

/// Priority for the message, default medium.
@property (nonatomic, retain) NSString *priority;

/// Trigger mode can be now or upcoming based on the `trigger` value
@property (nonatomic, retain) NSString *triggerMode;

/// Message type, inapp or push
@property (nonatomic, retain) NSString *eventName;

/// Unread Status - pending/displayed
@property (nonatomic, retain) NSString *status;

/// Display on specific screen eg - CartViewController
@property (nonatomic, retain) NSString *displayOn;

/// Set timestamp from the message payload `timestamp`
@property (nonatomic, retain) NSString *timestamp;

/// Inbox availabilty - inapp/ inbox+inapp/ inbox
@property (nonatomic, retain) NSString *availability;

/// Start time for the message, `trigger` is set as future date.
@property (nonatomic, retain) NSNumber *startTime;

/// Expiry date for the message
@property (nonatomic, retain) NSNumber *endTime;

/// Message creation date from the payload
@property (nonatomic, retain) NSNumber *createdAt;

/// Entire mesasge payload
@property (nonatomic, retain) NSData *payload;


+ (BOOL)insertMesseages:(NSArray<NSDictionary*> *)messagesToInsert;

+ (void)fetchAllMessagesWithHandler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)fetchAllMessagesForInboxWithHandler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)fetchInAppMessageToDisplayOnScreen:(NSString*)displayOn WithHandler:(void (^)(BOOL, NSArray * _Nullable))handler;

+ (void)fetchLastReceivedMessageId:(void (^)(BOOL, NSString *, NSString *))handler;

+ (void)checkIfMessagesPresentForMessageUUIDs:(NSArray*)messageUUIDs handler:(void (^)(BOOL, NSDictionary *))handler;

/// Erase all the In app notifications records from the SDK database.
+ (void)eraseEntityData;

+ (void)markMessageAsRead:(NSString *)messageUUID;

+ (void)syncMessageUnreadStatusWithDB:(NSDictionary * _Nullable)messages status:(NSDictionary* _Nullable)statuses;

+ (void)syncDeletedMessagesWithDB:(NSArray *)deleteIds;

+ (void)deleteInboxMessageFromDB:(NSManagedObjectID *)objectId completionHandler:(void (^_Nonnull)(BOOL))handler;

+ (NSFetchRequest*)getFetchRequestForPredicate:(NSPredicate* _Nullable)predicate sortDescriptor:(NSArray<NSSortDescriptor*>* _Nullable)sortDescriptor;

+ (void)deleteExpiredMessagesFromDB;

+ (void)getUnreadMessagesCountFromDB:(void(^)(BOOL, NSUInteger))handler;

+ (void)postNotificationInboxUnreadMessageCountDidChange:(BlueshiftInboxChangeType)refreshType;

NS_ASSUME_NONNULL_END

@end
