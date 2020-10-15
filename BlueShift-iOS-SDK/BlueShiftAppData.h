//
//  BlueShiftAppData.h
//  BlueShift-iOS-SDK
//
//  Created by Shahas on 27/12/16.
//  Copyright © 2016 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlueShiftAppData : NSObject

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *appBuildNumber;
@property (nonatomic, strong) NSString *bundleIdentifier;
@property BOOL currentUNAuthorizationStatus;

/// Set this flag to false to disable push notifications explicitly. You will need to fire the identify call after changing the value of flag.
/// To enable push notification later, you will need to set it to true and fire identify call.
/// The default value fot the enablePush is set to true
@property (nonatomic) BOOL enablePush;

+ (instancetype) currentAppData;

- (NSDictionary *)toDictionary;

@end
