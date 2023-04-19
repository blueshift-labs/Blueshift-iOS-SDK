//
//  BlueShiftNotificationView.m
//  BlueShift-iOS-SDK
//
//  Created by shahas kp on 12/07/19.
//

#import "BlueShiftNotificationView.h"

@implementation BlueShiftNotificationView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}

@end
