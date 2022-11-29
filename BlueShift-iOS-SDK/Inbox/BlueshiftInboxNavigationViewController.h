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

@property IBInspectable NSString* _Nullable tableViewCellNibName;

@property IBInspectable (nonatomic) NSString* _Nullable inboxDelegateName;

@property (nonatomic) id<BlueshiftInboxViewControllerDelegate>_Nullable inboxDelegate;

@end

NS_ASSUME_NONNULL_END
