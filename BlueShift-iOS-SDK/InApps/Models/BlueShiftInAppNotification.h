//
//  BlueShiftInAppNotification.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"
#import "BlueShiftNotificationLabel.h"
#import "BlueshiftNotificationButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlueShiftInAppNotification : NSObject

@property (nonatomic, readwrite) BlueShiftInAppType inAppType;

@property (nonatomic, copy, readwrite) NSString *html;
@property (nonatomic, copy, readwrite) NSString *url;

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subTitle;
@property (nonatomic, copy, readwrite) NSString *descriptionText;

@property (nonatomic, assign, readwrite) NSString *position;

@property (nonatomic, readwrite) BOOL shadowBackground;

@property (nonatomic, copy, readwrite) NSString *dimensionType;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float width;

@property (nonatomic, readwrite) BOOL showCloseButton;

@property (nonatomic, assign, readwrite) long *expiresAt;
@property (nonatomic, copy, readwrite) NSString *trigger;
@property (nonatomic, readwrite) BlueShiftNotificationLabel *contentStyle;
@property (nonatomic, readwrite) BlueShiftNotificationLabel *content;
@property (nonatomic, readwrite) BlueshiftNotificationButton *dismiss;
@property (nonatomic, readwrite) BlueshiftNotificationButton *appOpen;
@property (nonatomic, readwrite) BlueshiftNotificationButton *share;


- (instancetype)initFromDictionary:(NSDictionary *)dictionary;
- (void)configureFromDictionary: (NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
