//
//  BlueshiftWebBrowserViewController.h
//  BlueShift-iOS-SDK
//
//  Created by Ketan Shikhare on 28/08/23.
//

#import <UIKit/UIKit.h>
#import <BlueShiftNotificationViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueshiftWebBrowserViewController : BlueShiftNotificationViewController

@property NSURL* url;
@property BOOL showOpenInBrowserButton;

@end

NS_ASSUME_NONNULL_END
