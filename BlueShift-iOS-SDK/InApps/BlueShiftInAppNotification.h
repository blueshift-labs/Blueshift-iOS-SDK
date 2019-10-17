//
//  BlueShiftInAppNotification.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import <Foundation/Foundation.h>
#import "BlueShiftInAppType.h"
#import "InAppNotificationEntity.h"

NS_ASSUME_NONNULL_BEGIN

/* margin rect of the In-App UI */
@interface BlueShiftInAppLayoutMargin :  NSObject

@property (nonatomic, assign, readwrite) float left;
@property (nonatomic, assign, readwrite) float right;
@property (nonatomic, assign, readwrite) float top;
@property (nonatomic, assign, readwrite) float bottom;

@end

/* notification Layout (presentation details) */
@interface BlueShiftInAppNotificationLayout : NSObject

@property (nonatomic, copy, readwrite, nullable) NSString *backgroundColor;
@property (nonatomic, copy, readwrite, nullable) NSString *position;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float width;;
@property (nonatomic, assign, readwrite) BOOL enableBackgroundAction;
@property (nonatomic, readwrite) BlueShiftInAppLayoutMargin *margin;

@end

/* notification contentStyle */
@interface BlueShiftInAppNotificationContentStyle : NSObject

@property (nonatomic, copy, readwrite, nullable) NSString *titleColor;
@property (nonatomic, copy, readwrite, nullable) NSString *titleBackgroundColor;
@property (nonatomic, assign, readwrite, nullable) NSNumber *titleSize;
@property (nonatomic, copy, readwrite, nullable) NSString *messageColor;
@property (nonatomic, copy, readwrite, nullable) NSString *messageBackgroundColor;
@property (nonatomic, assign, readwrite, nullable) NSNumber *messageSize;
@property (nonatomic, copy, readwrite, nullable) NSString *messageAlign;
@property (nonatomic, copy, readwrite, nullable) NSString *titleGravity;
@property (nonatomic, copy, readwrite, nullable) NSString *messageGravity;
@property (nonatomic, assign, readwrite, nullable) NSNumber *iconSize;
@property (nonatomic, copy, readwrite, nullable) NSString *iconColor;
@property (nonatomic, copy, readwrite, nullable) NSString *iconBackgroundColor;
@property (nonatomic, assign, readwrite, nullable) NSNumber *iconBackgroundRadius;
@property (nonatomic, assign, readwrite, nullable) NSNumber *actionsOrientation;
@property (nonatomic, assign, readwrite, nullable) NSNumber *secondaryIconSize;
@property (nonatomic, copy, readwrite, nullable) NSString *secondaryIconColor;
@property (nonatomic, copy, readwrite, nullable) NSString *secondaryIconBackgroundColor;
@property (nonatomic, assign, readwrite, nullable) NSNumber *secondaryIconBackgroundRadius;
@property (nonatomic, readwrite) BlueShiftInAppLayoutMargin *actionsPadding;

@end

/* Notification button details */
@interface BlueShiftInAppNotificationButton : NSObject

@property (nonatomic, copy, readwrite, nullable) NSString *text;
@property (nonatomic, copy, readwrite, nullable) NSString *textColor;
@property (nonatomic, copy, readwrite, nullable) NSString *backgroundColor;
@property (nonatomic, copy, readwrite, nullable) NSString *iosLink;
@property (nonatomic, copy, readwrite, nullable) NSString *sharableText;
@property (nonatomic, copy, readwrite, nullable) NSString* buttonType;
@property (nonatomic, assign, readwrite, nullable) NSNumber *backgroundRadius;

- (NSDictionary *)convertObjectToDictionary:(BlueShiftInAppNotificationButton *)buttonDetails;

@end

/* notification content , either be html link/ html source / layout props */
@interface BlueShiftInAppNotificationContent : NSObject

@property (nonatomic, strong, readwrite, nullable) NSString *content;
@property (nonatomic, copy, readwrite, nullable) NSString *url;
@property (nonatomic, copy, readwrite, nullable) NSString *title;
@property (nonatomic, copy, readwrite, nullable) NSString *subTitle;
@property (nonatomic, copy, readwrite, nullable) NSString *message;
@property (nonatomic, copy, readwrite, nullable) NSString *icon;
@property (nonatomic, readwrite) NSMutableArray<BlueShiftInAppNotificationButton *>* actions;
@property (nonatomic, copy, readwrite, nullable) NSString *banner;
@property (nonatomic, copy, readwrite, nullable) NSString *secondarIcon;

/* configure In-App Entity */
- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType;

@end

@interface BlueShiftInAppNotification : NSObject


/* object Id of the record (entity) */
@property (nonatomic, readwrite, nullable) NSManagedObjectID* objectID;

/* type of in-app */
@property (nonatomic, readwrite) BlueShiftInAppType inAppType;

/* content of in-app notification msg*/
@property (nonatomic, strong, readwrite) BlueShiftInAppNotificationContent* notificationContent;
@property (nonatomic, assign, readwrite) NSString *position;

@property (nonatomic, copy, readwrite) NSString *dimensionType;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float width;

@property (nonatomic, readwrite) BOOL showCloseButton;
@property (nonatomic, assign, readwrite) long *expiresAt;
@property (nonatomic, copy, readwrite) NSString *trigger;
@property (nonatomic, readwrite) BlueShiftInAppNotificationLayout *templateStyle;
@property (nonatomic, readwrite) BlueShiftInAppNotificationContentStyle *contentStyle;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *notificationPayload;

- (instancetype)initFromEntity: (InAppNotificationEntity *) appEntity;

@end

NS_ASSUME_NONNULL_END
