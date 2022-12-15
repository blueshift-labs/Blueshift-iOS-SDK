//
//  BlueshiftInboxManager.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 14/12/22.
//

#import <Foundation/Foundation.h>
#import "BlueshiftInboxMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxManager : NSObject

+ (void)showInboxNotificationForMessage:(BlueshiftInboxMessage* _Nullable)message;

+ (void)deleteInboxMessage:(BlueshiftInboxMessage* _Nullable)message completionHandler:(void (^_Nonnull)(BOOL))handler;

+ (void)markInboxMessageAsRead:(BlueshiftInboxMessage* _Nullable)message;

+ (void)getInboxMessagesWithHandler:(void (^_Nonnull)(BOOL, NSMutableArray<BlueshiftInboxMessage*>* _Nullable))success;

+ (void)getLatestInboxMessagesUsingAPI:(void (^_Nonnull)(void))success failure:(void (^)( NSError* _Nullable ))failure;

+ (void)getInboxUnreadMessagesCount:(void(^)(NSUInteger))handler;

+ (void)addInboxNotifications:(NSMutableArray *)notificationArray handler:(void (^)(BOOL))handler;

+ (void)handleInboxMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^)(BOOL))completionHandler;

@end

NS_ASSUME_NONNULL_END
