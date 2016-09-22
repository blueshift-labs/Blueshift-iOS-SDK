//
//  BlueShiftAlertView.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "BlueShiftNotificationConstants.h"

typedef enum {
    BlueShiftAlertViewContextNotificationCategoryCart,
    BlueShiftAlertViewContextNotificationCategoryBuy,
    BlueShiftAlertViewContextNotificationCategoryOffer,
    BlueShiftAlertViewContextNotificationOneButtonAlert,
    BlueShiftAlertViewContextNotificationTwoButtonAlert
} BlueShiftAlertViewContext;

@interface BlueShiftAlertView : UIAlertView<UIAlertViewDelegate>

@property BlueShiftAlertViewContext alertViewContext;

+ (instancetype)alertViewWithPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary andDelegate:(id)delegate;

@end
