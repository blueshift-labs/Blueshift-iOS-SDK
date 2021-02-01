//
//  BlueShiftPushAnalytics.h
//  BlueShift-iOS-Extension-SDK
//
//  Created by shahas kp on 11/10/17.
//

#import <Foundation/Foundation.h>

@interface BlueShiftPushAnalytics : NSObject

+ (void)sendPushAnalytics:(NSString *)type withParams:(NSDictionary *)userInfo;

/// Returns the device data dictionary which includes device_id and app_name
+ (NSDictionary*)getDeviceData;

@end
