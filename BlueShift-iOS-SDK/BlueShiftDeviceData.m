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

#define kBlueshiftDeviceIdSourceUUID    @"BlueshiftDeviceIdSourceUUID"
#define kLatitude                       @"latitude"
#define kLongitude                      @"longitude"
#define kDeviceIDFA                     @"device_idfa"
#define kNetworkCarrier                 @"network_carrier"
#define kOSName                         @"os_name"
#define kDeviceManufacturer             @"device_manufacturer"
#define kDeviceIDFV                     @"device_idfv"
#define kIDFADefaultValue               @"00000000-0000-0000-0000-000000000000"
#define kDeviceToken                    @"device_token"
#define kDeviceType                     @"device_type"
#define kDeviceID                       @"device_id"
#define kApple                          @"apple"
#define kiOS                            @"iOS"

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
            if (bundleId != nil) {
                deviceUUID = [NSString stringWithFormat:@"%@:%@", self.deviceIDFV,bundleId];
            } else {
                [BlueshiftLog logError:nil withDescription:@"Failed to get the bundle Id." methodName:nil];
            }
        }
            break;
        case BlueshiftDeviceIdSourceCustom:
            if (self.customDeviceID && ![self.customDeviceID isEqualToString:@""]) {
                deviceUUID = self.customDeviceID;
            } else {
                NSLog(@"[BlueShift] - ERROR: CUSTOM device id is not provided");
            }
            break;
        default:
            deviceUUID = self.deviceIDFV;
            break;
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
    return [NSString stringWithFormat:@"%@ %@",kiOS, [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)deviceManufacturer {
    return kApple;
}

- (NSString*)deviceIDFA {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
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
    
    if (self.currentLocation && [BlueShift sharedInstance].config.enableLocationAccess) {
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
        NSString *appGroupID = [BlueShift sharedInstance].config.appGroupID;
        if(appGroupID && ![appGroupID isEqualToString:@""]) {
            NSUserDefaults *appGroupUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
            NSString* bundleId = [[BlueShiftAppData currentAppData] bundleIdentifier];
            NSString *key = [NSString stringWithFormat:@"Blueshift:%@",bundleId];
            //Store data on standard userdefaults for avoiding writing multiple times
            //and avoid warning for writing appgroupid userdefault
            NSDictionary *storedData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
            if (!storedData || (storedData && ![[storedData valueForKey:kDeviceID] isEqual:self.deviceUUID])) {
                NSMutableDictionary *deviceData = [[NSMutableDictionary alloc]init];
                [deviceData setObject:self.deviceUUID forKey:kDeviceID];
                [deviceData setObject:[[BlueShiftAppData currentAppData] bundleIdentifier] forKey:@"app_name"];
                
                [appGroupUserDefaults setObject:deviceData forKey:key];
                [appGroupUserDefaults synchronize];
                [[NSUserDefaults standardUserDefaults] setObject:deviceData forKey:key];
            }
        }
    }
}

@end
