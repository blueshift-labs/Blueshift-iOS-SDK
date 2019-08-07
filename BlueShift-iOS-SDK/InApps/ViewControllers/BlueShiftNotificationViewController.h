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
- (void)inAppDidDismiss:(BlueShiftInAppNotification *)notificationPayload fromViewController:(BlueShiftNotificationViewController*)controller;
- (void)inAppActionDidTapped:(BlueShiftInAppNotificationButton *)notificationActionButton fromViewController:(BlueShiftNotificationViewController *)
controller;
- (void)inAppDidShow:(BlueShiftInAppNotification *)notification fromViewController:(BlueShiftNotificationViewController*)controller;
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
- (CGRect)positionNotificationView:(UIView *) notificationView;
- (void)configureBackground;
- (UIColor *)colorWithHexString:(NSString *)str;
- (void)loadNotificationView;
- (UIView *) fetchNotificationView;
- (void)loadImageFromURL:(UIImageView *)imageView andImageURL:(NSString *)imageURL;
- (void)setLabelText:(UILabel *)label andString:(NSString *)value labelColor:(NSString *)labelColorCode backgroundColor:(NSString *)backgroundColorCode;
- (void)applyIconToLabelView:(UILabel *)iconLabelView;

@end

NS_ASSUME_NONNULL_END
