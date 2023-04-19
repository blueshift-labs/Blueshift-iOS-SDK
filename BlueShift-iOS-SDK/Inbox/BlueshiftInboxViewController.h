//
//  BlueshiftInboxViewController.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import <UIKit/UIKit.h>
#import "BlueshiftInboxMessage.h"
#import "BlueshiftInboxTableViewCell.h"
#import "BlueshiftInboxMessage.h"
#import "BlueshiftInboxViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BlueshiftInboxViewControllerDelegate <NSObject>

@optional

/// Set this property in case you want to filter the messages. Return true or false based on if you want to show this messages inside inbox or not.
@property (copy) BOOL(^ _Nullable messageFilter)(BlueshiftInboxMessage*);

/// This property can be only set if you want to use two or more custom cells in the Inbox.
/// example - If you want to use a custom themed cell as default cell and one more custom cell for promotion based messages.
/// In this case, you can set this array with all the custom cell nib names.
/// All the nib must be present in the main bundle.
@property NSArray<NSString*>* _Nullable customCellNibNames;

/// Set this property if you want to sort the messages in certain order. With the default order, the new messages will be displayed on top.
/// The messages can be sorted using date/title/unread status.
/// To sort it using date, you can return `return msg1date.compare(msg1date)`
/// To sort it using title, you can return ` return msg1Title.caseInsensitiveCompare(msg2Title)`
@property (copy) NSComparisonResult(^ _Nullable messageComparator)(BlueshiftInboxMessage*, BlueshiftInboxMessage*);

- (NSString* _Nullable)getCustomCellNibNameForMessage:(BlueshiftInboxMessage*)message;

- (NSString* _Nullable)formatDate:(BlueshiftInboxMessage*)message;

- (void)configureCustomFieldsForCell:(BlueshiftInboxTableViewCell*)cell inboxMessage:(BlueshiftInboxMessage*)message;

- (void)inboxMessageDeleted:(BlueshiftInboxMessage*)message;

- (void)inboxMessageSelected:(BlueshiftInboxMessage*)message;

@end

IB_DESIGNABLE
@interface BlueshiftInboxViewController : UITableViewController

/// If you dont want to use the SDK provided default cell layout, then you can create your own custom layout inside a xib and provide the nib name here.
/// Setting this value is optional if you want to use the SDK provided default cell layout.
/// This option allows you to use only one custom cell in the inbox, and that custom cell will be used as default cell by the SDK.
/// The custom cell nib must be present in the main bundle.
@property IBInspectable NSString* _Nullable customCellNibName;

/// This value needs to be only set from the Storyboard or Xib to get the `BlueshiftInboxViewControllerDelegate` callbacks.
/// Create a class which implements the protocol `BlueshiftInboxViewControllerDelegate`, implement the required methods.
/// The name must be set in format - `module_name.classs_name` from the storyboard.
/// @warning Set this value only if you are configuring the inbox using the storyboard or xib. Skip setting this property if you are preseting inbox from the code.
@property IBInspectable NSString* _Nullable inboxDelegateName;

/// Set this property to change the unread badge color displayed on the inbox message cell.
/// The default color is Cyan.
@property IBInspectable UIColor* _Nullable unreadBadgeColor;

/// Set this property to change the color for the pull down to refresh control.
/// The default color is Cyan.
@property IBInspectable UIColor* _Nullable refreshControlColor;

/// Set this property to true or false if you want to show/hide the activity indicator while displaying the in-app notification.
/// The in-app notification might take time to display as it needs to download the resources like images or html pages.
/// The inbox will show activity indicatory till the time it is downloading the resources, once its ready it will hide the activity indicator and present the in-app notification.
/// The default value is True.
@property IBInspectable BOOL showActivityIndicator;

/// Set color for the activity indicator.
/// If you have not opted for `showActivityIndicator` then you can skip setting this.
/// The default color is Gray.
@property IBInspectable UIColor* activityIndicatorColor;

/// Set inboxDelegate to get the `BlueshiftInboxViewControllerDelegate` callbacks.
/// Create a class which implements the protocol `BlueshiftInboxViewControllerDelegate`, implement the required methods, create a object and assgin it to this property.
/// @warning Set this property only if you are preseting inbox from the code. Skip setting this if you are configuring the inbox using the storyboard or xib.
@property (nonatomic) id<BlueshiftInboxViewControllerDelegate>_Nullable inboxDelegate;

/// Init the InboxViewController with the `BlueshiftInboxViewControllerDelegate` delegate
- (instancetype)initWithInboxDelegate:(id<BlueshiftInboxViewControllerDelegate>)inboxDelegate;

@end

NS_ASSUME_NONNULL_END
