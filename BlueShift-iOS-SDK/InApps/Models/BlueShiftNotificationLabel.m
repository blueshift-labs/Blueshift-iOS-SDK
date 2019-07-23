//
//  BlueShiftNotificationLabel.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 18/07/19.
//

#import "BlueShiftNotificationLabel.h"

@implementation BlueShiftNotificationLabel

- (instancetype)initFromDictionary: (NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"title"]) {
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"title_color"]) {
        self.titleColor = [dictionary objectForKey:@"title_color"];
    }
    if ([dictionary objectForKey:@"title_background_color"]) {
        self.titleBackgroundColor = [dictionary objectForKey:@"title_background_color"];
    }
    if ([dictionary objectForKey:@"message"]) {
        self.message = [dictionary objectForKey:@"message"];
    }
    if ([dictionary objectForKey:@"message_color"]) {
        self.messageColor = [dictionary objectForKey:@"message_color"];
    }
    if ([dictionary objectForKey:@"message_background_color"]) {
        self.messageBackgroundColor = [dictionary objectForKey:@"message_background_color"];
    }
    if ([dictionary objectForKey:@"message_align"]) {
        self.messageAlign = [dictionary objectForKey:@"message_align"];
    }
    if ([dictionary objectForKey:@"background_image"]) {
        self.backgroundImage = [dictionary objectForKey:@"background_image"];
    }
    if ([dictionary objectForKey:@"background_color"]) {
        self.backgroundColor = [dictionary objectForKey:@"background_color"];
    }
    if ([dictionary objectForKey:@"title_size"]) {
        self.titleSize = [dictionary objectForKey:@"title_size"];
    }
    if ([dictionary objectForKey:@"message_size"]) {
        self.messageSize = [dictionary objectForKey:@"message_size"];
    }
    if ([dictionary objectForKey:@"title_background"]) {
        self.titleBackground = [dictionary objectForKey:@"title_background"];
    }
    
    return self;
}

@end
