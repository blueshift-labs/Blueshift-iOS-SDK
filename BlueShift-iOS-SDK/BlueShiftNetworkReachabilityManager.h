//
//  BlueShiftNetworkReachabilityManager.h
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
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
