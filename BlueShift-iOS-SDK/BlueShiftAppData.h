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
@property BOOL isPushPermissionAccepted;
@property (nonatomic) BOOL enablePush;

+ (instancetype) currentAppData;

- (NSDictionary *)toDictionary;

@end
