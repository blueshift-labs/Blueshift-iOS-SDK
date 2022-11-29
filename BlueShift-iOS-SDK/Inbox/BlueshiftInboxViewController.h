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

@interface BlueshiftInboxViewController : UITableViewController

@property IBInspectable NSString* _Nullable customCellNibName;

@property IBInspectable NSString* _Nullable inboxDelegateName;

@property (nonatomic, weak) id<BlueshiftInboxViewControllerDelegate>_Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
