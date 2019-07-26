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
        
            NSDictionary *contentDictionary = [payloadDictionary objectForKey:@"content"];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                    if ([contentDictionary objectForKey:@"html"]) {
                        self.content = (NSString*)[contentDictionary objectForKey:@"html"];
                    }
                    if ([contentDictionary objectForKey:@"url"]) {
                        self.url = (NSString*)[contentDictionary objectForKey:@"url"];
                    }
                    break;
                    
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                case BlueShiftNotificationSlideBanner:
                    if ([contentDictionary objectForKey:@"title"]) {
                        self.title = (NSString*)[contentDictionary objectForKey:@"title"];
                    }
                    if ([contentDictionary objectForKey:@"sub_title"]) {
                        self.subTitle = (NSString*)[contentDictionary objectForKey:@"sub_title"];
                    }
                    if ([contentDictionary objectForKey:@"message"]) {
                        self.message = (NSString*)[contentDictionary objectForKey:@"message"];
                    }
                    if ([contentDictionary objectForKey:@"background_image"]) {
                        self.backgroundImage = (NSString*)[contentDictionary objectForKey:@"background_image"];
                    }
                    if ([contentDictionary objectForKey:@"background_color"]) {
                        self.backgroundColor = (NSString*)[contentDictionary objectForKey:@"background_color"];
                    }
                    if ([contentDictionary objectForKey:@"icon"]) {
                        self.icon =(NSString *)[contentDictionary objectForKey:@"icon"];
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
            
            NSDictionary *templateStyleDictionary = [payloadDictionary objectForKey:@"template_style"];
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                case BlueShiftNotificationSlideBanner:
                    if ([templateStyleDictionary objectForKey:@"background_color"]) {
                        self.backgroundColor = (NSString *)[templateStyleDictionary objectForKey:@"background_color"];
                    }
                    if ([templateStyleDictionary objectForKey:@"position"]) {
                        self.position = (NSString *)[templateStyleDictionary objectForKey:@"position"];
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
            
            NSDictionary *contenStyletDictionary = [payloadDictionary objectForKey:@"content_style"];
        
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                case BlueShiftNotificationSlideBanner:
                    if ([contenStyletDictionary objectForKey:@"title_color"]) {
                        self.titleColor = (NSString *)[contenStyletDictionary objectForKey:@"title_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"title_background_color"]) {
                         self.titleBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:@"title_background_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"title_gravity"]) {
                        self.titleGravity = (NSString *)[contenStyletDictionary objectForKey:@"title_gravity"];
                    }
                    if ([contenStyletDictionary objectForKey:@"title_size"]) {
                        self.titleSize = (NSNumber *)[contenStyletDictionary objectForKey:@"title_size"];
                    }
                    if ([contenStyletDictionary objectForKey:@"message_color"]) {
                        self.messageColor = (NSString *)[contenStyletDictionary objectForKey:@"message_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"message_align"]) {
                        self.messageAlign = (NSString *)[contenStyletDictionary objectForKey:@"message_align"];
                    }
                    if ([contenStyletDictionary objectForKey:@"message_background_color"]) {
                        self.messageBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:@"message_background_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"message_gravity"]) {
                        self.messageGravity = (NSString *)[contenStyletDictionary objectForKey:@"message_gravity"];
                    }
                    if ([contenStyletDictionary objectForKey:@"message_size"]) {
                        self.messageSize = (NSNumber *)[contenStyletDictionary objectForKey:@"message_size"];
                    }
                    if ([contenStyletDictionary objectForKey:@"icon_size"]) {
                        self.iconSize = (NSNumber *)[contenStyletDictionary objectForKey:@"icon_size"];
                    }
                    if ([contenStyletDictionary objectForKey:@"icon_color"]) {
                        self.iconColor = (NSString *)[contenStyletDictionary objectForKey:@"icon_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"icon_background_color"]) {
                        self.iconBackgroundColor = (NSString *)[contenStyletDictionary objectForKey:@"icon_background_color"];
                    }
                    if ([contenStyletDictionary objectForKey:@"icon_background_radius"]){
                        self.iconBackgroundRadius = (NSNumber *)[contenStyletDictionary objectForKey:@"icon_background_radius"];
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

@implementation BlueShiftInAppNotificationButton

- (instancetype)initFromDictionary: (NSDictionary *) payloadDictionary withType: (BlueShiftInAppType)inAppType {
    if (self = [super init]) {
        
        @try {
            
            switch (inAppType) {
                case BlueShiftInAppTypeHTML:
                case BlueShiftInAppTypeModal:
                case BlueShiftInAppModalWithImage:
                case BlueShiftNotificationSlideBanner:
                    if ([payloadDictionary objectForKey:@"text"]) {
                        self.text = (NSString *)[payloadDictionary objectForKey:@"text"];
                    }
                    if ([payloadDictionary objectForKey:@"text_color"]) {
                        self.textColor = (NSString *)[payloadDictionary objectForKey:@"text_color"];
                    }
                    if ([payloadDictionary objectForKey:@"background_color"]) {
                        self.backgroundColor = (NSString *)[payloadDictionary objectForKey:@"background_color"];
                    }
                    if ([payloadDictionary objectForKey:@"page"]) {
                        self.page = (NSString *)[payloadDictionary objectForKey:@"page"];
                    }
                    if ([payloadDictionary objectForKey:@"extra"]) {
                        self.extra = [self initFromDictionary: [payloadDictionary objectForKey:@"extra"] withType: inAppType];
                    }
                    if ([payloadDictionary objectForKey:@"content"]) {
                        self.content = [self initFromDictionary: [payloadDictionary objectForKey:@"content"] withType: inAppType];
                    }
                    if ([payloadDictionary objectForKey:@"image"]) {
                        self.image = (NSString *)[payloadDictionary objectForKey:@"image"];
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
            
            NSDictionary *inAppDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:appEntity.payload];
            if ([inAppDictionary objectForKey:@"inapp"]) {
                NSDictionary *payloadDictionary = [inAppDictionary objectForKey:@"inapp"];
                
                self.notificationContent = [[BlueShiftInAppNotificationContent alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
                self.contentStyle = [[BlueShiftInAppNotificationContentStyle alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
                self.templateStyle = [[BlueShiftInAppNotificationLayout alloc] initFromDictionary:payloadDictionary withType: self.inAppType];
                
                if ([payloadDictionary valueForKeyPath:@"action.dismiss"]) {
                    self.dismiss = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.dismiss"] withType: self.inAppType];
                }
                if ([payloadDictionary valueForKeyPath:@"action.app_open"]) {
                    self.appOpen = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.app_open"] withType: self.inAppType];
                }
                if ([payloadDictionary valueForKeyPath:@"action.share"]) {
                    self.share = [[BlueShiftInAppNotificationButton alloc] initFromDictionary: [payloadDictionary valueForKeyPath:@"action.share"] withType: self.inAppType];
                }
                
                self.showCloseButton = YES;
                self.position = @"center";
                self.dimensionType = @"percentage";
                self.width = 100;
                self.height = 50;
                
            }
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

@end
