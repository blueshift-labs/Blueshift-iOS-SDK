//
//  BlueShiftConfig.m
//  BlueShiftiOSSDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftConfig.h"
#import "BlueshiftLog.h"
#import <objc/runtime.h>
#import "BlueshiftConstants.h"

@implementation BlueShiftConfig

- (id)init {
    self = [super init];
    if (self) {
        // Remote notifications
        self.enableSilentPushNotification = YES;
        self.enablePushNotification = YES;
                
        // App open
        self.enableAppOpenTrackEvent = false;
        self.automaticAppOpenTimeInterval = 60*60*24; // 24 Hours
        
        self.debug = NO;
        
        // In-app notifications
        self.enableInAppNotification = NO;
        self.inAppBackgroundFetchEnabled = YES;
        self.inAppManualTriggerEnabled = NO;
        self.BlueshiftInAppNotificationTimeInterval = kDefaultInAppTimeInterval;
        
        // Default BlueshiftDeviceIdSource
        self.blueshiftDeviceIdSource = BlueshiftDeviceIdSourceIDFV;
        
        // Default Region US
        self.region = BlueshiftRegionUS;
        
        self.sdkCoreDataFilesLocation = BlueshiftFilesLocationDocumentDirectory;        
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
