//
//  BlueShiftNotificationWindow.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 11/07/19.
//

#import "BlueShiftNotificationWindow.h"

@implementation BlueShiftNotificationWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}

@end
