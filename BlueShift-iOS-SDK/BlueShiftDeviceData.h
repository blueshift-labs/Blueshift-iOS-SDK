//
//  BlueShiftDeviceData.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreLocation/CoreLocation.h>
#import "BlueshiftDeviceIdSource.h"

@class BlueShift;

@interface BlueShiftDeviceData : NSObject

/// Get current device id
@property (nonatomic, strong) NSString *deviceUUID;

/// Get the push notification device token
@property (nonatomic, strong) NSString *deviceToken;

/// Get the device identifier for the vendor
@property (nonatomic, strong) NSString *deviceIDFV;

/// Set the location information to SDK
@property (nonatomic, strong) CLLocation *currentLocation;

/// Get the device manufacturere
@property (nonatomic, strong) NSString *deviceManufacturer;

/// Get the device type
@property (nonatomic, strong) NSString *deviceType;

/// Get the device OS and version
@property (nonatomic, strong) NSString *operatingSystem;

/// Get the network carrier name
@property (nonatomic, strong) NSString *networkCarrierName;

/// Get the selected device id source type
@property (nonatomic, assign) BlueshiftDeviceIdSource blueshiftDeviceIdSource;

/// Set the device Advertising id to SDK
@property (nonatomic, strong) NSString *deviceIDFA;
@property (nonatomic, strong) NSString *deviceLanguage;
@property (nonatomic, strong) NSString *deviceCountry;

/// Set the custom device id to the SDK
/// when blueshiftDeviceIdSource is set as DeviceIDSourceCUSTOM.
@property (nonatomic, strong) NSString * customDeviceID;

+ (instancetype) currentDeviceData;

- (NSDictionary *)toDictionary;

/// This method will only work if the device id type is set as UUID. It will not work for device id types IDFV or IDFV:BundleId.
/// Calling this method will reset the existing UUID device id and SDK will generate a new device id.
/// This function will also fire an identify event to update the device to Blueshift.
- (void)resetDeviceUUID;

@end
