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
    if (_blueshiftDeviceIdSource == BlueshiftDeviceIdSourceUUID) {
        [BlueshiftLog logInfo:@"Resetting the Device id." withDetails:nil methodName:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBlueshiftDeviceIdSourceUUID];
        [[BlueShift sharedInstance] identifyUserWithDetails:nil canBatchThisEvent:NO];
    } else {
        [BlueshiftLog logInfo:@"Can not reset the Device id as it is applicable to only BlueshiftDeviceIdSourceUUID type." withDetails:nil methodName:nil];
    }
}

- (NSString *)deviceIDFV {
    NSString *idfvString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return idfvString;
}

- (NSString *)deviceType {
    return [[UIDevice currentDevice] model];
}

- (NSString *)getNetworkCarrierName {
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
    
    if (@available(iOS 16.0, *)) {
        //Skip adding carrier name to the device info
    } else {
        if(!self.networkCarrierName) {
            self.networkCarrierName = [self getNetworkCarrierName];
        }
        // Added check for simulator which returns nil value.
        if (self.networkCarrierName) {
            [deviceMutableDictionary setObject: self.networkCarrierName forKey:kNetworkCarrier];
        }
    }
    
    if (self.currentLocation) {
        [deviceMutableDictionary setObject: [NSNumber numberWithFloat:self.currentLocation.coordinate.latitude] forKey:kLatitude];
        [deviceMutableDictionary setObject:[NSNumber numberWithFloat:self.currentLocation.coordinate.longitude] forKey:kLongitude];
    }
    
    if (self.deviceIDFA) {
        NSString *IDFAString = [self.deviceIDFA isEqualToString:kIDFADefaultValue] ? @"" : self.deviceIDFA;
        [deviceMutableDictionary setObject:IDFAString forKey:kDeviceIDFA];
    }
    
    if (!self.deviceCountry) {
        self.deviceCountry = (NSString*)[[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    }
    [deviceMutableDictionary setValue:self.deviceCountry forKey:kCountryCode];
    

    if (!self.deviceLanguage) {
        self.deviceLanguage = (NSString*)[[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
    }
    [deviceMutableDictionary setValue:self.deviceLanguage forKey:kLanguageCode];
    
    return [deviceMutableDictionary copy];
}

@end
