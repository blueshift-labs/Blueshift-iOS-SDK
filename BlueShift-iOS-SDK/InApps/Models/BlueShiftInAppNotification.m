//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "../BlueShiftInAppNotificationConstant.h"

@implementation BlueShiftInAppNotificationButton

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([payloadDictionary objectForKey: kInAppNotificationModalTextKey]) {
                        self.text = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalTextKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotiificationModalTextColorKey]) {
                        self.textColor = (NSString *)[payloadDictionary objectForKey: kInAppNotiificationModalTextColorKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalBackgroundColorKey]) {
                        self.backgroundColor = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalBackgroundColorKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalPageKey]) {
                        self.page = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalPageKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalExtraKey]) {
                        self.extra = [payloadDictionary objectForKey: kInAppNotificationModalExtraKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalContentKey]){
                        self.content = [payloadDictionary objectForKey: kInAppNotificationModalContentKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalImageKey]) {
                        self.image = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalImageKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalSharableTextKey]) {
                        self.sharableText = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalSharableTextKey];
                    }
                    
                    break;
                    
                default:
                    break;
            }
            
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

- (NSDictionary *)convertObjectToDictionary:(BlueShiftInAppNotificationButton *)buttonDetails {
    NSMutableDictionary *buttonDictionary = [[NSMutableDictionary alloc] init];
    if (buttonDetails) {
        [buttonDictionary setValue: buttonDetails.text  forKey: kInAppNotificationModalTextKey];
        [buttonDictionary setValue: buttonDetails.textColor forKey: kInAppNotiificationModalTextColorKey];
        [buttonDictionary setValue: buttonDetails.backgroundColor forKey: kInAppNotificationModalBackgroundColorKey];
        [buttonDictionary setValue: buttonDetails.page forKey: kInAppNotificationModalPageKey];
        [buttonDictionary setValue: buttonDetails.extra forKey: kInAppNotificationModalExtraKey];
        [buttonDictionary setValue: buttonDetails.content forKey: kInAppNotificationModalContentKey];
        [buttonDictionary setValue: buttonDetails.image forKey: kInAppNotificationModalImageKey];
        [buttonDictionary setValue: buttonDetails.sharableText forKey: kInAppNotificationModalSharableTextKey];
    }
    
    return buttonDictionary;
}

@end

@implementation BlueShiftInAppNotificationContent

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
        
            NSDictionary *contentDictionary = [payloadDictionary objectForKey: kInAppNotificationModalContentKey];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                    if ([contentDictionary objectForKey: kInAppNotificationModalHTMLKey]) {
                        self.content = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalHTMLKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalURLKey]) {
                        self.url = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalURLKey];
                    }
                    break;
                    
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([contentDictionary objectForKey: kInAppNotificationModalTitleKey]) {
                        self.title = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalTitleKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalSubTitleKey]) {
                        self.subTitle = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalSubTitleKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalMessageKey]) {
                        self.message = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalMessageKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalBackgroundImageKey]) {
                        self.backgroundImage = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalBackgroundImageKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalBackgroundColorKey]) {
                        self.backgroundColor = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalBackgroundColorKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalIconKey]) {
                        self.icon =(NSString *)[contentDictionary objectForKey: kInAppNotificationModalIconKey];
                    }

                    if ([contentDictionary objectForKey: kInAppNotificationActionButtonKey]) {
                        NSDictionary *actionButtonDictionary = [contentDictionary objectForKey: kInAppNotificationActionButtonKey];
                        NSMutableArray<BlueShiftInAppNotificationButton *> *actions = [[NSMutableArray alloc] init];
                        for(id key in actionButtonDictionary){
                            [actions addObject:[[BlueShiftInAppNotificationButton alloc] initFromDictionary:[actionButtonDictionary objectForKey: key] withType: inAppType]];
                        }
                        
                        self.actions = actions;
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalBannerKey]) {
                        self.banner = (NSString *)[contentDictionary objectForKey:kInAppNotificationModalBannerKey];
                    }

                    break;
                    
                default:
                    break; 
            }
            
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end

@implementation BlueShiftInAppNotificationLayout

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            NSDictionary *templateStyleDictionary = [payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleKey];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundColorKey]) {
                        self.backgroundColor = (NSString *)[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundColorKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalPositionKey]) {
                        self.position = (NSString *)[templateStyleDictionary objectForKey: kInAppNotificationModalPositionKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalWidthKey]) {
                        self.width = [[templateStyleDictionary objectForKey: kInAppNotificationModalWidthKey]
                                     floatValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalHeightKey]) {
                        self.height = [[templateStyleDictionary objectForKey: kInAppNotificationModalHeightKey] floatValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalFullScreenKey]) {
                        self.fullScreen = [[templateStyleDictionary objectForKey: kInAppNotificationModalFullScreenKey] boolValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundActionKey]) {
                        self.enableBackgroundAction = [[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundActionKey] boolValue];
                    }
                    
                    break;
                    
                default:
                    break;
            }
            
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end

@implementation BlueShiftInAppNotificationContentStyle

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            NSDictionary *contenStyletDictionary = [payloadDictionary objectForKey: kInAppNotificationModalContentStyleKey];
    
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleColorKey]) {
                        self.titleColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleBackgroundColorKey]) {
                         self.titleBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleGravityKey]) {
                        self.titleGravity = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleGravityKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleSizeKey]) {
                        self.titleSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageColorKey]) {
                        self.messageColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageAlignKey]) {
                        self.messageAlign = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageAlignKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageBackgroundColorKey]) {
                        self.messageBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageGravityKey]) {
                        self.messageGravity = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageGravityKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageSizeKey]) {
                        self.messageSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey:kInAppNotificationModalIconSizeKey]) {
                        self.iconSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconColorKey]) {
                        self.iconColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundColorKey]) {
                        self.iconBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundRadiusKey]){
                        self.iconBackgroundRadius = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundRadiusKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalActionsOrientationKey]) {
                        self.actionsOrientation =(NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalActionsOrientationKey];
                    }
                    
                    break;
                    
                default:
                    break;
            }
            
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end

@implementation BlueShiftInAppNotification

- (instancetype)initFromEntity: (InAppNotificationEntity *) appEntity {
    
    if (self = [super init]) {
        @try {
            self.inAppType = [BlueShiftInAppNotificationHelper inAppTypeFromString: appEntity.type];
            
            self.objectID = appEntity.objectID;
            
            NSDictionary *inAppDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:appEntity.payload];
            if ([inAppDictionary objectForKey: kInAppNotificationKey]) {
                NSDictionary *payloadDictionary = [[NSDictionary alloc] init];
                payloadDictionary = [inAppDictionary objectForKey:@"inapp"];
                
                self.notificationPayload = [inAppDictionary objectForKey:@"inapp"];
                self.notificationContent = [[BlueShiftInAppNotificationContent alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
                
                self.contentStyle = [[BlueShiftInAppNotificationContentStyle alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
                
                self.templateStyle = [[BlueShiftInAppNotificationLayout alloc] initFromDictionary:payloadDictionary withType: self.inAppType];
                
                self.showCloseButton = YES;
                self.position = kInAppNotificationModalPositionCenterKey;
                self.dimensionType = kInAppNotificationModalResolutionPercntageKey;
                self.width = 90;
                self.height = 90;
                
            }
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end
