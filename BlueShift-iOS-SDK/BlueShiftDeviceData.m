//
//  BlueShiftDeviceData.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import "BlueShiftDeviceData.h"
#import "BlueShift.h"
#import "BlueshiftLog.h"
#import "BlueShiftAppData.h"
#import "BlueshiftConstants.h"

static BlueShiftDeviceData *_currentDeviceData = nil;

@implementation BlueShiftDeviceData

+ (instancetype) currentDeviceData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _currentDeviceData = [[self alloc] init];
    });
    return _currentDeviceData;
}

- (NSString *)deviceUUID {
    NSString *deviceUUID = @"";
    switch (_blueshiftDeviceIdSource) {
        case BlueshiftDeviceIdSourceIDFV:
            deviceUUID = self.deviceIDFV;
            break;
        case BlueshiftDeviceIdSourceUUID:
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults stringForKey:kBlueshiftDeviceIdSourceUUID]) {
                deviceUUID = [defaults stringForKey:kBlueshiftDeviceIdSourceUUID];
            } else {
                NSString* UUID = [[NSUUID UUID] UUIDString];
                [defaults setObject:UUID forKey: kBlueshiftDeviceIdSourceUUID];
                deviceUUID = [UUID copy];
            }
        }
            break;
        case BlueshiftDeviceIdSourceIDFVBundleID:
        {
            NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
            NSString* idfv = self.deviceIDFV;
            if (bundleId != nil && idfv != nil) {
                deviceUUID = [NSString stringWithFormat:@"%@:%@", idfv,bundleId];
            } else {
                if (idfv == nil) {
                    [BlueshiftLog logError:nil withDescription:@"Failed to get the IDFV." methodName:nil];
                } else {
                    [BlueshiftLog logError:nil withDescription:@"Failed to get the bundle Id." methodName:nil];
                }
            }
        }
            break;
        case BlueshiftDeviceIdSourceCustom:
            if (self.customDeviceID && ![self.customDeviceID isEqualToString:@""]) {
                deviceUUID = self.customDeviceID;
            } else {
                [BlueshiftLog logError:nil withDescription:@"CUSTOM device id is not provided" methodName:nil];
            }
            break;
        default:
            deviceUUID = self.deviceIDFV;
            break;
    }
    return deviceUUID;
}

- (void)resetDeviceUUID {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBlueshiftDeviceIdSourceUUID];
    [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
}

- (NSString *)deviceIDFV {
    NSString *idfvString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return idfvString;
}

- (NSString *)deviceType {
    return [[UIDevice currentDevice] model];
}

- (NSString *)networkCarrierName {
    // Skip fetching network carrier for simulator
    #if TARGET_OS_SIMULATOR
        return nil;
    #else
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netinfo subscriberCellularProvider];
        return [carrier carrierName];
    #endif
}

- (NSString *)operatingSystem {
    return [NSString stringWithFormat:@"%@ %@",kiOS, [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)deviceManufacturer {
    return kApple;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *deviceMutableDictionary = [NSMutableDictionary dictionary];
    if (self.deviceUUID) {
        [deviceMutableDictionary setObject:self.deviceUUID forKey:kDeviceID];
    }
    
    if (self.deviceType) {
        [deviceMutableDictionary setObject:self.deviceType forKey:kDeviceType];
    }
    
    NSString *storedDeviceToken = [[BlueShift sharedInstance] getDeviceToken];
    if (storedDeviceToken) {
        [deviceMutableDictionary setObject:storedDeviceToken forKey:kDeviceToken];
    }
    
    if (self.deviceIDFV) {
        [deviceMutableDictionary setObject:self.deviceIDFV forKey:kDeviceIDFV];
    }
    
    [deviceMutableDictionary setObject:self.deviceManufacturer forKey:kDeviceManufacturer];
    
    if (self.operatingSystem) {
        [deviceMutableDictionary setObject:self.operatingSystem forKey:kOSName];
    }
    
    NSString *networkCarrier = self.networkCarrierName;
    if (networkCarrier) {
        [deviceMutableDictionary setObject: networkCarrier forKey:kNetworkCarrier];
    }
    
    if (self.currentLocation) {
        [deviceMutableDictionary setObject: [NSNumber numberWithFloat:self.currentLocation.coordinate.latitude] forKey:kLatitude];
        [deviceMutableDictionary setObject:[NSNumber numberWithFloat:self.currentLocation.coordinate.longitude] forKey:kLongitude];
    }
    
    if (self.deviceIDFA) {
        NSString *IDFAString = [self.deviceIDFA isEqualToString:kIDFADefaultValue] ? @"" : self.deviceIDFA;
        [deviceMutableDictionary setObject:IDFAString forKey:kDeviceIDFA];
    }

    return [deviceMutableDictionary copy];
}

-(void)saveDeviceDataForNotificationExtensionUse {
    //Save device data for notifcation extension to use it and send to server with delivered tracking api call
    if (@available(iOS 10.0, *)) {
        @try {
            NSString *deviceId = self.deviceUUID;
            NSString *appName = [[BlueShiftAppData currentAppData] bundleIdentifier];
            NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
            
            if(appGroupID && ![appGroupID isEqualToString:@""] && deviceId && appName) {
                NSUserDefaults *appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
                NSString* bundleId = [[BlueShiftAppData currentAppData] bundleIdentifier];
                NSString *key = [NSString stringWithFormat:@"Blueshift:%@",bundleId];
                //Store data on standard userdefaults for avoiding writing multiple times
                //and avoid warning for writing appgroupid userdefault
                NSDictionary *storedData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
                if (!storedData || (storedData && ![[storedData valueForKey:kDeviceID] isEqual:deviceId])) {
                    NSMutableDictionary *deviceData = [[NSMutableDictionary alloc]init];
                    [deviceData setObject:deviceId forKey:kDeviceID];
                    [deviceData setObject:appName forKey:kAppName];
                    
                    [appGroupUserDefaults setObject:deviceData forKey:key];
                    [[NSUserDefaults standardUserDefaults] setObject:deviceData forKey:key];
                }
            }
        } @catch (NSException *exception) {
            [BlueshiftLog logException:exception withDescription:@"Failed to initialise SDK." methodName:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]];
        }
    }
}

@end
