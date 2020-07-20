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
+ (CGFloat)convertHeightToPercentage:(UIView *) notificationView;
+ (CGFloat)convertPercentageHeightToPoints:(float) height;
@end

NS_ASSUME_NONNULL_END
