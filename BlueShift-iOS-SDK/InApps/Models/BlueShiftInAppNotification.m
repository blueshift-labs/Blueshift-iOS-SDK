//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"

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
    self.html = [dictionary objectForKey:@"html"];
    self.title = [dictionary objectForKey:@"title"];
    self.subTitle = [dictionary objectForKey:@"subTitle"];
    self.descriptionText = [dictionary objectForKey:@"description"];
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
}

@end
