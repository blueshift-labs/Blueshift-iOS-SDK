//
//  BlueShiftInAppNotificationHelper.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotificationHelper : NSObject

+ (BlueShiftInAppType)inAppTypeFromString:(NSString*_Nonnull)inAppType;

@end

NS_ASSUME_NONNULL_END
