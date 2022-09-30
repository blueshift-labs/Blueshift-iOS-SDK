//
//  BlueShiftNetworkReachabilityManager.m
//  BlueShift-iOS-SDK
//
//  Copyright (c) Blueshift. All rights reserved.
//
#import "BlueShiftNetworkReachabilityManager.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "NetworkReachability.h"

@implementation BlueShiftNetworkReachabilityManager

+ (BOOL)networkConnected {
    BlueShiftReachability *reach = [BlueShiftReachability reachabilityWithHostName:@"www.google.com"];
    if (reach.currentReachabilityStatus == ReachableViaWiFi || reach.currentReachabilityStatus == ReachableViaWWAN) {
        return YES;
    } else {
        return NO;
    }
}

@end
