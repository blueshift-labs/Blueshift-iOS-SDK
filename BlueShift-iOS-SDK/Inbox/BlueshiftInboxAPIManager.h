//
//  BlueshiftInboxAPIManager.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan on 18/04/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxAPIManager : NSObject

/// API call to get the in-app notifications from the server. The response will be a dictionary containing messages.
/// - Parameters:
///   - success: success callback
///   - failure: failure callback
+ (void) fetchInAppNotificationWithSuccess:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure;


/// API call to get the unread status infomration for Inbox messages. The response will be an array of objects consisting the message ids, read status, and other info.
/// - Parameters:
///   - success: success callback
///   - failure: failure callback
+ (void)getMessageIdsAndStatus:(void (^)(NSArray* _Nullable))success failure:(void (^)(NSError* _Nullable))failure;


/// API call to get the inbox messages for given message ids received from the `getUnreadStatus` API call. The response will be a dictionary containing messages.
/// - Parameters:
///   - messageIds: message ids to fetch messages
///   - success: success callback
///   - failure: failure callback
+ (void)getMessagesForMessageUUIDs:(NSArray* _Nullable)messageIds success:(void (^)(NSDictionary*))success failure:(void (^)(NSError* _Nullable, NSArray* _Nullable))failure;


/// API call to delete inbox messages from server using the message ids.
/// - Parameters:
///   - messageIds: array of message ids to delete from server
///   - success: success callback
///   - failure: failure callback
+ (void)deleteMessagesWithMessageUUIDs:(NSArray*)messageIds success:(void (^)(void))success failure:(void (^)(NSError* _Nullable))failure;

@end

NS_ASSUME_NONNULL_END
