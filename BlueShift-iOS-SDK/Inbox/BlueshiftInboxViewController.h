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

NS_ASSUME_NONNULL_BEGIN
@protocol BlueshiftInboxViewControllerDelegate <NSObject>

@optional

@property NSComparisonResult sortOrder;

- (NSString* _Nullable)formatDate:(BlueshiftInboxMessage*)message;

- (void)configureCustomFieldsForCell:(BlueshiftInboxTableViewCell*)cell inboxMessage:(BlueshiftInboxMessage*)message;

- (void)inboxMessageDeleted:(BlueshiftInboxMessage*)message;

- (void)inboxMessageSelected:(BlueshiftInboxMessage*)message;

@end

IB_DESIGNABLE
@interface BlueshiftInboxViewController : UITableViewController

@property IBInspectable NSString* _Nullable customCellNibName;

@property IBInspectable NSString* _Nullable inboxDelegateName;

@property IBInspectable UIColor* _Nullable unreadBadgeColor;

@property (nonatomic) id<BlueshiftInboxViewControllerDelegate>_Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
