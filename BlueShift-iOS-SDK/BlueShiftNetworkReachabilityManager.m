//
//  BlueShiftNetworkReachabilityManager.m
//  BlueShift-iOS-SDK
//
//  Created by Arjun K P on 02/03/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import "BlueShiftNetworkReachabilityManager.h"

@implementation BlueShiftNetworkReachabilityManager



// Method to start monitoring network connectivity ...

+ (void)monitorNetworkConnectivity {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [BlueShiftRequestQueue setRequestQueueStatus:BlueShiftRequestQueueStatusAvailable];
                [BlueShiftRequestQueue processRequestsInQueue];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                break;
        }
    }];
}



// Method to check whether internet is connected ...

+ (BOOL)networkConnected {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

@end
