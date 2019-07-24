//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"

@implementation BlueShiftInAppNotificationContent

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            NSDictionary *inAppDictionary = [payloadDictionary objectForKey:@"inapp"];
            NSDictionary *contentDictionary = [inAppDictionary objectForKey:@"content"];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                    self.content = (NSString*)[contentDictionary objectForKey:@"html"];
                    self.url = (NSString*)[contentDictionary objectForKey:@"url"];
                    break;
                    
                case BlueShiftInAppTypeModal:
                    self.title = (NSString*)[contentDictionary objectForKey:@"title"];
                    self.subTitle = (NSString*)[contentDictionary objectForKey:@"sub_title"];
                    self.message = (NSString*)[contentDictionary objectForKey:@"message"];
                    self.backgroundImage = (NSString*)[contentDictionary objectForKey:@"background_image"];
                    self.backgroundColor = (NSString*)[contentDictionary objectForKey:@"background_color"];

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
            
            NSDictionary *contenStyletDictionary = [payloadDictionary objectForKey:@"content_style"];
        
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                    self.titleColor = (NSString *)[contenStyletDictionary objectForKey:@"title_color"];
                    self.titleBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:@"title_background_color"];
                    self.titleGravity = (NSString *)[contenStyletDictionary objectForKey:@"title_gravity"];
                    self.titleSize = (NSNumber *)[contenStyletDictionary objectForKey:@"title_size"];
                    self.messageColor = (NSString *)[contenStyletDictionary objectForKey:@"message_color"];
                    self.messageAlign = (NSString *)[contenStyletDictionary objectForKey:@"message_align"];
                    self.messageBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:@"message_background_color"];
                    self.messageGravity = (NSString *)[contenStyletDictionary objectForKey:@"message_gravity"];
                    self.messageSize = (NSNumber *)[contenStyletDictionary objectForKey:@"message_size"];
                    
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

@implementation BlueShiftInAppNotificationButton

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                    self.text = (NSString *)[payloadDictionary objectForKey:@"text"];
                    self.textColor = (NSString *)[payloadDictionary objectForKey:@"text_color"];
                    self.backgroundColor = (NSString *)[payloadDictionary objectForKey:@"background_color"];
                    self.page = (NSString *)[payloadDictionary objectForKey:@"page"];
                    self.extra = [self initFromDictionary: [payloadDictionary objectForKey:@"extra"] withType: inAppType];
                    self.content = [self initFromDictionary: [payloadDictionary objectForKey:@"content"] withType: inAppType];
                    self.image = (NSString *)[payloadDictionary objectForKey:@"image"];
                    
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
            
            NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:appEntity.payload];
            self.notificationContent = [[BlueShiftInAppNotificationContent alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
            self.contentStyle = [[BlueShiftInAppNotificationContentStyle alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
            self.dismiss = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.dismiss"] withType: self.inAppType];
            self.appOpen = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.app_open"] withType: self.inAppType];
            self.share = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.share"] withType: self.inAppType];
            self.showCloseButton = YES;
            self.position = @"center";
            self.dimensionType = @"percentage";
            
            self.width = 90;
            self.height = 50;
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end
