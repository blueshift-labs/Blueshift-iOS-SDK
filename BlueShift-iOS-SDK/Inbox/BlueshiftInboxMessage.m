//
//  BlueshiftInboxMessage.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 16/11/22.
//

#import "BlueshiftInboxMessage.h"
#import "BlueshiftLog.h"

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

- (NSDictionary *)toDictionary {
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    @try {
        [messageDict setValue:self.messageUUID forKey:@"messageId"];
        [messageDict setValue:self.messagePayload forKey:@"data"];
        NSString* status = self.readStatus ? @"read" : @"unread";
        [messageDict setValue:status forKey:@"status"];
        double seconds = [self.createdAtDate timeIntervalSince1970];
        NSNumber *timestamp = [NSNumber numberWithInteger: (NSInteger)seconds];
        [messageDict setValue:timestamp forKey:@"createdAt"];
        [messageDict setValue:self.title forKey:@"title"];
        [messageDict setValue:self.detail forKey:@"details"];
        NSString *imageUrl = [self.iconImageURL isEqualToString:@""]? nil : self.iconImageURL;
        [messageDict setValue:imageUrl forKey:@"imageUrl"];
    } @catch (NSException *exception) {
        [BlueshiftLog logException:exception withDescription:nil methodName:nil];
    }
    return [messageDict copy];
}

- (instancetype)initWithDictionary:(NSDictionary *)messageDict {
    self = [super init];
    if (self) {
        @try {
            self.messageUUID = [messageDict valueForKey:@"messageId"];
            NSDictionary* data = [messageDict valueForKey:@"data"];
            self.messagePayload = [data copy];
            self.inAppNotificationType = [[[data valueForKey:@"data"] valueForKey:@"inapp"] valueForKey:@"type"];
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:nil methodName:nil];
        }
    }
    return self;
}

@end
