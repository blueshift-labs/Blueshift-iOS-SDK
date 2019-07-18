//
//  BlueShiftNotificationViewController.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <UIKit/UIKit.h>
#import "../Models/BlueShiftInAppNotification.h"

NS_ASSUME_NONNULL_BEGIN

@class BlueShiftNotificationViewController;

@protocol BlueShiftNotificationDelegate <NSObject>
- (void)inAppDidDismiss:(BlueShiftInAppNotification*)notification fromViewController:(BlueShiftNotificationViewController*)controller;
@optional
- (void)inAppDidShow:(BlueShiftInAppNotification*)notification fromViewController:(BlueShiftNotificationViewController*)controller;
@end

@interface BlueShiftNotificationViewController : UIViewController

@property (nonatomic, strong) UIWindow* _Nullable window;
@property (nonatomic, strong, readwrite) BlueShiftInAppNotification *notification;
@property (nonatomic, assign) BOOL canTouchesPassThroughWindow;
@property (nonatomic, weak) id <BlueShiftNotificationDelegate> delegate;

- (instancetype)initWithNotification:(BlueShiftInAppNotification *)notification;

- (void)setTouchesPassThroughWindow:(BOOL) can;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)closeButtonDidTapped;
- (void)createWindow;

@end

NS_ASSUME_NONNULL_END
