//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftInAppNotificationConstant.h"

@implementation BlueShiftInAppNotificationButton

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([payloadDictionary objectForKey: kInAppNotificationModalTextKey] && [payloadDictionary objectForKey: kInAppNotificationModalTextKey] != [NSNull null]) {
                        self.text = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalTextKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotiificationModalTextColorKey] &&
                        [payloadDictionary objectForKey: kInAppNotiificationModalTextColorKey] != [NSNull null]) {
                        self.textColor = (NSString *)[payloadDictionary objectForKey: kInAppNotiificationModalTextColorKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalBackgroundColorKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalBackgroundColorKey] != [NSNull null]) {
                        self.backgroundColor = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalBackgroundColorKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalPageKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalPageKey] != [NSNull null]) {
                        self.iosLink = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalPageKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalSharableTextKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalSharableTextKey] != [NSNull null]) {
                        self.sharableText = (NSString *)[payloadDictionary objectForKey: kInAppNotificationModalSharableTextKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationButtonTypeKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationButtonTypeKey] != [NSNull null]) {
                        self.buttonType = (NSString *) [payloadDictionary objectForKey: kInAppNotificationButtonTypeKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey] != [NSNull null]) {
                        self.backgroundRadius = (NSNumber *)[payloadDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey];
                    }
                    if ([payloadDictionary objectForKey: kInAppNotificationModalTextSizeKey] && [payloadDictionary objectForKey: kInAppNotificationModalTextSizeKey] != [NSNull null]) {
                        self.textSize = (NSNumber *)[payloadDictionary objectForKey: kInAppNotificationModalTextSizeKey];
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


@implementation BlueShiftInAppNotificationContent

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
        
            NSDictionary *contentDictionary = [payloadDictionary objectForKey: kInAppNotificationModalContentKey];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                    if ([contentDictionary objectForKey: kInAppNotificationModalHTMLKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalHTMLKey] != [NSNull null]) {
                        self.content = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalHTMLKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalURLKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalURLKey] != [NSNull null]) {
                        self.url = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalURLKey];
                    }
                    break;
                    
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([contentDictionary objectForKey: kInAppNotificationModalTitleKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalTitleKey] != [NSNull null]) {
                        self.title = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalTitleKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalSubTitleKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalSubTitleKey] != [NSNull null]) {
                        self.subTitle = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalSubTitleKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalMessageKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalMessageKey] != [NSNull null]) {
                        self.message = (NSString*)[contentDictionary objectForKey: kInAppNotificationModalMessageKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalIconKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalIconKey] != [NSNull null]) {
                        self.icon =(NSString *)[contentDictionary objectForKey: kInAppNotificationModalIconKey];
                    }

                    if ([contentDictionary objectForKey: kInAppNotificationActionButtonKey]) {
                        NSMutableArray<BlueShiftInAppNotificationButton *> *actions = [[NSMutableArray alloc] init];
                        for(NSDictionary* button in [contentDictionary objectForKey: kInAppNotificationActionButtonKey]){
                            [actions addObject:[[BlueShiftInAppNotificationButton alloc] initFromDictionary: button withType: inAppType]];
                        }
                        
                        self.actions = actions;
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalBannerKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalBannerKey] != [NSNull null]) {
                        self.banner = (NSString *)[contentDictionary objectForKey: kInAppNotificationModalBannerKey];
                    }
                    if ([contentDictionary objectForKey: kInAppNotificationModalSecondaryIconKey] &&
                        [contentDictionary objectForKey: kInAppNotificationModalSecondaryIconKey] != [NSNull null]) {
                        self.secondarIcon = (NSString *)[contentDictionary objectForKey: kInAppNotificationModalSecondaryIconKey];
                    }
                    
                    if ([contentDictionary objectForKey: kInAppNotificationModalIconImageKey] && [contentDictionary objectForKey: kInAppNotificationModalIconImageKey] != [NSNull null]) {
                        self.iconImage = (NSString *)[contentDictionary objectForKey: kInAppNotificationModalIconImageKey];
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


@implementation BlueShiftInAppLayoutMargin

- (instancetype)initFromDictionary: (NSDictionary *)marginDictionary {
    if (self = [super init]) {
        @try {
            if([marginDictionary objectForKey: kInAppNotificationModalLayoutMarginTopKey] &&
               [marginDictionary objectForKey: kInAppNotificationModalLayoutMarginTopKey] != [NSNull null]){
                self.top = [[marginDictionary objectForKey: kInAppNotificationModalLayoutMarginTopKey] floatValue];
            }
            if ([marginDictionary objectForKey: kInAppNotificationModalLayoutMarginBottomKey] &&
                [marginDictionary objectForKey: kInAppNotificationModalLayoutMarginBottomKey] != [NSNull null]) {
                self.bottom = [[marginDictionary objectForKey: kInAppNotificationModalLayoutMarginBottomKey] floatValue];
            }
            if ([marginDictionary objectForKey: kInAppNotificationModalLayoutMarginLeftKey] &&
                [marginDictionary objectForKey: kInAppNotificationModalLayoutMarginLeftKey] != [NSNull null]) {
                self.left = [[marginDictionary objectForKey: kInAppNotificationModalLayoutMarginLeftKey] floatValue];
            }
            if ([marginDictionary objectForKey: kInAppNotificationModalLayoutMarginRightKey] &&
                [marginDictionary objectForKey: kInAppNotificationModalLayoutMarginRightKey] != [NSNull null]) {
                self.right = [[marginDictionary objectForKey: kInAppNotificationModalLayoutMarginRightKey] floatValue];
            }
        } @catch (NSException *e) {
            
        }
    }
    
    return self;
}


@end


@implementation BlueShiftInAppNotificationLayout

- (instancetype)initFromDictionary: (NSDictionary *)templateStyleDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundColorKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundColorKey] != [NSNull null]) {
                        self.backgroundColor = (NSString *)[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundColorKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalPositionKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalPositionKey] != [NSNull null]) {
                        self.position = (NSString *)[templateStyleDictionary objectForKey: kInAppNotificationModalPositionKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalWidthKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalWidthKey] != [NSNull null]) {
                        self.width = [[templateStyleDictionary objectForKey: kInAppNotificationModalWidthKey]
                                     floatValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalHeightKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalHeightKey] != [NSNull null]) {
                        self.height = [[templateStyleDictionary objectForKey: kInAppNotificationModalHeightKey] floatValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundActionKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundActionKey] != [NSNull null]){
                        self.enableBackgroundAction = [[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundActionKey] boolValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalLayoutMarginKey]) {
                        NSDictionary *marginDictionary = [templateStyleDictionary objectForKey: kInAppNotificationModalLayoutMarginKey];
                        self.margin = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary :marginDictionary];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundImageKey] && [templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundImageKey] != [NSNull null]) {
                        self.backgroundImage = (NSString *)[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundImageKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalEnableCloseButtonKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalEnableCloseButtonKey] != [NSNull null]){
                        self.enableCloseButton = [[templateStyleDictionary objectForKey: kInAppNotificationModalEnableCloseButtonKey] boolValue];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey] &&
                        [templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey] != [NSNull null]) {
                        self.backgroundRadius = (NSNumber *)[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundRadiusKey];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalCloseButtonKey] && [templateStyleDictionary objectForKey: kInAppNotificationModalCloseButtonKey] != [NSNull null]) {
                        NSDictionary *closeButtonPayload = [templateStyleDictionary objectForKey: kInAppNotificationModalCloseButtonKey];
                        self.closeButton =  [[BlueShiftInAppNotificationButton alloc] initFromDictionary: closeButtonPayload withType: inAppType];
                    }
                    if ([templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundDimAmountKey] && [templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundDimAmountKey] != [NSNull null]) {
                        self.backgroundDimAmount = (NSNumber *)[templateStyleDictionary objectForKey: kInAppNotificationModalBackgroundDimAmountKey];
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

- (instancetype)initFromDictionary: (NSDictionary *) contenStyletDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftNotificationSlideBanner:
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalTitleColorKey] != [NSNull null]) {
                        self.titleColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleBackgroundColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalTitleBackgroundColorKey] != [NSNull null]) {
                         self.titleBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleGravityKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalTitleGravityKey] != [NSNull null]) {
                        self.titleGravity = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleGravityKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitleSizeKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalTitleSizeKey] != [NSNull null]) {
                        self.titleSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalTitleSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessageColorKey] != [NSNull null]) {
                        self.messageColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageAlignKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessageAlignKey] != [NSNull null]) {
                        self.messageAlign = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageAlignKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageBackgroundColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessageBackgroundColorKey] != [NSNull null]) {
                        self.messageBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageGravityKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessageGravityKey] != [NSNull null]) {
                        self.messageGravity = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageGravityKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessageSizeKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessageSizeKey] != [NSNull null]) {
                        self.messageSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalMessageSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey:kInAppNotificationModalIconSizeKey] &&
                        [contenStyletDictionary objectForKey:kInAppNotificationModalIconSizeKey] != [NSNull null]) {
                        self.iconSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalIconColorKey] != [NSNull null]) {
                        self.iconColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundColorKey] != [NSNull null]) {
                        self.iconBackgroundColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundRadiusKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundRadiusKey] != [NSNull null]){
                        self.iconBackgroundRadius = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalIconBackgroundRadiusKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalActionsOrientationKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalActionsOrientationKey] != [NSNull null]) {
                        self.actionsOrientation =(NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalActionsOrientationKey];
                    }
                    if ([contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconSizeKey] &&
                        [contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconSizeKey] != [NSNull null]) {
                        self.secondaryIconSize = (NSNumber *)[contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconSizeKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconColorKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconColorKey] != [NSNull null]) {
                        self.secondaryIconColor = (NSString *)[contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconColorKey];
                    }
                    if ([contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconBackgroundColorKey] &&
                        [contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconBackgroundColorKey] != [NSNull null]) {
                        self.secondaryIconBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconBackgroundColorKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconRadiusKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalSecondaryIconRadiusKey] != [NSNull null]) {
                        self.secondaryIconBackgroundRadius = (NSNumber *)[contenStyletDictionary objectForKey:kInAppNotificationModalSecondaryIconRadiusKey];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalActionsPaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalActionsPaddingKey] != [NSNull null]) {
                        NSDictionary *marginDictionary = [contenStyletDictionary objectForKey: kInAppNotificationModalActionsPaddingKey];
                        self.actionsPadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary :marginDictionary];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconPaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalIconPaddingKey] != [NSNull null]) {
                        NSDictionary *iconPadding = [contenStyletDictionary objectForKey: kInAppNotificationModalIconPaddingKey];
                        self.iconPadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary: iconPadding];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalTitlePaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalTitlePaddingKey] != [NSNull null]) {
                        NSDictionary *titlePadding = [contenStyletDictionary objectForKey: kInAppNotificationModalTitlePaddingKey];
                        self.titlePadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary:titlePadding];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalMessagePaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalMessagePaddingKey] != [NSNull null]) {
                        NSDictionary *messagePadding = [contenStyletDictionary objectForKey: kInAppNotificationModalMessagePaddingKey];
                        self.messagePadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary: messagePadding];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalBannerPaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalBannerPaddingKey] != [NSNull null] ) {
                        NSDictionary *bannerPadding = [contenStyletDictionary objectForKey: kInAppNotificationModalBannerPaddingKey];
                        self.bannerPadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary:bannerPadding];
                    }
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalSubTitlePaddingKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalSubTitlePaddingKey] != [NSNull null]) {
                        NSDictionary *subTitlePadding = [contenStyletDictionary objectForKey: kInAppNotificationModalSubTitlePaddingKey];
                        self.subTitlePadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary: subTitlePadding];
                    }
                    
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconImagePaddingKey] && [contenStyletDictionary objectForKey: kInAppNotificationModalIconImagePaddingKey] != [NSNull null]) {
                        NSDictionary *iconImagePadding = [contenStyletDictionary objectForKey: kInAppNotificationModalIconImagePaddingKey];
                        self.iconImagePadding = [[BlueShiftInAppLayoutMargin alloc] initFromDictionary: iconImagePadding];
                    }
                    
                    if ([contenStyletDictionary objectForKey: kInAppNotificationModalIconImageBackgroundColorKey] && [contenStyletDictionary objectForKey: kInAppNotificationModalIconImageBackgroundColorKey] != [NSNull null]) {
                        self.iconImageBackgroundColor = (NSString *) [contenStyletDictionary objectForKey: kInAppNotificationModalIconImageBackgroundColorKey];
                    }
                    
                    if ([contenStyletDictionary objectForKey:kInAppNotificationModalIconImageBackgroundRadiusKey] &&
                        [contenStyletDictionary objectForKey: kInAppNotificationModalIconImageBackgroundRadiusKey] != [NSNull null]) {
                        self.iconImageBackgroundRadius =(NSNumber *)[contenStyletDictionary objectForKey:kInAppNotificationModalIconImageBackgroundRadiusKey];
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
            
            NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:appEntity.payload];
            if ([dictionary objectForKey: kInAppNotificationDataKey]) {
                self.notificationPayload = dictionary;
                NSDictionary *inAppDictionary = [dictionary objectForKey: kInAppNotificationDataKey];
    
                if ([inAppDictionary objectForKey: kInAppNotificationKey]) {
                    NSDictionary *payloadDictionary = [[NSDictionary alloc] init];
                    payloadDictionary = [inAppDictionary objectForKey:@"inapp"];
                
                    self.notificationContent = [[BlueShiftInAppNotificationContent alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
                
                    if ([payloadDictionary objectForKey: kInAppNotificationModalContentStyleKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalContentStyleKey] != [NSNull null]) {
                        NSDictionary *contenStyletDictionary = [payloadDictionary objectForKey: kInAppNotificationModalContentStyleKey];
                        self.contentStyle = [[BlueShiftInAppNotificationContentStyle alloc] initFromDictionary: contenStyletDictionary withType: self.inAppType];
                    }
                    
                    if ([payloadDictionary objectForKey: kInAppNotificationModalContentStyleDarkKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalContentStyleDarkKey] != [NSNull null]) {
                        NSDictionary *contentStyleDarkDictionary = [payloadDictionary objectForKey: kInAppNotificationModalContentStyleDarkKey];
                        self.contentStyleDark = [[BlueShiftInAppNotificationContentStyle alloc] initFromDictionary: contentStyleDarkDictionary withType: self.inAppType];
                    }
                
                    if ([payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleKey] != [NSNull null]) {
                        NSDictionary *templateStyleDictionary = [payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleKey];
                        self.templateStyle = [[BlueShiftInAppNotificationLayout alloc] initFromDictionary: templateStyleDictionary withType: self.inAppType];
                    }
                    
                    if ([payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleDarkKey] &&
                        [payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleDarkKey] != [NSNull null]){
                        NSDictionary *templateStyleDarkDictionary = [payloadDictionary objectForKey: kInAppNotificationModalTemplateStyleDarkKey];
                        self.templateStyleDark = [[BlueShiftInAppNotificationLayout alloc] initFromDictionary:templateStyleDarkDictionary withType:self.inAppType];
                    }
                    
                    self.position = kInAppNotificationModalPositionCenterKey;
                    self.dimensionType = kInAppNotificationModalResolutionPercntageKey;
                    self.width = 100;
                    self.height = 100;
                
                }
            }
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end
