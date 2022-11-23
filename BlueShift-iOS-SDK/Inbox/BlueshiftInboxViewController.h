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
- (void)configureCustomFieldsForCell:(BlueshiftInboxTableViewCell*)cell inboxMessage:(BlueshiftInboxMessage*)message;

@end

@interface BlueshiftInboxViewController : UITableViewController

@property IBInspectable NSString* _Nullable tableViewCellNibName;

@property IBInspectable NSString* _Nullable inboxDelegateName;

@property id<BlueshiftInboxViewControllerDelegate>_Nullable inboxDelegate;

@property IBInspectable (nonatomic) BlueshiftInboxDateFormatType blueshiftInboxDateFormatType;

@property IBInspectable (nonatomic) NSString* _Nullable blueshiftInboxDateFormat;

@end

NS_ASSUME_NONNULL_END
