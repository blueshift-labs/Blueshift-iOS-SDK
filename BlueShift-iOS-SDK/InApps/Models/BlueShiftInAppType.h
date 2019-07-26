//
//  BlueShiftInAppType.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define INAPP_POSITION @"pos"
#define INAPP_POSITION_BOTTOM @"bottom"
#define INAPP_POSITION_TOP @"top"
#define INAPP_POSITION_CENTER @"center"

typedef NS_ENUM(NSUInteger, BlueShiftInAppType){
    BlueShiftInAppTypeHTML,
    BlueShiftInAppTypeModal,
    BlueShiftInAppModalWithImage,
    BlueShiftNotificationSlideBanner,
    BlueShiftNotificationOneButton,
    BlueShiftInAppDefault
};

NS_ASSUME_NONNULL_END
