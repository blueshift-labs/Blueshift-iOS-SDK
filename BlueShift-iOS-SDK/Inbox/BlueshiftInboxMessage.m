//
//  BlueshiftInboxMessage.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 16/11/22.
//

#import "BlueshiftInboxMessage.h"

@implementation BlueshiftInboxMessage

- (instancetype)initWithMessageId:(NSString* _Nullable)messageId objectId:(NSManagedObjectID* _Nullable)objectId inAppType:(NSString* _Nullable)inAppType readStatus:(BOOL)status title:(NSString* _Nullable)title detail:(NSString* _Nullable)detail createdAtDate:(NSDate* _Nullable)createdAtDate iconImageURL:(NSString* _Nullable)iconImageURL messagePayload:(NSDictionary* _Nullable)messagePayload {
    self = [super init];
    if (self) {
        
        self.messageType = BlueshiftInboxNotificationTypeInApp;
        
        self.inAppNotificationType = inAppType;
        
        self.readStatus = status;
        
        self.messageUUID = messageId;
        
        self.objectId = objectId;
        
        self.title = title;
        
        self.detail = detail;
        
        self.createdAtDate = createdAtDate;
        
        self.iconImageURL = iconImageURL;
                
        self.messagePayload = messagePayload;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.messageType = BlueshiftInboxNotificationTypeInApp;
    }
    return self;
}
@end
