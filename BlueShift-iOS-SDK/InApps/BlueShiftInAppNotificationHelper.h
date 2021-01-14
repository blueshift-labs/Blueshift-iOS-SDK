//
//  BlueShiftInAppNotificationHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationHelper : NSObject

+ (BlueShiftInAppType)inAppTypeFromString:(NSString*_Nonnull)inAppType;
+ (NSString *)getLocalDirectory:(NSString *)fileName;
+ (BOOL)hasFileExist:(NSString *)fileName;
+ (NSString *)createFileNameFromURL:(NSString *)imageURL;
+ (BOOL)hasDigits:(NSString *)digits;
+ (void)deleteFileFromLocal:(NSString *) fileName;
+ (CGFloat)convertPointsHeightToPercentage:(float) height forWindow:(UIWindow*)window;
+ (CGFloat)convertPointsWidthToPercentage:(float) width forWindow:(UIWindow*)window;
+ (CGFloat)convertPercentageHeightToPoints:(float) height forWindow:(UIWindow*)window;
+ (CGFloat)convertPercentageWidthToPoints:(float) width forWindow:(UIWindow*)window;
+ (NSString*)getEncodedURLString:(NSString*) urlString;

/// Returns the height of window excluding the top and bottom  safe area
/// @param window - get presentation height for this window
+ (CGFloat)getPresentationAreaHeightForWindow:(UIWindow*)window;

/// Returns the width of window excluding the left and right  safe area
/// @param window - get presentation width for this window
+ (CGFloat)getPresentationAreaWidthForWindow:(UIWindow*)window;

/// Returns the safe area insets for the given window or key window
/// @param window - get safe area insets for this window
+ (UIEdgeInsets)getApplicationWindowSafeAreaInsets:(UIWindow*)window API_AVAILABLE(ios(11.0));

+ (BOOL)checkAppDelegateWindowPresent;
+ (BOOL)isIpadDevice;

/// Returns the size of window for given window. If window object is null then return the keyWindow size or  UIScreen size
/// @param window current window of the view
+ (CGSize)getApplicationWindowSize:(UIWindow *)window;

/// Returns application key window based on multi window app or single window app
/// @warning In the sceneDelegate enabled apps, In order to access multiple windows to find the keyWindow, this function needs to be called on the main thread
+ (UIWindow *)getApplicationKeyWindow;

@end

NS_ASSUME_NONNULL_END
