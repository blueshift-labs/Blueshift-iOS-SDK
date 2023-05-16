//
//  BlueShiftNetworkReachabilityManager.h
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//

#import "BlueShiftRequestOperationManager.h"
#import "BlueShiftRequestQueue.h"

@interface BlueShiftNetworkReachabilityManager : NSObject

/// Check whether internet is connected
+ (BOOL)networkConnected;

@end
