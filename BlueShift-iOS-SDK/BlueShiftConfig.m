//
//  BlueShiftConfig.m
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftConfig.h"
#import "BlueshiftLog.h"
#import <objc/runtime.h>

@implementation BlueShiftConfig

- (id)init {
    self = [super init];
    if (self) {
        self.enablePushNotification = YES;
        self.enableLocationAccess = YES;
        self.enableAnalytics = YES;
        self.enableAppOpenTrackEvent = YES;
        
        self.debug = NO;
        
        //In App
        self.enableInAppNotification = NO;
        self.inAppBackgroundFetchEnabled = YES;
        self.inAppManualTriggerEnabled = NO;
        
        //Default BlueshiftDeviceIdSource
        self.blueshiftDeviceIdSource = BlueshiftDeviceIdSourceIDFV;
        
        if (@available(iOS 13.0, *)) {
            self.isSceneDelegateConfiguration = NO;
        }
        
        self.enableIDFACollection = YES;
    }
    return self;
}

+ (BlueShiftConfig *)config {
    return [[BlueShiftConfig alloc] init];
}

- (BOOL)validateConfigDetails {
    BOOL status = YES;
    
    if (self.apiKey == NULL || self.apiKey == nil) {
        status = NO;
        [BlueshiftLog logError:nil withDescription:@"SDK initialization failed! Please set a valid API key inside the Blueshift config to initialize the SDK." methodName:nil];
    }
    
    return status;
}

- (NSString*_Nullable)getConfigStringToLog {
    unsigned int numberOfProperties = 0;
    NSString *configString = @"";
    objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
    for (NSUInteger i = 0; i < numberOfProperties; i++) {
        objc_property_t property = propertyArray[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
        configString = [NSString stringWithFormat:@"%@ %@ : %@\n", configString, name, [self valueForKey:name]];
    }
    free(propertyArray);
    return configString;
}

@end
