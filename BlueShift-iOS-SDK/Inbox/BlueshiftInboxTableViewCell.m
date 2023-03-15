//
//  BlueshiftInboxTableViewCell.m
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import "BlueshiftInboxTableViewCell.h"
#import "BlueshiftConstants.h"
#import "BlueShiftRequestOperationManager.h"

@interface BlueshiftInboxTableViewCell ()
    @property NSString* thumbnailURL;
@end

@implementation BlueshiftInboxTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [super initWithCoder:coder];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self && [reuseIdentifier isEqualToString: kBSInboxDefaultCellIdentifier]) {
        return [self layoutTableViewCell:self];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.iconImageView.image = nil;
}
- (void)setIconImageURL:(NSString *)imageURL {
    if (imageURL) {
        self.thumbnailURL = imageURL;
        NSData *thumbnailData = [BlueShiftRequestOperationManager.sharedRequestOperationManager getCachedImageDataForURL:imageURL];
        if (thumbnailData) {
            self.iconImageView.image = [UIImage imageWithData:thumbnailData];
        } else {
            NSURL *url = [NSURL URLWithString:imageURL];
            __weak __typeof(self)weakSelf = self;
            // Download image
            [BlueShiftRequestOperationManager.sharedRequestOperationManager downloadImageForURL:url handler:^(BOOL status, NSData * _Nonnull thumbnailData, NSError * _Nonnull err) {
                // Assign thumbnail image if the url matches
                if (thumbnailData && [imageURL isEqualToString:weakSelf.thumbnailURL]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.iconImageView.image = [UIImage imageWithData:thumbnailData];
                        [weakSelf setNeedsLayout];
                    });
                }
            }];
        }
    }
}

- (instancetype)layoutTableViewCell:(BlueshiftInboxTableViewCell*)cell {
    UIStackView* wrapperStackView = [self createWrapperStackViewForCell:cell];
    [wrapperStackView addArrangedSubview: [self createUnreadBadgeWrapperView]];
    [wrapperStackView addArrangedSubview:[self createLabelsStackView:[self createTitleLabel] detailLabel:[self createDetailLabel] dateLabel:[self createDateLabel]]];
    [wrapperStackView addArrangedSubview:[self createIconImageWrapperView]];
    return cell;
}

- (UIStackView*)createWrapperStackViewForCell:(BlueshiftInboxTableViewCell*)cell {
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentTop;
    stackView.distribution = UIStackViewDistributionFill;
    [cell.contentView addSubview:stackView];
    
    NSArray *constraints = @[[NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:5.0f],
                             [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-5.0f],
                             [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:10.f],
                             [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-10.f],
    ];
    [cell.contentView addConstraints:constraints];
    return stackView;
}

- (UIView*)createUnreadBadgeWrapperView {
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *badgeView = [[UIView alloc] init];
    badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    badgeView.layer.cornerRadius = 6.0;
    badgeView.backgroundColor = [UIColor colorWithRed:0 green:193 blue:193 alpha:1];
    [wrapperView addSubview:badgeView];
    
    NSArray *wrapperConstraints = @[[NSLayoutConstraint constraintWithItem:badgeView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute: NSLayoutAttributeCenterX multiplier:1.0f constant:0.f],
                                  [NSLayoutConstraint constraintWithItem:badgeView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute:NSLayoutAttributeTop multiplier:1.0f constant:5.f],
                                    [NSLayoutConstraint constraintWithItem:wrapperView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:22.0f]

    ];
    [wrapperView addConstraints:wrapperConstraints];
    
    NSArray *badgeConstraints = @[[NSLayoutConstraint constraintWithItem:badgeView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:12.0f],
                                  [NSLayoutConstraint constraintWithItem:badgeView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:12.0f]];
    [badgeView addConstraints:badgeConstraints];
    self.unreadBadgeView = badgeView;
    return wrapperView;
}

- (UILabel*)createTitleLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont boldSystemFontOfSize:17.0f];
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight ? UIColor.blackColor : UIColor.whiteColor;
        }];
    } else {
        label.textColor = UIColor.blackColor;
    }
    label.numberOfLines = 0;
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisVertical];
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisHorizontal];
    self.titleLabel = label;
    return label;
}

- (UILabel*)createDetailLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:15.0f];
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight ? UIColor.grayColor : UIColor.lightGrayColor;
        }];
    } else {
        label.textColor = UIColor.grayColor;
    }
    label.numberOfLines = 0;
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisVertical];
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisHorizontal];
    self.detailLabel = label;
    return label;
}

- (UILabel*)createDateLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:13.0f];
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight ? UIColor.lightGrayColor : UIColor.grayColor;
        }];
    } else {
        label.textColor = UIColor.lightGrayColor;
    }
    label.numberOfLines = 1;
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisVertical];
    [label setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisHorizontal];
    self.dateLabel = label;
    return label;
}

- (UIStackView*)createLabelsStackView:(UILabel*) titleLabel detailLabel:(UILabel*)detailLabel dateLabel:(UILabel*)dateLabel {
    UIStackView* stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.spacing = 5;
    
    [stackView addArrangedSubview:titleLabel];
    [stackView addArrangedSubview:detailLabel];
    [stackView addArrangedSubview:dateLabel];
    return stackView;
}

- (UIView*)createIconImageWrapperView {
    UIView* wrapperView = [[UIView alloc] init];
    wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView* imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
//    imageView.backgroundColor = UIColor.lightGrayColor;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 10;
    [wrapperView addSubview:imageView];
    
    
    NSArray *wrapperConstraints = @[[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f],
                                    [NSLayoutConstraint constraintWithItem:wrapperView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:70.0f],
                                    [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:wrapperView attribute: NSLayoutAttributeCenterX multiplier:1.0f constant:0.f]
    ];
    [wrapperView addConstraints:wrapperConstraints];
    
    NSArray *imageConstraints = @[[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:60.0f],
                                  [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:60.0f]
                                  ];
    [imageView addConstraints:imageConstraints];
    self.iconImageView = imageView;
    self.iconWrapperView = wrapperView;
    return wrapperView;
}

@end
