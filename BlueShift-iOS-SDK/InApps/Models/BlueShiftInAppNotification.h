//
//  BlueShiftInAppNotification.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"
#import "InAppNotificationEntity.h"
#import "BlueShiftNotificationLabel.h"
#import "BlueshiftNotificationButton.h"

NS_ASSUME_NONNULL_BEGIN

/* notification content , either be html link/ html source / layout props */
@interface BlueShiftInAppNotificationContent : NSObject

@property (nonatomic, strong, readwrite, nullable) NSString *content;
@property (nonatomic, copy, readwrite, nullable) NSString *url;

@property (nonatomic, copy, readwrite, nullable) NSString *title;
@property (nonatomic, copy, readwrite, nullable) NSString *subTitle;
@property (nonatomic, copy, readwrite, nullable) NSString *descriptionText;
@property (nonatomic, copy, readwrite, nullable) NSString *backgroundImage;
@property (nonatomic, copy, readwrite, nullable) NSString *backgroundColor;

/* configure In-App Entity */
- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType;
@end





/* notification Layout (presentation details) */
@interface BlueShiftInAppNotificationLayout : NSObject

/* margin rect of the In-App UI */
@property (nonatomic, assign, readwrite, nullable) Rect *margin;

@end







@interface BlueShiftInAppNotification : NSObject

/* type of in-app */
@property (nonatomic, readwrite) BlueShiftInAppType inAppType;

/* content of in-app notification msg*/
@property (nonatomic, strong, readwrite) BlueShiftInAppNotificationContent* notificationContent;


@property (nonatomic, assign, readwrite) NSString *position;

@property (nonatomic, copy, readwrite) NSString *dimensionType;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float width;

@property (nonatomic, readwrite) BOOL showCloseButton;

- (instancetype)initFromEntity: (InAppNotificationEntity *) appEntity;

@property (nonatomic, assign, readwrite) long *expiresAt;
@property (nonatomic, copy, readwrite) NSString *trigger;
@property (nonatomic, readwrite) BlueShiftNotificationLabel *contentStyle;
@property (nonatomic, readwrite) BlueShiftNotificationLabel *content;
@property (nonatomic, readwrite) BlueshiftNotificationButton *dismiss;
@property (nonatomic, readwrite) BlueshiftNotificationButton *appOpen;
@property (nonatomic, readwrite) BlueshiftNotificationButton *share;

@end

NS_ASSUME_NONNULL_END
