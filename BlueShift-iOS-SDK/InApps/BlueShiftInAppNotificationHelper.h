//
//  BlueShiftInAppNotificationHelper.h
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"
#import <UIKit/UIKit.h>
#import "BlueshiftInboxMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationHelper : NSObject

+ (BlueShiftInAppType)inAppTypeFromString:(NSString*_Nonnull)inAppType;
+ (NSString *)getLocalDirectory:(NSString *)fileName;
+ (BOOL)hasFileExist:(NSString *)fileName;
+ (NSString *)createFileNameFromURL:(NSString *)fileURL;
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
/// @warning In the sceneDelegate enabled apps, In order to access multiple windows to find the keyWindow, this function needs to be executed on the main thread
+ (UIWindow *)getApplicationKeyWindow;

/// Download font awesome file if not downloaded alredy.
/// @param completionHandler  block to be called after downloading the font file.
+ (void)downloadFontAwesomeFile:(void(^)(void))completionHandler;

+ (NSDateFormatter*)getUTCDateFormatter;

+ (NSDate*)getUTCDateFromDateString:(NSString*)createdAtDateString;

+ (NSString * _Nullable)getMessageUUID:(NSDictionary *)notificationPayload;

+ (BOOL)isExpired:(double)expiryTime;

/// Check if a url is valid web url
/// - Parameter url: url to check
+ (BOOL)isValidWebURL:(NSURL*)url;

/// Check if a url is of open in web browser type
/// - Parameter url: url to check
+ (BOOL)isOpenInWebURL:(NSURL*)url;

/// Remove url query param from a given url
/// - Parameters:
///   - param: param to remove from url
///   - url: param will be removed from this url
/// - Returns: param removed url
+ (NSURL* _Nullable)removeQueryParam:(NSString*)param FromURL:(NSURL*)url;


@end

NS_ASSUME_NONNULL_END
