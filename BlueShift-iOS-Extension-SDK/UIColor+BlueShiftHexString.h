//
//  UIColor+HexString.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 02/03/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor(BlueShiftHexString)

+ (UIColor *) colorWithHexString: (NSString *) hexString;
+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length;

@end
