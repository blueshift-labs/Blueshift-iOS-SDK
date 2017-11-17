//
//  BlueShiftAlertView.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#define kAlertTitle     @"Notification Alert"
#define kDismissButton  @"Dismiss"
#define kViewButton     @"View"
#define kBuyButton      @"Buy"
#define kOpenButton     @"Open"
#define kShowButton     @"Show"

#import <UIKit/UIKit.h>
#import "BlueShiftNotificationConstants.h"

@protocol BlueShiftAlertControllerDelegate <NSObject>

@optional
- (void)handleAlertActionButtonForCategoryCartWithActionName:(NSString *_Nullable)name;
- (void)handleAlertActionButtonForCategoryBuyWithActionName:(NSString *_Nullable)name;
- (void)handleAlertActionButtonForCategoryPromotionWithActionName:(NSString *_Nullable)name;
- (void)handleAlertActionButtonForCategoryTwoButtonAlertWithActionName:(NSString *_Nullable)name;
@end

@interface BlueShiftAlertView : NSObject

@property (nonatomic, weak) id<BlueShiftAlertControllerDelegate> _Nullable alertControllerDelegate;

- (UIAlertController *_Nonnull)alertViewWithPushDetailsDictionary:(NSDictionary *_Nonnull)pushDetailsDictionary;

@end
