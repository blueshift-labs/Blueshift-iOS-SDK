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

@property (nonatomic, assign) IBInspectable BOOL enableLargeTitle;

@property (nonatomic) IBInspectable  BOOL showActivityIndicator;

@property (nonatomic) IBInspectable  UIColor* activityIndicatorColor;

@property (nonatomic) IBInspectable  BOOL groupSections;

@property (nonatomic) id<BlueshiftInboxViewControllerDelegate> _Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
