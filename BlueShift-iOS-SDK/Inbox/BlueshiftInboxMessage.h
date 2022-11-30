//
//  BlueshiftInboxMessage.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 16/11/22.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlueShiftInAppType.h"

typedef NS_ENUM (NSUInteger,BlueshiftInboxNotificationType) {
    BlueshiftInboxNotificationTypeInApp
};

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxMessage : NSObject

@property BlueshiftInboxNotificationType messageType;

@property NSString* inAppNotificationType;

@property BOOL readStatus;

@property NSString* _Nullable messageUUID;

@property NSManagedObjectID* _Nullable objectId;

@property NSString* _Nullable title;

@property NSString* _Nullable detail;

@property NSDate* _Nullable date;

@property NSString* _Nullable iconImageURL;

@property NSDictionary* _Nullable messagePayload;

- (instancetype)initMessageId:(NSString* _Nullable)mId objectId:(NSManagedObjectID* _Nullable)oId inAppType:(NSString* _Nullable)inAppType readStatus:(BOOL)status title:(NSString* _Nullable)title detail:(NSString* _Nullable)detail date:(NSDate* _Nullable)date iconURL:(NSString* _Nullable)iconURL messagePayload:(NSDictionary* _Nullable)messagePayload;

@end

NS_ASSUME_NONNULL_END
