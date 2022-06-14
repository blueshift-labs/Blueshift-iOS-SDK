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

@property (nonatomic, strong) NSString *deviceUUID;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) NSString *deviceIDFV;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) NSString *deviceManufacturer;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, strong) NSString *operatingSystem;
@property (nonatomic, strong) NSString *networkCarrierName;
@property (nonatomic, assign) BlueshiftDeviceIdSource blueshiftDeviceIdSource;
@property (nonatomic, strong) NSString *deviceIDFA;

//Custom device id provision for DeviceIDSourceCUSTOM
@property (nonatomic, strong) NSString * customDeviceID;

+ (instancetype) currentDeviceData;

- (NSDictionary *)toDictionary;

/// This method will only work if the device id type is set as UUID. It will not work for device id types IDFV or IDFV:BundleId.
/// Calling this method will reset the existing UUID device id and SDK will generate a new device id.
/// This function will also fire an identify event to update the device to Blueshift.
- (void)resetDeviceUUID;

@end
