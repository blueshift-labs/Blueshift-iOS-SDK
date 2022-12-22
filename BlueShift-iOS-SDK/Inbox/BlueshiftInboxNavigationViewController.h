//
//  BlueshiftInboxNavigationViewController.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 15/11/22.
//

#import <UIKit/UIKit.h>
#import "BlueshiftInboxViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftInboxNavigationViewController : UINavigationController

@property (nonatomic, assign) IBInspectable NSString* _Nullable customCellNibName;

@property (nonatomic, assign) IBInspectable NSString* _Nullable inboxDelegateName;

@property (nonatomic, assign) IBInspectable UIColor* _Nullable unreadBadgeColor;

/// Set this property to true to enable the large title.
/// Default value is False.
@property (nonatomic, assign) IBInspectable BOOL enableLargeTitle;

@property (nonatomic) IBInspectable  BOOL showActivityIndicator;

@property (nonatomic) IBInspectable  UIColor* activityIndicatorColor;

/// Set this property to true if you want to enable the sections.
/// By default the groupSections are disabled.
@property (nonatomic) IBInspectable  BOOL groupSections;

/// Set this property to true in case you want to show `Done` button on the navigation bar in order to dismiss the inbox.
/// Default value is True.
@property (nonatomic) IBInspectable  BOOL showDoneButton;

@property (nonatomic) id<BlueshiftInboxViewControllerDelegate> _Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
