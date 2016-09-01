//
//  BlueShiftNetworkReachabilityManager.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import "AFNetworkReachabilityManager.h"
#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftRequestQueue.h"

@interface BlueShiftNetworkReachabilityManager : AFNetworkReachabilityManager



// Method to start monitoring network connectivity ...
+ (void)monitorNetworkConnectivity;



// Method to check whether internet is connected ...
+ (BOOL)networkConnected;

@end
