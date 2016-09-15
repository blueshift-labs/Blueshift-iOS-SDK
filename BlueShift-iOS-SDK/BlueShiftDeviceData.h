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
#import <AdSupport/AdSupport.h>
#import "BlueShiftMacros.h"

@class BlueShift;

@interface BlueShiftDeviceData : NSObject

@property (nonatomic, strong) NSString *deviceUUID;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) NSString *deviceIDFA;
@property (nonatomic, strong) NSString *deviceIDFV;
@property  CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) NSString *deviceManufacturer;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, strong) NSString *operatingSystem;
@property (nonatomic, strong) NSString *networkCarrierName;

+ (instancetype) currentDeviceData;

- (NSDictionary *)toDictionary;

@end
