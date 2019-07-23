//
//  BlueShiftInAppNotification.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 10/07/19.
//

#import "BlueShiftInAppNotification.h"
#import "BlueShiftInAppNotificationHelper.h"
#import "BlueShiftNotificationLabel.h"

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
                    self.subTitle = (NSString*)[contentDictionary objectForKey:@"subTitle"];
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
