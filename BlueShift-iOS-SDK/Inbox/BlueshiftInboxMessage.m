//
//  BlueshiftInboxMessage.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 16/11/22.
//

#import "BlueshiftInboxMessage.h"

@implementation BlueshiftInboxMessage
- (instancetype)initMessageId:(NSString*)mId objectId:(NSManagedObjectID*)oId inAppType:(NSString*)inAppType readStatus:(BOOL)status title:(NSString*)title detail:(NSString*)detail date:(NSDate*)date iconURL:(NSString*)iconURL messagePayload:(NSDictionary*)messagePayload {
    self = [super init];
    if (self) {
        
        self.messageType = BlueshiftInboxNotificationTypeInApp;
        
        self.inAppNotificationType = inAppType;
        
        self.readStatus = status;
        
        self.messageUUID = mId;
        
        self.objectId = oId;
        
        self.title = title;
        
        self.detail = detail;
        
        self.date = date;
        
        self.iconImageURL = iconURL;
                
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