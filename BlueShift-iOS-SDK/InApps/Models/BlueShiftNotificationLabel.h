//
//  BlueShiftNotificationLabel.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 18/07/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftNotificationLabel : NSObject

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *titleColor;
@property (nonatomic, copy, readwrite) NSString *titleBackgroundColor;
@property (assign, readwrite) NSNumber *titleSize;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, copy, readwrite) NSString *messageColor;
@property (nonatomic, copy, readwrite) NSString *messageBackgroundColor;
@property (assign, readwrite) NSNumber *messageSize;
@property (nonatomic, copy, readwrite) NSString *messageAlign;
@property (nonatomic, copy, readwrite) NSString *backgroundImage;
@property (nonatomic, copy, readwrite) NSString *backgroundColor;
@property (nonatomic, assign, readwrite) NSNumber *width;
@property (nonatomic, assign, readwrite) NSNumber *height;
@property (nonatomic, copy, readwrite) NSString *titleBackground;

- (instancetype)initFromDictionary: (NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
