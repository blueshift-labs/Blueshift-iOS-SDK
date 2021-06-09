//
//  BlueShiftNotificationWebViewController.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import <UIKit/UIKit.h>
#import "BlueShiftNotificationViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftNotificationWebViewController : BlueShiftNotificationViewController
- (void)setupWebView:(void (^)(void))block;
@end

NS_ASSUME_NONNULL_END
