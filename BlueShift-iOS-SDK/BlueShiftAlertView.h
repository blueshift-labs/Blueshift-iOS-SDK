//
//  BlueShiftAlertView.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 26/02/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueShiftNotificationConstants.h"

typedef enum {
    BlueShiftAlertViewContextNotificationCategoryCart,
    BlueShiftAlertViewContextNotificationCategoryBuy,
    BlueShiftAlertViewContextNotificationCategoryOffer
} BlueShiftAlertViewContext;

@interface BlueShiftAlertView : UIAlertView<UIAlertViewDelegate>

@property BlueShiftAlertViewContext alertViewContext;

+ (instancetype)alertViewWithPushDetailsDictionary:(NSDictionary *)pushDetailsDictionary andDelegate:(id)delegate;

@end
