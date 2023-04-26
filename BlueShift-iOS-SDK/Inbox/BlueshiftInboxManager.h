//
//  BlueshiftInboxManager.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 14/12/22.
//

#import <Foundation/Foundation.h>
#import <BlueshiftInboxViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxManager : NSObject


/// Show notification for the given Inbox message. Returns true or false based on if the in-app is displayed or not.
/// - Parameter message: inbox message to display
/// - Returns BOOL based on if the notification was successfully displayed or not.
+ (BOOL)showNotificationForInboxMessage:(BlueshiftInboxMessage* _Nullable)message inboxInAppDelegate:(id<BlueshiftInboxInAppNotificationDelegate> _Nullable)inboxInAppDelegate;

/// Delete inbox message from the server and local.
/// - Parameters:
///   - message: inbox message to delete
///   - handler: completion handler with `BOOL` completion status and `NSString` error message.
/// - The completion handler returns on the background thread, make sure you run any UI activity on main thread in the callback.
+ (void)deleteInboxMessage:(BlueshiftInboxMessage* _Nullable)message completionHandler:(void (^_Nonnull)(BOOL, NSString* _Nullable))handler;

/// Get the synced inbox messages to show inside the inbox.
/// The messages will be automatically synced in local db by the SDK and can be retrived using this method to display in the inbox.
/// - Parameter success: success callback which will provide an array of `BlueshiftInboxMessage` objects. The handler with response will be invoked on background thread. Perform any UI changes on main thread using GCD.
+ (void)getCachedInboxMessagesWithHandler:(void (^_Nonnull)(BOOL, NSMutableArray<BlueshiftInboxMessage*>* _Nullable))success;


/// This method will sync the new messages received by the user on server with the local db.
/// After the sync, the new messages will be availble at local db for the later use.
/// - Parameter handler: success callback will tell you that the sync is complete.
+ (void)syncInboxMessages:(void (^_Nonnull)(void))handler;


/// This method will provide the count for unread messages. This count can be used to update the unread notifications badge.
/// - Parameter handler: completion handler with BOOL status and unread messages count. The handler will be invoked on main thread.
+ (void)getInboxUnreadMessagesCount:(void(^_Nonnull)(BOOL, NSUInteger))handler;


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
+ (void)processInboxMessagesForAPIResponse:(NSDictionary *)apiResponse withCompletionHandler:(void (^_Nonnull)(BOOL))completionHandler;

/// Delete the inbox messages if user if logging out or profile is getting changed.
/// This method will delete all the local inbox messages, and new messages will be fetched for the new user/profile.
+ (void)deleteAllInboxMessagesFromDB;

@end

NS_ASSUME_NONNULL_END
