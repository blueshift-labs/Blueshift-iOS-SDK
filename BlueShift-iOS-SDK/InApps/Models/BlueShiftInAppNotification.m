//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftNotificationLabel.h"

@implementation BlueShiftInAppNotification


- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        @try {
            self.inAppType = BlueShiftInAppDefault;
            self.showCloseButton = YES;
            self.shadowBackground = NO;
            self.position = @"center";
            self.dimensionType = @"percentage";
            self.width = 90;
            self.height = 50;
        } @catch (NSException *e) {
            
        }
    }
    return self;
}

- (void)configureFromDictionary: (NSDictionary *)dictionary {
    self.inAppType =  [BlueShiftInAppNotificationHelper inAppTypeFromString:[dictionary objectForKey:@"type"]];
    if ([dictionary objectForKey:@"html"]) {
        self.html = [dictionary objectForKey:@"html"];
    }
    if ([dictionary objectForKey:@"title"]) {
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"subTitle"]) {
        self.subTitle = [dictionary objectForKey:@"subTitle"];
    }
    if ([dictionary objectForKey:@"description"]) {
        self.descriptionText = [dictionary objectForKey:@"description"];
    }
    if([dictionary objectForKey:@"width"]) {
        self.width = [[dictionary objectForKey:@"width"] floatValue];
    }
    if([dictionary objectForKey:@"height"]) {
        self.height = [[dictionary objectForKey:@"height"] floatValue];
    }
    if([dictionary objectForKey:@"position"]) {
        self.position = [dictionary objectForKey:@"position"];
    }
    if([dictionary objectForKey:@"dimension_type"]) {
        self.dimensionType = [dictionary objectForKey:@"dimension_type"];
    }
    if([dictionary objectForKey:@"shadow_backround"]) {
        self.shadowBackground = [dictionary objectForKey:@"shadow_backround"];
    }
    if([dictionary objectForKey:@"show_close_button"]) {
        self.showCloseButton = [dictionary objectForKey:@"show_close_button"];
    }
    if ([dictionary objectForKey:@"trigger"]) {
        self.trigger = [dictionary objectForKey:@"trigger"];
    }
    if ([dictionary objectForKey:@"content_style"]) {
        self.contentStyle = [[BlueShiftNotificationLabel alloc] initFromDictionary:[dictionary objectForKey:@"content_style"]];
    }
    if ([dictionary objectForKey:@"content"]) {
        self.content = [[BlueShiftNotificationLabel alloc] initFromDictionary:[dictionary objectForKey:@"content"]];
    }
    if ([dictionary objectForKey:@"action"]) {
        if ([dictionary valueForKeyPath:@"action.dismiss"]) {
            self.dismiss = [[BlueshiftNotificationButton alloc] initFromDictionary:[dictionary valueForKeyPath:@"action.dismiss"]];
        }
        if ([dictionary valueForKeyPath:@"action.app_open"]) {
            self.appOpen = [[BlueshiftNotificationButton alloc] initFromDictionary:[dictionary valueForKeyPath:@"action.app_open"]];
        }
        if ([dictionary valueForKeyPath:@"action.share"]) {
            self.share = [[BlueshiftNotificationButton alloc] initFromDictionary:[dictionary valueForKeyPath:@"action.share"]];
        }
    }
}

@end
