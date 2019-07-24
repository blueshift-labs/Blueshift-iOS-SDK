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



@implementation BlueShiftInAppNotification

- (instancetype)initFromEntity: (InAppNotificationEntity *) appEntity {
    
    if (self = [super init]) {
        @try {
            self.inAppType = [BlueShiftInAppNotificationHelper inAppTypeFromString: appEntity.type];
            
            NSDictionary *payloadDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:appEntity.payload];
            self.notificationContent = [[BlueShiftInAppNotificationContent alloc] initFromDictionary: payloadDictionary withType: self.inAppType];
            
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
