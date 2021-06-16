//
//  BlueShiftNotificationViewController.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <UIKit/UIKit.h>
#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class BlueShiftNotificationViewController;

@protocol BlueShiftNotificationDelegate <NSObject>
@optional
- (void)inAppDidDismiss:(NSDictionary *)notificationPayload fromViewController:(BlueShiftNotificationViewController*)controller;
- (void)inAppActionDidTapped:(NSDictionary *)notificationActionButtonPayload fromViewController:(BlueShiftNotificationViewController *)controller;
- (void)inAppDidShow:(NSDictionary *)notification fromViewController:(BlueShiftNotificationViewController*)controller;
- (void)presentInAppViewController:(BlueShiftNotificationViewController* _Nullable)notificationController forNotification:(BlueShiftInAppNotification* _Nullable)notification;
@end

@interface BlueShiftNotificationViewController : UIViewController

@property (nonatomic, strong) UIWindow* _Nullable window;
@property (nonatomic, strong, readwrite) BlueShiftInAppNotification *notification;
@property (nonatomic, assign) BOOL canTouchesPassThroughWindow;
@property (nonatomic, weak) id <BlueShiftNotificationDelegate> delegate;
@property (nonatomic, weak) id<BlueShiftInAppNotificationDelegate> inAppNotificationDelegate;
@property (nonatomic, strong) NSString* _Nullable displayOnScreen;

- (instancetype)initWithNotification:(BlueShiftInAppNotification *)notification;

- (void)setTouchesPassThroughWindow:(BOOL) can;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

- (void)closeButtonDidTapped;
- (void)createWindow;
- (void)configureBackground;
- (UIColor *)colorWithHexString:(NSString *)str;
- (void)loadNotificationView;
- (void)loadImageFromURL:(NSString *)imageURL forImageView:(UIImageView *)imageView;
- (void)setLabelText:(UILabel *)label andString:(NSString *)value labelColor:(NSString *)labelColorCode backgroundColor:(NSString *)backgroundColorCode;
- (void)applyIconToLabelView:(UILabel *)iconLabelView andFontIconSize:(NSNumber *)fontSize;
- (void)handleActionButtonNavigation:(BlueShiftInAppNotificationButton *)buttonDetails;
- (CGFloat)getLabelHeight:(UILabel*)label labelWidth:(CGFloat)width;
- (UIView *)createNotificationWindow;
- (void)loadImageFromLocal:(UIImageView *)imageView imageFilePath:(NSString *)filePath;
- (void)sendActionEventAnalytics:(NSDictionary *)details;
- (int)getTextAlignement:(NSString *)alignmentString;
- (BOOL)isValidString:(NSString *)data;
- (void)setBackgroundImageFromURL:(UIView *)notificationView;
- (void)setBackgroundColor:(UIView *)notificationView;
- (void)setBackgroundRadius:(UIView *)notificationView;
- (void)setBackgroundDim;
- (void)createCloseButton:(CGRect)frame;
- (void)setButton:(UIButton *)button andString:(NSString *)value textColor:(NSString *)textColorCode backgroundColor:(NSString *)backgroundColorCode;

/// returns dictionary with in-app notification details to share to openURL method of appDelegate
/// @param inAppbutton nullable in-app notification clicked button object
- (NSDictionary *)getInAppOpenURLOptions:(BlueShiftInAppNotificationButton * _Nullable)inAppbutton;

-(NSData*)loadAndCacheImageForURLString:(NSString*)urlString;

/// Check if the notification has a valid background image present.
/// @param notification notification object to perfor the check
- (BOOL)isBackgroundImagePresentForNotification:(BlueShiftInAppNotification*)notification;

/// Check if the slide in notification has in icon background image present.
/// @param notification notification object to perfor the check
- (BOOL)isSlideInIconImagePresent:(BlueShiftInAppNotification*)notification;

/// Check if the notification has a valid banner image present.
/// @param notification notification object to perfor the check
- (BOOL)isBannerImagePresentForNotification:(BlueShiftInAppNotification*)notification;

@end

NS_ASSUME_NONNULL_END
