//
//  BlueShiftConfig.h
//  BlueShiftiOSSDK
//
//  Created by Arjun K P on 19/02/15.
//  Copyright (c) 2015 Bullfinch Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueShiftDeepLink.h"
#import "BlueShiftUserInfo.h"

@interface BlueShiftConfig : NSObject

@property NSString *apiKey;
@property NSDictionary *applicationLaunchOptions;

@property NSURL *productPageURL;
@property NSURL *cartPageURL;
@property NSURL *offerPageURL;

- (BOOL)validateConfigDetails;

+ (BlueShiftConfig *)config;
@end
