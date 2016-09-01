//
//  BlueShiftDeviceData.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import "BlueShiftDeviceData.h"


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
    NSString *idfvString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return idfvString;
}

- (NSString *)deviceIDFA {
    NSString *idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return idfaString;
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
        [deviceMutableDictionary setObject:self.deviceToken forKey:@"device_token"];
    }
    
    if (self.deviceIDFA) {
        [deviceMutableDictionary setObject:self.deviceIDFA forKey:@"device_idfa"];
    }
    
    if (self.deviceIDFV) {
        [deviceMutableDictionary setObject:self.deviceIDFV forKey:@"device_idfv"];
    }
    
    [deviceMutableDictionary setObject:self.deviceManufacturer forKey:@"device_manufacturer"];
    
    if (self.operatingSystem) {
        [deviceMutableDictionary setObject:self.operatingSystem forKey:@"os_name"];
    }
    
    if (self.networkCarrierName) {
        [deviceMutableDictionary setObject:self.networkCarrierName forKey:@"network_carrier"];
    }
    
    if (self.currentLocation) {
        [deviceMutableDictionary setObject: [NSNumber numberWithFloat:self.currentLocation.coordinate.latitude] forKey:@"latitude"];
        [deviceMutableDictionary setObject:[NSNumber numberWithFloat:self.currentLocation.coordinate.longitude] forKey:@"longitude"];
    }
    
    return [deviceMutableDictionary copy];
}


@end
