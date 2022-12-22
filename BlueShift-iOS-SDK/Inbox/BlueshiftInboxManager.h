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


/// Show notification for the given Inbox message.
/// - Parameter message: inbox message to display
+ (void)showInboxNotificationForMessage:(BlueshiftInboxMessage* _Nullable)message;


/// Delete inbox message from the server and local.
/// - Parameters:
///   - message: inbox message to delete
///   - handler: completion handler with `BOOL` completion status
+ (void)deleteInboxMessage:(BlueshiftInboxMessage* _Nullable)message completionHandler:(void (^_Nonnull)(BOOL))handler;


/// Mark an inbox notification as read when visited.
/// - Parameter message: inbox message to mark as read
+ (void)markInboxMessageAsRead:(BlueshiftInboxMessage* _Nullable)message;


/// Get the synced inbox messages to show inside the inbox.
/// The messages will be automatically synced in local db by the SDK and can be retrived using this method to display in the inbox.
/// - Parameter success: success callback which will provide an array of `BlueshiftInboxMessage` objects
+ (void)getCachedInboxMessagesWithHandler:(void (^_Nonnull)(BOOL, NSMutableArray<BlueshiftInboxMessage*>* _Nullable))success;


/// This method will sync the new messages received by the user on server with the local db.
/// After the sync, the new messages will be availble at local db for the later use.
/// - Parameter success: success callback will tell you that the sync is complete.
+ (void)syncNewInboxMessages:(void (^_Nonnull)(void))success;


/// This method will provide the count for unread messages. This count can be used to update the unread notifications badge.
/// - Parameter handler: completion handler with unread messages count.
+ (void)getInboxUnreadMessagesCount:(void(^_Nonnull)(NSUInteger))handler;


/// This method is for adding the fetched messages from server to the local db for later use.
/// - Parameters:
///   - messagesToBeAdded: messages array to add in the db.
///   - handler: completion handler with `BOOL` completion status
/// - Not recommended to use unless needed as the `syncNewInboxMessages` method does the work of making api call and adding it to local db.
+ (void)addInboxNotifications:(NSMutableArray *)messagesToBeAdded handler:(void (^_Nonnull)(BOOL))handler;


/// This method is for adding the fetched messages from server to the local db for later use.
/// - Parameters:
///   - apiResponse: apiResponse received from the `getMessagesForMessageUUIDs` API call.
///   - completionHandler: completion handler with `BOOL` completion status
/// - Not recommended to use unless needed as the `syncNewInboxMessages` method does the work of making api call and adding it to local db.
+ (void)handleInboxMessageForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^_Nonnull)(BOOL))completionHandler;

/// Delete the inbox messages if user if logging out or profile is getting changed.
/// This method will delete all the local inbox messages, and new messages will be fetched for the new user/profile.
+ (void)deleteAllInboxMessagesFromDB;

+ (BOOL)isSyncing;

@end

NS_ASSUME_NONNULL_END
