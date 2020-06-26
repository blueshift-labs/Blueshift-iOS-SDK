//
//  BlueShiftDeviceData.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import "BlueShiftDeviceData.h"
#import "BlueShift.h"

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
    if (_blueshiftDeviceIdSource && _blueshiftDeviceIdSource == BlueshiftDeviceIdSourceUUID) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults stringForKey:@"BlueshiftDeviceIdSourceUUID"]) {
            deviceUUID = [defaults stringForKey:@"BlueshiftDeviceIdSourceUUID"];
        } else {
            NSString* UUID = [[NSUUID UUID] UUIDString];
            [defaults setObject:UUID forKey: @"BlueshiftDeviceIdSourceUUID"];
            deviceUUID = [UUID copy];
        }
    } else if (_blueshiftDeviceIdSource && _blueshiftDeviceIdSource == BlueshiftDeviceIdSourceIDFVBundleID && [[NSBundle mainBundle] bundleIdentifier] != nil) {
         NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
         deviceUUID = [NSString stringWithFormat:@"%@:%@", self.deviceIDFV,bundleId];
     } else {
        deviceUUID = self.deviceIDFV;
    }
    return deviceUUID;
}


- (NSString *)deviceIDFV {
    NSString *idfvString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return idfvString;
}

- (NSString *)deviceType {
    return [[UIDevice currentDevice] model];
}

- (NSString *)networkCarrierName {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return [carrier carrierName];
}

- (NSString *)operatingSystem {
    return [NSString stringWithFormat:@"iOS %@", [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)deviceManufacturer {
    return @"apple";
}

- (CLLocation *)currentLocation {
    _currentLocation = [self.locationManager location];
    return _currentLocation;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *deviceMutableDictionary = [NSMutableDictionary dictionary];
    if (self.deviceUUID) {
        [deviceMutableDictionary setObject:self.deviceUUID forKey:@"device_id"];
    }
    
    if (self.deviceType) {
        [deviceMutableDictionary setObject:self.deviceType forKey:@"device_type"];
    }
    
    if (self.deviceToken) {
        NSString *storedDeviceToken = [[BlueShift sharedInstance] getDeviceToken];
        [deviceMutableDictionary setObject:storedDeviceToken forKey:@"device_token"];
    }
    
    if (self.deviceIDFV) {
        [deviceMutableDictionary setObject:self.deviceIDFV forKey:@"device_idfv"];
    }
    
    [deviceMutableDictionary setObject:self.deviceManufacturer forKey:@"device_manufacturer"];
    
    if (self.operatingSystem) {
        [deviceMutableDictionary setObject:self.operatingSystem forKey:@"os_name"];
    }
    
    NSString *networkCarrier = self.networkCarrierName;
    if (networkCarrier) {
        [deviceMutableDictionary setObject: networkCarrier forKey:@"network_carrier"];
    }
    
    if (self.currentLocation) {
        [deviceMutableDictionary setObject: [NSNumber numberWithFloat:self.currentLocation.coordinate.latitude] forKey:@"latitude"];
        [deviceMutableDictionary setObject:[NSNumber numberWithFloat:self.currentLocation.coordinate.longitude] forKey:@"longitude"];
    }
    
    return [deviceMutableDictionary copy];
}


@end
