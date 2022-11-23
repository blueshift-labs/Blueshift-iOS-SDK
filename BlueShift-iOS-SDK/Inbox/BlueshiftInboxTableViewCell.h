//
//  BlueshiftInboxTableViewCell.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxTableViewCell : UITableViewCell

/// Title of the notification
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;


/// Detail/sub-title of the notification
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;


/// Date label of the notification
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

/// Imageview for the Notification Icon
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;

/// Unread badge view to change the color based on status
@property (strong, nonatomic) IBOutlet UIView *unreadBadgeView;

/// Icon imageView wrapper view
@property (strong, nonatomic) IBOutlet UIView *iconWrapperView;

@end

NS_ASSUME_NONNULL_END
