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
+ (CGFloat)getPresentationAreaHeightForWindow:(UIWindow*)window;
+ (CGFloat)getPresentationAreaWidthForWindow:(UIWindow*)window;
+ (BOOL)checkAppDelegateWindowPresent;
+ (BOOL)isIpadDevice;
+ (CGSize)getApplicationWindowSize;
+ (UIWindow *)getApplicationKeyWindow;

@end

NS_ASSUME_NONNULL_END
