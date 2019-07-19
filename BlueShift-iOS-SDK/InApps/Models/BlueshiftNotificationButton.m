//
//  BlueshiftNotificationButton.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal Subair on 19/07/19.
//

#import "BlueshiftNotificationButton.h"

@implementation BlueshiftNotificationButton

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"text"]) {
        self.title = [dictionary objectForKey:@"text"];
    }
    if ([dictionary objectForKey:@"text_color"]) {
        self.textColor = [dictionary objectForKey:@"text_color"];
    }
    if ([dictionary objectForKey:@"background_color"]) {
        self.backgroundColor = [dictionary objectForKey:@"background_color"];
    }
    if ([dictionary objectForKey:@"page"]) {
        self.page = [dictionary objectForKey:@"page"];
    }
    if ([dictionary objectForKey:@"extras"]) {
        self.extra = [self initFromDictionary:[dictionary objectForKey:@"extras"]];
    }
    if ([dictionary objectForKey:@"content"]) {
        self.content = [self initFromDictionary:[dictionary objectForKey:@"content"]];
    }
    if ([dictionary objectForKey:@"image"]) {
        self.image = [dictionary objectForKey:@"image"];
    }
    
    return self;
}

@end
