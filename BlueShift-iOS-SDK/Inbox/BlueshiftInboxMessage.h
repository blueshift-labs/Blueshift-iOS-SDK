//
//  BlueshiftInboxMessage.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 16/11/22.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <BlueShiftInAppType.h>

typedef NS_ENUM (NSUInteger,BlueshiftInboxNotificationType) {
    BlueshiftInboxNotificationTypeInApp
};

typedef NS_ENUM (NSUInteger, BlueshiftInboxChangeType) {
    BlueshiftInboxChangeTypeMarkAsUnread       = 0,
    BlueshiftInboxChangeTypeSync               = 1,
    BlueshiftInboxChangeTypeMessageDelete      = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxMessage : NSObject

@property BlueshiftInboxNotificationType messageType;

@property NSString* _Nullable inAppNotificationType;

@property BOOL readStatus;

@property NSString* _Nullable messageUUID;

@property NSManagedObjectID* _Nullable objectId;

@property NSString* _Nullable title;

@property NSString* _Nullable detail;

@property NSDate* _Nullable createdAtDate;

@property NSString* _Nullable iconImageURL;

@property NSDictionary* _Nullable messagePayload;

- (instancetype)initWithMessageId:(NSString* _Nullable)messageId objectId:(NSManagedObjectID* _Nullable)objectId inAppType:(NSString* _Nullable)inAppType readStatus:(BOOL)status title:(NSString* _Nullable)title detail:(NSString* _Nullable)detail createdAtDate:(NSDate* _Nullable)createdAtDate iconImageURL:(NSString* _Nullable)iconImageURL messagePayload:(NSDictionary* _Nullable)messagePayload;

@end

NS_ASSUME_NONNULL_END
